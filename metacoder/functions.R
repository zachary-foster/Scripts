library(reshape2)
library(ggplot2)
library(igraph)
library(png)
library(grid)
library(spider)
library(tools)
library(Hmisc)
library(knitr)
library(xtable)
library(plyr)
library(plotrix)
library(zoo)
library(stringr)


source('internal_functions.R')
source('plotting_functions.R')


filter_taxonomy_string <- function(taxon, min_level, max_level, taxon_levels) {
  parsed_taxonomy <- sapply(unlist(strsplit(taxon, split=';', fixed=T)),
                            strsplit, split='__', fixed=T)
  filter <- sapply(parsed_taxonomy, function(x) ordered(x[1], taxon_levels) >= min_level & ordered(x[1], taxon_levels) <= max_level)
  parsed_taxonomy <- parsed_taxonomy[filter]
  paste(sapply(parsed_taxonomy, paste, collapse='__'), collapse=';')
}

subsample_by_taxonomy <- function(distance_matrix, taxon, taxon_level, level_order, triangular=TRUE, level_to_analyze = 'subtaxon', max_subset=NA) {
  base_level <- offset_ordered_factor(taxon_level, 1)
  if (level_to_analyze == 'subtaxon') {
    level_to_analyze <- base_level
  }
  
  #if the level is not applicable return NA
  if (is.na(level_to_analyze) || taxon_level >= level_to_analyze) {
    return(NA)
  }
  
  #get indexes where taxon is present 
  indexes <- grep(taxon, row.names(distance_matrix), value = FALSE, fixed = TRUE)
  if (!is.na(max_subset) && length(indexes) > max_subset) {  #if their are too many instances, randomly subsample
    indexes = sample(indexes, max_subset)
  }
  
  #subsample matrix
  submatrix <- distance_matrix[indexes, indexes, drop = FALSE]
  names <- row.names(submatrix)
  names <- mapply(FUN=filter_taxonomy_string, names, MoreArgs=list(base_level, level_to_analyze, level_order))
  row.names(submatrix) <- names
  colnames(submatrix) <- names
  if (triangular) {
    submatrix[upper.tri(submatrix, diag=TRUE)] <- NA
  }
  return(submatrix)
}

taxon_info <- function(identifications, level_order, separator=';') {
  split_taxonomy <- strsplit(identifications, separator, fixed=TRUE)
  taxonomy <- unlist(lapply(split_taxonomy, function(x) sapply(seq(1, length(x)), function(y) paste(x[1:y], collapse=separator))))
  counts <- table(taxonomy)
  taxon_names <- names(counts)
  counts <- as.vector(counts)
  taxon_level <- sapply(strsplit(taxon_names, separator, fixed=TRUE), 
                        function(x) level_order[max(match(sub("__.*$", "", x), level_order))])
  taxon_level <- ordered(taxon_level, level_order)
  taxon_short_names <- sapply(1:length(taxon_names), function(i) 
    filter_taxonomy_string(taxon_names[i], taxon_level[i], taxon_level[i], level_order))
  taxon_short_names <- sub("^.*__", "", taxon_short_names)
  data.frame(row.names=taxon_names, 
             level=taxon_level, 
             name=taxon_short_names, 
             count=counts)
  
}



#Functions for calculating taxon-specific statiscs
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

distance_distribution <- function(distance, identity=NULL, distance_bin_width=0.001, output_file_path=NULL,  plot_file_path=NULL, name=NULL, ...) {
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
    distance_distribution$same <- hist(distance[identity], plot=FALSE, breaks=breaks)$counts
    if (length(unique(rownames(distance))) >= 2) {
      distance_distribution$different <- hist(distance[!identity], plot=FALSE, breaks=breaks)$counts
    } else {
      distance_distribution$different <- 0
      
    }
  } else {
    distance_distribution <- NA
  }
  output$distance_distribution <- distance_distribution
  
  #write output data
  if (!is.null(output_file_path)) {
    if (is_valid_input) {
      if (file.exists(output_file_path) && file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".txt",
                                                   name = name,
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
  
  #Make plot of output data
  if (!is.null(plot_file_path)) {
    if (is_valid_input) {
      if (file.exists(plot_file_path) && file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".png",
                                                   name = name,
                                                   ...)
      } else {
        file_path <- plot_file_path
      }
      my_plot <- plot_distance_distribution(output$distance_distribution, 
                                            save_png = file_path, 
                                            title = name, 
                                            bin_width=distance_bin_width)    
    } else {
      file_path <- NA
    }
    output$threshold_optimization_plot_path <- file_path
  }
  
  
  return(output)
}

threshold_optimization <- function(distance, threshold_resolution=0.001, output_file_path=NULL, plot_file_path=NULL, name=NULL, ...) {
  output <- list()
  
  #Validate input data
  is_valid_input = length(unique(rownames(distance))) >= 2
  
  if (is_valid_input) {
    #convert lower tri matrix to full
    distance[upper.tri(distance, diag=TRUE)] <- t(distance)[upper.tri(distance, diag=TRUE)]
    diag(distance) <- 0    
    
    #Calulate threshold error rates
    min_x <- 0
#     max_x = quantile(distance, .8, na.rm=TRUE, type=3)
    max_x <- max(distance)
    threshold <- seq(min_x, max_x, by = threshold_resolution)
    my_test <<- distance
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
      if (file.exists(output_file_path) && file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".txt",
                                                   name = name,
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
  
  #Make plot of output data
  if (!is.null(plot_file_path)) {
    if (is_valid_input) {
      if (file.exists(plot_file_path) && file.info(output_file_path)$isdir) {
        file_path <- taxon_output_path_preparation(output_file_path, 
                                                   sub_directory=as.character(match.call()[[1]]),
                                                   ext=".png",
                                                   name = name,
                                                   ...)
      } else {
        file_path <- plot_file_path
      }
      my_plot <- plot_threshold_optimization(output$threshold_optimization, 
                                             save_png = file_path, 
                                             title = name)    
    } else {
      file_path <- NA
    }
    output$threshold_optimization_plot_path <- file_path
  }
  
  return(output)
}

calculate_barcode_statistics <- function(distance_matrix, taxonomy_levels,
                                         saved_output_path = getwd(),
                                         level_to_analyze = 's',
                                         distance_type = 'PID',
                                         max_sequences_to_compare = 1000,
                                         return_raw_data = FALSE,
                                         #                                          remove_na_rows = TRUE,
                                         save_statistics = FALSE,
                                         save_raw_data = FALSE,
                                         save_plots = FALSE,
                                         taxonomy_separator = ';',
                                         functions_to_apply = list("overall_statistics",
                                                                   "intertaxon_statistics",
                                                                   "intrataxon_statistics",
                                                                   "distance_distribution",
                                                                   "threshold_optimization"),
                                         ...) {
  
  
  #If the metric is similarity (ie 1=same instead of 0), convert to distance
  if (distance_matrix[1,1] == 1) {
    distance_matrix = 1 - distance_matrix
  }
  
  #Prepare output directory and paths
  output_prefix <-  paste(distance_type, '_', taxonomy_levels[level_to_analyze], sep='')
  if(save_raw_data || save_plots) {
    data_output_directory_name <- paste(output_prefix, '_raw_data', sep='')
    data_output_directory <- file.path(saved_output_path, data_output_directory_name, fsep = .Platform$file.sep)
    if (!file.exists(data_output_directory)) {
      dir.create(data_output_directory, recursive=TRUE)
    }
  } 
  if (save_raw_data) {
    raw_data_output_directory = data_output_directory
  } else {
    raw_data_output_directory = NULL    
  }
  if (save_plots) {
    plot_output_directory = data_output_directory
  } else {
    plot_output_directory = NULL
  }
  
  #Calculate taxonomy statistics
  taxonomy_data <- taxon_info(distance_matrix_taxonomy, names(taxonomy_levels))
  taxonomy_data <- taxonomy_data[order(taxonomy_data$level), ]
  taxonomy_data$id <- 1:nrow(taxonomy_data)
  
  #apply functions to subsets of distance matrix for each taxon (CAN TAKE LONG TIME)
  get_stat_function_arguments <- function(data_frame_row, ...) {
    distance <- subsample_by_taxonomy(distance_matrix, row.names(data_frame_row), data_frame_row$level, names(taxonomy_levels), ...)
    list(distance,
         identity = sapply(rownames(distance), function(x) colnames(distance) == x),
         name = data_frame_row$name,
         title = data_frame_row$name,
         id = data_frame_row$id,
         level_name = taxonomy_levels[data_frame_row$level])
  }
  
  taxon_statistics <- fapply(taxonomy_data, functions_to_apply,
                             .preprocessor = get_stat_function_arguments,
                             .preprocessor_args = list(level_to_analyze = level_to_analyze, 
                                                       max_subset = max_sequences_to_compare),
                             .allow_complex = return_raw_data,
                             output_file_path = raw_data_output_directory,
                             plot_file_path = plot_output_directory, 
                             ...)
  taxon_statistics <- cbind(taxonomy_data, taxon_statistics)
  
  #   #Remove rows that are all NA 
  #   if (remove_na_rows) {
  #     taxon_statistics <- remove_all_na_rows(taxon_statistics)                          
  #   }
  
  #Calculate statistics derived from other statistics
  taxon_statistics$inter_intra_differnece <- taxon_statistics$intertaxon_distance_mean - taxon_statistics$intrataxon_distance_mean
  taxon_statistics$optimal_error <- (taxon_statistics$optimal_false_negative + taxon_statistics$optimal_false_positive) / taxon_statistics$subsampled_count
  
  if (save_statistics) {
    taxon_statistics_output_name = paste('taxon_statistics', '_', output_prefix, '.txt', sep='')
    taxon_statistics_output_path =  file.path(saved_output_path, taxon_statistics_output_name, fsep = .Platform$file.sep)
    complex_column <- sapply(taxon_statistics, is.recursive)
    write.table(taxon_statistics[,!complex_column], file=taxon_statistics_output_path, sep="\t", quote=FALSE, col.names=NA)
  }
  
  return(taxon_statistics)
}

#===================================================================================================
#' Queries sequences for a given taxon
#'
#' Produces a sequinr query object that can be used to download sequences. 
#' @param query_id A character vector of length 1 specifying the variable name the query will be bound to.
#' @param taxon A character vector of taxa. Specifing multiple taxa is equivalent to 
#'    running the command multiple times with each taxa and concatenating the results. 
#' @param key A character vector of keywords. All keywords must be present for a given
#'    sequence to be returned.
#' @param type The type of the sequence to return (e.g. RRNA). Use `getType()` to see options. 
#' @return A instance of class seqinr::qaw, as returned by seqinr::query. 
#' @details Based off a exercise in the seqinr vignette.
#' @example
#'   \dontrun{
#'     choosebank("genbank")
#'     query_taxon("test", c("phytophthora", "pythium"), c("@18S@", "@28S@"), "RRNA")
#'     str(test)
#'     closebank()
#'   }
#' @seealso taxize::ncbi_getbyname seqinr::query
#' @importFrom seqinr query
#' @export
query_taxon <- function(query_id, taxon, key = character(0), type)   {
  
  single_query <- function(query_id, taxon, key) {
    query("single_query", paste('sp=', taxon, sep=''), virtual=TRUE)
    if (length(key) >= 1) names(key) <- paste("key_query", seq_along(key), sep="_")
    for (item in names(key)) {
      query(item, paste('single_query AND T=', type, ' AND K=', key[item], sep=""), virtual=TRUE)
      query(item, paste("PAR", item), virtual=TRUE) # Replace by parent sequences
    }
    return(query(query_id, paste(names(key), collapse=" AND "), virtual=TRUE))
  }
  
  queries <- mapply(single_query, paste("taxon_query", seq_along(taxon), sep="_"), taxon, key)
  query_names <- apply(queries, MARGIN=2, function(x) x$name)
  query(query_id, paste(query_names, collapse=" OR "))
}


#===================================================================================================
#' Extract the binomial organism name from genbank annotations.
#' 
#' @importFrom stringr str_match
extract_organism <- function(annotation) {
  index <- vapply(annotation, grep, FUN.VALUE=numeric(1), pattern="^SOURCE")
  value <- mapply(`[`, annotation, index)
  str_match(value, "^SOURCE[ \t]+(.+)$")[, 2]
}


#===================================================================================================
#' Extract the description from genbank annotations.
#' 
#' @importFrom stringr str_match
extract_description <- function(annotation) {
  annotation <- vapply(annotation, paste, character(1), collapse="")
  result <- str_match(annotation, "DEFINITION[ \t]+(.+)ACCESSION")[, 2]
  gsub("[ \t]+", " ", result)
}


#===================================================================================================
#' Extract the gi from genbank annotations.
#' 
#' @importFrom stringr str_match
extract_gi <- function(annotation) {
  index <- vapply(annotation, grep, FUN.VALUE=numeric(1), pattern="^VERSION")
  value <- mapply(`[`, annotation, index)
  str_match(value, "^VERSION[ \t]+.+GI:([0-9]+)$")[, 2]
}


#===================================================================================================
#' Download the sequences from an seqinr query object and formats them with their annotations
#' 
#' Formats the output of `sequinr::getSequence` and `sequinr::getAnnot` to the output of 
#' `taxize::ncbi_getbyid`.
#' @param query_req A list of class `SeqAcnucWeb` (e.g. what `sequinr::query` produces in the
#'    `x$req` element of the output.
#' @return A data.frame in the format of the output of `taxize::ncbi_getbyid`.
#' @importFrom seqinr choosebank closebank getSequence getAnnot
#' @export
download_gb_query <- function(query_req) {
  choosebank("genbank")
  on.exit(closebank())
  sequence <- getSequence(query_req)
  annotation <- getAnnot(query_req)
  sequence <- vapply(sequence, paste, character(1), collapse="")
  sequence <- toupper(sequence)
  data.frame(taxon = extract_organism(annotation),
             gene_desc = extract_description(annotation),
             gi_no = extract_gi(annotation),
             acc_no = as.character(query_req),
             length = vapply(sequence, nchar, numeric(1)),
             sequence = sequence)
}


#===================================================================================================
#' Converts a list of class seqinr::SeqAcnucWeb to a data.frame
#' 
#' @param query_req A list of class seqinr::SeqAcnucWeb
#' @return A data frame with rows named after the sequence names and columns 'length' and 'frame'. 
query_req_to_dataframe <- function(query_req) {
  data.frame(length = vapply(query_req, attr, numeric(1), "length"),
             frame = vapply(query_req, attr, numeric(1), "frame"),
             row.names = as.character(query_req),
             stringsAsFactors = FALSE)
}


#===================================================================================================
#' Downloads sequences that result from a taxon and keyword search
#' 
#' This function is meant to download sequences associated with a taxon and a set of keywords from
#' Genbank using a simple interface. More complicated queries should be done using the tools of the
#' `sequnir` and `taxize` packages, as this function does. 
#' @param taxon A character vector of taxa.
#' @param key A character vector of keywords. All keywords must be present for a given
#'    sequence to be returned.
#' @param type The type of the sequence to return (e.g. RRNA). Use `getType()` to see options. 
#' @param seq_length A numeric vector of length 2. The range of sequence lengths to allow.
#' @param max_count The maximum number of sequences to download. See note below for additional
#'   considerations.
#' @param subsample A character vector of length 1. Specifies how to subsample if more search 
#'   results are found than `max_count`. "subsample": randomly select using `sample`; "head": use
#'   first results; "tail": use last results.
#' @param standardize If TRUE, validate binomial taxon names using `taxize`.
#' @param use_acnuc If TRUE, sequences are downloaded using tools from `sequinr`. This is typically
#'   slower. 
#' @details This function first searches genbank via ACNUC and finds all sequences of a given taxon
#'   with given keywords (e.g. genes). It then subsamples these search results if there are too many
#'   and downloads the subsample sequences. The results are compiled into a data frame and
#'   returned. 
#' @note When `use_acnuc = FALSE`, some sequences that are found during searching with `seqinr` are
#'   not found when downloading using `taxize`. This is because `seqinr::query` returns the ACNUC
#'   id, which appears to be the genbank "locus" field, whereas `taxize::ncbi_getbyid` uses the
#'   "accession" or "GI" field. Usually the "locus" and "accession" field are the same, but when 
#'   they are differnt results of the search are not downloaded. Therefore the maximum count of 
#'   sequences will not always be returned even if more than the maximum are found.
#' @seealso download_gb_query query_taxon
#' @examples
#'   \dontrun{x <- download_gb_taxon(c("phytophthora", "pythium"), c("@18S@", "@28S@"), "RRNA")}
#' @importFrom seqinr choosebank closebank 
#' @importFrom taxize ncbi_getbyid gnr_resolve
#' @export
download_gb_taxon <- function(taxon, key, type,
                              seq_length = c(1,10000),
                              max_count = 100,
                              subsample = c("random", "head", "tail"),
                              standardize = TRUE,
                              use_acnuc = FALSE) {
  # Verify arguments -------------------------------------------------------------------------------
  subsample <- match.arg(subsample)
  stopifnot(length(seq_length) == 2, seq_length[1] <= seq_length[2])
  # Search for potential sequences -----------------------------------------------------------------
  choosebank("genbank")
  on.exit(closebank())
  query_taxon("taxon_query", taxon, key, type)
  results <- query_req_to_dataframe(taxon_query$req)
  results$index <- 1:nrow(results)
  # Filter by sequence length ----------------------------------------------------------------------
  results <- results[results$length >= seq_length[1] & results$length <= seq_length[2], ]
  # Subsample if necessary -------------------------------------------------------------------------
  max_count <- min(nrow(results), max_count)
  results <- switch(subsample,
                    "random" = results[sample(1:nrow(results), max_count), ],
                    "head"   = head(results, max_count), 
                    "tail"   = tail(results, max_count))
  # Download sequences -----------------------------------------------------------------------------
  if (use_acnuc) {
    sequences <- download_gb_query(taxon_query$req[results$index]) #seqinr used
  } else {
    sequences <- ncbi_getbyid(rownames(results), verbose=FALSE) #taxize used
  }
  # Standardize binomial names ---------------------------------------------------------------------
  if (standardize) {
    gnr_result <- gnr_resolve(sequences$taxon,
                              data_source_ids = 4, #4 is the code for NCBI
                              stripauthority = TRUE,
                              best_match_only = TRUE)
    gnr_result <- gnr_result$result
    sequences$taxon <- gnr_result$matched_name2[order(as.integer(rownames(gnr_result)))]
  }
  return(sequences)
}
