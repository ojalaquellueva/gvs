#!/bin/bash

#########################################################################
# Centroid Detection Service (CDS) core application
#  
# Purpose: Flags coordinates that are potential political division centroids 
#
# Usage: ./cds.sh
#
# Requirements: 
# 	1. Table gadm in database gadm, with political division names
#		standardized using GNRS
#	2. Database & service gnrs (used to standardize table gadm)
#	3. Database geonames (used to build database gnrs)
#
# Authors: Brad Boyle (bboyle@email.arizona.edu)
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x

# for testing
job="whatever"

######################################################
# Set basic parameters, functions and options
######################################################

# Enable the following for strict debugging only:
#set -e

# Pointless command to trigger sudo password request. 
# Should remain in effect for all sudo commands in this 
# script, regardless of sudo timeout
#sudo pwd >/dev/null

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
mkdir -p "$DIR/log" 
touch $glogfile

# Set includes directory path, relative to $DIR
includes_dir=$DIR"/includes"

# Load parameters, functions and get command-line options
#source "$includes_dir/startup_master.sh"

# Load parameters file
source "$DIR/params.sh"

# Load db configuration params
source "$db_config_path/db_config.sh"	

# Load functions 
source "$includes_dir/functions.sh"

# Set local directories to same as main
data_dir_local=$data_base_dir
data_dir=$data_base_dir
DIR_LOCAL=$DIR

###########################################################
# Get options
###########################################################

# Set defaults
infile=""	# Input file and path
outfile=""	# Output file and path
api="false"		# Assume not an api call
pgpassword=""	# Not needed if not an api call
silent="false"	# off; sets both $e and $i to false if true
i="true"						# Interactive mode on by default
e="true"						# Echo on by default
appendlog="false"				# Append to existing logfile 

while [ "$1" != "" ]; do
    case $1 in
        -a | --api )         	api="true"
                            	;;
        -j | --job )        	shift
                                job=$1
                                ;;
        -f | --infile )        	shift
                                infile=$1
                                ;;
        -o | --outfile )       	shift
                                outfile=$1
                                ;;
        -n | --nowarnings )		i="false"
        						;;
        -e | --echo )			e="true"
        						;;
        -s | --silent )			silent="true"
        						e="false"
        						i="false"
        						;;
        -m | --mail )         	m="true"
                                ;;
        -a | --appendlog )		appendlog="true" 	# Start new logfile, 
        											# replace if exists
        						;;
         * )                     echo "ERROR: invalid option"; exit 1
    esac
    shift
done

#####################
# Validate options
#####################

# Input file (required)
if [[ "$infile" == "" ]]; then
	echo "ERROR: input file required"
	exit 1;
else
	# Check file exists
	if [ ! -f "$infile" ]; then
		echo "ERROR: file '$infile' does not exist"
		exit 1;
	fi
fi

# Output file (optional)
# If not provided, name output file as inputfile basename plus
# "_cds_results" and save to same directory
if [[ ! "$outfile" == "" ]]; then
	# Check destination directory exists
	outdir=$(dirname "${outfile}")
	if [ ! -d "$outdir" ]; then
		echo "ERROR in outfile '$outfile': no such path"
		exit 1
	fi
else
	# Create outfile path
	outdir=$(dirname "${infile}")
	filename=$(basename -- "${infile}")
	ext="${filename##*.}"
	base="${filename%.*}"
	outfilename="${base}_cds_results.${ext}"
	outfile="${outdir}/${outfilename}"
fi

# Set PGPASSWORD for api access
# Parameter $pgpwd set in config file
if  [ "$api" == "true" ]; then
	pgpassword="PGPASSWORD=$pgpwd"
	
	# Only set remaining options if api=true
	# Hence no defaults above
	if [ "$silent" == "true" ]; then
		e="false"
	else
		e="true"
	fi
fi

# Check email address in params if -m option chosen
if [ "$m" == "true" ] && [ "$email" == "" ]; then
	echo "ERROR: -m option used but no email in params file"
	exit 1;
fi

######################################################
# Custom confirmation message. 
# Will only be displayed if -s (silent) option not used.
######################################################

if [ "$i" == "true" ]; then

	# Current user
	curr_user="$(whoami)"

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Run process '$pname' using the following parameters: 

	Current user:		$curr_user
	Input file:		$infile
	Output file:		$outfile

EOF
	)"		
	confirm "$msg_conf"
fi

# Start time, send mail if requested and echo begin message
# Start timing & process ID
starttime="$(date)"
start=`date +%s%N`; prev=$start
pid=$$

if [[ "$m" = "true" ]]; then 
	source "${includes_dir}/mail_process_start.sh"	# Email notification
fi

if [ "$i" == "true" ]; then
	echoi $e ""; echoi $e "------ Process started at $starttime ------"
	echoi $e ""
fi

#########################################################################
# Main
#########################################################################


############################################
# Load raw data to table user_data
############################################

# Import the input file
if [ "$api" == "false" ]; then
	echoi $e -n "Importing raw data..."
	sql="\COPY user_data_raw(latitude,longitude) FROM '${infile}' DELIMITER ',' CSV HEADER"
	cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -c \"$sql\""
	eval $cmd
	source "$DIR/includes/check_status.sh" 
fi

# Load the raw data to table user_data
echoi $e "Loading raw data to table user_data"

echoi $e -n "- Dropping indexes on user_data..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/drop_indexes_user_data.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

# This deletes any existing data in table user_data
# Assume user_data_raw has been populated
echoi $e -n "- Loading user_data..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/load_user_data.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 



echo "STOPPING..."; exit 0

: <<'COMMENT_BLOCK_1'

############################################
# Check against existing results in cache
############################################

echoi $e -n "- Checking existing results in cache..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/check_cache.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

#echo "EXITING!!!"; exit 0

############################################
# Resolve Political divisions
############################################

echoi $e "Country:"

echoi $e -n "- exact..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/resolve_country_exact.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

echoi $e -n "- fuzzy..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v match_threshold=$match_threshold -v job=$job -f $DIR_LOCAL/sql/resolve_country_fuzzy.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

echoi $e "State/province:"

echoi $e -n "- exact..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/resolve_sp_exact.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

echoi $e -n "- fuzzy..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v match_threshold=$match_threshold -v job=$job -f $DIR_LOCAL/sql/resolve_sp_fuzzy.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

echoi $e "County/parish:"

echoi $e -n "- exact..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/resolve_cp_exact.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

echoi $e -n "- fuzzy..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v match_threshold=$match_threshold -v job=$job -f $DIR_LOCAL/sql/resolve_cp_fuzzy.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

############################################
# Summarize results
############################################

echoi $e -n "Summarizing results..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/summarize.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

############################################
# Populate ISO codes (add-on feature)
############################################

echoi $e -n "Populating ISO codes..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/iso_codes.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 

############################################
# Updating cache
############################################

# Add new results to cache
echoi $e -n "Updating cache..."
cmd="$pgpassword PGOPTIONS='--client-min-messages=warning' psql -U $USER -d $DB_CDS --set ON_ERROR_STOP=1 -q -v job=$job -f $DIR_LOCAL/sql/update_cache.sql"
eval $cmd
source "$DIR/includes/check_status.sh" 


COMMENT_BLOCK_1


######################################################
# Report total elapsed time and exit if running solo
######################################################

if [ -z ${master+x} ]; then source "$DIR/includes/finish.sh"; fi

######################################################
# End script
######################################################