source("functions.R")

#Constants
taxonomy_levels = c(k='Kingdom', d='Domain', p='Phylum', c='Class', sc='Subclass', o='Order', so='Suborder', f='Family', g='Genus', s='Species', i='Individual')
taxonomy_separator = ';'

#Parameters
distance_matrix_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/distance_matrix_pid.txt"
taxonomy_file = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/subsampled_database_taxon_statistics.txt"
root_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1"
level_to_analyze = 'f'
distance_type = 'PID'

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
taxonomy_level_levels <- c(levels(taxonomy_data$level)[unique(taxonomy_data$level)])
taxonomy_data$level <- ordered(taxonomy_data$level, taxonomy_level_levels)

#Prepare output directory
if (!file.exists(output_directory)) {
  dir.create(output_directory, recursive=TRUE)
}
if (!file.exists(plot_directory)) {
  dir.create(plot_directory, recursive=TRUE)
}

#Functions for calculating additional taxon-specific statiscs
overall_statistics <- function(data, taxon, identity) {
  my_mean <- mean(data, na.rm=TRUE)
  my_sd <- sd(data, na.rm=TRUE)
  comparison_count <- sum(!is.na(data))
  individual_count <- nrow(data)
  return(list(my_mean, my_sd, comparison_count, individual_count))
}

intertaxon_statistics <- function(data, taxon, identity) {
  if (length(unique(rownames(data))) < 2) {
    return(list(NA, NA, NA))
  }
  inter_data <- data[!identity]
  my_mean <- mean(inter_data, na.rm=TRUE)
  my_sd <- sd(inter_data, na.rm=TRUE)
  my_count <- sum(!is.na(inter_data))
  return(list(my_mean, my_sd, my_count))
}

intrataxon_statistics <- function(data, taxon, identity) {
  if (all(is.na(unique(rownames(data))))) {
    return(list(NA, NA, NA, NA))
  }
  intra_data <- data[identity]
  my_mean <- mean(intra_data, na.rm=TRUE)
  my_sd <- sd(intra_data, na.rm=TRUE)
  comparison_count <- sum(!is.na(intra_data))
  taxon_count <- length(unique(rownames(data)))
  return(list(my_mean, my_sd, comparison_count, taxon_count))
}

distance_graph_hist <- function(data, taxon, identity) {
  data$value <- remove_outliers(data$value)
  taxon_name <- as.character(taxonomy_data[taxon, 'name'])
  file_name <- paste(c(taxonomy_levels[as.character(taxonomy_data[taxon, 'level'])], '_', 
                       taxon_name,
                       '_', as.character(taxonomy_data[taxon, 'id']),
                       '.png'), collapse="") 
  sub_directory <- file.path(plot_directory, 'distance_distribution', fsep = .Platform$file.sep)
  file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
  if (!file.exists(sub_directory)) {
    dir.create(sub_directory, recursive=TRUE)
  }
  png(file = file_path, bg = "transparent")
  my_plot <-ggplot(data, aes(value)) + 
    labs(title=taxon_name) +
    theme(title=element_text(size=30),
          axis.line=element_blank(),
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          legend.position="none",
          panel.background=element_blank(),
          panel.border=element_blank(),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.background=element_blank())
  if (sum(data$relation == "Same") > 0) {
    my_plot + geom_histogram(data=data[data$relation == "Same",], binwidth = .001, fill = 'magenta', alpha = .3, na.rm=TRUE)
  }
  if (sum(data$relation == "Different") > 0) {
    my_plot + geom_histogram(data=data[data$relation == "Different",], binwidth = .001, fill = 'cyan', alpha = .3, na.rm=TRUE)
  }
  if (is.na(unique(data$relation))) {
    my_plot + geom_histogram(data=data, binwidth = .001, fill = 'grey', alpha = .3, na.rm=TRUE)
  }
  
  print(my_plot)
  dev.off()
  return(list(file_path))
}

distance_graph <- function(data, taxon, identity) {
  data <- melt(data, na.rm=TRUE)
  data <- cbind(data, relation=ifelse(data$Var1 == data$Var2, "Same", "Different"))
  data$value <- remove_outliers(data$value)
  taxon_name <- as.character(taxonomy_data[taxon, 'name'])
  file_name <- paste(c(taxonomy_levels[as.character(taxonomy_data[taxon, 'level'])], '_', 
                       taxon_name,
                       '_', as.character(taxonomy_data[taxon, 'id']),
                       '.png'), collapse="") 
  sub_directory <- file.path(plot_directory, 'distance_distribution', fsep = .Platform$file.sep)
  file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
  if (!file.exists(sub_directory)) {
    dir.create(sub_directory, recursive=TRUE)
  }
  png(file = file_path, bg = "transparent")
  print(ggplot(data, aes(value, fill=relation, y = ..scaled..)) + 
          geom_density(alpha = .3, size=0, na.rm=TRUE, adjust = .3, position='identity') +
          #          geom_density(aes(value, fill=NA), colour='lightgrey', na.rm=TRUE, adjust = .1, size=.8, position='identity') +
          scale_fill_manual( values=c( "magenta","cyan" ) ) +
          labs(title=taxon_name) +
          theme(title=element_text(size=30),
                axis.line=element_blank(),
                #                axis.text.x=element_blank(),
                axis.text.y=element_blank(),
                axis.ticks.y=element_blank(),
                axis.title.x=element_blank(),
                axis.title.y=element_blank(),
                legend.position="none",
                panel.background=element_blank(),
                panel.border=element_blank(),
                panel.grid.major=element_blank(),
                panel.grid.minor=element_blank(),
                plot.background=element_blank()))
  dev.off()
  return(list(file_path))
}

threshold_optimization_graph <- function(data, taxon, identity) {
  min_x = 0
  max_x = quantile(data, .8, na.rm=TRUE, type=3)
  #convert lower tri matrix to full
  data[upper.tri(data, diag=TRUE)] <- t(data)[upper.tri(data, diag=TRUE)]
  diag(data) <- 0
  taxon_name <- as.character(taxonomy_data[taxon, 'name'])
  file_name <- paste(c(taxonomy_levels[as.character(taxonomy_data[taxon, 'level'])], '_', 
                       taxon_name,
                       '_', as.character(taxonomy_data[taxon, 'id']),
                       '.png'), collapse="") 
  sub_directory <- file.path(plot_directory, 'threshold_optimization', fsep = .Platform$file.sep)
  file_path <- file.path(sub_directory, file_name, fsep = .Platform$file.sep)
  if (!file.exists(sub_directory)) {
    dir.create(sub_directory, recursive=TRUE)
  }
  threshold <- seq(min_x, max_x, by = .0005)
  statistics <- lapply(threshold, function(x) threshOpt(data, row.names(data), thresh = x))
  statistics <- as.data.frame(do.call(rbind, statistics))
  optimal_error <- min(statistics[,'Cumulative error'])
  optimal_index <- which(optimal_error == statistics[,'Cumulative error']) 
  optimal_threshold <- mean(statistics[optimal_index,'Threshold'], rm.na=TRUE)
  optimal_false_negative <- statistics[optimal_index[1],'False neg']
  optimal_false_positive <- statistics[optimal_index[length(optimal_index)],'False pos']
  min_x_display = 0
  #max_x_display = statistics[quantile(statistics[,'False neg'], 0.9, type=3) == statistics[,'False neg'],'Threshold'][1]
  optimal_error_proportion <- optimal_error / nrow(data)
  error_at_max_x <- ((1 - optimal_error_proportion) / 2) + optimal_error_proportion
  max_x_display = statistics[which(statistics[,'False neg'] / nrow(data) > error_at_max_x)[1], 'Threshold']
  if (is.na(max_x_display)) {
    max_x_display = max_x
  }
  statistics <- melt(statistics, measure.vars=4:6, id.vars = 1,  na.rm=TRUE)
  statistics$value <- statistics$value / nrow(data)
  png(file = file_path, bg = "transparent")
  my_plot <- ggplot(statistics[statistics$variable != "Cumulative error",], aes(x=Threshold, y=value)) + 
    geom_area(aes(fill = variable), alpha = .3, , position='identity') +
    geom_line(data=statistics[statistics$variable == "Cumulative error",], , position='identity') +
    labs(title=taxon_name) +
    scale_x_continuous(limits = c(min_x_display, max_x_display)) +
    theme(title=element_text(size=30),
          axis.line=element_blank(),
          #          axis.text.x=element_blank(),
          #          axis.text.y=element_blank(),
          #          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          legend.position="none",
          panel.background=element_blank(),
          panel.border=element_blank(),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.background=element_blank())
  print(my_plot)
  dev.off()
  return(list(file_path, optimal_threshold, optimal_false_negative, optimal_false_positive, optimal_error))
}

functions_to_apply <- list(overall_statistics = c("distance_mean", "distance_sd", "distance_count", "subsampled_count"), 
                           intertaxon_statistics = c("intertaxon_distance_mean", "intertaxon_distance_sd", "intertaxon_distance_count"),
                           intrataxon_statistics = c("intrataxon_distance_mean", "intrataxon_distance_sd", "intrataxon_distance_count", "subtaxon_count"),
                           distance_graph = c("distance_graph"),
                           threshold_optimization_graph = c("threshold_graph", "optimal_threshold", "optimal_false_negative", "optimal_false_positive", "optimal_error"))

apply_functions <- function(taxon, functions, max_subset=NA, level = 'subtaxon', ...) {
  data <- subsample_by_taxonomy(taxon, level = level, max_subset=max_subset)
  if (!is.matrix(data)) {
    #return all outputs as NA without using functions
    empty_list <- lapply(unlist(functions), function(x) NA)
    names(empty_list) <- unlist(functions)
    return(empty_list)
  }
  #make true/false matrix for future filering
  identity <-  sapply(rownames(data), function(x) colnames(data) == x)
  output <- sapply(names(functions), function(f) get(f)(data, taxon, identity, ...))
  #turn nested lists into a list of vectors
  output <- unlist(recursive=F, lapply(1:length(functions), 
                                       function(x) lapply(1:length(functions[[x]]),
                                                          function(y) output[[x]][[y]])))
  names(output) <- unlist(functions)
  #close any graphics devices that did not close
  if (length(dev.list()) > 0) {
    for (count in 1:length(dev.list())) {dev.off()}
  }
  return(output)
}

#apply functions to subsets of distance matrix for each taxon (CAN TAKE LONG TIME)
raw_taxon_stats <- lapply(row.names(taxonomy_data), FUN=apply_functions, functions_to_apply, level=level_to_analyze, max_subset=1000)
raw_taxon_stats <- ldply(raw_taxon_stats, data.frame)
raw_taxon_stats$inter_intra_differnece <- raw_taxon_stats$intertaxon_distance_mean - raw_taxon_stats$intrataxon_distance_mean
raw_taxon_stats$optimal_error <- (raw_taxon_stats$optimal_false_negative + raw_taxon_stats$optimal_false_positive) / raw_taxon_stats$subsampled_count


#add calculated stats to uploaded ones
taxonomy_data <- cbind(taxonomy_data, raw_taxon_stats)
rm(raw_taxon_stats)

#save statisics
write.table(taxonomy_data, file=taxon_statistics_output_path, sep="\t", quote=FALSE, col.names=NA)
