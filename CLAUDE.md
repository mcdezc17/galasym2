# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GALASYM2 is an IRAF/PyRAF package (v2.0) for measuring galaxy asymmetry/morphology
indices from FITS imaging. The pipeline is written almost entirely as IRAF CL
scripts (`.cl`, IRAF's own scripting language) plus a handful of standalone
Python helper scripts. There is no application build, no package manager
project, and no automated test suite — this is a scientific data-reduction
pipeline meant to be run interactively inside IRAF/PyRAF against real FITS
images and object catalogs.

Repo root only contains `config/`:
- `config/src/` — all `.cl` task definitions and Python helper scripts (the "code").
- `config/sextractor/` — SExtractor config templates, convolution filters, NNW star/galaxy classifier.
- `config/psfex/` — PSFEx config templates, plus `psfex/prepsfex/` for the pre-PSFEx SExtractor star-selection pass.

At runtime the pipeline creates and writes into a `data/` tree (not checked
in) alongside a `pawlik/` tree for the standalone shape-asymmetry scripts —
see "Runtime data layout" below.

## Running the package

This requires a working IRAF v2.16+ / PyRAF install plus SExtractor, PSFEx,
and STILTS (Starlink Tables Infrastructure Library Tool Set) on `$PATH`, and
(for interactive masking steps) DS9.

Load the package from an `cl`/PyRAF session, from the directory you want
`data/` created in:
```
cl < /home/sloan/galasym2-master/config/src/galasym2.cl
```
`galasym2.cl` hard-codes `direc = "/home/sloan/galasym2-master/config/src/"`
(config/src/galasym2.cl:5) — if this repo is ever relocated or cloned
elsewhere, that line must be updated first or the package will fail to find
its own tasks.

Typical session order:
1. `first_time` — prompts for the 5 psets (`datapar`, `photimg`, `sexpar`,
   `psfexp`, `exp_pst`), validates the input image/table, writes
   `data/data_files/full_params.txt`, then calls `config_files`.
2. `config_files` (hidden task) — renders the SExtractor cold/hot/third config
   files and the PSFEx config file from pset values, then calls `find_objs`.
3. `find_objs` (hidden task) — the main driver: cuts out per-object postage
   stamps (single-image mode) or ingests a folder of pre-cut images
   (list mode), runs PSFEx PSF modeling, then runs a two-pass
   cold-mode/hot-mode SExtractor extraction with `imedit`-based interactive
   masking between passes.
4. One or more index tasks, run against the object list `find_objs` produced:
   `alpha_index`, `outer_abs_index`, `outer_rms_index`, `outer_res_index`,
   `a180_index`, `shape_index`, `snr_task`. Each is its own
   pset-parameterized IRAF task computing a different 180°-rotation
   residual / asymmetry statistic over elliptical apertures (via
   `imexpr`/`imstat`) around each object's fitted center. `find_center`
   (hidden) is the sub-pixel center-refinement routine several of these
   tasks depend on. `outer_abs_index`/`outer_rms_index` take a `bulge_clip`
   pset (sigma-clip that carves a hole around the bulge before measuring);
   setting it to `"off"` disables the hole entirely, which is what the
   retired `abs_index`/`rms_index` tasks (moved to `config/src/dont_src/`)
   always did — `outer_abs_index`/`outer_rms_index` with `bulge_clip="off"`
   are their direct replacement.

Because tasks read state back from files under `data/data_files/` and
`data/results_sex/` rather than passing IRAF parameters directly, **task
order matters** and most tasks are safe to re-run (they skip work if the
expected output file already exists) — check the `if(!access(...))` /
`if(!imaccess(...))` guards near the top of a `.cl` file before assuming a
re-run will redo anything.

### Editing SExtractor/PSFEx config

Never hand-edit `config/sextractor/cold_default.sex`, `hot_default.sex`,
`third_config.sex`, `my_shape.sex`, or `config/psfex/my_default.psfex` —
these are generated/overwritten by the `config_files` task
(config/src/config_files.cl) from the pset `.par` files
(`config/src/datapar.par`, `photimg.par`, `sexpar.par`, `psfexp.par`,
`exp_pst.par`). Change the relevant `.par` default and re-run `first_time`
instead. Static, hand-maintained templates live alongside them
(`default.sex`, `default.param`, `default.nnw`, `*.conv` filters,
`template_default.psfex`) and are not touched by the pipeline.

### Standalone Python scripts (config/src/)

These are independent of the IRAF pipeline and are run directly with
`python3`/`python`:
- `ned_calc.py` — Ned Wright cosmology calculator; given
  `z H0 Omega_m Omega_vac` prints `kpc/arcsec` scale. Called internally by
  `find_objs.cl` (config/src/find_objs.cl:197) to size cutouts in kpc; can
  also be run standalone.
- `shape_asymmetry.py` — from-scratch implementation of the Pawlik, Wild &
  Verma (2016, MNRAS 456, 3032) shape-asymmetry index `A_S`: boxcar smoothing,
  flood-fill detection mask, PCA-aligned elliptical aperture, 180° rotation
  residual. Takes a catalog + images dir, writes per-object results.
- `loop_pawlik.py` — batch driver that invokes `shape_asymmetry.py` once per
  detection-threshold (`--sigmas`, either an explicit list or a
  start/stop/step triple) against one catalog, writing results under
  `pawlik/pawlik_<sigma>/`.
- `concat_pawlik.py` — merges the per-sigma `pawlik/pawlik_<sigma>/*.csv`
  outputs from `loop_pawlik.py` into single wide CSVs
  (`pawlik/merged_asymmetry.csv`, `merged_Rmax.csv`, `merged_SMAmax.csv`,
  `merged_ASTD.csv`), one column per sigma, keyed by object `ID`. Must be run
  from the project root (the directory containing `pawlik/`).
- `graph_As_colorsigma.py` — diagnostic plotting of `A_S` vs. detection sigma
  per object, classifying/coloring curves by shape (tidal-like vs. core-like)
  based on the initial monotonic run of the curve.

These have real Python dependencies (`numpy`, `pandas`, `astropy`, `scipy`,
`matplotlib`) — there's no `requirements.txt`/`pyproject.toml` in the repo,
so check what's importable before assuming an environment is set up.

### `config/src/.dont_src/`

Older/superseded `.cl` tasks and Python scripts (e.g. `psf_model.cl`,
`glxy_model.cl`, `sim_observation.py`) whose logic has been folded into
`find_objs.cl` directly, plus one-off experiments (`graf.py`, `ejemplo.cl`).
Nothing here is `task`-declared in `galasym2.cl` and nothing sources it — the
directory name is a deliberate "don't source this" marker. Treat it as
historical reference, not live code; don't wire it back into the package
without checking whether `find_objs.cl` already reimplements the same step.

## Runtime data layout

Created under the current working directory the first time `first_time` (or
`find_objs`) runs, mirroring what each task expects to find on the next run:
```
data/
  data_files/            catalogs, region files (.reg), imedit logfiles, full_params.txt
  data_images/
    observed/            per-object cutouts + masked variants
    background/
    segmentation/
    model/
    residual/
  cache/                 scratch images for find_center's sub-pixel search
  results_sex/            per-object SExtractor .cat files, concatenated catalogs
  results_psfex/          PSFEx outputs (PSF model, check-plots, check-images)
pawlik/
  pawlik_<sigma>/         per-sigma outputs from loop_pawlik.py -> shape_asymmetry.py
  merged_*.csv            outputs of concat_pawlik.py
```
Object identity threads through nearly every file name and catalog column as
`id_obj`/`ID`, taken from the first column of the initial position table (or
derived from each image's filename in list mode).

## Language/style notes for the `.cl` files

- IRAF CL, not a general-purpose language: `struct *list` + `fscan`/`scan` is
  the pattern for reading catalogs line-by-line; `key_word` dispatch tables
  (`if(key_word == "SOME_KEY"){...}`) are how each task re-reads the pset
  values that `first_time` flattened into `data/data_files/full_params.txt`.
- Shell/external-tool calls go through `printf("! <cmd>\n", ...) | cl` (for
  SExtractor/PSFEx/awk) or `... | cl` piping into STILTS (`stilts tpipe`,
  `tjoin`) for catalog joins/filters — look for these when tracing where a
  catalog column actually gets computed, since it's often outside IRAF proper.
- Comments and prints are in Spanish; task names, pset prompts, and file
  paths are in English. Keep that convention when touching existing files
  rather than translating in place.
