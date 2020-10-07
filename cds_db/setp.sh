#!/bin/bash

#########################################################################
# Purpose: Set ownership and permissions for all tables in database 
#
# Usage:	./setp.sh
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

# Get working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Iinitialize logfile if not called by another (master) script
if [ -z ${master+x} ]; then
	sudo pwd >/dev/null	# Trigger sudo password request
	#master=`basename "$0"`
	export glogfile="$DIR/log/logfile_"$local_basename".txt"
	sudo mkdir -p "$DIR/log" 
	sudo touch $glogfile

	# Set includes directory path, relative to $DIR
	includes_dir=$DIR"/../includes"

	# Load parameters, functions and get command-line options
	source "$includes_dir/startup_master.sh"

	# # Set process name and confirm operation
	pname="Set permissions for database $DB_CDS"

fi

# Set local directories to same as main
data_dir_local=$data_base_dir
data_dir=$data_base_dir
DIR_LOCAL=$DIR

######################################################
# Custom confirmation message. 
# Will only be displayed if -s (silent) option not used.
# Also not displayed if this script called by other script.
######################################################

if [ -z ${master+x} ] && [ "$i" == "true" ]; then

	# Current user
	curr_user="$(whoami)"

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Run process '$pname' using the following parameters: 

	DB name:		$DB_CDS
	Current user:		$curr_user
	Admin user/db owner:	$USER_ADMIN
	Read-only user:		$USER_READ

EOF
	)"		
	confirm "$msg_conf"

fi 

# Start time, send mail if requested and echo begin message
source "$includes_dir/start_process.sh"  

#########################################################################
# Main
#########################################################################

# Check if db already exists
# Warn to drop manually. This is safer.
if ! (psql -lqt | cut -d \| -f 1 | grep -qw "$DB_CDS"); then
	# Reset confirmation message
	msg="Database '$DB_CDS' doesn't exist!"
	echo $msg; exit 1
fi

############################################
# Alter ownership and permissions
############################################
echoi $e "Setting ownership and permissions:"

echoi $e -n "- Setting permissions for admin user '$USER_ADMIN'"
if [[ "$USER_ADMIN" == "" ]]; then
	echoi $e "...admin user not set"
else
	echoi $e ":"
	echoi $e -n "-- Changing DB owner to '$USER_ADMIN'"
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "ALTER DATABASE $DB_CDS OWNER TO $USER_ADMIN" 
	source "$includes_dir/check_status.sh"  

	echoi $e -n "-- Granting permissions to '$USER_ADMIN'..."
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
	\set ON_ERROR_STOP on
	REVOKE CONNECT ON DATABASE $DB_CDS FROM PUBLIC;
	GRANT CONNECT ON DATABASE $DB_CDS TO $USER_ADMIN;
	GRANT ALL PRIVILEGES ON DATABASE $DB_CDS TO $USER_ADMIN;
	\c $DB_CDS
	GRANT USAGE ON SCHEMA public TO $USER_ADMIN;
	GRANT SELECT ON ALL TABLES IN SCHEMA public TO $USER_ADMIN;
	GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $USER_ADMIN;
EOF
	source "$includes_dir/check_status.sh" 

	echoi $e "-- Transferring ownership of non-postgis relations to user '$USER_ADMIN':"
	# Only postgis table should be spatial_ref_sys
	
	echoi $e -n "--- Tables..."
#	for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname='public' and tableowner<>'postgres';" $DB_CDS` ; do  sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q -c "alter table \"$tbl\" owner to $USER_ADMIN" $DB_CDS ; done
	# Using "tablename not in (...)" instead of "tableowner<>'postgres'" 
	# prevents ownership change being blocked for tables created manually 
	# while logged in as postgres
	for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname='public' and tablename not in ('spatial_ref_sys');" $DB_CDS` ; do  sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q -c "alter table \"$tbl\" owner to $USER_ADMIN" $DB_CDS ; done
	source "$includes_dir/check_status.sh"  

	echoi $e -n "--- Sequences..."
	for tbl in `psql -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" $DB_CDS` ; do  sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q -c "alter sequence \"$tbl\" owner to $USER_ADMIN" $DB_CDS ; done
	source "$includes_dir/check_status.sh"  
	
	echoi $e -n "-- Views..."
	for tbl in `psql -qAt -c "select table_name from information_schema.views where table_schema = 'public' and table_name not in ('geography_columns','geometry_columns','raster_columns','raster_overviews');" $DB_CDS` ; do  psql -c "alter view \"$tbl\" owner to $USER_ADMIN" $DB_CDS ; done
	source "$includes_dir/check_status.sh"  
fi

echoi $e -n "- Granting read access to read-only user \"$USER_READ\"..."
if [[ ! "$USER_READ" == "" ]]; then
	
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
	\set ON_ERROR_STOP on
	REVOKE CONNECT ON DATABASE $DB_CDS FROM PUBLIC;
	GRANT CONNECT ON DATABASE $DB_CDS TO $USER_READ;
	\c $DB_CDS
	GRANT USAGE ON SCHEMA public TO $USER_READ;
	GRANT SELECT ON ALL TABLES IN SCHEMA public TO $USER_READ;
EOF
	source "$includes_dir/check_status.sh" 
else 
	$echoi $e "read-only user not set"
fi 

######################################################
# Report total elapsed time and exit
######################################################

if [ -z ${master+x} ] && [ "$i" == "true" ]; then
	source "$includes_dir/finish.sh"
fi
