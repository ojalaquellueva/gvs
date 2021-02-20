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
MAX_DIST=1000

# Maximum relative distance
# Proportion of actual distance to true centroid
# divided by maximum possible distance (from farthest
# point on political division perimiter to true centroid)
MAX_DIST_REL=0.002

# Complete clear all data from table user_data
# For development only
# Any value other than true, does nothing
# TURN OFF DURING PRODUCTION!
CLEAR_USER_DATA="false"

##########################
# Paths, adjust according  
# to your installation
##########################

BASEDIR="/home/boyle/bien/cds2"

# Path to db_config.sh
# For production, keep outside app directory & supply absolute path
# Omit trailing slash
db_config_path="${BASEDIR}/config"

# Relative data directory name
# CDS will look here inside app directory for user input
# and will write results here, unless $data_dir_local_abs
# is set (next parameter)
# Omit trailing slash
data_base_dir="../data"		

# Absolute path to data directory
# Use this if data directory outside root application directory
# Comment out to use $data_base_dir (relative, above)
# Omit trailing slash
data_dir_local_abs="${BASEDIR}/data"
#data_dir_local_abs="/home/boyle/bien3/repos/cds/data/user_data"

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
submitted_filename="cds_submitted.csv" 

# Default name of results file
results_filename="cds_results.csv"

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
pname="CDS"
pname_local=$pname

# General process name prefix for email notifications
pname_header_prefix="BIEN notification: process"
