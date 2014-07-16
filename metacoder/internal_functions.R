### Generic internal functions
offset_ordered_factor <- function(ordered_factor, offset) { 
  my_levels <-  levels(ordered_factor)
  new_level <- my_levels[which(my_levels == ordered_factor) + offset]
  ordered(new_level, my_levels)
}

fapply <- function(iterable, functions, 
                   .preprocessor={function(x) x},
                   .preprocessor_args=list(),
                   .allow_complex=TRUE,
                   ...) {
  apply_functions <- function(input, functions, ...) {
    if (!is.list(input)) {
      input <- list(input)
    }
    input <- append(input, list(...))
    results <- lapply(functions, function(f) do.call(f, input))
    atomics <- which(!sapply(results, is.recursive))
    if (length(atomics) > 0) {
      results[atomics] <- lapply(1:length(atomics), function(i) {y <- list(results[[atomics[i]]]); 
                                                                 names(y) <- functions[i];
                                                                 y})
    }
    results <- unlist(results, recursive=FALSE)
    if (!.allow_complex) {
      results <- results[!sapply(results, is.recursive)]
    }
    return(results)
  }
  if (length(iterable) < 1) {
    return(NULL)
  }
  if (is.data.frame(iterable) | is.matrix(iterable)) {
    iterable_length <- length(iterable[[1]])    
    row_names <- row.names(iterable)
    call_preprocessor <- function(i) {do.call(.preprocessor, append(list(iterable[i,]), .preprocessor_args))}
  } else if (is.list(iterable)) {
    iterable_length <- length(iterable)
    row_names <- unlist(iterable)
    call_preprocessor <- function(i) {do.call(.preprocessor, append(list(iterable[[i]]), .preprocessor_args))}    
  } else {
    iterable_length <- length(iterable)
    row_names <- iterable
    call_preprocessor <- function(i) {do.call(.preprocessor, append(list(iterable[i]), .preprocessor_args))}        
  }
  output <- lapply(1:iterable_length, function(i) apply_functions(call_preprocessor(i), functions, ...))
  column_names <- names(output[[1]])
  output <- lapply(1:length(output[[1]]), function(i) lapply(output, function(row) row[[i]]))
  output <- lapply(output, function(x) if (!is.recursive(x[[1]])) {unlist(x, recursive=FALSE)} else {I(x)})
  output <- do.call(data.frame, output)
  colnames(output) <- column_names
  row.names(output) <- row_names
  return(output)
}

remove_all_na_rows <- function(input) {
  na_rows <- sapply(1:nrow(input), function(x) sum(!is.na(input[x,])) != 0)
  input[na_rows, ]
}

remove_outliers <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.01, .99), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

which_median <- function(x) which.min(abs(x - median(x)))

which_middle <- function(x) {
  middle <- (max(x) + min(x)) / 2
  which.min(abs(x - middle))
}

### File system functions
rm_ext <- function(file) {
  sub("[.][^.]*$", "", file, perl=TRUE)
}

next_incremental_file_number <-function(directory) {
  current_numbers <- as.integer(rm_ext(list.files(directory, no..=TRUE)))
  if (length(current_numbers) == 0) {
    current_numbers = 0
  }
  max(current_numbers) + 1
}

### iGraph-associated functions
taxon_edge_list <- function(taxonomy, separator) {
  get_taxon_edge_list <- function(taxon) {
    apply(matrix(c(1:(length(taxon)-1),2:length(taxon)), ncol = 2), 1, function(x) c(taxon[x[1]], taxon[x[2]]))
  }
  taxons <- unique(taxonomy)
  taxons <- strsplit(taxons, separator, fixed=TRUE)
  taxons <- taxons[sapply(taxons, length) > 1]
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

get_vertex_children <- function(graph, vertex) {
  which(shortest.paths(graph, V(graph)[vertex], mode="out") != Inf)
}

delete_vetices_and_children <- function(graph, vertices) {
  #delete children
  vertices <- unlist(sapply(vertices, function(x) get_vertex_children(graph, x)))
  graph <- delete.vertices(graph, vertices)
  return(graph)
}

