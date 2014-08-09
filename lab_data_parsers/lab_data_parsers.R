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
  data$time <- mdy_hms(data$time)
  data <- data[order(data$time), ]
  row.names(data) <- 1:nrow(data)
  data$sample_id <- as.character(data$sample_id)
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
  names(absorbance) <- sample_id
  if (length(unique(wavelength)) != 1) {
    stop("wavelengths are not the same between samples")
  }
  data <- ldply(absorbance)
  if (average) {
    data <- aggregate(. ~ .id, data = data, mean)
    sample_id <- data$.id
    data <- t(data[,-1])
  }
  rownames(data) <- wavelength[[1]]
  colnames(data) <- sample_id
  return(data)
}

read_qbit <- function(path, volume_used=NULL) {
  if (!require(lubridate)) {
    stop("install package lubridate")
  }
  data <- read.csv(path, header=TRUE, fileEncoding="latin1")
  data <- data[rev(1:nrow(data)),]
  colnames(data) <- c("name", "time", "dilute_concentration", "dilute_unit", "concentration", "unit",
                      "assay", "sample_volume", "dilution_factor", "std_1_rfu", "std__rfu", "std_3_rfu",
                      "excitation", "green_rfu", "far_red_rfu")
  data$dilute_concentration <- as.numeric(data$dilute_concentration)
  numeric_cols = c("dilute_concentration", "concentration", "sample_volume","dilution_factor",
                   "std_1_rfu", "std__rfu", "std_3_rfu", "green_rfu", "far_red_rfu")   
  data[,numeric_cols] = apply(data[,numeric_cols], 2, function(x) as.numeric(as.character(x)))
  if (!is.null(volume_used)) { 
    data$concentration <- data$dilute_concentration * (200 / volume_used)
  }
  data$time <- ymd_hms(data$time)
  row.names(data) <- 1:nrow(data)
  return(data)
}

volume_for_dilution <- function(initial_conc, final_volume, final_conc = min(initial_conc)) {
  initial_volume <- (final_conc * final_volume) / initial_conc
  volume_added <- final_volume - initial_volume
  return(list(initial_volume=initial_volume, volume_added=volume_added))
}

volume_for_dilution_table <- function(initial_conc, final_volume, final_conc = min(initial_conc), id=names(initial_conc), display=TRUE, ...) {
  if (!require(knitr)) {
    stop("install package knitr")
  }
  
  #Generate table of dilution values
  data <- volume_for_dilution(initial_conc, final_volume, final_conc)
  output_table <- data.frame(ID=1:length(data[[1]]))
  if (!is.null(id)) {
    output_table[,'Sample'] <- id
  }
  output_table[,'Initial Conc.'] <- initial_conc
  output_table[, 'Sample Vol.'] <- data$initial_volume
  output_table[, 'Solvent Vol.'] <- data$volume_added
  
  #generate header and contextual table columns
  output_header <- sprintf("Dilution table for **%d** samples.\n", length(initial_conc))
  if (length(unique(final_volume)) == 1) {
    output_header <- c(output_header, sprintf("All samples will be diluted to a final volume of **%f**.", final_volume))
  } else {
    output_table[, 'Final Vol.'] <- data$final_volume
  }
  if (length(unique(final_conc)) == 1) {
    output_header <- c(output_header, sprintf("All samples will be diluted to a final concentration of **%f**.", final_conc))
  } else {
    output_table[, 'Final Conc.'] <- data$final_conc
  }
  
  #print results
  if (display) {
    writeLines(output_header)
    writeLines("")
    kable(output_table, ...)    
  }
  
  return(output_table)
}

pcr_table <- function(count, additives=c(DNA=1), additive_concentration=rep('', length(additives))) {
  if (!require(knitr)) {
    stop("install package knitr")
  }
  master_mix_volume = 19.75 - sum(additives)
  data <- data.frame(Component=c("Water", "10x Buffer", "dNTP", "Primer 1", "Primer 2", "Taq", names(additives)),
                     Concentration=c("", "", "10mM", "10uM", "10uM", "", additive_concentration),
                     Single=c(master_mix_volume, 2.5, .5, 1, 1, .25, additives),
                     stringsAsFactors=FALSE)
  data$Total <- data$Single * count
  data$Safe <- data$Total * 1.1
  data[data$Component %in% names(additives), c("Total", "Safe")] = 0
  data <- rbind(data, c(Component="Total", Concentration="", Single=sum(data$Single), Total=sum(data$Total), Safe=sum(data$Safe)))
  
  writeLines(paste("PCR ingredients for ", count, ", ", data$Single[nrow(data)], "ul reactions:", sep=""))
  writeLines("")
  
  kable(data, format = "markdown", )
  return(data)
}

serial_dilution_table <- function(range, count, volume = 100) {
  base <- 10
  dilution_exp <- diff(log(range, base)) / (count) #exponent to raise for each dilution
  dilution_factor <- base^dilution_exp
  each_addition <-  dilution_factor * range[1] * volume / (range[1] - dilution_factor * range[1])
  data <- data.frame(N=0:count, Dilution = base^(dilution_exp * 0:(count)))
  data$Concentration = data$Dilution * range[1]
  
  writeLines(paste("**Serial dilution table**\nFor each dilution, dilute ", 
                   signif(each_addition, 4),
                   " of the previous sample in ",
                   signif(volume, 4),
                   " of solvent:\n", sep=""))
  kable(data, format = "markdown")
  return(data)
}