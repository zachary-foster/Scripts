source("functions.R")

#Constants
taxonomy_levels = c(k='Kingdom', d='Domain', p='Phylum', c='Class', sc='Subclass', o='Order', so='Suborder', f='Family', g='Genus', s='Species', i='Individual')
taxonomy_separator = ';'
plot_directory_name =  "figures"

#Parameters
threshold_statistics_file = ""
root_directory = "/home/local/USDA-ARS/fosterz/Repositories/Analysis/taxon_specific_barcode_gap/rdp_fungi_28s_1"
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

#construct taxonomy graph
taxonomy_graph <- graph.edgelist(taxon_edge_list(row.names(taxonomy_data)[2:nrow(taxonomy_data)], taxonomy_separator))
taxon_root <- V(taxonomy_graph)[1]

#common graph attributes
taxa_to_exclude <- which(taxonomy_data$level >= level_to_analyze |
                           taxonomy_data$subtaxon_count < 2 |
                           # is.na(taxonomy_data$distance_graph) |
                           taxonomy_data$count < 30)

#rename levels for graphing
taxonomy_data$level <- ordered(taxonomy_data$level, levels=names(taxonomy_levels), labels=taxonomy_levels)


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
