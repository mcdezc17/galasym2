#!/usr/bin/env python3
"""
find_center.py
===============

Reimplementación en Python de la tarea IRAF `find_center` (find_center.cl):
búsqueda, por fuerza bruta sobre una grilla de centros candidatos, del pixel
que minimiza la suma de ABS(I-I_180) y de la suma de RMS(I-I_180) dentro de
una apertura elíptica (0.95 * petro_r) sin normalización ni corrección de
cielo.

find_center.cl hace, por cada uno de los delta_pix^2 puntos de la grilla:
imcopy (recorte a disco) + imtranspose x2 (rotación 180 vía transposición
doble) + imexpr x2 (residuo) + imstat x2 (suma) + imdelete x5 (limpieza) --
~10 operaciones de I/O sobre disco por punto de grilla, por objeto. Esta
versión carga cada imagen enmascarada UNA sola vez a memoria (numpy), calcula
la máscara elíptica UNA sola vez por objeto (siempre centrada en el medio de
la caja de recorte, no depende del punto de grilla) y hace toda la búsqueda
como slicing/aritmética vectorizada en memoria.

Equivalencias clave con find_center.cl:
  - La rotación 180 grados de find_center.cl (imtranspose seguido de un
    flip de eje, aplicado dos veces) es matemáticamente idéntica a invertir
    ambos ejes del array de una sola vez (identidad estándar
    rot90(rot90(M)) == M[::-1, ::-1]).
  - Los dos factores de radio de Petrosian usados NO son el mismo: 1.5 (más
    un margen de 0.5 px) fija el tamaño de la caja de recorte, mientras que
    0.95 es el semieje real de la apertura elíptica de medida.
  - Bordes de imagen: a diferencia de find_center.cl (que recorta con
    `imcopy` sobre una sección que podría salirse de la imagen), esta
    versión rellena con NaN los píxeles fuera de los límites de la imagen de
    entrada y los excluye de la suma. El resultado es idéntico al original
    mientras la elipse de medida (radio ~0.95*petro_r, más chica que la caja
    de recorte) quede contenida en píxeles reales de la imagen.

ADVERTENCIA: la conversión pixel->cielo (RA/DEC) usa astropy.wcs en vez de
`wcsctran` de IRAF. Debe validarse contra la salida real de find_center.cl en
datos reales antes de usarse en producción -- ver plan de implementación.

Uso:
    find_center                       # parado en la carpeta de la muestra
                                       # (usa gconf y data/ por defecto)
    find_center /ruta/a/gconf         # con gconf explícito
    find_center /ruta/a/gconf --data-dir otra_data

Entradas esperadas (relativas a --data-dir, por defecto "data", igual que en
find_center.cl):
    <data-dir>/results_sex/params_to_index.txt
    <data-dir>/data_images/observed/<ID>_obs_secondmask.fits
    <data-dir>/data_images/observed/<ID>.fits

Salidas:
    <data-dir>/data_files/abs_mincenter.txt
    <data-dir>/data_files/rms_mincenter.txt
(mismo formato de 5 columnas -- ID, RAmin, DECmin, Xmin, Ymin -- que produce
find_center.cl; los consumidores (alpha_index.cl, outer_*_index.cl) los leen
con `scan()`, tolerante a ancho/precisión.)
"""

import argparse
import sys
import warnings
from pathlib import Path

import numpy as np
from astropy.io import fits
from astropy.wcs import WCS

# Factores de radio de Petrosian (idénticos a find_center.cl):
BOX_MARGIN_SCALE = 1.5   # margen de la caja de recorte (con +0.5 px extra)
APERTURE_SCALE = 0.95    # semieje real de la apertura elíptica de medida


def read_catalog(path):
    """Lee params_to_index.txt (mismo orden de columnas que find_center.cl:115)."""
    records = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) < 12:
                raise ValueError(f"Línea de catálogo mal formada en {path}: {line!r}")
            records.append({
                "id_obj": parts[0],
                "xc": int(round(float(parts[4]))),
                "yc": int(round(float(parts[5]))),
                "a_img": float(parts[6]),
                "b_img": float(parts[7]),
                "theta_img": float(parts[10]),
                "petro_r": float(parts[11]),
            })
    return records


def read_pixel_scale_seeing(default_sex_path):
    """Lee PIXEL_SCALE y SEEING_FWHM de <cfg>/sextractor/default.sex."""
    pixel_scale = None
    seeing_arc = None
    with open(default_sex_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            tokens = line.split()
            key = tokens[0]
            if key == "PIXEL_SCALE":
                pixel_scale = float(tokens[1])
            elif key == "SEEING_FWHM":
                seeing_arc = float(tokens[1])
    if pixel_scale is None or seeing_arc is None:
        raise ValueError(
            f"No se encontró PIXEL_SCALE y/o SEEING_FWHM en {default_sex_path}"
        )
    return pixel_scale, seeing_arc


def build_ellipse_mask(xlen, ylen, cx, cy, r_a, r_b, theta_rad):
    """Máscara booleana de la elipse rotada (misma expresión que ellip_expr
    en find_center.cl:173), en coordenadas de pixel 1-indexadas I,J."""
    I = np.arange(1, xlen + 1, dtype=float)
    J = np.arange(1, ylen + 1, dtype=float)
    II, JJ = np.meshgrid(I, J)  # shape (ylen, xlen)
    cos_e, sin_e = np.cos(theta_rad), np.sin(theta_rad)
    term1 = ((II - cx) * cos_e + (JJ - cy) * sin_e) ** 2 / r_a ** 2
    term2 = ((II - cx) * sin_e - (JJ - cy) * cos_e) ** 2 / r_b ** 2
    return (term1 + term2) <= 1.0


def extract_padded_crop(arr, px1, px2, py1, py2):
    """Recorta arr[py1:py2, px1:px2] (1-indexado, inclusive) rellenando con
    NaN los píxeles fuera de los límites de arr."""
    xlen = px2 - px1 + 1
    ylen = py2 - py1 + 1
    out = np.full((ylen, xlen), np.nan, dtype=float)
    h, w = arr.shape
    src_x0, src_x1 = max(px1, 1), min(px2, w)
    src_y0, src_y1 = max(py1, 1), min(py2, h)
    if src_x0 <= src_x1 and src_y0 <= src_y1:
        dst_x0 = src_x0 - px1
        dst_y0 = src_y0 - py1
        out[dst_y0:dst_y0 + (src_y1 - src_y0 + 1),
            dst_x0:dst_x0 + (src_x1 - src_x0 + 1)] = \
            arr[src_y0 - 1:src_y1, src_x0 - 1:src_x1]
    return out


def find_object_center(arr, rec, delta_pix):
    """Búsqueda en grilla del centro que minimiza ABS(I-I_180) y RMS(I-I_180).

    Devuelve ((min_x0_abs, min_y0_abs), (min_x0_rms, min_y0_rms)).
    """
    theta_rad = np.deg2rad(rec["theta_img"])

    A_outer = BOX_MARGIN_SCALE * rec["petro_r"] * rec["a_img"] + 0.5
    B_outer = BOX_MARGIN_SCALE * rec["petro_r"] * rec["b_img"] + 0.5
    xlen_min = int(2 * np.sqrt((A_outer * np.cos(theta_rad)) ** 2 +
                                (B_outer * np.sin(theta_rad)) ** 2))
    ylen_min = int(2 * np.sqrt((A_outer * np.sin(theta_rad)) ** 2 +
                                (B_outer * np.cos(theta_rad)) ** 2))
    if xlen_min % 2 == 0:
        xlen_min += 1
    if ylen_min % 2 == 0:
        ylen_min += 1

    tmp_xc = xlen_min / 2.0
    tmp_yc = ylen_min / 2.0
    r_a = APERTURE_SCALE * rec["a_img"] * rec["petro_r"]
    r_b = APERTURE_SCALE * rec["b_img"] * rec["petro_r"]
    mask = build_ellipse_mask(xlen_min, ylen_min, tmp_xc, tmp_yc, r_a, r_b, theta_rad)

    half_x = (xlen_min - 1) // 2
    half_y = (ylen_min - 1) // 2
    x0_start = rec["xc"] - delta_pix // 2
    y0_start = rec["yc"] - delta_pix // 2

    n_grid = delta_pix * delta_pix
    sum_abs = np.empty(n_grid)
    sum_rms = np.empty(n_grid)
    x0s = np.empty(n_grid, dtype=int)
    y0s = np.empty(n_grid, dtype=int)

    idx = 0
    for i in range(delta_pix):
        x0 = x0_start + i
        px1, px2 = x0 - half_x, x0 + half_x
        for j in range(delta_pix):
            y0 = y0_start + j
            py1, py2 = y0 - half_y, y0 + half_y

            crop = extract_padded_crop(arr, px1, px2, py1, py2)
            # Rotación 180 grados == invertir ambos ejes (ver docstring del módulo).
            crop_rot = crop[::-1, ::-1]

            with np.errstate(invalid="ignore"):
                diff = crop - crop_rot
            valid = mask & np.isfinite(diff)

            if valid.any():
                sum_abs[idx] = np.abs(diff[valid]).sum()
                sum_rms[idx] = np.square(diff[valid]).sum()
            else:
                sum_abs[idx] = 0.0
                sum_rms[idx] = 0.0

            x0s[idx] = x0
            y0s[idx] = y0
            idx += 1

    i_abs = int(np.argmin(sum_abs))
    i_rms = int(np.argmin(sum_rms))
    return (int(x0s[i_abs]), int(y0s[i_abs])), (int(x0s[i_rms]), int(y0s[i_rms]))


def pix_to_world(image_path, x0, y0):
    """Convierte pixel (1-indexado, 'logical') a cielo ('world'), equivalente
    a wcsctran(inwcs='logical', outwcs='world') de IRAF."""
    with fits.open(image_path) as hdul:
        header = hdul[0].header
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        w = WCS(header)
        ra, dec = w.wcs_pix2world([[x0, y0]], 1)[0]
    return float(ra), float(dec)


# find_center.py vive en config/src/; su directorio padre-padre es config/,
# el mismo directorio que 'set gconf' apunta en galasym2.cl.
GCONF_DEFAULT = str(Path(__file__).resolve().parent.parent) + "/"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("Uso:")[0])
    parser.add_argument("cfg", nargs="?", default=GCONF_DEFAULT,
                         help="Directorio de configuración (gconf de IRAF); "
                              "debe contener 'sextractor/default.sex'. "
                              f"Por defecto: {GCONF_DEFAULT} (autodetectado "
                              "como el directorio 'config/' que contiene a "
                              "este script).")
    parser.add_argument("--data-dir", default="data",
                         help="Raíz del árbol de datos en tiempo de ejecución "
                              "(por defecto 'data', igual que find_center.cl).")
    args = parser.parse_args(argv)

    data_dir = Path(args.data_dir)
    outsex_dir = data_dir / "results_sex"
    datafiles_dir = data_dir / "data_files"
    observed_dir = data_dir / "data_images" / "observed"
    cfg_dir = Path(args.cfg)

    catalog_path = outsex_dir / "params_to_index.txt"
    if not catalog_path.exists():
        print(f"ERR(fatal): mandatory that it exist:\n - {catalog_path}", file=sys.stderr)
        return 1

    records = read_catalog(catalog_path)
    pixel_scale, seeing_arc = read_pixel_scale_seeing(cfg_dir / "sextractor" / "default.sex")
    seeing_pix = seeing_arc / pixel_scale
    delta_pix = int(seeing_pix + 1.0)
    if delta_pix % 2 == 0:
        delta_pix += 1

    datafiles_dir.mkdir(parents=True, exist_ok=True)

    abs_lines = []
    rms_lines = []

    for n, rec in enumerate(records, start=1):
        id_obj = rec["id_obj"]
        masked_path = observed_dir / f"{id_obj}_obs_secondmask.fits"
        orig_path = observed_dir / f"{id_obj}.fits"

        if not masked_path.exists():
            print(f"AVISO: falta {masked_path}, se omite {id_obj}", file=sys.stderr)
            continue

        with fits.open(masked_path) as hdul:
            arr = hdul[0].data.astype(float)

        print(f"\r - calculating for n: {n:3d} | OBJ: {id_obj}", end="")

        (min_x0_abs, min_y0_abs), (min_x0_rms, min_y0_rms) = \
            find_object_center(arr, rec, delta_pix)

        if orig_path.exists():
            ra_abs, dec_abs = pix_to_world(orig_path, min_x0_abs, min_y0_abs)
            ra_rms, dec_rms = pix_to_world(orig_path, min_x0_rms, min_y0_rms)
        else:
            print(f"\nAVISO: falta {orig_path}, no se calcula RA/DEC para {id_obj}",
                  file=sys.stderr)
            ra_abs = dec_abs = ra_rms = dec_rms = float("nan")

        abs_lines.append("%32s %14f %14f %5d %5d\n" %
                          (id_obj, ra_abs, dec_abs, min_x0_abs, min_y0_abs))
        rms_lines.append("%32s %14f %14f %5d %5d\n" %
                          (id_obj, ra_rms, dec_rms, min_x0_rms, min_y0_rms))

    print()

    with open(datafiles_dir / "abs_mincenter.txt", "w") as f:
        f.write("# Lista de centros (en pixeles) que minimizan la suma de ABS(I-I_180)\n")
        f.write("#%31s %14s %14s %5s %5s\n" % ("ID", "RAmin", "DECmin", "Xmin", "Ymin"))
        f.writelines(abs_lines)

    with open(datafiles_dir / "rms_mincenter.txt", "w") as f:
        f.write("# Lista de centros (en pixeles) que minimizan la suma de RMS(I-I_180)\n")
        f.write("#%31s %14s %14s %5s %5s\n" % ("ID", "RAmin", "DECmin", "Xmin", "Ymin"))
        f.writelines(rms_lines)

    return 0


if __name__ == "__main__":
    sys.exit(main())
