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

mycircle <- function(coords, v=NULL, params) {
  vertex.color <- params("vertex", "color")
  if (length(vertex.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.color[v]
  }
  vertex.size  <- 1/200 * params("vertex", "size")
  if (length(vertex.size) != 1 && !is.null(v)) {
    vertex.size <- vertex.size[v]
  }
  vertex.frame.color <- params("vertex", "frame.color")
  if (length(vertex.frame.color) != 1 && !is.null(v)) {
    vertex.frame.color <- vertex.frame.color[v]
  }
  vertex.frame.width <- params("vertex", "frame.width")
  if (length(vertex.frame.width) != 1 && !is.null(v)) {
    vertex.frame.width <- vertex.frame.width[v]
  }
  
  mapply(coords[,1], coords[,2], vertex.color, vertex.frame.color,
         vertex.size, vertex.frame.width,
         FUN=function(x, y, bg, fg, size, lwd) {
           symbols(x=x, y=y, bg=bg, fg=fg, lwd=lwd,
                   circles=size, add=TRUE, inches=FALSE)
         })
}
add.vertex.shape("fcircle", 
                 plot=mycircle, 
                 parameters=list(vertex.frame.color=1, vertex.frame.width=1))

taxon_edge_list <- function(taxonomy, separator) {
  get_taxon_edge_list <- function(taxon) {
    apply(matrix(c(1:(length(taxon)-1),2:length(taxon)), ncol = 2), 1, function(x) c(taxon[x[1]], taxon[x[2]]))
  }
  taxons <- strsplit(taxonomy, separator, fixed=TRUE)
  taxons <- lapply(taxons, function(x) sapply(seq(1, length(x)), function(y) paste(x[1:y], collapse=separator)))
  edge_list <- t(do.call(cbind,lapply(taxons, FUN=get_taxon_edge_list)))
  edge_list[!duplicated(edge_list),]
}

get_edge_parents <-function(graph) {
  get.edges(graph, 1:ecount(graph))[,1]
}

get_edge_children <- function(graph) {
  get.edges(graph, 1:ecount(graph))[,2]
}

add_alpha <- function(col, alpha=1){
  apply(sapply(col, col2rgb)/255, 2,
        function(x)
          rgb(x[1], x[2], x[3], alpha=alpha))
}

get_vertex_children <- function(graph, vertex) {
  which(shortest.paths(graph, V(graph)[vertex], mode="out") != Inf)
}

offset_ordered_factor <- function(ordered_factor, offset) { 
  my_levels <-  levels(ordered_factor)
  new_level <- my_levels[which(my_levels == ordered_factor) + offset]
  ordered(new_level, my_levels)
}

fapply <- function(iterable, functions, 
                   preprocessor={function(x) x},
                   preprocessor_args=list(),
                   allow_complex=TRUE,
                   ...) {
  apply_functions <- function(input, functions, ...) {
    if (!is.list(input)) {
      input <- list(input)
    }
    input <- append(input, list(...))
    results <- lapply(functions, function(f) do.call(f, input))
    atomics <- which(!sapply(results, is.recursive))
    results[atomics] <- lapply(1:length(atomics), function(i) {y <- list(results[atomics[i]]); 
                                                               names(y) <- functions[i];
                                                               y})
    results <- unlist(results, recursive=FALSE)
    
    if (allow_complex) {
      results <- lapply(results, function(x) if (is.recursive(x)) {I(x)} else {x})
    } else {
      results <- results[!sapply(results, is.recursive)]
    }
    return(results)
  }
  if (length(iterable) < 1) {
    return(NULL)
  }
  if (is.data.frame(iterable) | is.matrix(iterable)) {
    iterable_length <- length(iterable[[1]])    
    call_preprocessor <- function(i) {do.call(preprocessor, append(list(iterable[i,]), preprocessor_args))}
  } else if (is.list(iterable)) {
    iterable_length <- length(iterable)
    call_preprocessor <- function(i) {do.call(preprocessor, append(list(iterable[[i]]), preprocessor_args))}    
  } else {
    iterable_length <- length(iterable)
    call_preprocessor <- function(i) {do.call(preprocessor, append(list(iterable[i]), preprocessor_args))}        
  }
  output <- lapply(1:iterable_length, function(i) apply_functions(call_preprocessor(i), functions, ...))
  column_names <- names(output[[1]])
  output <- lapply(1:length(output[[1]]), function(i) lapply(output, function(row) row[[i]]))
  output <- as.data.frame(do.call(cbind, output))
  colnames(output) <- column_names
  if (is.data.frame(iterable) | is.matrix(iterable)) {
    row.names(output) <- row.names(iterable)
  }
  return(output)
}

remove_outliers <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.01, .99), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

delete_vetices_and_children <- function(graph, vertices) {
  #delete children
  vertices <- unlist(sapply(vertices, function(x) get_vertex_children(graph, x)))
  graph <- delete.vertices(graph, vertices)
  return(graph)
}

continuous_color_legend <- function(values, background="#00000000", ...) {
  #Extract Legend (http://stackoverflow.com/questions/12041042/how-to-plot-just-the-legends-in-ggplot2)
  g_legend<-function(a.gplot){ 
    tmp <- ggplot_gtable(ggplot_build(a.gplot)) 
    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box") 
    legend <- tmp$grobs[[leg]] 
    return(legend)} 
  mid_point = (max(values) + min(values)) / 2
  label_points <- seq(min(values), max(values), length.out=7)
  labels <- as.character(signif(label_points, 2))
  full_plot <- qplot(x,y, colour=value, data=data.frame(x=1, y=1, value=values)) + 
    scale_colour_gradient2(breaks = label_points, labels = labels, midpoint=mid_point, ...) + 
    theme(legend.key.size = unit(5, "cm"), 
          legend.text = element_text(size=85),
          legend.title = element_text(size=85),
          legend.background = element_rect(fill = background))
  g_legend(full_plot)
}

which_median <- function(x) which.min(abs(x - median(x)))

which_middle <- function(x) {
  middle <- (max(x) + min(x)) / 2
  which.min(abs(x - middle))
}

plot_image_tree <- function(graph, image_file_paths, labels=NA, scaling=1, exclude=c(), root_index=1, label_color = "black", display=FALSE) {
  #store the distance of all verticies and edges from the root
  root <- V(graph)[root_index]
  vertex_depth <- sapply(get.shortest.paths(graph, from=root)$vpath, length)
  edge_depth <- vertex_depth[get_edge_parents(graph)]
  
  #set vertex graphing parameters
  V(graph)$size <- (log(scaling + .5) / max(log(scaling) + .5)) * 10
  if (is.na(labels)) {
    V(graph)$label.cex <- 0
  } else {
    V(graph)$label <- labels
    V(graph)$label.cex <- V(graph)$size * .05 + .15
    V(graph)$label.color <- label_color
  }
  V(graph)$alpha <- (max(vertex_depth)*1.5 - vertex_depth) / (max(vertex_depth)*1.5)
  V(graph)$raster_file <- image_file_paths #not used in disaply, but should be subset below
  
  #set edge graphing parameters
  E(graph)$width <- V(graph)$size[get_edge_children(graph)] * 5
  E(graph)$color <- sapply(((max(edge_depth)*4 - edge_depth) / (max(edge_depth)*4)) * .3,
                           function(x) rgb(red=.3,green=.3,blue=.3,alpha=x))
  
  #exclude specific verticies and their decendents from display
  graph <- delete_vetices_and_children(graph, exclude)
  
  #Calculate vertex layout
  graph_layout <- layout.reingold.tilford(graph, root = root_index, circular = TRUE)
  
  #Load vertex images 
  V(graph)$raster <- lapply(as.character(V(graph)$raster_file), readPNG)
  
  #plot graph
  my_plot <- plot(graph,
                  layout=graph_layout,
                  margin=0, 
                  vertex.label.dist=0,
                  vertex.label.degree=0,
                  vertex.label=labels,
                  edge.arrow.size =0,
                  vertex.shape="raster", 
                  vertex.size=V(graph)$size*1.5,
                  vertex.size2=V(graph)$size*1.5)
  if (display) {
    print(my_plot)
  }
  return(plot)
}

plot_value_tree <- function(graph, values, labels=NA, scaling=1, exclude=c(), root_index=1, label_color = "black", display=FALSE, fade=FALSE, legend_text="", value_range=c(0,1), highlight_outliers=TRUE, background="#00000000") {
  #store the distance of all verticies and edges from the root
  root <- V(graph)[root_index]
  vertex_depth <- sapply(get.shortest.paths(graph, from=root)$vpath, length)
  edge_depth <- vertex_depth[get_edge_parents(graph)]
  
  #set vertex graphing parameters
  V(graph)$size <- (log(scaling + .5) / max(log(scaling) + .5)) * 10
  if (is.na(labels)) {
    V(graph)$label.cex <- 0
  } else if (labels == TRUE) {
    V(graph)$label <- as.character(signif(values, 2))
    V(graph)$label.cex <- V(graph)$size * .45 + .15
    V(graph)$label.color <- label_color
  } else {
    V(graph)$label <- labels
    V(graph)$label.cex <- V(graph)$size * .45 + .15
    V(graph)$label.color <- label_color
  }
  if (fade == TRUE) {
    V(graph)$alpha <- (max(vertex_depth)*1.5 - vertex_depth) / (max(vertex_depth)*1.5)
  } else if (fade == FALSE) {
    V(graph)$alpha <- 1
  } else {
    V(graph)$alpha <- fade
  }
  V(graph)$values <- values
  
  #set edge graphing parameters
  E(graph)$width <- V(graph)$size[get_edge_children(graph)] * 5
  E(graph)$color <- sapply(((max(edge_depth)*4 - edge_depth) / (max(edge_depth)*4)) * .3,
                           function(x) rgb(red=.3,green=.3,blue=.3,alpha=x))
  
  #exclude specific verticies and their decendents from display
  graph <- delete_vetices_and_children(graph, exclude)
  
  #set vertex color
  color_values <- V(graph)$values
  value_range_quantile <- quantile(color_values, value_range, na.rm=TRUE)
  if (highlight_outliers) {
    outliers <- color_values < value_range_quantile[1] | color_values > value_range_quantile[2]
    V(graph)$frame.width <- ifelse(outliers, 25, .05)    
  }
  outliers <- color_values < value_range_quantile[1] | color_values > value_range_quantile[2]
  V(graph)$frame.width <- ifelse(outliers, 25, .05)
  color_values[color_values < value_range_quantile[1]] <- value_range_quantile[1]
  color_values[color_values > value_range_quantile[2]] <- value_range_quantile[2]
  V(graph)$color=mapply(add_alpha, 
                        color.scale(color_values, c(1,0,0), c(0,1,0), c(0,0,1), xrange=c(min(color_values), max(color_values))), 
                        alpha=V(graph)$alpha)
  
  #Calculate vertex layout
  graph_layout <- layout.reingold.tilford(graph, root = root_index, circular = TRUE)
  
  #Load vertex images 
  V(graph)$raster <- lapply(as.character(V(graph)$raster_file), readPNG)
  
  #plot graph
  my_plot <- plot(graph,
                  layout=graph_layout,
                  margin=0, 
                  vertex.label.dist=0,
                  vertex.label.degree=0,
                  edge.arrow.size =0,
                  vertex.shape="fcircle", 
                  vertex.frame.color='black')
  
  #Make legend (http://stackoverflow.com/questions/12041042/how-to-plot-just-the-legends-in-ggplot2)
  legend <- continuous_color_legend(color_values,
                                    low=V(graph)$color[which.min(color_values)], 
                                    mid=V(graph)$color[which_middle(color_values)], 
                                    high=V(graph)$color[which.max(color_values)],
                                    name=legend_text,
                                    background=background)  
  pushViewport(viewport(x=0.9, y=0.15))
  grid.draw(legend)
  
  if (display) {
    print(my_plot)
  }
  return(plot)
}
