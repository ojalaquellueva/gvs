#!/bin/bash

##############################################################
# Application parameters
# Check and change as needed
##############################################################

# Reference database for world geometries
TBL_GEOM="gadm"		# World geometries table
DB_GEOM="gadm"		# Source db for world geom table
SCH_GEOM="public"	# Schema of world geom table

# Name of database

# Path to db_config.sh
# For production, keep outside app working directory & supply
# absolute path
# For development, if keep inside working directory, then supply
# relative path
# Omit trailing slash
db_config_path="/home/boyle/bien/cds/config"

# Path to general function directory
# If directory is outside app working directory, supply
# absolute path, otherwise supply relative path
# Omit trailing slash
#functions_path=""
functions_path="/home/boyle/functions/sh"
functions_path="/home/boyle/cds/src/includes"

# Path to data directory for database build
# Recommend call this "data"
# If directory is outside app working directory, supply
# absolute path, otherwise use relative path (i.e., no 
# forward slash at start).
# Recommend keeping outside app directory
# Omit trailing slash
data_base_dir="/home/boyle/bien/cds/data"
#data_base_dir="data"		 # Relative path

# Makes user_admin the owner of the db and all objects in db
# If leave user_admin blank ("") then database will be owned
# by whatever user you use to run this script, and postgis tables
# will belong to postgres
USER_ADMIN="bien"		# Admin user

# Give user_read select permission on the database
# If leave blank ("") user_read will not be added and only
# you will have access to db
USER_READ="bien_private"	# Read only user

# Destination email for process notifications
# You must supply a valid email if you used the -m option
email="bboyle@email.arizona.edu"

# Short name for this operation, for screen echo and 
# notification emails. Number suffix matches script suffix
pname="Build CDS database "

# General process name prefix for email notifications
pname_header_prefix="BIEN notification: process"