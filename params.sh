#!/bin/bash

##############################################################
# Application parameters
# Check and change as needed
##############################################################

######################################
# is_centroid thresholds
#
# Country, state and county canditate 
# centroids must surpass these thresholds 
# to qualify as a "true" centroid
# (is_centroid=1)
##########################

# Maximum distance (km) to true political division centroid
MAX_DIST_DEFAULT=1000

# Maximum relative distance
# Proportion of actual distance to true centroid
# divided by maximum possible distance (from farthest
# point on political division perimiter to true centroid)
MAX_DIST_REL_DEFAULT=0.002

# Complete clear all data from table user_data
# For development only
# Any value other than true, does nothing
# TURN OFF DURING PRODUCTION!
CLEAR_USER_DATA="false"

##############################################################
# Application parameters
##############################################################

# Relative path to server-specific configuration file.
# Currently contains only one parameter, $BASE_DIR, which
# is the absolute path to the immediate parent of this
# directory (i.e., the repo). Recommend keep server_config.sh
# in $BASE_DIR/config/
currdir=$(dirname ${BASH_SOURCE[0]})
source "${currdir}/../config/server_config.sh";

#################################
# You should not need to change
# the remaining parameters unless 
# you alter default configuration
#################################

# Path to db_config.sh
# For production, keep outside app directory & supply absolute path
# Omit trailing slash
db_config_path="${BASEDIR}/config"

# Relative data directory name
# GVS will look here inside app directory for user input
# and will write results here, unless $data_dir_local_abs
# is set (next parameter)
# Omit trailing slash
data_base_dir="../data"		

# Absolute path to data directory
# Use this if data directory outside root application directory
# Comment out to use $data_base_dir (relative, above)
# Omit trailing slash
data_dir_local_abs="${BASEDIR}/data"
#data_dir_local_abs="/home/boyle/bien/gvs/data/user_data"

# For backward-compatibility
data_dir_local=$data_dir_local_abs

#############################################################
# Normally shouldn't have to change remaining parameters
#############################################################

##########################
# Default input/output file names
##########################

# Default name of the raw data file to be imported. 
# This name will be used if no file name supplied as command line
# parameter. Must be located in the user_data directory
submitted_filename="gvs_submitted.csv" 

# Default name of results file
results_filename="gvs_results.csv"

##########################
# Input subsample parameters
##########################

# 't' to limit number of records imported (for testing)
# 'f' to run full import
# recordlimit ignored if use_limit='f'
use_limit='f'
recordlimit=100000000000

##########################
# Display/notification parameters
##########################

# Destination email for process notifications
# You must supply a valid email if you used the -m option
email="bboyle@email.arizona.edu"

# Short name for this operation, for screen echo and 
# notification emails. Number suffix matches script suffix
pname="GVS"
pname_local=$pname

# General process name prefix for email notifications
pname_header_prefix="BIEN notification: process"
