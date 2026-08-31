import argparse
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SHAPE_ASYMMETRY_PY = SCRIPT_DIR / "shape_asymmetry.py"


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "catalog",
        help="Lista de galaxias (ascii separado por espacios o .csv), con columna de ID"
        )

    # parser.add_argument(
    #     "--shape-grid-n",
    #     type=int,
    #     default=5
    # )
    #
    # parser.add_argument(
    #     "--shape-grid-step",
    #     type=float,
    #     default=0.5
    # )

    parser.add_argument(
        "--pixel-scale",
        type=float,
        required=True
    )

    parser.add_argument(
        "--sigmas",
        nargs="+",
        type=float,
        required=True
    )

    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("./pawlik"),
        help="Directorio raíz del árbol de salida (por defecto ./pawlik), "
             "pasado tal cual a shape_asymmetry.py como su --output-dir"
    )

    parser.add_argument(
        "--save-shape-images",
        action="store_true",
        default=False,
        help="Pasado tal cual a shape_asymmetry.py: guarda las imágenes "
             "FITS ID_binarymask, ID_residual e ID_asymm_residual por "
             "galaxia. Desactivado por defecto."
    )

    args = parser.parse_args()

    if len(args.sigmas) == 3:
        inicio, fin, paso = args.sigmas

        valores = []
        valor = inicio

        while valor <= fin:
            valores.append(round(valor, 10))
            valor += paso
    else:
        valores = args.sigmas

    print("Valores:", valores)

    # -------------------------------------------
    # Ejecutar shape_asymmetry.py
    # -------------------------------------------

    for val in valores:
        print(f"\n >> Ejecutando: {SHAPE_ASYMMETRY_PY} --nsigma {val} --no-bg-refine --pixel-scale {args.pixel_scale} --output-dir {args.output_dir}")

        comando = [
            "python3",
            str(SHAPE_ASYMMETRY_PY),
            Path(args.catalog),
            "--nsigma",
            str(val),
            "--no-bg-refine",
            "--pixel-scale",
            str(args.pixel_scale),
            "--output-dir",
            str(args.output_dir)
        ]

        if args.save_shape_images:
            comando.append("--save-shape-images")

        resultado = subprocess.run(
            comando,
            capture_output=True,
            text=True
        )

        if resultado.returncode == 0:
            print("Salida exitosa:")
            print(resultado.stdout)
        else:
            print("Ocurrió un error:")
            print(resultado.stderr)

        print("-" * 40)

    # -------------------------------------------
    # Concatenando índices
    # -------------------------------------------

    # print("Concatenando indices...")

    # comando = [
    #     "python3",
    #     "config/src/concat_pawlik.py",
    #     "--columns"
    # ] + list(map(str, valores))
    #
    # subprocess.run(comando)


if __name__ == "__main__":
    main()
