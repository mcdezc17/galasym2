import argparse
import csv
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from matplotlib.colors import Normalize
from matplotlib.collections import LineCollection
import numpy as np
import pandas as pd


def curve_colors(x_vals, norm, cmap):
    """
    Devuelve un color de `cmap` por cada punto de la curva, usando una
    normalización GLOBAL (compartida por todas las curvas), de modo que un
    mismo valor de sigma (As_%.1f) siempre corresponda al mismo color sin
    importar a qué curva pertenezca. Tanto 'autumn' (tidal-like) como
    'winter' (dysk-like) tienen su extremo más brillante (rojo / azul) en
    el valor 0 del colormap, que es justamente donde cae el sigma menor
    (norm(sigma_min) = 0) — sin necesidad de invertir el colormap.
    """
    return cmap(norm(x_vals))


def initial_run(sigma_sorted, y_sorted, increasing=False):
    """
    Caracteriza la racha inicial de `y_sorted` (As) empezando en el primer
    punto (sigma mínimo del objeto), mientras se mantenga NO-CRECIENTE
    (increasing=False -> forma 'tidal-like': As decrece al alejarse del
    centro, sigma creciente = radio decreciente) o NO-DECRECIENTE
    (increasing=True -> forma 'core-like': As crece al acercarse al
    centro). `sigma_sorted`/`y_sorted` deben venir ordenados por sigma
    ascendente.

    En ambos casos, la racha mide cuánto se sostiene la tendencia antes de
    revertirse por primera vez -- que es donde empieza el ruido/
    inestabilidad típico del interior: "la asimetría crece hacia afuera,
    aunque sea inestable en el interior" (o, para core-like, el espejo:
    la asimetría se concentra en el núcleo y se diluye hacia afuera).

    Returns
    -------
    n : int
        Número de puntos de la racha (incluyendo el primero).
    span : float
        Extensión en unidades de sigma de la racha.
    end_value : float
        Valor de As en el último punto de la racha (el más alejado del
        sigma mínimo que sigue sosteniendo la tendencia).
    """
    n = 1
    for i in range(1, len(y_sorted)):
        step_ok = (y_sorted[i] >= y_sorted[i - 1] - 1e-9) if increasing \
            else (y_sorted[i] <= y_sorted[i - 1] + 1e-9)
        if step_ok:
            n += 1
        else:
            break
    span = sigma_sorted[n - 1] - sigma_sorted[0]
    end_value = y_sorted[n - 1]
    return n, span, end_value


def main():
    # 1. Configurar los argumentos de línea de comandos
    parser = argparse.ArgumentParser(
        description="Grafica las curvas de asimetría y reporta objetos anómalos, "
        "clasificándolos en 'tidal-like' (autumn), 'core-like' (spring) o "
        "'dysk-like' (winter) y "
        "coloreando cada punto con un gradiente según su sigma (As_%.1f)."
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("pawlik"),
        help="Directorio raíz del árbol (por defecto: pawlik). Determina los "
             "valores por defecto de --input/--rmax-input/--smamax-input/"
             "--astd-input y de los archivos que este script escribe "
             "(perturbed_ids.txt, imagen del gráfico).",
    )
    parser.add_argument(
        "--input",
        type=str,
        default=None,
        help="Archivo CSV de entrada (por defecto: <output-dir>/merged_asymmetry.csv)",
    )
    parser.add_argument(
        "--nan-mode",
        type=str,
        choices=["1", "2"],
        #required=True,
        default="2",
        help="Estrategia para NaN: '1' para ignorar (scatter) o '2' para interpolación (líneas)",
    )
    parser.add_argument(
        "--max-value",
        type=float,
        default=0.2,
        help="Umbral crítico. Si un objeto lo supera, se considera anómalo (por defecto: 0.2)",
    )
    parser.add_argument(
        "--mid-value",
        type=float,
        default=0.15,
        help="Umbral medio inferior. Valores entre este y max-value también se consideran anómalos (por defecto: 0.15)",
    )
    parser.add_argument(
        "--tidal-shape-span",
        type=float,
        default=3.0,
        help="Criterio de FORMA para tidal-like (adicional al criterio "
             "fuerte de --max-value): un objeto también se clasifica "
             "tidal-like si As(sigma mínimo) >= --mid-value Y la racha "
             "inicial no-creciente de As (empezando en sigma mínimo) se "
             "sostiene al menos esta cantidad de unidades de sigma antes "
             "de la primera subida (por defecto: 3.0)",
    )
    parser.add_argument(
        "--core-shape-span",
        type=float,
        default=5.0,
        help="Criterio de FORMA para core-like (espejo de "
             "--tidal-shape-span): un objeto se clasifica core-like si, "
             "empezando en sigma mínimo, As sostiene una racha NO "
             "DECRECIENTE de al menos esta cantidad de unidades de sigma "
             "Y el valor de As al final de esa racha (el punto más "
             "cercano al núcleo que se alcanza) es >= --mid-value (por "
             "defecto: 3.0)",
    )
    parser.add_argument(
        "--x-axis",
        type=str,
        choices=["sigma", "rmax", "smamax"],
        default="rmax",
        help="Qué representa el eje X: 'sigma' (umbral de detección, "
             "comportamiento original: la posición y el color de cada punto "
             "son el mismo sigma) o 'rmax'/'smamax' (por defecto 'rmax'): "
             "el eje X pasa a ser, para cada objeto POR SEPARADO, la "
             "fracción Rmax_X.Y / Rmax_(sigma mínimo válido de ese objeto) "
             "-- o el equivalente con SMAmax. El color de cada punto sigue "
             "siendo su sigma (colorbar global), independientemente del "
             "modo elegido.",
    )
    parser.add_argument(
        "--rmax-input",
        type=str,
        default=None,
        help="CSV con columnas ID, Rmax_X.Y por objeto. Solo se usa con "
             "--x-axis rmax (por defecto: <output-dir>/merged_Rmax.csv)",
    )
    parser.add_argument(
        "--smamax-input",
        type=str,
        default=None,
        help="CSV con columnas ID, SMAmax_X.Y por objeto. Solo se usa con "
             "--x-axis smamax (por defecto: <output-dir>/merged_SMAmax.csv)",
    )
    parser.add_argument(
        "--sigma-units",
        type=str,
        choices=["nsigma", "mu"],
        default="nsigma",
        help="Unidades para el color de cada punto (y para la posición en "
             "--x-axis sigma): 'nsigma' (comportamiento original, umbral de "
             "detección en unidades de sigma del fondo) o 'mu' (brillo "
             "superficial equivalente del umbral, en mag/arcsec^2, usando "
             "ZP, --pixel-scale y el sigma de fondo LOCAL de cada objeto "
             "leído de --astd-input; por defecto: nsigma)",
    )
    parser.add_argument(
        "--zp",
        type=float,
        default=30.0,
        help="Zero-point fotométrico del mosaico (mag; MAGZEROP de "
             "A496J.fits = 30.0 por defecto). Solo se usa con "
             "--sigma-units mu.",
    )
    parser.add_argument(
        "--pixel-scale",
        type=float,
        default=0.3,
        help="Escala de placa en arcsec/pixel (0.3 = CD1_1/CD2_2 de "
             "A496J.fits por defecto). Solo se usa con --sigma-units mu.",
    )
    parser.add_argument(
        "--astd-input",
        type=str,
        default=None,
        help="CSV con columnas ID, ASTD_X.Y por objeto (sigma de fondo "
             "LOCAL, en counts, ya calculado por shape_asymmetry.py por "
             "objeto y por nsigma). Solo se usa con --sigma-units mu "
             "(por defecto: <output-dir>/merged_ASTD.csv)",
    )
    parser.add_argument(
        "--astd-spread-warn",
        type=float,
        default=0.05,
        help="Umbral relativo (fracción) de dispersión de ASTD entre "
             "niveles de sigma de un mismo objeto a partir del cual se "
             "imprime una advertencia (por defecto 0.05 = 5%%). Con "
             "--no-bg-refine (uso estándar de loop_pawlik.py) ASTD no "
             "depende de nsigma y debería ser prácticamente constante por "
             "objeto; una dispersión alta sugiere que esa corrida usó el "
             "refinamiento de fondo en anillo [Rmax,2*Rmax], que puede "
             "inflarse por incluir la propia galaxia. Solo aplica con "
             "--sigma-units mu.",
    )
    args = parser.parse_args()

    args.input = args.input or str(args.output_dir / "merged_asymmetry.csv")
    args.rmax_input = args.rmax_input or str(args.output_dir / "merged_Rmax.csv")
    args.smamax_input = args.smamax_input or str(args.output_dir / "merged_SMAmax.csv")
    args.astd_input = args.astd_input or str(args.output_dir / "merged_ASTD.csv")

    # 2. Cargar el archivo CSV
    file_path = Path(args.input)
    if not file_path.exists():
        print(f"❌ Error: No se encontró el archivo '{file_path}'.")
        sys.exit(1)

    df = pd.read_csv(file_path)

    if "ID" not in df.columns:
        print(f"❌ Error: El archivo '{file_path}' no contiene la columna 'ID'.")
        sys.exit(1)

    # 3. Identificar las columnas de datos y extraer los valores de X
    as_cols = [c for c in df.columns if c.startswith("As_")]
    if not as_cols:
        print(
            "❌ Error: No se encontraron columnas que sigan el formato 'As_X.X'."
        )
        sys.exit(1)

    x_values = np.array([float(col.split("_")[1]) for col in as_cols])

    # 3b. Si el eje X es una longitud (rmax/smamax), cargar ese catálogo y
    # armar el mapeo sigma -> nombre de columna (mismos sufijos X.Y que As_).
    length_df = None
    length_prefix = None
    length_path = None
    length_cols_by_sigma = {}
    if args.x_axis in ("rmax", "smamax"):
        length_prefix = "Rmax" if args.x_axis == "rmax" else "SMAmax"
        length_path = Path(args.rmax_input if args.x_axis == "rmax" else args.smamax_input)
        if not length_path.exists():
            print(f"❌ Error: No se encontró el archivo '{length_path}' "
                  f"(requerido para --x-axis {args.x_axis}).")
            sys.exit(1)
        length_df = pd.read_csv(length_path)
        if "ID" not in length_df.columns:
            print(f"❌ Error: El archivo '{length_path}' no contiene la columna 'ID'.")
            sys.exit(1)
        length_df = length_df.set_index("ID")
        length_cols_by_sigma = {v: f"{length_prefix}_{v:.1f}" for v in x_values}

    # 3c. Si el color (y, en --x-axis sigma, también la posición) se pide en
    # brillo superficial (mu, mag/arcsec^2), cargar el sigma de fondo LOCAL
    # por objeto (ASTD_X.Y, ya calculado por shape_asymmetry.py) y el
    # zero-point de brillo superficial ZP_mu = ZP + 5*log10(pixel_scale)
    # -- constante para toda la muestra porque todos los objetos vienen del
    # mismo mosaico reducido (mismo ZP, misma escala de placa); lo que SÍ es
    # local a cada objeto (y se lee de ASTD) es el sigma del fondo.
    astd_df = None
    astd_path = None
    astd_cols_by_sigma = {}
    zp_mu = None
    n_sin_astd = 0
    if args.sigma_units == "mu":
        astd_path = Path(args.astd_input)
        if not astd_path.exists():
            print(f"❌ Error: No se encontró el archivo '{astd_path}' "
                  f"(requerido para --sigma-units mu).")
            sys.exit(1)
        astd_df = pd.read_csv(astd_path)
        if "ID" not in astd_df.columns:
            print(f"❌ Error: El archivo '{astd_path}' no contiene la columna 'ID'.")
            sys.exit(1)
        astd_df = astd_df.set_index("ID")
        astd_cols_by_sigma = {v: f"ASTD_{v:.1f}" for v in x_values}
        zp_mu = args.zp + 5.0 * np.log10(args.pixel_scale)
        print(f"Modo de color/eje: brillo superficial (mu). "
              f"ZP={args.zp:.3f} mag, pixel_scale={args.pixel_scale:.4f} "
              f"arcsec/px -> ZP_mu={zp_mu:.4f} mag/arcsec^2 (constante para "
              f"toda la muestra). Sigma de fondo LOCAL por objeto leído de "
              f"'{astd_path.name}'.")

    # 4. Configurar el gráfico
    plt.figure(figsize=(10, 6))

    curvas_grises = []
    curvas_tidal = []
    curvas_core = []
    curvas_dysk = []
    tidal_reason = {}  # obj_id -> "fuerte" | "forma"
    n_tidal_fuerte = 0
    n_tidal_forma = 0
    n_sin_longitud = 0  # objetos omitidos por falta de Rmax/SMAmax utilizable

    # 5. Evaluar cada objeto y clasificarlo por color
    for idx, row in df.iterrows():
        obj_id = row["ID"]
        y_values = pd.to_numeric(row[as_cols], errors="coerce").values
        valid_mask = ~np.isnan(y_values)

        if not np.any(valid_mask):
            continue

        # Arrays de referencia para la CLASIFICACIÓN (tidal/dysk/normal):
        # se basan únicamente en la validez de As, independientemente del
        # modo de eje X elegido (para que un objeto se clasifique igual
        # sin importar si se grafica en sigma, rmax o smamax).
        order_as = np.argsort(x_values[valid_mask])
        sigma_as_valid = x_values[valid_mask][order_as]
        y_as_valid = y_values[valid_mask][order_as]
        y_en_sigma_min = y_as_valid[0]

        # (i) tidal-like, CRITERIO FUERTE: ya es anómalo (>= max_value) en
        # el sigma MÁS BAJO válido del objeto (típicamente 1.0).
        tidal_fuerte = y_en_sigma_min >= args.max_value

        # (i-bis) tidal-like, CRITERIO DE FORMA: no llega a max_value en
        # sigma mínimo, pero arranca por encima de mid_value Y sostiene
        # una caída de As (racha inicial no-creciente) de al menos
        # --tidal-shape-span unidades de sigma antes de la primera
        # subida. Detecta curvas como ID_IC_0375_F: nunca cruzan
        # max_value en sigma mínimo, pero su forma (As decreciendo
        # sostenidamente al reducir el radio) es igual de "tidal" que el
        # criterio fuerte.
        _, tidal_run_span, _ = initial_run(sigma_as_valid, y_as_valid, increasing=False)
        tidal_forma = (
            not tidal_fuerte
            and y_en_sigma_min >= args.mid_value
            and tidal_run_span >= args.tidal_shape_span
        )

        tidal = tidal_fuerte or tidal_forma

        # (ii) core-like: espejo de tidal-like por forma. En vez de mirar
        # el valor de As en sigma mínimo (radio más grande), miramos hasta
        # dónde sostiene As una racha NO DECRECIENTE al acercarse al
        # núcleo (sigma creciente = radio decreciente); si esa racha se
        # sostiene lo suficiente (--core-shape-span) Y el valor de As en
        # el punto más profundo alcanzado (el núcleo, no el radio
        # completo) ya es >= mid_value, la asimetría está concentrada en
        # el centro y se diluye hacia afuera -- justo lo opuesto de
        # tidal-like.
        _, core_run_span, core_run_end = initial_run(sigma_as_valid, y_as_valid, increasing=True)
        core = (
            not tidal
            and core_run_end >= args.mid_value
            and core_run_span >= args.core_shape_span
        )

        # (iii) dysk-like: no es tidal ni core, pero supera mid_value en
        # algún punto -- esto ya cubre tanto el caso "solo mid_value" como
        # "supera max_value pero en un sigma interior" (max_value >
        # mid_value siempre, así que superar max_value en cualquier punto
        # implica superar mid_value ahí mismo).
        dysk = (not tidal) and (not core) and np.any(y_as_valid > args.mid_value)

        sigma_valid = sigma_as_valid
        y_valid = y_as_valid

        # Máscara combinada para graficar: parte de valid_mask (As válido) y
        # se restringe además por la validez de longitud (rmax/smamax) y/o
        # de ASTD (mu), según los modos activos. sigma_valid/y_valid se
        # recalculan sobre esta máscara para --x-axis distinto de 'sigma'
        # y/o --sigma-units mu; en el caso original (sigma + nsigma) no
        # cambia nada respecto al comportamiento previo.
        combined_mask = valid_mask.copy()
        length_full = None
        astd_full = None

        if args.x_axis in ("rmax", "smamax"):
            if obj_id not in length_df.index:
                print(f"⚠️  {obj_id}: sin fila en '{length_path.name}', se omite del gráfico.")
                n_sin_longitud += 1
                continue
            length_row = length_df.loc[obj_id]
            length_full = np.array([
                pd.to_numeric(length_row.get(length_cols_by_sigma[v], np.nan), errors="coerce")
                for v in x_values
            ])
            combined_mask = combined_mask & np.isfinite(length_full)

        if args.sigma_units == "mu":
            if obj_id not in astd_df.index:
                print(f"⚠️  {obj_id}: sin fila en '{astd_path.name}', se omite del gráfico.")
                n_sin_astd += 1
                continue
            astd_row = astd_df.loc[obj_id]
            astd_full = np.array([
                pd.to_numeric(astd_row.get(astd_cols_by_sigma[v], np.nan), errors="coerce")
                for v in x_values
            ])
            combined_mask = combined_mask & np.isfinite(astd_full) & (astd_full > 0)

        if not np.array_equal(combined_mask, valid_mask) and not np.any(combined_mask):
            print(f"⚠️  {obj_id}: sin datos válidos combinados (As"
                  + (f" + {length_prefix}" if length_full is not None else "")
                  + (" + ASTD" if astd_full is not None else "")
                  + "), se omite del gráfico.")
            n_sin_longitud += 1
            continue

        sigma_valid = x_values[combined_mask]
        y_valid = y_values[combined_mask]

        # color_vals: cantidad física a representar en color (y, en
        # --x-axis sigma, también en posición). 'nsigma' = comportamiento
        # original (color_vals == sigma_valid). 'mu' = brillo superficial
        # equivalente del umbral nsigma*ASTD_local, en mag/arcsec^2 --
        # ASTD_local es el sigma de fondo de ESTE objeto (no uno global del
        # mosaico), así que dos objetos en el mismo nsigma pueden caer en
        # mu ligeramente distintos si su cielo local difiere.
        color_vals = sigma_valid
        if args.sigma_units == "mu":
            astd_valid = astd_full[combined_mask]
            if astd_valid.size > 1:
                astd_mean = astd_valid.mean()
                spread = (astd_valid.max() - astd_valid.min()) / astd_mean if astd_mean else 0.0
                if spread > args.astd_spread_warn:
                    print(f"⚠️  {obj_id}: ASTD varía {spread*100:.1f}% entre "
                          f"niveles de sigma (min={astd_valid.min():.4g}, "
                          f"max={astd_valid.max():.4g} counts). Con "
                          f"--no-bg-refine (uso estándar) ASTD no depende de "
                          f"nsigma y debería ser ~constante por objeto; "
                          f"revisa si esta corrida usó el refinamiento de "
                          f"fondo en anillo [Rmax,2*Rmax] (puede inflarse al "
                          f"incluir la propia galaxia).")
            color_vals = zp_mu - 2.5 * np.log10(sigma_valid * astd_valid)

        if args.x_axis == "sigma":
            # Posición y color representan la misma cantidad (sigma o mu,
            # según --sigma-units).
            plot_x = color_vals
            color_x = color_vals
        else:
            # eje X = fracción de Rmax/SMAmax respecto al propio sigma
            # mínimo válido del objeto (siempre en nsigma, no en mu: es una
            # referencia geométrica, no de brillo). El color sigue siendo
            # color_vals (sigma o mu), independiente de plot_x.
            length_valid = length_full[combined_mask]

            idx_min_sigma = np.argmin(sigma_valid)
            reference_length = length_valid[idx_min_sigma]
            if not np.isfinite(reference_length) or reference_length == 0:
                print(f"⚠️  {obj_id}: referencia de {length_prefix} (en su sigma "
                      f"mínimo válido) inválida, se omite del gráfico.")
                n_sin_longitud += 1
                continue

            plot_x = length_valid / reference_length
            color_x = color_vals

        kind = "tidal" if tidal else "core" if core else "dysk" if dysk else "gray"
        color = "lightgray"  # solo se usa tal cual para las curvas grises
        zorder = 3 if tidal else 2 if (core or dysk) else 1

        datos_objeto = {
            "id": obj_id,
            "x": plot_x,
            "y": y_valid,
            "color_x": color_x,
            "color": color,
            "kind": kind,
            "zorder": zorder,
        }

        if tidal:
            curvas_tidal.append(datos_objeto)
            if tidal_fuerte:
                tidal_reason[obj_id] = "fuerte"
                n_tidal_fuerte += 1
            else:
                tidal_reason[obj_id] = "forma"
                n_tidal_forma += 1

        elif core:
            curvas_core.append(datos_objeto)

        elif dysk:
            curvas_dysk.append(datos_objeto)

        else:
            curvas_grises.append(datos_objeto)

    print("\n=== RESUMEN DE PROCESAMIENTO ===")
    print(f"• Total de objetos válidos: {len(df)}")
    if args.x_axis != "sigma":
        print(f"• Omitidos por falta de {length_prefix} utilizable: {n_sin_longitud}")
    if args.sigma_units == "mu":
        print(f"• Omitidos por falta de ASTD utilizable: {n_sin_astd}")
    print(f"• Objetos normales: {len(curvas_grises)}")
    print(f"• Objetos dysk-like (As > {args.mid_value} en algún sigma, sin ser tidal-like ni core-like): {len(curvas_dysk)}")
    print(f"• Objetos core-like (As concentrada en el núcleo, se diluye hacia afuera): {len(curvas_core)}")
    print(f"• Objetos tidal-like: {len(curvas_tidal)}  "
          f"(criterio fuerte: {n_tidal_fuerte}, criterio de forma: {n_tidal_forma})")

    # 6. Guardar la clasificación (ID, perturbed) de todo lo no-normal:
    # tidal-like / core-like / dysk-like.
    txt_output = str(args.output_dir / "perturbed_ids.txt")
    clasificados = curvas_tidal + curvas_core + curvas_dysk
    if clasificados:
        print(f"\n - OBJETOS CLASIFICADOS (no normales):")
        for obj in clasificados:
            extra = f" ({tidal_reason[obj['id']]})" if obj["kind"] == "tidal" else ""
            print(f"   {obj['id']}: {obj['kind']}-like{extra}")

        with open(txt_output, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["ID", "perturbed"])
            for obj in clasificados:
                writer.writerow([obj["id"], f"{obj['kind']}-like"])
        print(f"\n - Clasificación guardada con éxito en: '{txt_output}'")
    else:
        print(
            f"\n - Ningún objeto fue clasificado como tidal-like/core-like/"
            f"dysk-like. No se generó '{txt_output}'."
        )

    # 7. Graficar primero las grises (color plano) y luego las anómalas
    # (tidal-like en autumn, core-like en spring, dysk-like en winter)
    for obj in curvas_grises:
        if args.nan_mode == "1":
            plt.scatter(
                obj["x"],
                obj["y"],
                color=obj["color"],
                alpha=0.6,
                zorder=obj["zorder"],
            )
        elif args.nan_mode == "2":
            plt.plot(
                obj["x"],
                obj["y"],
                #marker="o",
                #markersize=2,
                linestyle="-",
                linewidth=1.0,
                color=obj["color"],
                alpha=0.5,
                zorder=obj["zorder"],
            )

    curvas_anomalas = curvas_tidal + curvas_core + curvas_dysk

    if args.sigma_units == "mu":
        # Normalización GLOBAL, pero ahora sobre el rango de mu REALIZADO
        # (mu es local por objeto -- distintos objetos con el mismo nsigma
        # pueden caer en mu distinto -- así que ya no hay un único valor de
        # referencia como x_values.min()/max(); se toma el mínimo/máximo
        # de mu efectivamente graficado en las curvas anómalas).
        if curvas_anomalas:
            all_color_vals = np.concatenate([obj["color_x"] for obj in curvas_anomalas])
            color_vmin, color_vmax = np.nanmin(all_color_vals), np.nanmax(all_color_vals)
        else:
            color_vmin, color_vmax = 0.0, 1.0
        sigma_norm = Normalize(vmin=color_vmin, vmax=color_vmax)
        # mu es DECRECIENTE en nsigma (más sigma -> umbral más brillante ->
        # mu menor), así que para conservar la misma convención visual que
        # en modo nsigma ("rojo/extremo saturado = inicio de la curva, en
        # su sigma mínimo") hace falta el colormap invertido: sigma mínimo
        # <-> mu MÁXIMO <-> debe seguir cayendo en el extremo 0 del cmap.
        cmap_by_kind = {
            "tidal": cm.autumn.reversed(),
            "core": cm.spring.reversed(),
            "dysk": cm.winter.reversed(),
        }
    else:
        # Normalización GLOBAL compartida por todas las curvas: un mismo
        # sigma (columna As_%.1f) siempre mapea al mismo color, sin
        # importar la curva.
        sigma_norm = Normalize(vmin=x_values.min(), vmax=x_values.max())
        cmap_by_kind = {"tidal": cm.autumn, "core": cm.spring, "dysk": cm.winter}

    for obj in curvas_anomalas:
        x, y = obj["x"], obj["y"]
        cmap = cmap_by_kind[obj["kind"]]
        point_colors = curve_colors(obj["color_x"], sigma_norm, cmap)
        linewidth = 1.8 if obj["kind"] == "tidal" else 1.2

        if args.nan_mode == "1":
            plt.scatter(
                x,
                y,
                color=point_colors,
                alpha=0.9,
                zorder=obj["zorder"],
                edgecolors="none",
            )
        elif args.nan_mode == "2":
            # Puntos (marcadores) coloreados individualmente
            plt.scatter(
                x,
                y,
                color=point_colors,
                s=1,
                zorder=obj["zorder"] + 0.1,
                edgecolors="none",
            )
            # Segmentos de línea con gradiente (cada tramo toma el color de su punto inicial)
            if len(x) > 1:
                points = np.array([x, y]).T.reshape(-1, 1, 2)
                segments = np.concatenate([points[:-1], points[1:]], axis=1)
                lc = LineCollection(
                    segments,
                    colors=point_colors[:-1],
                    linewidth=linewidth,
                    zorder=obj["zorder"],
                    alpha=0.9,
                )
                plt.gca().add_collection(lc)

    # 8. Línea horizontal de referencia para identificar el umbral
    plt.axhline(
        y=args.max_value, color="black", linestyle=":", alpha=0.7, zorder=4
    )

    # 9. Estética final del gráfico
    color_label = "mu" if args.sigma_units == "mu" else "sigma"
    if args.x_axis == "sigma":
        if args.sigma_units == "mu":
            xlabel = r"Brillo Superficial del Umbral de Detección $\mu$ [mag/arcsec$^2$]"
            title_eje = "eje X = mu"
        else:
            xlabel = r"Umbral de Detección ($\sigma$)"
            title_eje = "eje X = sigma"
    else:
        xlabel = f"{length_prefix} / {length_prefix}(σ mínimo válido del objeto)  [fracción]"
        title_eje = f"eje X = fracción de {length_prefix}"

    plt.title(
        f"Curvas de Asimetría ({title_eje}; tidal=autumn, core=spring, dysk=winter, color por {color_label})",
        fontsize=13,
        fontweight="bold",
    )
    plt.xlabel(xlabel, fontsize=12)
    plt.ylabel("Asimetría de Forma (As)", fontsize=12)
    plt.grid(True, linestyle="--", alpha=0.3)

    # Leyenda personalizada
    # from matplotlib.lines import Line2D
    #
    # custom_lines = [
    #     Line2D([0], [0], color=cm.viridis_r(0.05), lw=2, label="Anómalo, sigma bajo (claro)"),
    #     Line2D([0], [0], color=cm.viridis_r(0.95), lw=2, label="Anómalo, sigma alto (oscuro)"),
    #     Line2D([0], [0], color="lightgray", lw=2, label=f"Normal (≤ {args.mid_value})"),
    #     Line2D([0], [0], color="black", linestyle=":", label=f"Umbral crítico ({args.max_value})"),
    # ]
    # plt.legend(handles=custom_lines, loc="upper right")

    # Dos barras de color, una por familia (tidal=autumn, dysk=winter),
    # compartiendo la misma normalización GLOBAL (mismo valor = mismo color
    # en ambas). En modo nsigma: autumn(0)=rojo y winter(0)=azul caen ambos
    # en sigma_norm=0, el sigma MENOR (inicio de cada curva). En modo mu se
    # usan los cmaps invertidos (ver arriba) para que ese mismo extremo
    # rojo/azul siga cayendo en el INICIO de la curva (sigma mínimo, que
    # ahora es mu MÁXIMO) -- así el significado visual del color no cambia
    # al cambiar de unidades, solo la etiqueta numérica. Solo la primera
    # barra necesita los números; la segunda solo muestra el degradé (para
    # no repetir la misma escala).
    sm_tidal = cm.ScalarMappable(cmap=cmap_by_kind["tidal"], norm=sigma_norm)
    sm_tidal.set_array([])
    cbar_tidal = plt.colorbar(sm_tidal, ax=plt.gca(), fraction=0.045, pad=0.02)
    if args.sigma_units == "mu":
        cbar_tidal.set_label(r"tidal-like ($\mu$ [mag/arcsec$^2$]; rojo = inicio de curva, $\sigma$ mínimo)", fontsize=9)
    else:
        cbar_tidal.set_label(r"tidal-like ($\sigma$; rojo = $\sigma$ menor)", fontsize=9)

    sm_core = cm.ScalarMappable(cmap=cmap_by_kind["core"], norm=sigma_norm)
    sm_core.set_array([])
    cbar_core = plt.colorbar(sm_core, ax=plt.gca(), fraction=0.045, pad=0.02)
    if args.sigma_units == "mu":
        cbar_core.set_label("core-like (rosa = inicio de curva, σ mínimo)", fontsize=9)
    else:
        cbar_core.set_label("core-like (rosa = σ menor)", fontsize=9)
    cbar_core.set_ticks([])

    sm_dysk = cm.ScalarMappable(cmap=cmap_by_kind["dysk"], norm=sigma_norm)
    sm_dysk.set_array([])
    cbar_dysk = plt.colorbar(sm_dysk, ax=plt.gca(), fraction=0.045, pad=0.09)
    if args.sigma_units == "mu":
        cbar_dysk.set_label("dysk-like (azul = inicio de curva, σ mínimo)", fontsize=9)
    else:
        cbar_dysk.set_label("dysk-like (azul = σ menor)", fontsize=9)
    cbar_dysk.set_ticks([])

    if args.x_axis == "sigma" and args.sigma_units != "mu":
        # Comportamiento original: sigma alto a la izquierda, sigma bajo a
        # la derecha.
        plt.gca().invert_xaxis()
    elif args.x_axis == "sigma" and args.sigma_units == "mu":
        # mu es DECRECIENTE en nsigma, así que el orden ascendente natural
        # de mu (por defecto, sin invertir) YA deja sigma alto/umbral
        # brillante (mu bajo) a la izquierda y sigma bajo/umbral tenue (mu
        # alto) a la derecha -- la MISMA convención visual de arriba, sin
        # necesidad de invertir el eje.
        pass
    else:
        # Sin invertir: como la fracción es inversamente proporcional a
        # sigma, esto reproduce la MISMA convención visual de arriba
        # (sigma alto/apertura chica a la izquierda, Rmax/SMAmax completo
        # -fracción=1- a la derecha), y de paso da una representación
        # natural de longitud (0 a la izquierda, tamaño máximo a la
        # derecha). El límite inferior se fija en 0 porque el dominio está
        # acotado ahí por construcción, aunque en la práctica casi ningún
        # objeto llegue a alcanzarlo.
        plt.xlim(left=0)
    plt.tight_layout()

    # Guardar y mostrar imagen
    mu_suffix = "_colormu" if args.sigma_units == "mu" else ""
    if args.x_axis == "sigma":
        img_name = f"asymmetry_highlighted_colorsigma{mu_suffix}.png" if mu_suffix \
            else "asymmetry_highlighted_colorsigma.png"
    else:
        img_name = f"asymmetry_highlighted_colorlength_{args.x_axis}{mu_suffix}.png"
    output_img = str(args.output_dir / img_name)
    plt.savefig(output_img, dpi=300)
    print(f"🎉 Gráfico guardado con éxito como '{output_img}'\n")
    plt.show()


if __name__ == "__main__":
    main()
