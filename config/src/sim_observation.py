#!/usr/bin/env python3

import sys
import os
import numpy as np
from astropy.io import fits

# ============================================================
# Usage:
#   python3 sim_observation.py n_sim image_in alpha_dir frac_extra
# ============================================================


def main():
    if len(sys.argv) < 5:
        print("Usage: python3 sim_observation.py n_sim image_in alpha_dir frac_extra")
        sys.exit(1)

    n_sim      = int(sys.argv[1])
    image_in   = sys.argv[2]      # must include .fits
    alpha_dir  = sys.argv[3]
    frac_extra = float(sys.argv[4])  # e.g. 0.10 for +10%

    # ------------------------------------------------------------
    # Locate original images
    # ------------------------------------------------------------
    obs_path   = f"./data/data_images/observed/observed_{image_in}"
    bgrms_path = f"./data/data_images/background/bgrms_{image_in}"
    bg_path    = f"./data/data_images/background/bg_{image_in}"

    if not os.path.exists(obs_path):
        print(f"ERROR: Observed image not found: {obs_path}")
        sys.exit(1)

    if not os.path.exists(bgrms_path):
        print(f"ERROR: Background RMS map not found: {bgrms_path}")
        sys.exit(1)

    # ------------------------------------------------------------
    # Load data
    # ------------------------------------------------------------
    obs_hdul   = fits.open(obs_path)
    obs_data   = obs_hdul[0].data.astype(float)
    obs_header = obs_hdul[0].header

    rms_data = fits.getdata(bgrms_path).astype(float)

    # Optional background
    bg_exists = os.path.exists(bg_path)
    bg_data   = fits.getdata(bg_path).astype(float) if bg_exists else None

    # Define "signal" = image without noise
    # A robust approach is:
    #   if bg_map exists: remove it
    #   if not: assume obs_data already contains signal+noise, and keep as is
    if bg_exists:
        signal = obs_data - bg_data
    else:
        signal = obs_data.copy()

    # ------------------------------------------------------------
    # Output directory
    # ------------------------------------------------------------
    outdir = f"./{alpha_dir}/uncertainty/images/"
    os.makedirs(outdir, exist_ok=True)

    print(f"Saving {n_sim} realizations into: {outdir}")

    # ------------------------------------------------------------
    # Split in two groups
    # ------------------------------------------------------------
    nA = n_sim // 2
    nB = n_sim - nA

    rmsA = rms_data
    rmsB = rms_data * (1.0 + frac_extra)

    print(f"Group A (n={nA}): sigma = RMS")
    print(f"Group B (n={nB}): sigma = (1 + {frac_extra}) * RMS")

    # ------------------------------------------------------------
    # Generate simulations
    # ------------------------------------------------------------
    for i in range(1, n_sim + 1):

        rms_i = rmsA if i <= nA else rmsB

        # fresh realization of noise, same shape as image
        noise_i = np.random.normal(loc=0.0, scale=rms_i)

        # simulated image:
        #   sim = signal + noise_i
        if bg_exists:
            sim_data = bg_data + signal + noise_i
        else:
            sim_data = signal + noise_i

        # --------------------------------------------------------
        # Save file
        # --------------------------------------------------------
        outname = f"{outdir}/sim{str(i)}_{image_in}"
        fits.writeto(outname, sim_data.astype(np.float32), obs_header, overwrite=True)

    print(f"All {n_sim} realizations generated successfully.\n")


# ============================================================
# Run
# ============================================================
if __name__ == "__main__":
    main()
