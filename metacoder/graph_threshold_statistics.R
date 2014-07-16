source("functions.R")
source("constants.R")

plot_directory_name =  "figures"

#Parameters
threshold_statistics_file = ""
root_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1"
taxon_data_folder <- "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1/pid"
level_to_analyze = 'f'
distance_type = 'PID'
tree_plot_width = 18000
tree_plot_height = 18000
square_plot_width = 900
single_plot_height = 1500
thresh_vs_error_plot_width = 800
tree_plot_background = "transparent"
single_plot_background = "transparent"

#Derived Parameters
output_directory_name = paste(distance_type, '_', taxonomy_levels[level_to_analyze], sep='') 
output_directory = file.path(root_directory, output_directory_name, fsep = .Platform$file.sep)
taxon_statistics_output_name = paste('taxon_statistics', '_', output_directory_name, '.txt', sep='')
taxon_statistics_output_path =  file.path(output_directory, taxon_statistics_output_name, fsep = .Platform$file.sep)
plot_directory = file.path(output_directory, plot_directory_name, fsep = .Platform$file.sep)
distance_tree_plot_name = paste('distance_distribution', '_', output_directory_name, '.png', sep='')
distance_tree_plot_path =  file.path(plot_directory, distance_tree_plot_name, fsep = .Platform$file.sep)
threshold_tree_plot_name = paste('threshold_optimization', '_', output_directory_name, '.png', sep='')
threshold_tree_plot_path =  file.path(plot_directory, threshold_tree_plot_name, fsep = .Platform$file.sep)
threshold_distribution_plot_name = paste('optimal_threshold_distribution', '_', output_directory_name, '.png', sep='')
threshold_distribution_plot_path = file.path(plot_directory, threshold_distribution_plot_name, fsep = .Platform$file.sep)
error_distribution_plot_name = paste('optimal_error_distribution', '_', output_directory_name, '.png', sep='')
error_distribution_plot_path = file.path(plot_directory, error_distribution_plot_name, fsep = .Platform$file.sep)
error_boxplot_plot_name = paste('optimal_error_boxplot', '_', output_directory_name, '.png', sep='')
error_boxplot_plot_path = file.path(plot_directory, error_boxplot_plot_name, fsep = .Platform$file.sep)
threshold_boxplot_plot_name = paste('optimal_threshold_boxplot', '_', output_directory_name, '.png', sep='')
threshold_boxplot_plot_path = file.path(plot_directory, threshold_boxplot_plot_name, fsep = .Platform$file.sep)
threshold_value_tree_name = paste('optimal_threshold_tree', '_', output_directory_name, '.png', sep='')
threshold_value_tree_path = file.path(plot_directory, threshold_value_tree_name, fsep = .Platform$file.sep)
error_value_tree_name = paste('optimal_error_tree', '_', output_directory_name, '.png', sep='')
error_value_tree_path = file.path(plot_directory, error_value_tree_name, fsep = .Platform$file.sep)
thresh_vs_error_plot_name = paste('threshold_vs_error', '_', output_directory_name, '.png', sep='')
thresh_vs_error_plot_path = file.path(plot_directory, thresh_vs_error_plot_name, fsep = .Platform$file.sep)


#Load taxon data 
taxon_data_files <- list.files(taxon_data_folder, pattern="taxon_statistics.+txt", full.names=TRUE)
taxon_data <- lapply(taxon_data_files, read.csv, sep="\t", row.names=1)
taxon_data_levels <- sub("taxon_statistics_.+_(.+).txt", "\\1", basename(taxon_data_files), perl=TRUE)
# taxon_data_levels <- taxon_data_levels[order(match(taxon_data_levels, taxonomy_levels))]
taxon_data_levels <- ordered(taxon_data_levels, taxonomy_levels)
names(taxon_data) <- taxon_data_levels

#reformat into single data frame
for (i in 1:length(taxon_data)) {
  taxon_data[[i]]$taxon <- rownames(taxon_data[[i]])
}
taxon_data <- ldply(taxon_data, rbind, .id="clustering_level")

# #construct taxonomy graph
# taxonomy_graph <- graph.edgelist(taxon_edge_list(row.names(taxonomy_data)[2:nrow(taxonomy_data)], taxonomy_separator))
# taxon_root <- V(taxonomy_graph)[1]

#rename levels for graphing
# for (i in 1:length(taxon_data)) {
#   taxon_data[[i]]$level <- ordered(taxon_data[[i]]$level, levels=names(taxonomy_levels), labels=taxonomy_levels)
#   
# }
taxon_data$level <- ordered(taxon_data$level, levels=names(taxonomy_levels), labels=taxonomy_levels)
taxon_data$clustering_level <- ordered(taxon_data$clustering_level, levels=taxonomy_levels, labels=taxonomy_levels)

#common graph attributes
# taxa_to_exclude <- lapply(1:length(taxon_data), function(i) 
#   which(taxon_data[[i]]$level >= names(taxon_data)[[i]] |
#           taxon_data[[i]]$subtaxon_count < 2 |
#           taxon_data[[i]]$count < 30))
# for (i in 1:length(taxon_data)) {
#   taxon_data[[i]] <- taxon_data[[i]][-taxa_to_exclude[[i]],]
# }
taxa_to_exclude <- which(taxon_data$level >= taxon_data$clustering_level |
                           taxon_data$subtaxon_count < 2 |
                           # is.na(taxon_data$distance_graph) |
                           taxon_data$count < 30 |
                           !complete.cases(taxon_data))
taxon_data <- taxon_data[-taxa_to_exclude,]


#boxplot of optimal error rates
png(file = error_boxplot_plot_path, bg = single_plot_background, width=900, height=900)
ggplot(data=taxonomy_data[-taxa_to_exclude, ], aes(level, optimal_error)) + 
  geom_boxplot() + 
  labs(title="Error rate distribution at optimal threshold ", y="Error rate", x="Taxonomic level") +
  theme(title=element_text(size=20),
        axis.text=element_text(size=14),
        axis.title=element_text(size=16),
        legend.position="none",
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.text.x = element_text(size = 18))
dev.off()

#boxplot of optimal thresholds
png(file = threshold_boxplot_plot_path, bg = single_plot_background, width=900, height=900)
ggplot(data=taxonomy_data[-taxa_to_exclude, ], aes(level, optimal_threshold)) + 
  geom_boxplot() + 
  labs(title="Optimal threshold distribution", y=paste(distance_type, " distance threshold"), x="Taxonomic level") +
  theme(title=element_text(size=20),
        axis.text=element_text(size=14),
        axis.title=element_text(size=16),
        legend.position="none",
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.text.x = element_text(size = 18))
dev.off()

#distribution of optimal error rates
png(file = error_distribution_plot_path, bg = single_plot_background, width=900, height=1400)
ggplot(data=taxonomy_data[-taxa_to_exclude, ], aes(optimal_error, fill=level)) + 
  geom_density(adjust=.2, warnings=FALSE, size=0) + 
  facet_wrap(~ level, drop=TRUE, ncol = 1) +
  labs(title="Error rate distribution at optimal threshold ", x=paste("Error Rate"), y="Frequency") +
  theme(title=element_text(size=20),
        axis.text.y=element_blank(),
        axis.text.x=element_text(size=14),
        axis.ticks.y=element_blank(),
        axis.title=element_text(size=16),
        legend.position="none",
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.text.x = element_text(size = 18))
dev.off()

#distribution of optimal thresholds
png(file = threshold_distribution_plot_path, bg = single_plot_background, width=900, height=1400)
filter = taxonomy_data$level != taxonomy_data$level[1] & taxonomy_data$level < taxonomy_levels[level_to_analyze]
ggplot(data=taxonomy_data[-taxa_to_exclude, ], aes(optimal_threshold, fill=level)) + 
  geom_density(adjust=.2, warnings=FALSE, size=0) + 
  facet_wrap(~ level, drop=TRUE, ncol = 1) +
  labs(title="Optimal threshold distribution", x=paste(distance_type, " distance threshold"), y="Frequency") +
  theme(title=element_text(size=20),
        axis.text.y=element_blank(),
        axis.text.x=element_text(size=14),
        axis.ticks.y=element_blank(),
        axis.title=element_text(size=16),
        legend.position="none",
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.text.x = element_text(size = 18))
dev.off()


#Plot distance distribution tree graph
png(file = distance_tree_plot_path, bg = tree_plot_background, width=tree_plot_width, height=tree_plot_height)
plot_image_tree(taxonomy_graph, taxonomy_data$distance_graph,
                scaling= taxonomy_data$count, 
                exclude=taxa_to_exclude)
dev.off()

#Plot optimal threshold tree graph
png(file = threshold_tree_plot_path, bg = tree_plot_background, width=tree_plot_width, height=tree_plot_height)
plot_image_tree(taxonomy_graph, taxonomy_data$threshold_graph,
                scaling= taxonomy_data$count, 
                exclude=taxa_to_exclude)
dev.off()

#Plot optimal threshold value tree
png(file = threshold_value_tree_path, bg = tree_plot_background, width=5000, height=5000)
plot_value_tree(taxonomy_graph, taxonomy_data$optimal_threshold,
                scaling= taxonomy_data$count, 
                exclude=taxa_to_exclude,
                value_range=c(0.03, 0.97),
                labels=TRUE, 
                label_color='#AAAAAA')
dev.off()

#Plot error rate value tree
png(file = error_value_tree_path, bg = tree_plot_background, width=5000, height=5000)
plot_value_tree(taxonomy_graph, 1-taxonomy_data$optimal_error,
                scaling= taxonomy_data$count, 
                exclude=taxa_to_exclude,
                value_range=c(0.03, 0.97),
                labels=TRUE, 
                label_color='#AAAAAA')
dev.off()

#Plot optimum threshold vs error rate 
png(file = thresh_vs_error_plot_path, bg = single_plot_background, width=thresh_vs_error_plot_width, height=thresh_vs_error_plot_width)
ggplot(data=taxonomy_data[-taxa_to_exclude, ], aes(optimal_threshold, optimal_error, colour=level)) + 
  geom_point(alpha=0.75, aes( size=subtaxon_count)) + 
  scale_size_continuous(trans="sqrt", guide="legend", range=c(3,10)) +
  guides(colour = guide_legend(override.aes = list(size=5))) +
  geom_rug(alpha=0.5) +
  labs(title="Optimal threshold vs error rate", 
       x=paste(distance_type, "distance threshold"), 
       y="Error rate",
       size=paste(taxonomy_levels[level_to_analyze], "\n", "Count", sep=''),
       colour="Level") +
  theme(title=element_text(size=20),
        axis.text=element_text(size=14),
        axis.title=element_text(size=16),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        legend.text = element_text(size=12),
        legend.title = element_text(size=16),
        legend.background = element_rect(fill = '#00000000'))

dev.off()





for (my_level in unique(taxon_data$clustering_level)) {
  if (length(taxon_data$taxon[taxon_data$clustering_level==my_level]) > 1) {
    output_name <- paste("threshold_value_tree_", as.character(my_level), '.png', sep='')
    output_path <- file.path(taxon_data_folder, output_name)
    print(output_name)
    plot_value_tree(taxon_data$taxon[taxon_data$clustering_level==my_level], 
                    taxon_data$optimal_threshold[taxon_data$clustering_level==my_level],
                    scaling= taxon_data$subsampled_count[taxon_data$clustering_level==my_level], 
                    value_range=c(0.03, 0.97),
                    labels=TRUE, 
                    label_color='#AAAAAA', 
                    save=output_path)    
  }
}

for (my_level in unique(taxon_data$clustering_level)) {
  if (length(taxon_data$taxon[taxon_data$clustering_level==my_level]) > 1) {
    output_name <- paste("error_value_tree_", as.character(my_level), '.png', sep='')
    output_path <- file.path(taxon_data_folder, output_name)
    print(output_name)
    plot_value_tree(taxon_data$taxon[taxon_data$clustering_level==my_level], 
                    taxon_data$optimal_error[taxon_data$clustering_level==my_level],
                    scaling= taxon_data$subsampled_count[taxon_data$clustering_level==my_level], 
                    value_range=c(0.03, 0.97),
                    labels=TRUE, 
                    label_color='#AAAAAA', 
                    save=output_path)    
  }
}

