plot_threshold_optimization <- function(input, title=NULL) {
  if (class(input) == "character" || class(input) == "factor" ) {
    if (file.exists(as.character(input))) {
      data <- read.csv(as.character(input), sep="\t")
    } else {
      stop("Cannot read input file.")
    }
  } else if (class(input) == "data.frame") {
    data <- input
  } else {
    stop("Invalid input class.")
  }
  max_x <- max(data$threshold)
  optimal_error <- min(data$cumulative_error)
  optimal_error_proportion <- optimal_error / nrow(data)
  error_at_max_x <- ((1 - optimal_error_proportion) / 2) + optimal_error_proportion
  max_x_display <- data$threshold[which(data$false_negative / nrow(data) > error_at_max_x)[1]]
  if (is.na(max_x_display)) {
    max_x_display <- max_x
  }
  min_x_display <- 0
  data <- melt(data, measure.vars=4:6, id.vars = 1,  na.rm=TRUE)
  data$value <- data$value / nrow(data)
  ggplot(data[data$variable != "cumulative_error", ], aes(x=threshold, y=value)) + 
    geom_area(aes(fill = variable), alpha = .3, , position='identity') +
    geom_line(data=data[data$variable == "cumulative_error", ], position='identity') +
    labs(title=title) +
    scale_x_continuous(limits = c(min_x_display, max_x_display)) +
    theme(title=element_text(size=30),
          axis.line=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          legend.position="none",
          panel.background=element_blank(),
          panel.border=element_blank(),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.background=element_blank())  
}