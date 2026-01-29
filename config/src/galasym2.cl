# PAckage script task for the GALASYM2 package

# Load necessary packages

set direc = "/home/sloan/galasym2/test/A496/J_band/config/src/"

package galasym2

# Declarar pset's
task datapar = "direc$datapar.par"
task photimg = "direc$photimg.par"
task sexpar  = "direc$sexpar.par"
task psfexp  = "direc$psfexp.par"
task exp_pst = "direc$exp_pst.par"
# task alpha_par = "direc$alpha_par.par"

# pre-procesamiento de las imagenes:
task first_time     = "direc$first_time.cl"
# lista de indices disponibles:
task alpha_index    = "direc$alpha_index.cl"

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

clbye()
