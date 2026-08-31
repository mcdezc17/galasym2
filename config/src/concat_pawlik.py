import argparse
import sys
from pathlib import Path
import pandas as pd


# Cada catálogo Pawlik que se concatena: prefijo de columna/carpeta, nombre
# del archivo fuente dentro de cada 'pawlik/pawlik_X.Y/', y nombre de salida
# por defecto (dentro de 'pawlik/', igual que el resto de los productos del
# pipeline; se conserva 'merged_asymmetry.csv' para As, tal como ya lo
# esperan otros scripts como graph_pawlik.py). Las rutas son
# relativas al directorio desde el que se invoque el script (debe ser la
# raíz del proyecto, donde vive 'pawlik/').
CATALOGS = [
    {"label": "As", "data_file": "As_data.csv", "default_output": "pawlik/merged_asymmetry.csv"},
    {"label": "Rmax", "data_file": "Rmax_data.csv", "default_output": "pawlik/merged_Rmax.csv"},
    {"label": "SMAmax", "data_file": "SMAmax_data.csv", "default_output": "pawlik/merged_SMAmax.csv"},
    {"label": "ASTD", "data_file": "ASTD_data.csv", "default_output": "pawlik/merged_ASTD.csv"},
]


def concat_catalog(label, data_file, sigmas_ordenados):
    """
    Concatena, en un solo DataFrame (columna 'ID' + una columna
    '{label}_X.Y' por cada sigma), el catálogo 'pawlik/pawlik_X.Y/{data_file}'
    de cada sigma en `sigmas_ordenados`. Devuelve None si ningún archivo
    resultó válido.
    """
    df_final = None

    for sigma in sigmas_ordenados:
        sigma_str = f"{sigma:.1f}"
        col_name = f"{label}_{sigma_str}"
        file_path = Path("pawlik", f"pawlik_{sigma_str}") / data_file

        if not file_path.exists():
            print(f"⚠️ [{label}] Advertencia: No se encontró el archivo '{file_path}'. Se saltará este valor.")
            continue

        print(f"➜ [{label}] Procesando: {file_path} (Buscando columna '{col_name}')")

        try:
            df_actual = pd.read_csv(file_path)

            if "ID" not in df_actual.columns:
                print(f"❌ [{label}] Error: El archivo '{file_path}' no contiene la columna 'ID'.")
                continue
            if col_name not in df_actual.columns:
                print(f"❌ [{label}] Error: El archivo '{file_path}' no contiene la columna '{col_name}'.")
                continue

            df_filtrado = df_actual[["ID", col_name]]

            if df_final is None:
                df_final = df_filtrado
            else:
                # 'outer merge' para conservar los IDs aunque falten datos
                df_final = pd.merge(df_final, df_filtrado, on="ID", how="outer")

        except Exception as e:
            print(f"❌ [{label}] Ocurrió un error leyendo '{file_path}': {e}")

    if df_final is not None:
        columnas_ordenadas = ["ID"] + [
            f"{label}_{f:.1f}" for f in sigmas_ordenados
            if f"{label}_{f:.1f}" in df_final.columns
        ]
        df_final = df_final[columnas_ordenadas]

    return df_final


def main():
    # 1. Configurar los argumentos de línea de comandos
    parser = argparse.ArgumentParser(
        description="Une, para cada carpeta pawlik/pawlik_X.Y/, las columnas "
        "de asimetría (As_data.csv), radio máximo (Rmax_data.csv) y semieje "
        "mayor máximo (SMAmax_data.csv) en tres tablas consolidadas."
    )
    parser.add_argument(
        "--columns",
        type=float,
        nargs="+",
        required=True,
        help="Lista de valores numéricos (nsigma) a buscar de forma creciente (ej: 3 5 10 20). "
             "Con exactamente 3 valores, se interpretan como inicio fin paso.",
    )
    parser.add_argument(
        "--as-output",
        type=str,
        default=CATALOGS[0]["default_output"],
        help=f"Nombre del CSV de salida para As (por defecto: {CATALOGS[0]['default_output']})",
    )
    parser.add_argument(
        "--rmax-output",
        type=str,
        default=CATALOGS[1]["default_output"],
        help=f"Nombre del CSV de salida para Rmax (por defecto: {CATALOGS[1]['default_output']})",
    )
    parser.add_argument(
        "--smamax-output",
        type=str,
        default=CATALOGS[2]["default_output"],
        help=f"Nombre del CSV de salida para SMAmax (por defecto: {CATALOGS[2]['default_output']})",
    )
    parser.add_argument(
        "--astd-output",
        type=str,
        default=CATALOGS[3]["default_output"],
        help=f"Nombre del CSV de salida para ASTD (sigma de fondo local por "
             f"objeto, en counts; por defecto: {CATALOGS[3]['default_output']})",
    )
    args = parser.parse_args()

    if len(args.columns) == 3:
        inicio, fin, paso = args.columns
        valores = []
        valor = inicio
        while valor <= fin:
            valores.append(round(valor, 10))
            valor += paso
    else:
        valores = args.columns

    print("Valores:", valores)

    sigmas_ordenados = sorted(valores)
    outputs = {
        "As": args.as_output,
        "Rmax": args.rmax_output,
        "SMAmax": args.smamax_output,
        "ASTD": args.astd_output,
    }

    print("Iniciando la búsqueda y unificación de archivos...")

    resultados = {}
    for catalog in CATALOGS:
        label = catalog["label"]
        print(f"\n=== {label} ===")
        df_final = concat_catalog(label, catalog["data_file"], sigmas_ordenados)
        resultados[label] = df_final

        if df_final is not None:
            output_path = outputs[label]
            df_final.to_csv(output_path, index=False)
            print(f"🎉 [{label}] ¡Éxito! Tabla unificada guardada correctamente en: {output_path}")
            print(df_final.head())
        else:
            print(f"❌ [{label}] Error: No se pudo generar el archivo de salida porque no se procesó ninguna columna válida.")

    # Resumen final
    print("\n=== RESUMEN ===")
    fallidos = []
    for catalog in CATALOGS:
        label = catalog["label"]
        if resultados[label] is not None:
            print(f"• {label}: OK -> {outputs[label]}")
        else:
            print(f"• {label}: FALLÓ (sin datos)")
            fallidos.append(label)

    if fallidos:
        sys.exit(1)


if __name__ == "__main__":
    main()
