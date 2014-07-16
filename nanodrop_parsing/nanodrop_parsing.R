read_nanodrop_tsv <- function(path, average=TRUE) {
  if (!require(lubridate)) {
    stop("install package lubridate")
  }
  data_format <- "%m/%d/%Y %I:%M:%S %p"
  data <- do.call(rbind, lapply(path, read.csv, sep='\t'))
  names(data) <- c("measurment", "sample_id", "user", "time",
                   "concentration", "unit", "a260", "a280",
                   "a260_a280", "a260_a230", "type", "factor")
  data$time <- mdy_hms(data$time)
  if (average) {
    data <- aggregate(. ~ sample_id, data = data, mean)
    class(data$time) = 'POSIXct'
    data$time = format(data$time, data_format)
  }
  return(data)
}

read_nanodrop_spectrum_tsv <- function(path, average=TRUE) {
  if (!require(lubridate)) {
    stop("install package lubridate")
  }
  if (!require(plyr)) {
    stop("install package plyr")
  }
  split_at <- function(x, pos) unname(split(x, cumsum(seq_along(x) %in% pos)))
  data <- sapply(path, function(x) c(readLines(x), '', ''))
  data <- split_at(data, which(data == ''))
  data <- data[sapply(data, length) > 1]
  data[-1] <- lapply(data[-1], function(x) x[-1]) 
  sample_id <- sapply(data, function(x) x[1])
  sample_date <- sapply(data, function(x) x[2])
  sample_date <- mdy_hms(sample_date)
  data <- lapply(data, function(x) x[-(1:3)]) 
  wavelength <- lapply(data, function(x) as.numeric(gsub("\t.*$", '', x)))
  absorbance <- lapply(data, function(x) as.numeric(gsub("^.*\t", '', x)))
  if (length(unique(wavelength)) != 1) {
    stop("wavelengths are not the same between samples")
  }
  data <- ldply(absorbance)
  if (average) {
    data$sample_id <- sample_id
    data <- aggregate(. ~ sample_id, data = data, mean)
    data <- t(data[,-1])
  }
  rownames(data) <- wavelength[[1]]
  colnames(data) <- unique(sample_id)
  return(data)
}

