### Generic ploting functions
add_alpha <- function(col, alpha=1){
  apply(sapply(col, col2rgb)/255, 2,
        function(x)
          rgb(x[1], x[2], x[3], alpha=alpha))
}




### iGraph-associated plotting functions
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
