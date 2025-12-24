# PAckage script task for the GALASYM2 package

# Load necessary packages

set direc = "/home/sloan/galasym2/test/A496/J_band/config/src/"

package galasym2

task main         = "direc$main.cl"
task psf_model    = "direc$psf_model.cl"
task glxy_model   = "direc$glxy_model.cl"
task distance     = "direc$distance.cl"
task select       = "direc$select.cl"
task uncertainty  = "direc$uncertainty.cl"

clbye()
