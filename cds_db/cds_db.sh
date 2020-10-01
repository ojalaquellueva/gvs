#!/bin/bash

#########################################################################
# Purpose: Creates and populates CDS database 
#
# Usage:	./cds_db.sh
#
# Authors: Brad Boyle (bboyle@email.arizona.edu)
# Date created: 11 Mar 2020
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x
#echo "EXITING script `basename "$BASH_SOURCE"`"; exit 0

######################################################
# Set basic parameters, functions and options
######################################################

# Enable the following for strict debugging only:
#set -e

# Pointless command to trigger sudo password request. 
# Should remain in effect for all sudo commands in this 
# script, regardless of sudo timeout
sudo pwd >/dev/null

# The name of this file. Tells sourced scripts not to reload general  
# parameters and command line options as they are being called by  
# another script. Allows component scripts to be called individually  
# if needed
master=`basename "$0"`

# Get working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Start logfile
export glogfile="$DIR/log/logfile_"$master".txt"
sudo mkdir -p "$DIR/log" 
sudo touch $glogfile

# Set includes directory path, relative to $DIR
includes_dir=$DIR"/../includes"

# Load parameters, functions and get command-line options
source "$includes_dir/startup_master.sh"

# # Set process name and confirm operation
# pname="Build centroid validation database $DB_CDS"
# source "$includes_dir/confirm.sh"

# Set local directories to same as main
data_dir_local=$data_base_dir
data_dir=$data_base_dir
DIR_LOCAL=$DIR

######################################################
# Custom confirmation message. 
# Will only be displayed if -s (silent) option not used.
######################################################

if [ "$i" == "true" ]; then

	# Current user
	curr_user="$(whoami)"

	# Admin user message
	user_admin_disp=$curr_user
	if [[ "$USER_ADMIN" != "" ]]; then
		user_admin_disp="$USER_ADMIN"
	fi

	# Read-only user message
	user_read_disp="[n/a]"
	if [[ "$USER_READ" != "" ]]; then
		user_read_disp="$USER_READ"
	fi

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Run process '$pname' using the following parameters: 

	CDS DB name:		$DB_CDS
	GADM source db:		${SCH_GEOM}.${DB_GEOM}
	GADM table:		$TBL_GEOM
	Data directory:		$data_dir
	Current user:		$curr_user
	Admin user/db owner:	$user_admin_disp
	Read-only user:		$user_read_disp

EOF
	)"		
	confirm "$msg_conf"
fi

# Start time, send mail if requested and echo begin message
source "$includes_dir/start_process.sh"  

#########################################################################
# Main
#########################################################################



# Skip the start
: <<'COMMENT_BLOCK_1'




############################################
# Create database in admin role & reassign
# to principal non-admin user of database
############################################

# Check if db already exists
# Warn to drop manually. This is safer.
if psql -lqt | cut -d \| -f 1 | grep -qw "$DB_CDS"; then
	# Reset confirmation message
	msg="Database '$DB_CDS' already exists! Please drop first."
	echo $msg; exit 1
fi

echoi $e -n "Creating database '$DB_CDS'..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "CREATE DATABASE $DB_CDS" 
source "$includes_dir/check_status.sh"  

echoi $e -n "Changing owner to 'bien'..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "ALTER DATABASE $DB_CDS OWNER TO bien" 
source "$includes_dir/check_status.sh"  

echoi $e -n "Granting permissions..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
\set ON_ERROR_STOP on
REVOKE CONNECT ON DATABASE $DB_CDS FROM PUBLIC;
GRANT CONNECT ON DATABASE $DB_CDS TO bien;
GRANT CONNECT ON DATABASE $DB_CDS TO public_bien;
GRANT ALL PRIVILEGES ON DATABASE $DB_CDS TO bien;
\c $DB_CDS
GRANT USAGE ON SCHEMA public TO public_bien;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO public_bien;
EOF
echoi $i "done"

echoi $e "Installing extensions:"

echoi $e -n "- fuzzystrmatch..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS fuzzystrmatch;
CREATE EXTENSION fuzzystrmatch;
EOF
echoi $i "done"

# For trigram fuzzy matching
echoi $e -n "- pg_trgm..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS pg_trgm;
CREATE EXTENSION pg_trgm;
EOF
echoi $i "done"

# For generating unaccented versions of text
echoi $e -n "- unaccent..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS unaccent;
CREATE EXTENSION unaccent;
EOF
echoi $i "done"

# POSTGIS
echoi $e -n "- postgis..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS postgis;
CREATE EXTENSION postgis;
EOF
echoi $i "done"

# Functions
echoi $e -n "Installing custom functions..."
PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR/sql/functions.sql
source "$includes_dir/check_status.sh"  

##########################################################
# Import existing world_geom table in local GADM database.
# TEMPORARY HACK until code import directly from GADM.
##########################################################

echoi $e "Importing table \"$TBL_GEOM\" from DB \"$DB_GEOM\":"

# Dump table from source databse
echoi $e -n "- Exporting dumpfile..."
dumpfile="/tmp/cds_world_geom.sql"
sudo -Hiu postgres pg_dump --no-owner -t "${SCH_GEOM}.${TBL_GEOM}" "$DB_GEOM" > $dumpfile
source "$includes_dir/check_status.sh"	

# Correct schema references if $SCH_GEOM<>"public"
# Will screw up the dumpfile if source schema is already "public"
if [[ ! "$SCH_GEOM" == "public" ]]; then
	echoi $e -n "- Correcting schema references in dumpfile..."
	sed -i -e "s/${SCH_GEOM}./public./g" $dumpfile
	sed -i -e "s/Schema: ${SCH_GEOM};/Schema: public;/g" $dumpfile
	sed -i -e "s/ ${SCH_GEOM}./ public./g" $dumpfile
	source "$includes_dir/check_status.sh"	
fi

# Import table from dumpfile to target db & schema
echoi $e -n "- Importing table from dumpfile..."
PGOPTIONS='--client-min-messages=warning' psql -q --set ON_ERROR_STOP=1 $DB_CDS < $dumpfile >/dev/null
source "$includes_dir/check_status.sh"	

echoi $e -n "- Removing dumpfile..."
rm $dumpfile
source "$includes_dir/check_status.sh"	

############################################
# Build core tables
############################################

echoi $e -n "Creating core tables..."
PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR/sql/create_core_tables.sql
source "$includes_dir/check_status.sh"  

############################################
# Build centroid tables
############################################

echoi $e "Creating centroid tables:"

echoi $e -n "- centroid_country..."
PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR/sql/create_centroid_country.sql
source "$includes_dir/check_status.sh"  

echoi $e -n "- centroid_state_province..."
PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR/sql/create_centroid_state_province.sql
source "$includes_dir/check_status.sh"  

echoi $e -n "- centroid_county_parish..."
PGOPTIONS='--client-min-messages=warning' psql -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR/sql/create_centroid_county_parish.sql
source "$includes_dir/check_status.sh"  



COMMENT_BLOCK_1



############################################
# Alter ownership and permissions
############################################

source "$DIR/setp.sh"

######################################################
# Report total elapsed time and exit
######################################################

if [ "$i" == "true" ]; then
	source "$includes_dir/finish.sh"
fi
