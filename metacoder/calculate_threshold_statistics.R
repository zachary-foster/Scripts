source("functions.R")

#Constants
taxonomy_levels = c(k='Kingdom', d='Domain', p='Phylum', c='Class', sc='Subclass', o='Order', so='Suborder', f='Family', g='Genus', s='Species', i='Individual')
taxonomy_separator = ';'

#Functions for calculating taxon-specific statiscs
overall_statistics <- function(taxon, distance, identity, ...) {
  if (!is.matrix(distance)) {
    return(list(distance_mean=NA, 
                distance_sd=NA,
                distance_count=NA,
                subsampled_count=NA))
  }
  if (sum(!is.na(distance)) == 0) { #if there are no values besides NA
    my_mean = NA
  } else {
    my_mean = mean(distance, na.rm=TRUE)
  }
  return(list(distance_mean=my_mean, 
              distance_sd=sd(distance, na.rm=TRUE),
              distance_count=sum(!is.na(distance)),
              subsampled_count=nrow(distance)))
}

intertaxon_statistics <- function(taxon, distance, identity, ...) {
  if (length(unique(rownames(distance))) < 2) {
    return(list(intertaxon_distance_mean=NA,
                intertaxon_distance_sd=NA,
                intertaxon_distance_count=NA))
  }
  inter_data <- distance[!identity]
  return(list(intertaxon_distance_mean=mean(inter_data, na.rm=TRUE),
              intertaxon_distance_sd=sd(inter_data, na.rm=TRUE),
              intertaxon_distance_count=sum(!is.na(inter_data))))
}

intrataxon_statistics <- function(taxon, distance, identity, ...) {
  subtaxon_count <- length(unique(rownames(distance)))
  if (subtaxon_count < 2) {
    return(list(intrataxon_distance_mean=NA,
                intrataxon_distance_sd=NA,
                intrataxon_distance_count=NA,
                subtaxon_count=NA))
  }
  intra_data <- distance[identity]
  return(list(intrataxon_distance_mean=mean(intra_data, na.rm=TRUE),
              intrataxon_distance_sd=sd(intra_data, na.rm=TRUE),
              intrataxon_distance_count=sum(!is.na(intra_data)),
              subtaxon_count=subtaxon_count))
}

distance_distribution <- function(taxon, distance, identity, distance_bin_width=0.001, ...) {
  if (!is.matrix(distance) | sum(!is.na(distance)) == 0) {
    return(list(distance_distribution=NA))
  }
  #Calculate distance distribution
  breaks <- seq(as.integer(min(distance, na.rm=TRUE) / distance_bin_width),
                as.integer(max(distance, na.rm=TRUE) / distance_bin_width) + 1)
  breaks <- breaks * distance_bin_width
  total_hist <- hist(distance, plot=FALSE, breaks=breaks)
  output <- data.frame(count_middle=total_hist$mids, total=total_hist$counts)
  if (length(unique(rownames(distance))) >= 2) {
    same_hist <- hist(distance[identity], plot=FALSE, breaks=breaks)
    different_hist <- hist(distance[!identity], plot=FALSE, breaks=breaks)
    output <- cbind(output, same=same_hist$counts, different=different_hist$counts)
  }
  
  #get output file path
  file_name <- paste(c(taxonomy_levels[taxon$level], '_', 
                       as.character(taxon$name),
                       '_', as.character(taxon$id),
                       '.txt'), collapse="") 
  #prepare output directory
  sub_directory <- file.path(output_directory, 'distance_distribution', fsep = .Platform$file.sep)
  file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
  if (!file.exists(sub_directory)) {
    dir.create(sub_directory, recursive=TRUE)
  }
  #write output data
  write.table(format(output, scientific = FALSE) , file=file_path, sep="\t", quote=FALSE, row.names=FALSE)
  return(list(distance_distribution=file_path))
}

threshold_optimization <- function(taxon, distance, identity, threshold_resolution=0.001, ...) {
  if (length(unique(rownames(distance))) < 2) {
    return(list(threshold_optimization = NA,
                optimal_threshold = NA, 
                optimal_false_negative = NA,
                optimal_false_positive = NA,
                optimal_error = NA))
  }
  #convert lower tri matrix to full
  distance[upper.tri(distance, diag=TRUE)] <- t(distance)[upper.tri(distance, diag=TRUE)]
  diag(distance) <- 0
  
  #Get output file path
  taxon_name <- as.character(taxon$name)
  file_name <- paste(c(taxonomy_levels[taxon$level], '_', 
                       taxon_name,
                       '_', as.character(taxon$id),'.txt'), collapse="") 
  sub_directory <- file.path(output_directory, 'threshold_optimization', fsep = .Platform$file.sep)
  file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
  
  #prepare output directory
  if (!file.exists(sub_directory)) {
    dir.create(sub_directory, recursive=TRUE)
  }
  
  #Calulate threshold error rates
  min_x = 0
  max_x = quantile(distance, .8, na.rm=TRUE, type=3)
  threshold <- seq(min_x, max_x, by = threshold_resolution)
  statistics <- lapply(threshold, function(x) threshOpt(distance, row.names(distance), thresh = x))
  statistics <- ldply(statistics)
  colnames(statistics) <- c("threshold", "true_negative", "true_positive", "false_negative", "false_positive", "cumulative_error")
  optimal_error <- min(statistics$cumulative_error)
  optimal_index <- which(optimal_error == statistics$cumulative_error) 
  optimal_threshold <- mean(statistics[optimal_index,'threshold'], rm.na=TRUE)
  optimal_false_negative <- statistics[optimal_index[1],'false_negative']
  optimal_false_positive <- statistics[optimal_index[length(optimal_index)],'false_positive']
  
  #write output data
  write.table(format(statistics, scientific = FALSE) , file=file_path, sep="\t", quote=FALSE, row.names=FALSE)
  return(list(threshold_optimization = file_path,
              optimal_threshold = optimal_threshold, 
              optimal_false_negative = optimal_false_negative,
              optimal_false_positive = optimal_false_positive,
              optimal_error = optimal_error))
}




#Parameters
distance_matrix_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test_distance_matrix.txt"
taxonomy_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test_database_taxon_statistics.txt"
root_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test"
level_to_analyze = 'g'
distance_type = 'PID'
max_sequences_to_compare = 100
append_to_input = FALSE
distance_bin_width = 0.001
threshold_resolution = 0.001
functions_to_apply <- list("overall_statistics",
                           "intertaxon_statistics",
                           "intrataxon_statistics",
                           "distance_distribution",
                           "threshold_optimization")




#Derived Parameters
output_directory_name = paste(distance_type, '_', taxonomy_levels[level_to_analyze], sep='') 
output_directory = file.path(root_directory, output_directory_name, fsep = .Platform$file.sep)
taxon_statistics_output_name = paste('taxon_statistics', '_', output_directory_name, '.txt', sep='')
taxon_statistics_output_path =  file.path(output_directory, taxon_statistics_output_name, fsep = .Platform$file.sep)

#load and format distance matrix (CAN TAKE LONG TIME)
distance_matrix = as.matrix(read.csv(distance_matrix_file, sep="\t", row.names=1, header=FALSE))
distance_matrix_names = row.names(distance_matrix)
distance_matrix_taxonomy = sapply(strsplit(distance_matrix_names, split='|', fixed=TRUE), function(x) x[3])

#If the metric is similarity (ie 1=same instead of 0), convert to distance
if (distance_matrix[1,1] == 1) {
  distance_matrix = 1 - distance_matrix
}

#load taxonomy statistics
taxonomy_data = read.csv(taxonomy_file, sep="\t", row.names=2, header=TRUE)

#order taxonomic levels into an ordered factor based on order of occurance in stats file
taxonomy_data$level <- ordered(taxonomy_data$level, levels=names(taxonomy_levels))

#Prepare output directory
if (!file.exists(output_directory)) {
  dir.create(output_directory, recursive=TRUE)
}


#apply functions to subsets of distance matrix for each taxon (CAN TAKE LONG TIME)
filter_taxonomy_string <- function(taxon, min_level, max_level) {
  my_levels <- levels(taxonomy_data[taxon, 'level'])
  parsed_taxonomy <- sapply(unlist(strsplit(taxon, split=';', fixed=T)),
                            strsplit, split='__', fixed=T)
  filter <- sapply(parsed_taxonomy, function(x) ordered(x[1], my_levels) >= min_level & ordered(x[1], my_levels) <= max_level)
  parsed_taxonomy <- parsed_taxonomy[filter]
  paste(sapply(parsed_taxonomy, paste, collapse='__'), collapse=';')
}

subsample_by_taxonomy <- function(taxon, triangular=TRUE, level = 'subtaxon', max_subset=NA) {
  base_level <- offset_ordered_factor(taxonomy_data[taxon, 'level'], 1)
  if (level == 'subtaxon') {
    level <- base_level
  }
  if (is.na(level) | taxonomy_data[taxon, 'level'] >= level) {
    return(NA)
  }
  indexes <- grep(taxon, distance_matrix_taxonomy, value = FALSE, fixed = TRUE)
  if (!is.na(max_subset) && length(indexes) > max_subset) {
    indexes = sample(indexes, max_subset)
  }
  submatrix <- distance_matrix[indexes, indexes, drop = FALSE]
  names <- distance_matrix_taxonomy[indexes]
  names <- mapply(FUN=filter_taxonomy_string, names, MoreArgs=list(base_level, level))
  row.names(submatrix) <- names
  colnames(submatrix) <- names
  if (triangular) {
    submatrix[upper.tri(submatrix, diag=TRUE)] <- NA
  }
  return(submatrix)
}

get_stat_function_args <- function(data_frame_row, ...) {
  distance <- subsample_by_taxonomy(row.names(data_frame_row), ...)
  identity <-  sapply(rownames(distance), function(x) colnames(distance) == x)
  list(data_frame_row, distance, identity)
}

taxon_statistics <- fapply(taxonomy_data, functions_to_apply,
                           preprocessor = get_stat_function_args,
                           preprocessor_args = list(level = level_to_analyze, 
                                                    max_subset = max_sequences_to_compare),
                           append = append_to_input, 
                           distance_bin_width = distance_bin_width,
                           threshold_resolution = threshold_resolution)


#Calculate statistics derived from other statistics
taxon_statistics$inter_intra_differnece <- taxon_statistics$intertaxon_distance_mean - taxon_statistics$intrataxon_distance_mean
taxon_statistics$optimal_error <- (taxon_statistics$optimal_false_negative + taxon_statistics$optimal_false_positive) / taxon_statistics$subsampled_count

#save statisics
write.table(taxon_statistics, file=taxon_statistics_output_path, sep="\t", quote=FALSE, col.names=NA)
