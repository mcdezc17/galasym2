# PAckage script task for the GALASYM2 package

# Load necessary packages

set direc = "/home/sloan/galasym2/test/A496/J_band/config/src/"

package galasym2

task find_objs      = "direc$find_objs.cl"
task psf_model      = "direc$psf_model.cl"
task glxy_model     = "direc$glxy_model.cl"
task distance       = "direc$distance.cl"
task select         = "direc$select.cl"
task uncertainty    = "direc$uncertainty.cl"
task $find_center   = "direc$find_center.cl"

clbye()
