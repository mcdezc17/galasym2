# PAckage script task for the GALASYM2 package

# Load necessary packages

set direc = "/home/sloan/galasym2-master/config/src/"
set gconf = "/home/sloan/galasym2-master/config/"

package galasym2

# Declarar pset's
task datapar = "direc$datapar.par"
task photimg = "direc$photimg.par"
task sexpar  = "direc$sexpar.par"
task psfexp  = "direc$psfexp.par"
task exp_pst = "direc$exp_pst.par"
# task alpha_par = "direc$alpha_par.par"

# pre-procesamiento de las imagenes:
task first_time      = "direc$first_time.cl"
# lista de indices disponibles:
task outer_res_index = "direc$outer_res_index.cl"
task alpha_index     = "direc$alpha_index.cl"
task outer_abs_index = "direc$outer_abs_index.cl"
task outer_rms_index = "direc$outer_rms_index.cl"
task a180_index      = "direc$a180_index.cl"
task snr_task        = "direc$snr_task.cl"

# No visibles:
task config_files   = "direc$config_files.cl"
task find_objs      = "direc$find_objs.cl"
task psf_model      = "direc$psf_model.cl"
task glxy_model     = "direc$glxy_model.cl"
task $find_center   = "direc$find_center.cl"

# -------------------------------------------
task distance       = "direc$distance.cl"
task select         = "direc$select.cl"
task uncertainty    = "direc$uncertainty.cl"

# hide PSET(s)
hidetask datapar
hidetask photimg
hidetask sexpar
hidetask psfexp
hidetask exp_pst
# hide TASK(s)
hidetask config_files
hidetask find_objs
hidetask psf_model
hidetask glxy_model
hidetask find_center
hidetask distance
hidetask select
hidetask uncertainty

print(" ")
print("    +------------------ GALASYM IRAF Package -------------------+")
print("    |                  Version 2.0, Nov, 2025                   |")
print("    |                                                           |")
print("    |               Requires IRAF v2.16 or greater              |")
print("    |        Tested with Ubuntu 24.04.3 LTS IRAF v2.16          |")
print("    |         Universidad de Guanajuato, Gto., Mexico           |")
print("    |     Please use GitHub site for submission of questions    |")
print("    |           https://github.com/mcdezc17/galasym             |")
print("    +-----------------------------------------------------------+")
print(" ")
print("  WARNING - setting imtype=fits")
print("          - required software: SExtractor, PSFExtractor & STILTS")
print(" ")

clbye()
