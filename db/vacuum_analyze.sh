#!/bin/bash

#########################################################################
# Purpose: Runs VACUUM ANALYZE on all tables in schema
#
# Notes:
#	1. Results echoed onscreen and saved to log file in log/
#  
# Author: Brad Boyle (bboyle@email.arizona.edu)
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x
#echoi $e; echoi $e "EXITING script `basename "$BASH_SOURCE"`"; exit 0

######################################################
# Set parameters, load functions & confirm operation
# 
# Loads local parameters only if called by master script.
# Otherwise loads all parameters, functions and options
######################################################

# Trigger sudo password request.
sudo pwd >/dev/null

# Get local working directory
DIR_LOCAL="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR_LOCAL" ]]; then DIR_LOCAL="$PWD"; fi

# $local = name of this file
# $local_basename = name of this file minus ='.sh' extension
# $local_basename should be same as containing directory, as  
# well as local data subdirectory within main data directory, 
# if local data directory needed
local=`basename "${BASH_SOURCE[0]}"`
local_basename="${local/.sh/}"

# Set parent directory if running independently & suppress main message
if [ -z ${master+x} ]; then
	DIR=$DIR_LOCAL"/.."
	suppress_main='true'
else
	suppress_main='false'
fi

# Load startup script for local files
# Sets remaining parameters and options, and issues confirmation
# and startup messages
source "$DIR/includes/startup_local.sh"	


# Uncomment to re-set these parameters in script
# db="vegbien"
# sch="analytical_db_test"
# 
db="gvs_dev"
sch="public"

verbose="true"

######################################################
# Custom confirmation message. 
# Will only be displayed if running as
# standalone script and -s (silent) option not used.
######################################################

if [[ "$i" = "true" && -z ${master+x} ]]; then 

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Process '$pname' will use following parameters: 
	
	Database:	$db
	Schema:		$sch
	
EOF
	)"		
	confirm "$msg_conf"
fi

#########################################################################
# Main
#########################################################################

echoi $e "Executing module '$local_basename'"
echoi $e " "

######################################################
# Run the queries, changing where clause each time
######################################################

echoi $e -n "Running vacuum analyze on schema ${sch} in database ${db}..."

if [ "$e" == "false" ] || [ "$verbose" == "false" ]; then
	# Quiet mode
	sudo -u postgres PGOPTIONS='--client-min-messages=warning' psql -t -A -d $db --pset pager=off -q -c "select format('vacuum analyse %I.%I;', n.nspname::varchar, t.relname::varchar) FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace WHERE t.relkind = 'r' and n.nspname::varchar = '$sch' order by 1"  | sudo -u postgres psql -U postgres -d $db -q 
else
	# Verbose
	sudo -u postgres PGOPTIONS='--client-min-messages=warning' psql -t -A -d $db -q -c "select format('vacuum verbose analyse %I.%I;', n.nspname::varchar, t.relname::varchar) FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace WHERE t.relkind = 'r' and n.nspname::varchar = '$sch' order by 1" | sudo -u postgres psql -U postgres -d $db 
fi
source "$DIR/includes/check_status.sh"	

######################################################
# Report total elapsed time and exit if running solo
######################################################

if [ -z ${master+x} ]; then source "$DIR/includes/finish.sh"; fi