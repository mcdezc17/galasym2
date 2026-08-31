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
        print(f"\n >> Ejecutando: {SHAPE_ASYMMETRY_PY} --nsigma {val} --no-bg-refine --pixel-scale {args.pixel_scale}")

        comando = [
            "python3",
            str(SHAPE_ASYMMETRY_PY),
            Path(args.catalog),
            "--nsigma",
            str(val),
            "--no-bg-refine",
            "--pixel-scale",
            str(args.pixel_scale)
        ]

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
