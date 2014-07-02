source("functions.R")

#Constants
taxonomy_levels = c(k='Kingdom', d='Domain', p='Phylum', c='Class', sc='Subclass', o='Order', so='Suborder', f='Family', g='Genus', s='Species', i='Individual')
taxonomy_separator = ';'

#Parameters
distance_matrix_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test_distance_matrix.txt"
taxonomy_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test_database_taxon_statistics.txt"
root_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/test"
level_to_analyze = 's'
distance_type = 'PID'
max_sequences_to_compare = 100
append_to_input = FALSE
distance_bin_width = 0.001
threshold_resolution = 0.001
remove_na_rows = TRUE
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

#Functions for calculating additional taxon-specific statiscs
taxon_output_path_preparation <- function(output_directory, sub_directory=NULL, name=NULL, id=NULL, level_name=NULL, ext="", ...) {
  #get directory path
  if (!is.null(sub_directory)) {
    output_directory <- file.path(output_directory, sub_directory, fsep = .Platform$file.sep)
  }
  #prepare output directory
  if (!file.exists(output_directory)) {
    dir.create(output_directory, recursive=TRUE)
  }  
  #get output file name
  file_name <- paste(c(as.character(level_name),
                       as.character(name),
                       as.character(id)),
                     collapse="_") 
  if (file_name == "") { #if file name information is NULL assume that files are incremental integers. 
    file_name = as.character(next_incremental_file_number(output_directory))
  }
  #add extension
  file_name <- paste(c(file_name,
                       ext),
                     collapse="") 
  file.path(output_directory, file_name, fsep = .Platform$file.sep)
} 

overall_statistics <- function(distance, ...) {
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

intertaxon_statistics <- function(distance, identity=NULL, ...) {
  output <- list()
  
  if (is.null(identity)) {
    identity = sapply(rownames(distance), function(x) colnames(distance) == x)
  }
  
  is_valid_input <- length(identity) > 0 && length(table(identity)) == 2

  if (is_valid_input) {
    inter_data <- distance[!identity]
    output$intertaxon_distance_mean <- mean(inter_data, na.rm=TRUE)
    output$intertaxon_distance_sd <- sd(inter_data, na.rm=TRUE)
    output$intertaxon_distance_count <- sum(!is.na(inter_data))
  } else {
    output$intertaxon_distance_mean <- NA
    output$intertaxon_distance_sd <- NA
    output$intertaxon_distance_count <- NA
  }
  return(output)
}

intrataxon_statistics <- function(distance, identity=NULL, ...) {
  output <- list()
  
  if (is.null(identity)) {
    identity = sapply(rownames(distance), function(x) colnames(distance) == x)
  }
  
  is_valid_input <- length(identity) > 0 && length(table(identity)) == 2

  if (is_valid_input) {
    intra_data <- distance[identity]
    output$intrataxon_distance_count <- sum(!is.na(intra_data))
    if (output$intrataxon_distance_count == 0) {
      output$intrataxon_distance_mean <- NA
    } else {
      output$intrataxon_distance_mean <- mean(intra_data, na.rm=TRUE)
    }
    output$intrataxon_distance_sd <- sd(intra_data, na.rm=TRUE)
    output$subtaxon_count <- length(unique(rownames(distance)))
  } else {
    output$intrataxon_distance_mean <- NA
    output$intrataxon_distance_sd <- NA
    output$intrataxon_distance_count <- NA
    output$subtaxon_count <- NA
  }
  return(output)
}

distance_distribution <- function(distance, identity=NULL, distance_bin_width=0.001, output_file_path=NULL, ...) {
  output <- list()
  
  if (is.null(identity)) {
    identity = sapply(rownames(distance), function(x) colnames(distance) == x)
  }
  
  #Validate input data
  is_valid_input = is.matrix(distance) && sum(!is.na(distance)) > 0
  
  #Calculate distance distribution
  if (is_valid_input) {
    breaks <- seq(as.integer(min(distance, na.rm=TRUE) / distance_bin_width),
                  as.integer(max(distance, na.rm=TRUE) / distance_bin_width) + 1)
    breaks <- breaks * distance_bin_width
    total_hist <- hist(distance, plot=FALSE, breaks=breaks)
    distance_distribution <- data.frame(count_middle=total_hist$mids, total=total_hist$counts)
    if (length(unique(rownames(distance))) >= 2) {
      same_hist <- hist(distance[identity], plot=FALSE, breaks=breaks)
      different_hist <- hist(distance[!identity], plot=FALSE, breaks=breaks)
      distance_distribution <- cbind(distance_distribution, 
                                     same=same_hist$counts,
                                     different=different_hist$counts)
    }
  } else {
    distance_distribution <- NA
  }
  output$distance_distribution <- distance_distribution
  
  #write output data
  if (!is.null(output_file_path)) {
    if (is_valid_input) {
      if (file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".txt",
                                                   ...)
      } else {
        file_path <- output_file_path
      }
      write.table(format(distance_distribution, scientific = FALSE) , file=file_path, sep="\t", quote=FALSE, row.names=FALSE)    
    } else {
      file_path <- NA
    }
    output$distance_distribution_file <- file_path
  }
  
  return(output)
}

threshold_optimization <- function(distance, threshold_resolution=0.001, output_file_path=NULL, ...) {
  output <- list()
  
  #Validate input data
  is_valid_input = length(unique(rownames(distance))) >= 2
  
  if (is_valid_input) {
    #convert lower tri matrix to full
    distance[upper.tri(distance, diag=TRUE)] <- t(distance)[upper.tri(distance, diag=TRUE)]
    diag(distance) <- 0    
    
    #Calulate threshold error rates
    min_x = 0
    max_x = quantile(distance, .8, na.rm=TRUE, type=3)
    threshold <- seq(min_x, max_x, by = threshold_resolution)
    statistics <- lapply(threshold, function(x) threshOpt(distance, row.names(distance), thresh = x))
    statistics <- ldply(statistics)
    colnames(statistics) <- c("threshold", "true_negative", "true_positive", "false_negative", "false_positive", "cumulative_error")
    output$optimal_error <- min(statistics$cumulative_error)
    optimal_index <- which(output$optimal_error == statistics$cumulative_error) 
    output$optimal_threshold <- mean(statistics[optimal_index,'threshold'], rm.na=TRUE)
    output$optimal_false_negative <- statistics[optimal_index[1],'false_negative']
    output$optimal_false_positive <- statistics[optimal_index[length(optimal_index)], 'false_positive']
    output$threshold_optimization <- statistics 
  } else {
    output$optimal_error <- NA
    output$optimal_threshold <- NA
    output$optimal_false_negative <- NA
    output$optimal_false_positive <- NA   
    output$threshold_optimization <- NA
  }


  #write output data
  if (!is.null(output_file_path)) {
    if (is_valid_input) {
      if (file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".txt",
                                                   ...)
      } else {
        file_path <- output_file_path
      }
      write.table(format(statistics, scientific = FALSE), file=file_path, sep="\t", quote=FALSE, row.names=FALSE)    
    } else {
      file_path <- NA
    }
    output$threshold_optimization_file <- file_path
  }
  
  return(output)
#   #Get output file path
#   taxon_name <- as.character(taxon$name)
#   file_name <- paste(c(taxonomy_levels[taxon$level], '_', 
#                        taxon_name,
#                        '_', as.character(taxon$id),'.txt'), collapse="") 
#   sub_directory <- file.path(output_directory, 'threshold_optimization', fsep = .Platform$file.sep)
#   file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
#   
#   #prepare output directory
#   if (!file.exists(sub_directory)) {
#     dir.create(sub_directory, recursive=TRUE)
#   }
#   
#   #write output data
#   write.table(format(statistics, scientific = FALSE) , file=file_path, sep="\t", quote=FALSE, row.names=FALSE)
#   return(list(threshold_optimization_file = file_path,
#               threshold_optimization = statistics,
#               optimal_threshold = optimal_threshold, 
#               optimal_false_negative = optimal_false_negative,
#               optimal_false_positive = optimal_false_positive,
#               optimal_error = optimal_error))
}

#apply functions to subsets of distance matrix for each taxon (CAN TAKE LONG TIME)

# calculate_threshold_statistics <- function(taxonomy_data, distance_matrix, save_statistics=TRUE
get_stat_function_arguments <- function(data_frame_row, ...) {
  distance <- subsample_by_taxonomy(distance_matrix, row.names(data_frame_row), taxon_level = data_frame_row$level, ...)
  list(distance,
       identity = sapply(rownames(distance), function(x) colnames(distance) == x),
       name = data_frame_row$name,
       id = data_frame_row$id,
       level_name = taxonomy_levels[data_frame_row$level])
}

taxon_statistics <- fapply(taxonomy_data, functions_to_apply,
                           .preprocessor = get_stat_function_arguments,
                           .preprocessor_args = list(level_to_analyze = level_to_analyze, 
                                                    max_subset = max_sequences_to_compare),
                           .allow_complex=TRUE,
                           output_file_path=output_directory,
                           distance_bin_width = distance_bin_width,
                           threshold_resolution = threshold_resolution)

#Remove rows that are all NA 
if (remove_na_rows) {
  taxon_statistics <- remove_na_rows(taxon_statistics)                          
}

                                           
#Calculate statistics derived from other statistics
taxon_statistics$inter_intra_differnece <- taxon_statistics$intertaxon_distance_mean - taxon_statistics$intrataxon_distance_mean
taxon_statistics$optimal_error <- (taxon_statistics$optimal_false_negative + taxon_statistics$optimal_false_positive) / taxon_statistics$subsampled_count

#save statisics
write.table(taxon_statistics, file=taxon_statistics_output_path, sep="\t", quote=FALSE, col.names=NA)
