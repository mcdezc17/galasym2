#!/usr/bin/env python3
"""
pawlik_shape_asymmetry.py
==========================

Implementación "genuina" del índice de asimetría de forma A_S de
Pawlik, Wild, Verma et al. (2016, MNRAS 456, 3032), incluyendo:

  1. Suavizado boxcar 3x3 sobre la imagen (running average).
  2. Máscara de detección binaria construida por CRECIMIENTO DE REGIÓN
     (flood-fill / 8-conectividad) a partir de un píxel semilla central,
     aceptando solo píxeles conectados con intensidad > n_sigma * std del
     fondo. Esto es fiel al texto original: "starting from the central
     pixel... accepting all pixels that are 8-connected to previously
     accepted pixels and have intensities above the chosen threshold."
  3. Refinamiento del "centro" real de la galaxia como el píxel más
     brillante DENTRO de la máscara (según el texto original), usado
     luego para calcular R_max, la apertura elíptica y la rotación 180°.
     -- Si el usuario entrega una lista de centros, esos centros se usan
        directamente para todo (semilla, R_max, elipse, rotación), sin
        refinar al píxel más brillante.
     -- Si NO se entrega lista de centros, se usa el centro geométrico
        de la imagen como semilla, y luego SÍ se refina al píxel más
        brillante dentro de la máscara (comportamiento fiel al paper).
  4. R_max: distancia entre el centro y el píxel más lejano dentro de la
     máscara.
  5. Refinamiento de fondo en dos pasadas: se recalcula el nivel de cielo
     y su std dentro de un anillo circular entre 1x y 2x R_max, se resta
     ese nivel de cielo de la imagen, y se repite la detección con el
     nuevo std. (Activado por defecto; desactivable con --no-bg-refine).
  6. Apertura elíptica alineada con los ejes principales (PCA) de la
     máscara, escalada para que la máscara quede exactamente inscrita.
  7. A_S = sum(|S - S_180|) / sum(2*S), calculado dentro de la apertura
     elíptica, donde S_180 es la máscara rotada 180° respecto al centro.

Uso:
    python pawlik_shape_asymmetry.py catalogo.csv --images-dir ./imagenes \
        --output-dir ./resultados_pawlik

    python pawlik_shape_asymmetry.py catalogo.dat --id-col 1 \
        --images-dir ./imagenes --centers-list centros.dat \
        --centers-id-col 1 --centers-x-col 2 --centers-y-col 3 \
        --output-dir ./resultados_pawlik

Referencia:
    Pawlik, M. M., Wild, V., Verma, A., et al. 2016, MNRAS, 456, 3032.
"""

import argparse
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from astropy.io import fits
from astropy.stats import sigma_clipped_stats
from astropy.wcs import WCS
from scipy.ndimage import uniform_filter, label, map_coordinates


# --------------------------------------------------------------------------
# Lectura de catálogos (ascii de ancho variable separado por espacios, o csv)
# --------------------------------------------------------------------------

def load_table(path, id_col=None):
    """
    Carga una tabla ascii (separada por espacios, con posible línea de
    encabezado que comienza con '#') o csv (con encabezado normal y una
    columna llamada 'ID').

    Parameters
    ----------
    path : str o Path
    id_col : int o None
        Para archivos ascii: número de columna (1-indexado) que contiene
        los ID. Obligatorio para ascii. Ignorado para csv (se busca la
        columna 'ID' automáticamente, sin importar mayúsculas/minúsculas).

    Returns
    -------
    df : pandas.DataFrame
        Todas las columnas leídas como texto (string), para preservar el
        formato original al reescribir la tabla de salida.
    colnames : list of str
    fmt : {'ascii', 'csv'}
    id_colname : str
        Nombre de la columna usada como ID (según colnames).
    """
    path = Path(path)
    is_csv = path.suffix.lower() == ".csv"

    if is_csv:
        df = pd.read_csv(path, dtype=str)
        colnames = list(df.columns)
        id_matches = [c for c in colnames if c.strip().lower() == "id"]
        if not id_matches:
            raise ValueError(
                f"No se encontró una columna llamada 'ID' en {path}. "
                f"Columnas disponibles: {colnames}"
            )
        id_colname = id_matches[0]
        return df, colnames, "csv", id_colname

    # --- ascii ---
    if id_col is None:
        raise ValueError(
            "Para archivos ascii debes indicar --id-col (número de "
            "columna, contando desde 1)."
        )

    header_line = None
    data_lines = []
    with open(path) as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line.strip():
                continue
            if line.lstrip().startswith("#"):
                if header_line is None:
                    header_line = line.lstrip("#").strip()
                continue
            data_lines.append(line.split())

    if not data_lines:
        raise ValueError(f"No se encontraron filas de datos en {path}")

    ncols = len(data_lines[0])
    if header_line is not None:
        header_names = header_line.split()
    else:
        header_names = []
    if len(header_names) != ncols:
        header_names = [f"col{i + 1}" for i in range(ncols)]

    if not (1 <= id_col <= ncols):
        raise ValueError(
            f"--id-col={id_col} fuera de rango; el archivo tiene {ncols} "
            f"columnas."
        )

    df = pd.DataFrame(data_lines, columns=header_names)
    id_colname = header_names[id_col - 1]
    return df, header_names, "ascii", id_colname


def load_centers(path, id_col=1, x_col=2, y_col=3):
    """
    Carga la lista de centros de rotación (ID, X, Y). Soporta el mismo
    formato ascii/csv que `load_table`. Devuelve un dict {ID: (x, y)}
    con x, y en coordenadas de píxel (convención FITS: eje x = columna,
    eje y = fila, origen en (0,0) para el primer píxel, como en el
    resto del script).
    """
    path = Path(path)
    is_csv = path.suffix.lower() == ".csv"

    if is_csv:
        df = pd.read_csv(path, dtype=str)
        cols = list(df.columns)
        idn = cols[id_col - 1]
        xn = cols[x_col - 1]
        yn = cols[y_col - 1]
    else:
        data_lines = []
        with open(path) as f:
            for raw in f:
                line = raw.rstrip("\n")
                if not line.strip() or line.lstrip().startswith("#"):
                    continue
                data_lines.append(line.split())
        ncols = len(data_lines[0])
        df = pd.DataFrame(data_lines, columns=[f"col{i+1}" for i in range(ncols)])
        idn, xn, yn = f"col{id_col}", f"col{x_col}", f"col{y_col}"

    centers = {}
    for _, row in df.iterrows():
        try:
            centers[row[idn]] = (float(row[xn]), float(row[yn]))
        except (ValueError, KeyError):
            continue
    return centers


def load_centers_raw(path, id_col=1):
    """
    Carga la lista de centros preservando su estructura original completa,
    para poder reescribirla más tarde actualizando solo algunas columnas
    sin perder el resto. Soporta tanto ascii (separado por espacios, con
    posibles líneas de comentario '#') como csv (con encabezado normal
    separado por comas).

    Returns
    -------
    fmt : {'ascii', 'csv'}
    header : list of str
        Para ascii: las líneas de comentario tal cual (verbatim).
        Para csv: una lista de un solo elemento con los nombres de columna
        originales (para reconstruir el encabezado csv).
    rows : list of (id, tokens)
        Cada fila de datos como lista cruda de valores (str), en el orden
        original de las columnas.
    """
    path = Path(path)
    is_csv = path.suffix.lower() == ".csv"

    if is_csv:
        df = pd.read_csv(path, dtype=str)
        colnames = list(df.columns)
        if not (1 <= id_col <= len(colnames)):
            raise ValueError(
                f"--centers-id-col={id_col} fuera de rango; el csv tiene "
                f"{len(colnames)} columnas."
            )
        rows = []
        for _, row in df.iterrows():
            tokens = [str(row[c]) for c in colnames]
            rows.append((tokens[id_col - 1], tokens))
        return "csv", [",".join(colnames)], rows

    header_lines = []
    rows = []
    with open(path) as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line.strip():
                continue
            if line.lstrip().startswith("#"):
                header_lines.append(line)
                continue
            tokens = line.split()
            if len(tokens) < id_col:
                continue
            rows.append((tokens[id_col - 1], tokens))
    return "ascii", header_lines, rows


def write_updated_centers_list(out_path, fmt, header, rows, updates,
                                x_col, y_col, ra_col=None, dec_col=None):
    """
    Reescribe la lista de centros original (tal como la devuelve
    `load_centers_raw`) sustituyendo, para cada ID presente en `updates`,
    los valores de las columnas X/Y (y RA/DEC si corresponde) por el
    centro de rotación EFECTIVAMENTE usado (en coordenadas de la imagen
    original, no del recorte). Las filas cuyo ID no aparece en `updates`
    (p. ej. porque la galaxia no se pudo procesar) se copian sin modificar.
    Soporta tanto ascii como csv, según `fmt`.

    updates : dict {ID: {"x":..., "y":..., "ra":..., "dec":...}}
    """
    sep = "," if fmt == "csv" else " "
    lines_out = list(header)
    for gal_id, tokens in rows:
        tokens = list(tokens)  # copia, no modificar la original
        upd = updates.get(gal_id)
        if upd is not None:
            if x_col - 1 < len(tokens) and upd.get("x") is not None:
                tokens[x_col - 1] = f"{upd['x']:.3f}"
            if y_col - 1 < len(tokens) and upd.get("y") is not None:
                tokens[y_col - 1] = f"{upd['y']:.3f}"
            if ra_col is not None and dec_col is not None \
                    and upd.get("ra") is not None and upd.get("dec") is not None:
                if ra_col - 1 < len(tokens):
                    tokens[ra_col - 1] = f"{upd['ra']:.8f}"
                if dec_col - 1 < len(tokens):
                    tokens[dec_col - 1] = f"{upd['dec']:.8f}"
        lines_out.append(sep.join(tokens))

    with open(out_path, "w") as f:
        f.write("\n".join(lines_out) + "\n")


# --------------------------------------------------------------------------
# Procesamiento de imagen individual
# --------------------------------------------------------------------------

def boxcar_smooth(data, size=3):
    """Filtro boxcar (media local) tratando NaN como huecos, no como ceros."""
    data = np.asarray(data, dtype=float)
    valid = np.isfinite(data)
    filled = np.where(valid, data, 0.0)
    summed = uniform_filter(filled, size=size, mode="constant", cval=0.0)
    counts = uniform_filter(valid.astype(float), size=size, mode="constant", cval=0.0)
    with np.errstate(invalid="ignore", divide="ignore"):
        out = summed / counts
    out[counts == 0] = 0.0
    return out


def crop_square_min(data, center_xy):
    """
    Recorta el cuadrado simétrico MÁS GRANDE posible centrado en
    `center_xy` (x, y) que cabe completamente dentro de `data`. Esto
    garantiza que la rotación de 180 grados respecto al nuevo centro no
    necesite píxeles fuera de la imagen original.

    Returns
    -------
    cropped : 2D ndarray
    new_center_xy : (x, y) en el sistema de coordenadas del recorte
    offset_xy : (x0, y0) esquina inferior-izquierda del recorte en el
        sistema de coordenadas original (para poder reconstruir si hace
        falta)
    """
    ny, nx = data.shape
    cx, cy = center_xy
    row_c = int(round(cy))
    col_c = int(round(cx))
    row_c = np.clip(row_c, 0, ny - 1)
    col_c = np.clip(col_c, 0, nx - 1)

    half = min(row_c, ny - 1 - row_c, col_c, nx - 1 - col_c)
    if half < 1:
        # el centro está pegado al borde; usar lo que se pueda (mínimo 1 px)
        half = max(half, 0)

    r0, r1 = row_c - half, row_c + half + 1
    c0, c1 = col_c - half, col_c + half + 1
    cropped = data[r0:r1, c0:c1]

    new_cx = cx - c0
    new_cy = cy - r0
    return cropped, (new_cx, new_cy), (c0, r0)


def grow_region(smoothed, threshold, seed_rc, connectivity=8, search_radius=5,
                 max_growth_radius=None):
    """
    Máscara binaria por crecimiento de región (8-conectados por defecto)
    a partir del píxel semilla `seed_rc` = (fila, columna).

    Si el píxel semilla no supera el umbral, se busca el píxel > umbral
    más cercano dentro de una ventana de `search_radius` píxeles y se usa
    como semilla (robustez ante centros ligeramente desalineados).

    max_growth_radius : float o None
        Si se entrega, limita el crecimiento a píxeles dentro de esta
        distancia (en píxeles) de la semilla EFECTIVAMENTE usada. Esto
        evita que la máscara se "fugue" hacia una fuente brillante vecina
        (p. ej. una estrella cercana) cuando existe un puente de píxeles
        tenues por encima del umbral que conecta ambas fuentes: sin este
        límite, el crecimiento por conectividad-8 no distingue entre
        "estructura real de la galaxia" y "objeto distinto conectado por
        casualidad", y la máscara resultante (y por lo tanto R_max, la
        elipse y A_S) queda contaminada por la fuente vecina.

    Returns
    -------
    mask : 2D ndarray (bool)
    seed_used : (row, col) semilla efectivamente usada, o None si no se
        encontró ningún píxel válido.
    """
    above = smoothed > threshold
    ny, nx = smoothed.shape
    row_s, col_s = seed_rc
    row_s = int(np.clip(round(row_s), 0, ny - 1))
    col_s = int(np.clip(round(col_s), 0, nx - 1))

    if not above[row_s, col_s]:
        found = None
        for r in range(1, search_radius + 1):
            r0, r1 = max(0, row_s - r), min(ny, row_s + r + 1)
            c0, c1 = max(0, col_s - r), min(nx, col_s + r + 1)
            sub = above[r0:r1, c0:c1]
            if sub.any():
                ys, xs = np.nonzero(sub)
                dists = (ys + r0 - row_s) ** 2 + (xs + c0 - col_s) ** 2
                k = np.argmin(dists)
                found = (ys[k] + r0, xs[k] + c0)
                break
        if found is None:
            return np.zeros_like(above), None
        row_s, col_s = found

    if connectivity == 8:
        structure = np.ones((3, 3), dtype=int)
    elif connectivity == 4:
        structure = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]])
    else:
        raise ValueError("connectivity debe ser 4 u 8")

    labeled, _ = label(above, structure=structure)
    seed_label = labeled[row_s, col_s]
    if seed_label == 0:
        return np.zeros_like(above), (row_s, col_s)

    mask = labeled == seed_label

    if max_growth_radius is not None:
        Y, X = np.mgrid[0:ny, 0:nx]
        dist = np.hypot(Y - row_s, X - col_s)
        mask = mask & (dist <= max_growth_radius)
        # Al recortar por radio, la región puede quedar fragmentada
        # (p. ej. si el "puente" hacia la fuente vecina caía justo en el
        # borde del radio). Nos quedamos solo con el fragmento que sigue
        # conteniendo la semilla.
        labeled2, _ = label(mask, structure=structure)
        seed_label2 = labeled2[row_s, col_s]
        mask = (labeled2 == seed_label2) if seed_label2 != 0 else np.zeros_like(above)

    return mask, (row_s, col_s)


def brightest_pixel_in_mask(data, mask):
    """Índice (fila, col) del píxel de mayor valor dentro de la máscara."""
    vals = np.where(mask, data, -np.inf)
    idx = np.unravel_index(np.argmax(vals), vals.shape)
    return idx  # (row, col)


def brightest_pixel_near_seed(data, mask, seed_rc, radius):
    """
    Índice (fila, col) del píxel más brillante DENTRO de la máscara, mas
    restringido a una ventana cuadrada de +/- `radius` píxeles alrededor
    de `seed_rc` (es decir, un grid de (2*radius+1) x (2*radius+1)).

    A diferencia de `brightest_pixel_in_mask`, esto NO se ve afectado por
    el tamaño total de la máscara: si la máscara se fusionó con una
    fuente vecina (p. ej. una estrella) lejos de la semilla, esa fuente
    queda fuera de la ventana de búsqueda y no puede ser elegida como
    centro, sin necesidad de restringir la máscara en sí.

    Si ningún píxel de la máscara cae dentro de la ventana (caso
    degenerado, p. ej. semilla desplazada respecto a la detección), se
    devuelve la propia semilla como respaldo.
    """
    ny, nx = data.shape
    row_s, col_s = int(round(seed_rc[0])), int(round(seed_rc[1]))
    r0, r1 = max(0, row_s - radius), min(ny, row_s + radius + 1)
    c0, c1 = max(0, col_s - radius), min(nx, col_s + radius + 1)

    sub_mask = mask[r0:r1, c0:c1]
    sub_data = data[r0:r1, c0:c1]

    if not sub_mask.any():
        return (row_s, col_s)

    vals = np.where(sub_mask, sub_data, -np.inf)
    idx_local = np.unravel_index(np.argmax(vals), vals.shape)
    return (idx_local[0] + r0, idx_local[1] + c0)


def r_max(mask, center_rc):
    """Distancia máxima (en píxeles) entre `center_rc` y cualquier píxel de la máscara."""
    ys, xs = np.nonzero(mask)
    if ys.size == 0:
        return 0.0
    row_c, col_c = center_rc
    d = np.hypot(ys - row_c, xs - col_c)
    return float(d.max())


def annulus_background(data, center_rc, r_in, r_out, sigma=3.0, maxiters=5):
    """Estadística de fondo (sigma-clipped) dentro de un anillo circular."""
    ny, nx = data.shape
    Y, X = np.mgrid[0:ny, 0:nx]
    row_c, col_c = center_rc
    r = np.hypot(Y - row_c, X - col_c)
    annulus = (r >= r_in) & (r <= r_out) & np.isfinite(data)
    if annulus.sum() < 10:
        # anillo insuficiente (imagen muy pequeña / R_max grande): usar
        # toda la imagen fuera de un radio r_in como respaldo
        annulus = (r >= r_in) & np.isfinite(data)
    if annulus.sum() < 10:
        annulus = np.isfinite(data)
    mean, median, std = sigma_clipped_stats(data[annulus], sigma=sigma, maxiters=maxiters)
    return mean, median, std


def fit_enclosing_ellipse(mask, center_rc):
    """
    Elipse alineada con los ejes principales (PCA) de la máscara,
    escalada para que todos los píxeles de la máscara queden inscritos.

    Returns
    -------
    a, b : semi-eje mayor y menor (píxeles)
    major_vec, minor_vec : vectores unitarios (dx, dy) de los ejes
    theta_deg : ángulo del eje mayor respecto al eje x, en grados
    """
    ys, xs = np.nonzero(mask)
    row_c, col_c = center_rc
    dx = xs - col_c
    dy = ys - row_c

    if len(dx) < 3:
        # máscara degenerada (muy pocos píxeles): elipse mínima por defecto
        return 1.5, 1.5, (1.0, 0.0), (0.0, 1.0), 0.0

    cov = np.cov(np.vstack([dx, dy]))
    eigvals, eigvecs = np.linalg.eigh(cov)
    order = np.argsort(eigvals)[::-1]
    eigvals = np.clip(eigvals[order], 1e-6, None)
    eigvecs = eigvecs[:, order]

    major_vec = eigvecs[:, 0]
    minor_vec = eigvecs[:, 1]
    lam_major, lam_minor = eigvals[0], eigvals[1]

    proj_major = dx * major_vec[0] + dy * major_vec[1]
    proj_minor = dx * minor_vec[0] + dy * minor_vec[1]

    ratio = (proj_major ** 2) / lam_major + (proj_minor ** 2) / lam_minor
    k = np.sqrt(ratio.max())

    a = k * np.sqrt(lam_major)
    b = k * np.sqrt(lam_minor)
    theta_deg = np.degrees(np.arctan2(major_vec[1], major_vec[0]))
    return float(a), float(b), tuple(major_vec), tuple(minor_vec), float(theta_deg)


def ellipse_aperture_mask(shape, center_rc, a, b, major_vec, minor_vec):
    ny, nx = shape
    Y, X = np.mgrid[0:ny, 0:nx]
    row_c, col_c = center_rc
    dx = X - col_c
    dy = Y - row_c
    proj_major = dx * major_vec[0] + dy * major_vec[1]
    proj_minor = dx * minor_vec[0] + dy * minor_vec[1]
    val = (proj_major / a) ** 2 + (proj_minor / b) ** 2
    return val <= 1.0


def embed_in_full_frame(local_array, full_shape, offset_xy, fill=0):
    """
    Incrusta `local_array` (un array calculado sobre el recorte interno,
    por eficiencia) en un lienzo del tamaño de la imagen ORIGINAL
    (`full_shape`), en la posición dada por `offset_xy` = (x0, y0), la
    esquina inferior-izquierda del recorte respecto a la imagen original
    (tal como la devuelve `crop_square_min`).

    El resultado tiene exactamente el mismo tamaño y sistema de
    coordenadas de píxel que la imagen original: cae pixel a pixel sobre
    ella, sin que quien use el archivo guardado deba aplicar ningún
    offset adicional.
    """
    full = np.full(full_shape, fill, dtype=local_array.dtype)
    x0, y0 = offset_xy
    ny, nx = local_array.shape
    full[y0:y0 + ny, x0:x0 + nx] = local_array
    return full


def rotate_180(mask, center_rc):
    """Rotación puntual de 180 grados respecto a `center_rc` (fila, col),
    válida para centros no enteros; usa interpolación de vecino más
    cercano para preservar valores binarios."""
    ny, nx = mask.shape
    Y, X = np.mgrid[0:ny, 0:nx]
    return rotate_180_fast(mask, center_rc, Y, X)


def rotate_180_fast(mask, center_rc, Y, X):
    """
    Igual que `rotate_180`, pero recibe las grillas de coordenadas `Y, X`
    ya construidas (via np.mgrid) en vez de reconstruirlas en cada
    llamada. Pensado para el bucle de búsqueda en grilla, donde el mismo
    array (mismo tamaño) se rota decenas de veces seguidas: reconstruir
    `np.mgrid` en cada candidato es trabajo repetido e innecesario.
    """
    row_c, col_c = center_rc
    src_row = 2 * row_c - Y
    src_col = 2 * col_c - X
    out = map_coordinates(
        mask.astype(float), [src_row, src_col], order=0, mode="constant", cval=0.0
    )
    return out > 0.5


def crop_for_search(mask_final, ap_mask, centre_rc, reach, max_total_offset, margin=2):
    """
    Recorte MÍNIMO (con margen de seguridad) del área de trabajo usada
    durante la búsqueda del centro de rotación que minimiza A_shape.

    IMPORTANTE: se recorta `mask_final` (la máscara COMPLETA, sin
    intersectar con la apertura elíptica) — no `mask_ap`. Esto es
    necesario porque, al rotar respecto a un centro candidato desplazado
    del centro original, un píxel que hoy queda FUERA de la elipse fija
    puede reflejarse hacia ADENTRO de ella; si ya se hubiera puesto en
    cero de antemano (como hace `mask_ap`), esa contribución real se
    perdería y el resultado dejaría de ser una verdadera rotación de
    180°.

    La búsqueda evalúa centros candidatos desplazados hasta
    `max_total_offset` píxeles del centro original. Para que cada
    evaluación sea una rotación de 180° verdadera (no truncada) dentro de
    la apertura elíptica, el recorte debe alcanzar, en cada dirección
    desde `centre_rc`:

        reach (p. ej. R_max o a_ell)  +  2 * max_total_offset

    (el factor 2 viene de que un candidato desplazado en `d` respecto al
    centro original mapea el punto reflejado a una distancia `2*d` de
    donde lo haría el centro original). Se añade además `margin` píxeles
    extra de colchón.

    Returns
    -------
    mask_final_sub, ap_sub : recortes de `mask_final` y `ap_mask`
    centre_sub : `centre_rc` trasladado al sistema de coordenadas del recorte
    offset : (r0, c0) del recorte respecto al array original, para poder
        reinsertar el resultado ganador al terminar la búsqueda
    """
    ny, nx = mask_final.shape
    half_width = max(reach, 1.0) + 2 * max_total_offset + margin

    row_c, col_c = centre_rc
    r0 = max(0, int(np.floor(row_c - half_width)))
    r1 = min(ny, int(np.ceil(row_c + half_width)) + 1)
    c0 = max(0, int(np.floor(col_c - half_width)))
    c1 = min(nx, int(np.ceil(col_c + half_width)) + 1)

    mask_final_sub = mask_final[r0:r1, c0:c1]
    ap_sub = ap_mask[r0:r1, c0:c1]
    centre_sub = (row_c - r0, col_c - c0)
    return mask_final_sub, ap_sub, centre_sub, (r0, c0)


def resolve_grid_n(n_requested, n_max):
    """
    Ajusta el tamaño de grilla solicitado para la búsqueda del centro de
    rotación que minimiza A_shape: lo fuerza a impar (redondeando hacia
    arriba) y lo recorta a `n_max` (también forzado a impar) si lo excede,
    avisando por pantalla en ese caso.
    """
    n = int(n_requested)
    if n % 2 == 0:
        n += 1
    n_max = int(n_max) if n_max else 11
    if n_max % 2 == 0:
        n_max += 1
    if n > n_max:
        print(f"Aviso: --shape-grid-n={n_requested} (ajustado a impar {n}) "
              f"excede el máximo permitido ({n_max}); se usará n={n_max}.")
        n = n_max
    return n


# --------------------------------------------------------------------------
# Pipeline principal por galaxia
# --------------------------------------------------------------------------

def process_galaxy(gal_id, images_dir, given_center_xy, args, masks_dir, resid_dir):
    """
    Procesa una galaxia completa: carga imagen, recorte opcional,
    detección, refinamiento de fondo, elipse, rotación y A_S.

    Returns
    -------
    dict con resultados y diagnóstico, incluyendo 'A_shape' (float o NaN)
    """
    fits_path = images_dir / f"{gal_id}_obs_secondmask.fits"
    # fits_path = images_dir / f"{gal_id}.fits"
    if not fits_path.exists():
        return {"A_shape": np.nan, "status": f"imagen no encontrada: {fits_path}",
                "Rmax": np.nan, "a_ell": np.nan, "b_ell": np.nan, "theta_deg": np.nan,
                "centre_ra": None, "centre_dec": None, "centre_row_orig": None, "centre_col_orig": None}

    with fits.open(fits_path) as hdul:
        data0 = hdul[0].data.astype(float)
        header0 = hdul[0].header

    ny0, nx0 = data0.shape
    use_given_center = given_center_xy is not None
    refine_to_brightest = (not use_given_center) and (args.center_mode != "fixed")
    if args.center_mode == "refine":
        refine_to_brightest = True
    if args.center_mode == "fixed":
        refine_to_brightest = False

    # --- centro / recorte inicial ---
    if use_given_center:
        cropped, (seed_cx, seed_cy), offset_xy = crop_square_min(data0, given_center_xy)
    else:
        seed_cx, seed_cy = nx0 / 2.0, ny0 / 2.0
        cropped = data0
        offset_xy = (0, 0)

    data = cropped
    ny, nx = data.shape
    seed_rc = (seed_cy, seed_cx)

    # --- pasada 1: estadística de fondo global (sigma-clipped) ---
    mean1, median1, std1 = sigma_clipped_stats(
        data[np.isfinite(data)], sigma=args.sigma_clip, maxiters=args.maxiters
    )
    data_sub = data - median1
    smoothed1 = boxcar_smooth(data_sub, size=args.boxcar)
    threshold1 = args.nsigma * std1

    mask1, seed_used1 = grow_region(
        smoothed1, threshold1, seed_rc, connectivity=args.connectivity,
        search_radius=args.seed_search_radius,
        max_growth_radius=args.max_growth_radius,
    )
    if seed_used1 is None or mask1.sum() == 0:
        return {"A_shape": np.nan, "status": "no se encontraron píxeles sobre el umbral (pasada 1)",
                "Rmax": np.nan, "a_ell": np.nan, "b_ell": np.nan, "theta_deg": np.nan,
                "centre_ra": None, "centre_dec": None, "centre_row_orig": None, "centre_col_orig": None}

    centre_rc = brightest_pixel_near_seed(data, mask1, seed_used1, args.center_search_radius) \
        if refine_to_brightest else (seed_cy, seed_cx)

    Rmax1 = r_max(mask1, centre_rc)

    mask_final = mask1
    std_final = std1
    data_final = data_sub

    # --- pasada 2: refinamiento de fondo en anillo [Rmax, 2*Rmax] ---
    if args.bg_refine and Rmax1 > 0:
        mean2, median2, std2 = annulus_background(
            data, centre_rc, Rmax1, 2 * Rmax1,
            sigma=args.sigma_clip, maxiters=args.maxiters,
        )
        data_sub2 = data - median2
        smoothed2 = boxcar_smooth(data_sub2, size=args.boxcar)
        threshold2 = args.nsigma * std2

        mask2, seed_used2 = grow_region(
            smoothed2, threshold2, centre_rc, connectivity=args.connectivity,
            search_radius=args.seed_search_radius,
            max_growth_radius=args.max_growth_radius,
        )
        if seed_used2 is not None and mask2.sum() > 0:
            mask_final = mask2
            std_final = std2
            data_final = data_sub2
            if refine_to_brightest:
                centre_rc = brightest_pixel_near_seed(data, mask2, centre_rc, args.center_search_radius)

    area = int(mask_final.sum())
    if area < args.min_area:
        status = f"área de la máscara ({area} px) < área mínima ({args.min_area} px)"
        a_shape = np.nan
    elif args.max_area is not None and area > args.max_area:
        status = f"área de la máscara ({area} px) > área máxima ({args.max_area} px), posible corrupción/fuga"
        a_shape = np.nan
    else:
        status = "ok"
        a_shape = None  # se calcula abajo

    Rmax_final = r_max(mask_final, centre_rc)
    a_ell, b_ell, major_vec, minor_vec, theta_deg = fit_enclosing_ellipse(mask_final, centre_rc)
    ap_mask = ellipse_aperture_mask(mask_final.shape, centre_rc, a_ell, b_ell, major_vec, minor_vec)

    mask_ap = mask_final & ap_mask
    denom = 2.0 * mask_ap.sum()  # constante durante toda la busqueda de grilla

    grid_used = False
    grid_n_used = None
    grid_offset = (0, 0)
    a_shape_base = np.nan

    if a_shape is None:
        # --- valor en el centro dado (sin busqueda), siempre calculado:
        # sirve de valor base y de candidato inicial de la busqueda ---
        mask180_ap = rotate_180(mask_final, centre_rc) & ap_mask
        base_num = float(np.sum(np.abs(mask_ap.astype(int) - mask180_ap.astype(int))))
        a_shape_base = base_num / denom if denom > 0 else np.nan

        best_num, best_offset, best_mask180_ap = base_num, (0, 0), mask180_ap

        run_search = bool(args.shape_grid_n_thick and args.shape_grid_n_thick > 1 and denom > 0)
        if run_search:
            n_thick = resolve_grid_n(args.shape_grid_n_thick, args.shape_grid_max_n)
            n_thin = resolve_grid_n(args.shape_grid_n_thin, args.shape_grid_max_n) \
                if args.shape_grid_n_thin and args.shape_grid_n_thin > 1 else 1
            step_thick = args.shape_grid_step_thick
            step_thin = args.shape_grid_step_thin
            half_thick = n_thick // 2
            half_thin = n_thin // 2

            # Recorte MÍNIMO seguro para toda la búsqueda (ver crop_for_search):
            # tiene que alcanzar para cualquier candidato de AMBAS etapas.
            max_total_offset = half_thick * step_thick + half_thin * step_thin
            reach = max(Rmax_final, a_ell)
            mask_sub, ap_sub, centre_sub, (r0, c0) = crop_for_search(
                mask_final, ap_mask, centre_rc, reach, max_total_offset, margin=2
            )
            mask_ap_sub = mask_ap[r0:r0 + mask_sub.shape[0], c0:c0 + mask_sub.shape[1]]
            mask_sub_float = mask_sub.astype(float)
            Y_sub, X_sub = np.mgrid[0:mask_sub.shape[0], 0:mask_sub.shape[1]]

            best_num_sub = float(np.sum(np.abs(
                mask_ap_sub.astype(int)
                - (rotate_180_fast(mask_sub_float, centre_sub, Y_sub, X_sub) & ap_sub).astype(int)
            )))
            best_offset_sub = (0, 0)
            best_mask180_sub = None

            # --- pasada 1 (gruesa): step=1 px, radio n_thick//2 ---
            for i_row in range(-half_thick, half_thick + 1):
                for i_col in range(-half_thick, half_thick + 1):
                    if i_row == 0 and i_col == 0:
                        continue  # ya calculado arriba
                    drow, dcol = i_row * step_thick, i_col * step_thick
                    cand_rc = (centre_sub[0] + drow, centre_sub[1] + dcol)
                    cand_mask180 = rotate_180_fast(mask_sub_float, cand_rc, Y_sub, X_sub) & ap_sub
                    num = float(np.sum(np.abs(mask_ap_sub.astype(int) - cand_mask180.astype(int))))
                    if num < best_num_sub:
                        best_num_sub, best_offset_sub, best_mask180_sub = num, (drow, dcol), cand_mask180

            # --- pasada 2 (fina): step=0.5 px, radio n_thin//2, ALREDEDOR del ganador grueso ---
            if n_thin > 1:
                coarse_offset = best_offset_sub
                for j_row in range(-half_thin, half_thin + 1):
                    for j_col in range(-half_thin, half_thin + 1):
                        if j_row == 0 and j_col == 0:
                            continue  # el ganador grueso ya está evaluado
                        drow = coarse_offset[0] + j_row * step_thin
                        dcol = coarse_offset[1] + j_col * step_thin
                        cand_rc = (centre_sub[0] + drow, centre_sub[1] + dcol)
                        cand_mask180 = rotate_180_fast(mask_sub_float, cand_rc, Y_sub, X_sub) & ap_sub
                        num = float(np.sum(np.abs(mask_ap_sub.astype(int) - cand_mask180.astype(int))))
                        if num < best_num_sub:
                            best_num_sub, best_offset_sub, best_mask180_sub = num, (drow, dcol), cand_mask180

            if best_num_sub < best_num:
                best_num, best_offset = best_num_sub, best_offset_sub
                if best_mask180_sub is not None:
                    best_mask180_ap = np.zeros_like(mask_ap)
                    best_mask180_ap[r0:r0 + mask_sub.shape[0], c0:c0 + mask_sub.shape[1]] = best_mask180_sub
            grid_used = True
            grid_n_used = (n_thick, n_thin)
            grid_offset = best_offset

        a_shape = best_num / denom if denom > 0 else np.nan
        mask180_ap = best_mask180_ap
        # El centro de rotacion que se reporta (header, .reg, RA/DEC) pasa a
        # ser el que minimizo A_shape; R_max y la elipse NO se recalculan
        # respecto a este nuevo punto, quedan ancladas al centro original
        # (dado por flujo / lista de centros), preservando coherencia.
        centre_rc = (centre_rc[0] + best_offset[0], centre_rc[1] + best_offset[1])
    else:
        mask180_ap = np.zeros_like(mask_ap)

    residual = mask_ap.astype(np.int16) - mask180_ap.astype(np.int16)

    asymm_residual = (residual > 0).astype(np.uint16)

    # --- RA/DEC del centro efectivamente usado para la rotación (no el de
    # la tabla de entrada): se convierte el píxel de `centre_rc` (en el
    # sistema de coordenadas del recorte) de vuelta al sistema de la imagen
    # original, y de ahí a RA/DEC usando el WCS del header. ---
    col_orig = centre_rc[1] + offset_xy[0]
    row_orig = centre_rc[0] + offset_xy[1]
    try:
        wcs = WCS(header0)
        centre_ra, centre_dec = [float(v) for v in
                                  wcs.all_pix2world([[col_orig, row_orig]], 0)[0]]
    except Exception:
        centre_ra, centre_dec = None, None

    # --- Incrustar los productos (calculados sobre el recorte interno, por
    # eficiencia) de vuelta en un lienzo del tamaño de la imagen ORIGINAL,
    # de modo que 'binarymask'/'residual' caigan pixel a pixel sobre
    # 'secondmask': ningún offset adicional es necesario para usarlos en
    # conjunto (ni en DS9, ni en ningún análisis posterior). ---
    full_shape = data0.shape
    mask_full = embed_in_full_frame(mask_final.astype(np.uint8), full_shape, offset_xy, fill=0)
    residual_full = embed_in_full_frame(residual, full_shape, offset_xy, fill=0)
    asymm_residual_full = embed_in_full_frame(asymm_residual, full_shape, offset_xy, fill=0)

    # --- guardar FITS: máscara y residuo ---
    # El header ya NO requiere ajustar CRPIX: al guardar el array
    # incrustado en el tamaño y grilla de la imagen original, el header
    # original (sin modificar) sigue siendo válido tal cual.
    hdr_out = header0.copy()
    hdr_out["RMAX"] = (Rmax_final, "Pawlik+2016 R_max [px]")
    hdr_out["CENTRR"] = (row_orig, "row of rotation center [px, marco de imagen original]")
    hdr_out["CENTRC"] = (col_orig, "col of rotation center [px, marco de imagen original]")
    hdr_out["ELLA"] = (a_ell, "semi-major axis of elliptical aperture [px]")
    hdr_out["ELLB"] = (b_ell, "semi-minor axis of elliptical aperture [px]")
    hdr_out["ELLPA"] = (theta_deg, "position angle of major axis [deg]")
    hdr_out["ASTD"] = (std_final, "background sigma used [counts]")
    hdr_out["ASHAPE"] = (a_shape if np.isfinite(a_shape) else "NaN",
                          "shape asymmetry index, Pawlik+2016")
    if grid_used:
        hdr_out["ASHAPE0"] = (a_shape_base if np.isfinite(a_shape_base) else "NaN",
                               "A_shape at the given center, before grid search")
        hdr_out["GRIDNTHK"] = (grid_n_used[0], "side of the coarse (thick) search grid [px]")
        hdr_out["GRIDNTHN"] = (grid_n_used[1], "side of the fine (thin) search grid [px]")
        hdr_out["GRIDSTK"] = (args.shape_grid_step_thick, "coarse grid step [px]")
        hdr_out["GRIDSTN"] = (args.shape_grid_step_thin, "fine grid step [px]")
        hdr_out["GRIDDR"] = (grid_offset[0], "row offset of best rotation center found [px]")
        hdr_out["GRIDDC"] = (grid_offset[1], "col offset of best rotation center found [px]")

    mask_path = masks_dir / f"{gal_id}_binarymask.fits"
    fits.PrimaryHDU(data=mask_full, header=hdr_out).writeto(mask_path, overwrite=True)

    resid_path = resid_dir / f"{gal_id}_residual.fits"
    fits.PrimaryHDU(data=residual_full, header=hdr_out).writeto(resid_path, overwrite=True)

    resid_path = resid_dir / f"{gal_id}_asymm_residual.fits"
    fits.PrimaryHDU(data=asymm_residual_full, header=hdr_out).writeto(resid_path, overwrite=True)

    return {
        "A_shape": a_shape,
        "status": status,
        "area": area,
        "Rmax": Rmax_final,
        "centre_row": centre_rc[0],
        "centre_col": centre_rc[1],
        "centre_row_orig": row_orig,
        "centre_col_orig": col_orig,
        "centre_ra": centre_ra,
        "centre_dec": centre_dec,
        "std": std_final,
        "a_ell": a_ell,
        "b_ell": b_ell,
        "theta_deg": theta_deg,
    }


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def write_index_table(output_dir, stem, colname, ids, values_fmt, write_ascii=False):
    """
    Escribe una tabla de solo DOS columnas, 'ID' y `colname`, con los
    valores ya formateados como string (ver `format_index_values`). Se
    usa para As_data, Rmax_data y SMAmax_data: estos catálogos ya NO
    heredan el resto de columnas del catálogo de entrada (RA, DEC,
    CLASS_*, etc.), solo el ID.

    Parameters
    ----------
    output_dir : Path
    stem : str
        Nombre base sin extensión (p. ej. "As_data", "Rmax_data").
    colname : str
        Nombre de la columna de valores (p. ej. "As_1.0", "Rmax_1.0").
    ids : list
    values_fmt : list of str
        Mismo largo que `ids`; ya formateados ("NaN" incluido donde
        corresponda).
    write_ascii : bool
        Si es True, además escribe la versión ascii (.dat) separada por
        espacios, con línea de cabecera "# ID <colname>".

    Returns
    -------
    csv_path, ascii_path (ascii_path es None si write_ascii=False)
    """
    csv_path = output_dir / f"{stem}.csv"
    with open(csv_path, "w", newline="") as f:
        f.write(f"ID,{colname}\n")
        for gal_id, val in zip(ids, values_fmt):
            f.write(f"{gal_id},{val}\n")

    ascii_path = None
    if write_ascii:
        ascii_path = output_dir / f"{stem}.dat"
        with open(ascii_path, "w") as f:
            f.write(f"# ID {colname}\n")
            for gal_id, val in zip(ids, values_fmt):
                f.write(f"{gal_id} {val}\n")

    return csv_path, ascii_path


def format_index_values(values):
    """[v1, v2, ...] (float, posiblemente NaN) -> ['%.5f' o 'NaN', ...]."""
    return [f"{v:.5f}" if np.isfinite(v) else "NaN" for v in values]


def get_radec_colnames(colnames, fmt):
    """
    Determina qué columnas del catálogo corresponden a RA y DEC.

    - csv: busca columnas llamadas 'RA' y 'DEC' (sin distinguir mayúsculas).
    - ascii: usa fijamente las columnas 2 y 3 (1-indexadas) de la lista de
      entrada, como se especificó (misma lista que contiene el ID).
    """
    if fmt == "csv":
        ra_matches = [c for c in colnames if c.strip().lower() == "ra"]
        dec_matches = [c for c in colnames if c.strip().lower() == "dec"]
        if not ra_matches or not dec_matches:
            raise ValueError(
                f"No se encontraron columnas 'RA'/'DEC' en el csv. "
                f"Columnas disponibles: {colnames}"
            )
        return ra_matches[0], dec_matches[0]
    else:
        if len(colnames) < 3:
            raise ValueError(
                "El archivo ascii necesita al menos 3 columnas (ID RA DEC "
                "...) para generar el archivo .reg de DS9."
            )
        return colnames[1], colnames[2]


def write_ds9_region(reg_path, entries):
    """
    Escribe un archivo de regiones DS9 (.reg) con una elipse por galaxia.

    Parameters
    ----------
    reg_path : Path
    entries : list of dict
        Cada dict con llaves: id, ra, dec, a_arcsec, b_arcsec, theta_deg,
        a_shape.
    """
    lines = [
        "# Region file format: DS9 version 4.1",
        'global dashlist=8 3 width=1 font="helvetica 12 bold roman" '
        "select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 "
        "include=1 source=1",
        "fk5",
    ]
    for e in entries:
        lines.append(
            f'ellipse({e["ra"]:.6f},{e["dec"]:.6f},'
            f'{e["a_arcsec"]:.3f}",{e["b_arcsec"]:.3f}",{e["theta_deg"]:.3f}) '
            f'# color=red dash=1 text={{{e["a_shape"]:.5f} {e["id"]}}}'
        )

    with open(reg_path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    p = argparse.ArgumentParser(
        description="Índice de asimetría de forma A_S, Pawlik et al. (2016)")
    p.add_argument("catalog", help="Lista de galaxias (ascii separado por "
                                    "espacios o .csv), con columna de ID")
    p.add_argument("--id-col", type=int, default=1,
                    help="Columna de ID (1-indexada), OBLIGATORIA si el "
                         "catálogo es ascii. Ignorada para .csv (se busca "
                         "la columna 'ID').")
    p.add_argument("--images-dir", type=Path, default=Path("./data/data_images/observed/"),
                    help="Directorio con las imágenes FITS nombradas "
                         "'<ID>.fits' (por defecto el directorio actual)")

    p.add_argument("--centers-list", type=Path, default="./data/data_files/abs_mincenter.txt",
                    help="Lista opcional con centros de rotación por ID "
                         "(ascii o csv). Si se omite, se usa el centro "
                         "geométrico de cada imagen.")
    p.add_argument("--centers-id-col", type=int, default=1,
                    help="Columna de ID en la lista de centros (1-indexada, "
                         "por defecto 1)")
    p.add_argument("--centers-x-col", type=int, default=4,
                    help="Columna de X (columna de píxel) en la lista de "
                         "centros (1-indexada, por defecto 2)")
    p.add_argument("--centers-y-col", type=int, default=5,
                    help="Columna de Y (fila de píxel) en la lista de "
                         "centros (1-indexada, por defecto 3)")
    p.add_argument("--centers-ra-col", type=int, default=2,
                    help="Columna de RA en la lista de centros (1-indexada, "
                         "por defecto 2). Se usa solo para escribir la "
                         "copia actualizada de la lista de centros; no "
                         "afecta el cálculo. Poner 0 para omitir la "
                         "actualización de RA/DEC.")
    p.add_argument("--centers-dec-col", type=int, default=3,
                    help="Columna de DEC en la lista de centros (1-indexada, "
                         "por defecto 3). Poner 0 para omitir la "
                         "actualización de RA/DEC.")
    p.add_argument("--no-save-updated-centers", dest="save_updated_centers",
                    action="store_false",
                    help="Desactiva el guardado de la copia actualizada de "
                         "la lista de centros (activado por defecto cuando "
                         "se entrega --centers-list).")
    p.set_defaults(save_updated_centers=True)

    p.add_argument("--center-mode", choices=["auto", "refine", "fixed"],
                    default="auto",
                    help="'auto' (por defecto): si se entrega lista de "
                         "centros, se usan tal cual (fixed); si no, se "
                         "refina al píxel más brillante dentro de la "
                         "máscara (refine). 'refine': siempre refina al "
                         "píxel más brillante. 'fixed': nunca refina, usa "
                         "siempre el centro dado o el centro de la imagen.")
    p.add_argument("--center-search-radius", type=int, default=2,
                    help="Radio (px) de la ventana local alrededor de la "
                         "semilla donde se busca el píxel más brillante "
                         "para refinar el centro (por defecto 2, i.e. una "
                         "ventana de 5x5 px). Esto es independiente del "
                         "tamaño de la máscara: aunque la máscara se "
                         "fusione con una fuente vecina lejana, esa fuente "
                         "queda fuera de esta ventana y nunca se elige "
                         "como centro. No afecta la máscara binaria en sí "
                         "(para eso, ver --max-growth-radius).")
    p.add_argument("--shape-grid-n-thick", type=int, default=5,
                    help="Búsqueda del centro de rotación que minimiza "
                         "A_shape, ETAPA GRUESA: grilla de n_thick x "
                         "n_thick píxeles alrededor del centro dado, con "
                         "paso --shape-grid-step-thick (por defecto 1 "
                         "píxel entero). La máscara y la apertura elíptica "
                         "se mantienen FIJAS (calculadas una única vez en "
                         "el centro original) durante toda la búsqueda; "
                         "solo se prueba rotar 180° respecto a cada punto "
                         "candidato. Debe ser impar; un valor par se "
                         "ajusta al impar siguiente. Poner en 0 o 1 para "
                         "desactivar toda la búsqueda (comportamiento "
                         "original: un solo punto, sin búsqueda). Por "
                         "defecto 5 (radio 2 px).")
    p.add_argument("--shape-grid-n-thin", type=int, default=3,
                    help="Búsqueda del centro de rotación, ETAPA FINA: "
                         "una vez encontrado el ganador de la etapa "
                         "gruesa, se explora una segunda grilla de "
                         "n_thin x n_thin puntos ALREDEDOR de ese ganador, "
                         "con paso --shape-grid-step-thin (por defecto 0.5 "
                         "px, sub-pixel — la rotación 180° se calcula por "
                         "interpolación, no requiere píxeles enteros). "
                         "Debe ser impar; un valor par se ajusta al impar "
                         "siguiente. Poner en 0 o 1 para omitir la etapa "
                         "fina y quedarse solo con el resultado grueso. "
                         "Por defecto 3 (radio 1 paso = 0.5 px).")
    p.add_argument("--shape-grid-step-thick", type=float, default=1.0,
                    help="Espaciado (px) entre puntos de la etapa GRUESA "
                         "de la búsqueda (por defecto 1.0 px)")
    p.add_argument("--shape-grid-step-thin", type=float, default=0.5,
                    help="Espaciado (px) entre puntos de la etapa FINA de "
                         "la búsqueda, alrededor del ganador de la etapa "
                         "gruesa (por defecto 0.5 px)")
    p.add_argument("--shape-grid-max-n", type=int, default=11,
                    help="Límite máximo (se fuerza impar) para "
                         "--shape-grid-n-thick / --shape-grid-n-thin, para "
                         "evitar grillas excesivamente grandes (por "
                         "defecto 11)")

    p.add_argument("--boxcar", type=int, default=3,
                    help="Tamaño del filtro boxcar (por defecto 3)")
    p.add_argument("--nsigma", type=float, default=1.0,
                    help="Umbral de detección en unidades de std del fondo "
                         "(por defecto 1.0, valor óptimo de Pawlik et al.)")
    p.add_argument("--sigma-clip", type=float, default=3.0,
                    help="Sigma para el sigma-clipping al estimar el fondo "
                         "(por defecto 3.0)")
    p.add_argument("--maxiters", type=int, default=5,
                    help="Iteraciones máximas del sigma-clipping (por "
                         "defecto 5)")
    p.add_argument("--connectivity", type=int, choices=[4, 8], default=8,
                    help="Conectividad para el crecimiento de región (por "
                         "defecto 8, como en Pawlik et al.)")
    p.add_argument("--min-area", type=int, default=100,
                    help="Área mínima en píxeles para considerar válida la "
                         "máscara detectada (por defecto 10)")
    p.add_argument("--max-area", type=int, default=None,
                    help="Área máxima en píxeles para considerar válida la "
                         "máscara detectada. Útil como salvaguarda contra "
                         "'fugas' del crecimiento de región hacia fuentes "
                         "vecinas o hacia el fondo (por defecto sin límite)")
    p.add_argument("--seed-search-radius", type=int, default=5,
                    help="Radio de búsqueda (px) de un píxel válido cercano "
                         "si la semilla exacta cae bajo el umbral (por "
                         "defecto 5)")
    p.add_argument("--max-growth-radius", type=float, default=None,
                    help="Radio máximo (px) que puede alcanzar el "
                         "crecimiento de región desde la semilla. Evita que "
                         "la máscara se fusione con una fuente vecina "
                         "brillante (p. ej. una estrella) conectada por un "
                         "puente tenue de píxeles sobre el umbral. Por "
                         "defecto sin límite (comportamiento original); se "
                         "recomienda fijarlo según el tamaño angular típico "
                         "esperado de las galaxias de la muestra.")
    p.add_argument("--no-bg-refine", dest="bg_refine", action="store_false",
                    help="Desactiva el refinamiento de fondo en dos pasadas "
                         "(anillo 1x-2x R_max). Activado por defecto.")
    p.set_defaults(bg_refine=True)

    p.add_argument("--pixel-scale", type=float, required=True,
                    help="Escala de placa en arcsec/pixel, usada para "
                         "convertir los semiejes de la elipse a arcosegundos "
                         "en el archivo .reg de DS9 (por defecto 0.3)")
    p.add_argument("--reg-name", type=str, default="index_shape.reg",
                    help="Nombre del archivo de regiones DS9 (por defecto "
                         "'index_shape.reg')")

    p.add_argument("--output-dir", type=Path, default=Path("./pawlik"),
                    help="Directorio de salida (por defecto ./pawlik)")

    args = p.parse_args()

    output_dir = Path(args.output_dir, f"pawlik_{args.nsigma:.1f}")

    #output_dir = args.output_dir
    masks_dir = output_dir / "binary_masks"
    resid_dir = output_dir / "residuals"
    output_dir.mkdir(parents=True, exist_ok=True)
    masks_dir.mkdir(parents=True, exist_ok=True)
    resid_dir.mkdir(parents=True, exist_ok=True)

    df, colnames, fmt, id_colname = load_table(args.catalog, id_col=args.id_col)
    print(f"Catálogo cargado ({fmt}): {len(df)} galaxias, columna ID = '{id_colname}'")

    index_name = f"As_{args.nsigma:.1f}"

    centers = {}
    if args.centers_list is not None:
        centers = load_centers(
            args.centers_list, id_col=args.centers_id_col,
            x_col=args.centers_x_col, y_col=args.centers_y_col,
        )
        print(f"Lista de centros cargada: {len(centers)} entradas")

    try:
        ra_colname, dec_colname = get_radec_colnames(colnames, fmt)
        can_write_reg = True
    except ValueError as e:
        print(f"Aviso: no se generará el archivo .reg de DS9 ({e})")
        can_write_reg = False

    a_shape_col = []
    rmax_col = []
    smamax_col = []
    astd_col = []
    reg_entries = []
    centers_updates = {}
    for i, row in df.iterrows():
        gal_id = row[id_colname]
        given_center = centers.get(gal_id, None)
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            result = process_galaxy(gal_id, args.images_dir, given_center, args, masks_dir, resid_dir)
        a_shape_col.append(result["A_shape"])

        # Rmax/SMAmax solo se reportan como válidos cuando A_shape TAMBIÉN
        # lo es. A_shape es NaN en tres casos (imagen no encontrada, sin
        # píxeles sobre el umbral, o área de la máscara fuera de
        # [min_area, max_area]); en el caso de área inválida, Rmax/a_ell
        # SÍ alcanzan a calcularse geométricamente (y quedan en el header
        # del FITS de la máscara para diagnóstico), pero se fuerzan a NaN
        # aquí para que las tres tablas de salida queden siempre alineadas
        # fila a fila: un Rmax/SMAmax válido implica un A_shape válido.
        if np.isfinite(result["A_shape"]):
            rmax_col.append(result.get("Rmax", np.nan))
            smamax_col.append(result.get("a_ell", np.nan))
            astd_col.append(result.get("std", np.nan))
        else:
            rmax_col.append(np.nan)
            smamax_col.append(np.nan)
            astd_col.append(np.nan)

        msg = f"[{i+1}/{len(df)}] {gal_id}: A_S = {result['A_shape']}"
        if result.get("status") != "ok":
            msg += f"  ({result.get('status')})"
        print(msg)

        # Centro efectivamente usado, en coordenadas de la imagen ORIGINAL
        # (no del recorte) — es lo que corresponde para actualizar la
        # lista de centros de entrada con el mismo sistema de referencia.
        if given_center is not None and result.get("centre_col_orig") is not None:
            centers_updates[gal_id] = {
                "x": result["centre_col_orig"],
                "y": result["centre_row_orig"],
                "ra": result.get("centre_ra"),
                "dec": result.get("centre_dec"),
            }

        if can_write_reg and np.isfinite(result["A_shape"]) and np.isfinite(result.get("a_ell", np.nan)):
            ra_val = result.get("centre_ra")
            dec_val = result.get("centre_dec")
            if ra_val is None or dec_val is None:
                # Respaldo: si no se pudo convertir el centro por WCS
                # (p. ej. header sin astrometría válida), se usa la
                # posición del catálogo de entrada como antes.
                print(f"Aviso: no se pudo convertir el centro de rotación de "
                      f"{gal_id} a RA/DEC (WCS no disponible); se usa la "
                      f"posición del catálogo de entrada en el .reg.")
                try:
                    ra_val = float(row[ra_colname])
                    dec_val = float(row[dec_colname])
                except (ValueError, KeyError):
                    continue
            reg_entries.append({
                "id": gal_id,
                "ra": ra_val,
                "dec": dec_val,
                "a_arcsec": result["a_ell"] * args.pixel_scale,
                "b_arcsec": result["b_ell"] * args.pixel_scale,
                "theta_deg": result["theta_deg"],
                "a_shape": result["A_shape"],
            })

    ids_col = df[id_colname].tolist()
    rmax_name = f"Rmax_{args.nsigma:.1f}"
    smamax_name = f"SMAmax_{args.nsigma:.1f}"
    astd_name = f"ASTD_{args.nsigma:.1f}"

    as_csv, as_ascii = write_index_table(
        output_dir, "As_data", index_name, ids_col,
        format_index_values(a_shape_col), write_ascii=True,
    )
    rmax_csv, _ = write_index_table(
        output_dir, "Rmax_data", rmax_name, ids_col,
        format_index_values(rmax_col), write_ascii=False,
    )
    smamax_csv, _ = write_index_table(
        output_dir, "SMAmax_data", smamax_name, ids_col,
        format_index_values(smamax_col), write_ascii=False,
    )
    astd_csv, _ = write_index_table(
        output_dir, "ASTD_data", astd_name, ids_col,
        format_index_values(astd_col), write_ascii=False,
    )

    print(f"\nTablas de resultados guardadas en:")
    print(f"  {as_ascii}")
    print(f"  {as_csv}")
    print(f"  {rmax_csv}")
    print(f"  {smamax_csv}")
    print(f"  {astd_csv}")
    print(f"Máscaras binarias en: {masks_dir}")
    print(f"Residuos (mask - mask180) en: {resid_dir}")

    if can_write_reg:
        reg_path = output_dir / args.reg_name
        write_ds9_region(reg_path, reg_entries)
        print(f"Archivo de regiones DS9 guardado en: {reg_path} "
              f"({len(reg_entries)}/{len(df)} galaxias incluidas)")

    if args.centers_list is not None and args.save_updated_centers:
        centers_fmt, centers_header, raw_rows = load_centers_raw(
            args.centers_list, id_col=args.centers_id_col
        )
        ra_col = args.centers_ra_col if args.centers_ra_col > 0 else None
        dec_col = args.centers_dec_col if args.centers_dec_col > 0 else None
        centers_stem = Path(args.centers_list).stem
        centers_suffix = Path(args.centers_list).suffix or ".dat"
        updated_path = output_dir / f"{centers_stem}_updated{centers_suffix}"
        write_updated_centers_list(
            updated_path, centers_fmt, centers_header, raw_rows, centers_updates,
            x_col=args.centers_x_col, y_col=args.centers_y_col,
            ra_col=ra_col, dec_col=dec_col,
        )
        print(f"Lista de centros actualizada guardada en: {updated_path} "
              f"({len(centers_updates)}/{len(raw_rows)} filas actualizadas)")


if __name__ == "__main__":
    main()
