# PAckage script task for the GALASYM2 package

# Load necessary packages

set direc = "/home/sloan/galasym2/test/A496/J_band/config/src/"

package galasym2

task main         = "direc$main.cl"
task select       = "direc$select.cl"
task uncertainty  = "direc$uncertainty.cl"

clbye()
