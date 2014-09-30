source("functions.R")
source("constants.R")

#Parameters
distance_matrix_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/distance_matrix_pid.txt"
output_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/pid"

#load and format distance matrix (CAN TAKE LONG TIME)
distance_matrix = as.matrix(read.csv(distance_matrix_file, sep="\t", row.names=1, header=FALSE))
distance_matrix_names = row.names(distance_matrix)
distance_matrix_taxonomy <- sapply(strsplit(distance_matrix_names, split='|', fixed=TRUE), function(x) x[3])
row.names(distance_matrix) <- distance_matrix_taxonomy
colnames(distance_matrix) <- distance_matrix_taxonomy

#Calculate statistics                                          
statistics <- lapply(clustering_levels, function(x) 
  calculate_barcode_statistics(distance_matrix, taxonomy_levels,
                               level_to_analyze= x,
                               saved_output_path = output_directory,
                               save_statistics = TRUE,
                               save_raw_data = TRUE,
                               save_plots = TRUE, 
                               distance_bin_width = 0.001,
                               threshold_resolution = 0.001,
                               max_sequences_to_compare = 500))