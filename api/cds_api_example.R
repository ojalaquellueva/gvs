###############################################
# CDS API Example
###############################################

#################################
# Parameters
#################################

# Base URL for CDS api
url = "http://vegbiendev.nceas.ucsb.edu:8775/cds_api.php" 

# Path and name of input file of taxon names 
# Comma-delimited CSV file, first column an integer ID, second column the name
# Test file from BIEN website:
names_file <- "https://bien.nceas.ucsb.edu/bien/wp-content/uploads/2020/10/cds_testfile.csv"

# Large test file of 600 names
names_file <- "https://bien.nceas.ucsb.edu/bien/wp-content/uploads/2020/10/cds_testfile_big.csv"

#################################
# Import the raw data
#################################

# Load libraries
library(RCurl) # API requests
library(jsonlite) # JSON coding/decoding

# Read in example file of taxon names
data <- read.csv(names_file, header=FALSE)

# Inspect the input data
head(data,25)

# # Uncomment this to work with smaller sample of the data
# data <- head(data,10)

# Convert the data to JSON
data_json <- jsonlite::toJSON(unname(data))

#################################
# Example 1: Resolve mode
#################################

# Set API options
mode <- "resolve"			# Processing mode
batches <- 25					# Number of batches, for parallel processing
										# input file will be divided into this many batches

# Threshold parameter options
# Comment out to use application defaults
maxdist <- 10					# Maximum distance from centroid to qualify as centroid
maxdistrel <- 0.1				# Maximum relative distance from centroid (relative to distance
										# from centroid  to farthest point in political division), to qualify
										# as centroid

# Convert the options to data frame and then JSON
opts <- data.frame( c(mode) )
names(opts) <- c("mode")
if ( exists("batches") ) opts$batches <- batches
if ( exists("maxdist") ) opts$maxdist <- maxdist
if ( exists("maxdistrel") ) opts$maxdistrel <- maxdistrel

opts_json <-  jsonlite::toJSON(opts)
opts_json <- gsub('\\[','',opts_json)
opts_json <- gsub('\\]','',opts_json)

# Combine the options and data into single JSON object
input_json <- paste0('{"opts":', opts_json, ',"data":', data_json, '}' )

# Construct the request
headers <- list('Accept' = 'application/json', 'Content-Type' = 'application/json', 'charset' = 'UTF-8')

# Send the API request (and time it)
start_time <- Sys.time()
results_json <- postForm(url, .opts=list(postfields= input_json, httpheader=headers))

# Get processing time
end_time <- Sys.time()
ptime <- end_time - start_time
print(paste0("Batches: ", batches))
print(paste0("Processing time: ", ptime))

# Convert JSON results to a data frame
results <-  jsonlite::fromJSON(results_json)

# Inspect the results
head(results, 10)

# Display header plus one row vertically
# to better compare the output fields
results.t <- as.data.frame( t( results[,1:ncol(results)] ) )
results.t[,3,drop =FALSE]

# A few columns showing coordinate validation
#results $match.score <- format(round(as.numeric(results $Overall_score),2), nsmall=2)
results[ , c('latitude_verbatim', 'longitude_verbatim', 'latitude', 'longitude', 
	'latlong_err', 'coordinate_decimal_places', 'coordinate_inherent_uncertainty_m')
	]

# A few columns showing political division matching
#results $match.score <- format(round(as.numeric(results $Overall_score),2), nsmall=2)
results[ , c('latitude_verbatim', 'longitude_verbatim', 'latitude', 'longitude', 
	'latlong_err', 'country', 'state', 'county')
	]

# Distance to nearest centroid for county
results[ results$latlong_err=='', c('latitude', 'longitude', 
	'country', 'state', 'county',
	'county_cent_dist', 	'county_cent_dist_relative', 'county_cent_type', 
	'county_cent_dist_max', 	'is_county_centroid'
	)]

# Consensue centroid 
results[ results$latlong_err=='', c('latitude', 'longitude', 
	'is_country_centroid', 	'is_state_centroid', 'is_county_centroid', 
	'centroid_dist_km', 
	'centroid_dist_relative', 'centroid_type', 'centroid_dist_max_km', 'centroid_poldiv',	
	'max_dist', 'max_dist_rel'
	)]

#################################
# Example 2: Get metadata for current 
# CDS version
#################################
rm( list = Filter( exists, c("results", "results_json") ) )

# All we need to do is reset option mode.
# all other options will be ignored
mode <- "meta"		

# Re-form the options json again
# Note that only 'mode' is needed
opts <- data.frame(c(mode))
names(opts) <- c("mode")
opts_json <- jsonlite::toJSON(opts)
opts_json <- gsub('\\[','',opts_json)
opts_json <- gsub('\\]','',opts_json)

# Make the options
# No data needed
input_json <- paste0('{"opts":', opts_json, '}' )

# Send the request again
results_json <- postForm(url, .opts=list(postfields= input_json, httpheader=headers))

# Display the results
results <- jsonlite::fromJSON(results_json)
print( results )
