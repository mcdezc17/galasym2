#!/usr/bin/env python3
import sys
import numpy as np
import matplotlib.pyplot as plt
import os


# -------------------------------------------------------------
# ------------ CARGA DE TABLAS DE SIMULACIÓN ------------------
# -------------------------------------------------------------
def load_simulation_table(path):
    """
    Carga tabla de simulaciones estilo SExtractor/stilts.
    Salta líneas con '#'.
    Ignora primera columna (ID).
    Igualación de tamaños por seguridad.
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"No existe archivo de simulaciones: {path}")

    data = []
    with open(path, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            cols = line.strip().split()
            if len(cols) < 2:
                continue
            values = [float(x) for x in cols[1:]]
            data.append(values)

    if len(data) == 0:
        raise ValueError(f"Archivo vacío o inválido: {path}")

    max_len = max(len(row) for row in data)
    clean = []
    for row in data:
        if len(row) == max_len:
            clean.append(row)
        else:
            clean.append(row + [np.nan] * (max_len - len(row)))

    return np.array(clean, dtype=float)


# -------------------------------------------------------------
# ------------ CARGA DE CURVA OBSERVADA -----------------------
# -------------------------------------------------------------
def load_observed_curve_from_big_table(path, id_obj):
    """
    De rot_prfl_index_set.cat o rot_cum_index_set.cat:
    Busca la fila cuyo primer token sea id_obj.
    Retorna array float con los valores desde la segunda columna.
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"No existe archivo observado: {path}")

    with open(path, "r") as f:
        for line in f:
            if line.startswith("#"):
                continue
            parts = line.split()
            if parts[0] == id_obj:
                return np.array(parts[1:], dtype=float)

    raise ValueError(f"No se encontró el ID {id_obj} en {path}")


# -------------------------------------------------------------
# --------------------- RADIOS X ------------------------------
# -------------------------------------------------------------
def build_x_values(n_cols):
    """Genera 0.25, 0.30, 0.35, ..."""
    return 0.25 + 0.05 * np.arange(n_cols)


# -------------------------------------------------------------
# ------------------ TABLA ESTADÍSTICAS -----------------------
# -------------------------------------------------------------
def compute_statistics_table(x_values, sims, observed_curve):
    """
    Devuelve una tabla (dict) con estadísticas por columna:
    mean, std, p16, p84, min, max, obs, delta_obs
    """
    mean = np.nanmean(sims, axis=0)
    std = np.nanstd(sims, axis=0)
    p16 = np.nanpercentile(sims, 16, axis=0)
    p84 = np.nanpercentile(sims, 84, axis=0)
    vmin = np.nanmin(sims, axis=0)
    vmax = np.nanmax(sims, axis=0)
    delta = observed_curve - mean

    return {
        "r_rp": x_values,
        "MC_mean": mean,
        "MC_std": std,
        "MC_p16": p16,
        "MC_p84": p84,
        "MC_min": vmin,
        "MC_max": vmax,
        "Obs_value": observed_curve,
        "Delta_Obs_vs_MC_mean": delta,
    }


def save_stats_table(path, table_dict):
    """
    Guarda una tabla ASCII tipo .tbl
    """

    keys = list(table_dict.keys())
    cols = len(table_dict[keys[0]])

    with open(path, "w") as f:
        header = "# " + " ".join(keys)
        f.write(header + "\n")

        for i in range(cols):
            row = [f"{table_dict[k][i]:.6f}" for k in keys]
            f.write(" ".join(row) + "\n")


# -------------------------------------------------------------
# ------------------------- PLOTS -----------------------------
# -------------------------------------------------------------
def plot_profile_with_band(x_values, sims, observed_curve, title):
    """Grafica simulaciones + banda 1σ + observado."""
    mean_curve = np.nanmean(sims, axis=0)
    p16 = np.nanpercentile(sims, 16, axis=0)
    p84 = np.nanpercentile(sims, 84, axis=0)

    plt.figure(figsize=(7, 5))

    for i in range(sims.shape[0]):
        plt.plot(x_values, sims[i], color="gray", alpha=0.15)

    plt.fill_between(x_values, p16, p84, alpha=0.35, color="C0", label="1σ (MC)")
    plt.plot(x_values, mean_curve, color="C0", lw=2, label="Media MC")
    plt.plot(x_values, observed_curve, color="C3", lw=2.5, label="Observado")

    plt.xlabel(r"$r / r_p$")
    plt.ylabel(r"$A_{\alpha}$")
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.grid(True)
    plt.show()


# -------------------------------------------------------------
# --------------------------- MAIN ----------------------------
# -------------------------------------------------------------
def main():
    if len(sys.argv) != 3:
        print("Uso: python3 sim_uncertainty.py alpha_dir id_obj")
        sys.exit(1)

    alpha_dir = sys.argv[1]
    id_obj = sys.argv[2]

    base_unc = os.path.join(alpha_dir, "uncertainty")
    os.makedirs(base_unc, exist_ok=True)

    # Paths simulaciones
    prfl_path = os.path.join(base_unc, f"{id_obj}_prfl_index_set.cat")
    cum_path  = os.path.join(base_unc, f"{id_obj}_cum_index_set.cat")

    # Paths observaciones
    base_obs = os.path.join(alpha_dir, "files", "catalogs", "rotated_alpha")
    obs_prfl_path = os.path.join(base_obs, "rot_prfl_index_set.cat")
    obs_cum_path  = os.path.join(base_obs, "rot_cum_index_set.cat")

    # Cargar datos
    sims_prfl = load_simulation_table(prfl_path)
    sims_cum  = load_simulation_table(cum_path)

    observed_prfl = load_observed_curve_from_big_table(obs_prfl_path, id_obj)
    observed_cum  = load_observed_curve_from_big_table(obs_cum_path, id_obj)

    # Radios
    n_cols = sims_prfl.shape[1]
    x_vals = build_x_values(n_cols)

    # ---------------------------------------------------------
    # ------------- GUARDAR TABLAS DE ESTADÍSTICAS -----------
    # ---------------------------------------------------------
    stats_prfl = compute_statistics_table(x_vals, sims_prfl, observed_prfl)
    stats_cum  = compute_statistics_table(x_vals, sims_cum, observed_cum)

    save_stats_table(os.path.join(base_unc, f"{id_obj}_stats_prfl.tbl"), stats_prfl)
    save_stats_table(os.path.join(base_unc, f"{id_obj}_stats_cum.tbl"), stats_cum)

    print(f"Tablas de estadísticas guardadas en:")
    print(f"  - {id_obj}_stats_prfl.tbl")
    print(f"  - {id_obj}_stats_cum.tbl")

    # ---------------------------------------------------------
    # ---------------------- PLOTS ----------------------------
    # ---------------------------------------------------------
    plot_profile_with_band(x_vals, sims_prfl, observed_prfl,
                           f"Asimetría PRFL — {id_obj}")

    plot_profile_with_band(x_vals, sims_cum, observed_cum,
                           f"Asimetría CUM — {id_obj}")


if __name__ == "__main__":
    main()
