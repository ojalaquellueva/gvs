#!/bin/bash

#########################################################################
# Centroid Detection Service (gvs) core application (parallel version)
#
# ***************** UNDER DEVELOPMENT! ********************
#  
# Purpose: Flags coordinates that are potential political division centroids 
#
# Usage: ./gvs.sh
#
# Requirements: 
# 	1. Table gadm in database gadm, with political division names
#		standardized using GNRS
#	2. Database & service gnrs (used to standardize table gadm)
#	3. Database geonames (used to build database gnrs)
#
# Note: parallel version processes each batch in a separate, uniquely-named
#	user-specific table named ("user_data_[UNIQUESUFFIX]") instead of 
#	storing all batches in the same table ("user_data") and identify each
#	batch with a unique job number ("job_id). The method used by this script
# 	prevents table locks on table "user_data" during update operations, thus 
# 	allowing postgres to process the batches fully in parallel.
#
# Authors: Brad Boyle (bboyle@email.arizona.edu)
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x

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
silent="false"	# off; sets both $e and $i to false if true
i="true"						# Interactive mode on by default
e="true"						# Echo on by default
appendlog="false"				# Append to existing logfile 

# psql default options
# User and password not set by default
# Must have passwordless authentication for these to work
opt_pgpassword=""	# Omit if not an api call
opt_user=""			# Omit if not an api call

# Optional threshold parameters
# Empty string: use default values supplied in params.sh
maxdist=""
maxdistrel=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --api )         	api="true"
                            	;;
        -f | --infile )        	shift
                                infile=$1
                                ;;
        -o | --outfile )       	shift
                                outfile=$1
                                ;;
        -d | --maxdist )       	shift
                                maxdist=$1
                                ;;
        -r | --maxdistrel )    	shift
                                maxdistrel=$1
                                ;;
        -n | --nowarnings )		i="false"
        						;;
        -e | --echo )			e="true"
        						;;
        -s | --silent )			silent="true"
        						e="false"
        						i="false"
        						;;
        -v | --nullval )        shift
        						nullval="$1"
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
		exit 1
	fi
fi

# Output file (optional)
# If not provided, name output file as inputfile basename plus
# "_gvs_results" and save to same directory
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
	outfilename="${base}_gvs_results.${ext}"
	outfile="${outdir}/${outfilename}"
fi

# Reset threshold parameter MAX_DIST if supplied
if [[ ! "$maxdist" == "" ]]; then
	# Check positive integer
	if test "$maxdist" -gt 0 2> /dev/null ; then
		MAX_DIST=$maxdist
	else
		echo "ERROR: Option -d/--maxdist must be a positive inteter"
		exit 1
	fi
else
	MAX_DIST=$MAX_DIST_DEFAULT
fi

# Reset threshold parameter MAX_DIST_REL if supplied
if [[ ! "$maxdistrel" == "" ]]; then
	# Check over (0:1)
	if (( $(echo "$maxdistrel > 0" |bc -l) )) && (( $(echo "$maxdistrel < 1" |bc -l) )); then
			MAX_DIST_REL=$maxdistrel
	else
		echo "ERROR1: Option -r/--maxdistrel must be fraction over (0:1)"
		exit 1
	fi
else
	MAX_DIST_REL=$MAX_DIST_REL_DEFAULT
fi

# Set user and password for api access
# Parameters $USER and $PWD_USER set in config file params.sh
if  [ "$api" == "true" ]; then
	opt_pgpassword="PGPASSWORD=$PWD_USER"
	opt_user="-U $USER"
	
	# Turn off all echoes, regardless of echo options sent
	e="false"
	i="false"
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

	Unix user:		$curr_user
	Default postgres user: $USER
	Actual postgres user: $opt_user
	Input file:		$infile
	Output file:		$outfile
	MAX_DIST:		$MAX_DIST
	MAX_DIST_REL:		$MAX_DIST_REL

EOF
	)"		
	confirm "$msg_conf"
fi

# Start time, send mail if requested and echo begin message
# Start timing & process ID
starttime="$(date)"
start=`date +%s%N`; prev=$start
pid=$$

if [[ "$m" == "true" ]]; then 
	source "${includes_dir}/mail_process_start.sh"	# Email notification
fi

if [ "$i" == "true" ]; then
	echoi $e ""; echoi $e "------ Process started at $starttime ------"
	echoi $e ""
fi

#########################################################################
# Main
#########################################################################

# Generate unique suffix by concatenating date in nanoseconds
# plus random integer for good measure
uniqid="$(date +%Y%m%d_%H%M%N)_${RANDOM}"	

# For testing only: all temp user data table have same name 
# so I don't have to delete a ton of tables
#uniqid="temp"

# Create unique names for user data tables and job_id
tbl_user_data="user_data_${uniqid}"
tbl_user_data_raw="${tbl_user_data}_raw"
job="job_${uniqid}"	

# # Uncomment for testing
# echo "Parameters:"
# echo "This script: gvs2.sh"
# echo "tbl_user_data=${tbl_user_data}"
# echo "tbl_user_data_raw=${tbl_user_data_raw}"
# echo "job=${job}"
# echo "db_config_path=${db_config_path}"
# echo "includes_dir=${includes_dir}"
# echo "DB_GVS=${DB_GVS}"
# echo "opt_pgpassword=${opt_pgpassword}"
# echo "opt_user=${opt_user}"
# echo " "

############################################
# Load raw data to table user_data
############################################

# Import the input file
echoi $e "Importing user data:"

# Create job-specific temp table to hold raw data
echoi $e -n "- Creating user data tables..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v tbl_user_data_raw=${tbl_user_data_raw} -f $DIR_LOCAL/sql/create_user_data_tables.sql"
# echo "\$cmd: "
# echo $cmd
eval $cmd
source "$DIR/includes/check_status.sh"

# Import the file to tempoprary raw data table
# $nullas statement set as optional command line parameter
echoi $e -n "- Importing raw data to \"$tbl_user_data_raw\"..."

# ///////////////// #
# NOTE: need option to import user_id
# ///////////////// #
metacmd="\COPY $tbl_user_data_raw(latitude,longitude) FROM '${infile}' DELIMITER ',' CSV $nullas "
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -c \"$metacmd\""
eval $cmd
source "$DIR/includes/check_status.sh"

: <<'COMMENT_BLOCK_clear_user_data'
# Remove completely after testing
# Not applicable when multiple process-specific user data tables used
if [ "$CLEAR_USER_DATA" == "true" ]; then
	# Admin-level option to completely clear table user_data, for testing
	# Set in params file
	echoi $e -n "- Clearing user_data (TESTING ONLY)..."
	sql="TRUNCATE user_data RESTART IDENTITY"
	cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -c \"$sql\""
	eval $cmd
	source "$DIR/includes/check_status.sh"
fi
COMMENT_BLOCK_clear_user_data

# Insert the raw data to user data table
echoi $e -n "- Copying raw data to table \"$tbl_user_data\"..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v job=$job -v tbl_user_data=${tbl_user_data} -v tbl_user_data_raw=${tbl_user_data_raw} -f $DIR_LOCAL/sql/load_user_data2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

# Drop the temp table
echoi $e -n "- Dropping temp table..."
sql="DROP TABLE $tbl_user_data_raw"
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -c \"$sql\""
eval $cmd
source "$DIR/includes/check_status.sh"

############################################
# Validate coordinates
############################################

echoi $e -n "Validating coordinates..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data='"$tbl_user_data"' -f $DIR_LOCAL/sql/validate_coordinates.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

echoi $e -n "Calculating coordinate uncertainty..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -f $DIR_LOCAL/sql/coordinate_uncertainty2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

############################################
# Populate political divisions
############################################

echoi $e -n "Populating political divisions..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -f $DIR_LOCAL/sql/populate_poldivs2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

############################################
# Check centroids
############################################

echoi $e "Calculating centroids:"

echoi $e -n "- country..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v MAX_DIST=$MAX_DIST -v MAX_DIST_REL=$MAX_DIST_REL -f $DIR_LOCAL/sql/check_centroid_country2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

echoi $e -n "- state..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v MAX_DIST=$MAX_DIST -v MAX_DIST_REL=$MAX_DIST_REL -f $DIR_LOCAL/sql/check_centroid_state2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

echoi $e -n "- county..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v MAX_DIST=$MAX_DIST -v MAX_DIST_REL=$MAX_DIST_REL -f $DIR_LOCAL/sql/check_centroid_county2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

echoi $e -n "- other subpolygons..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v MAX_DIST=$MAX_DIST -v MAX_DIST_REL=$MAX_DIST_REL -f $DIR_LOCAL/sql/check_centroid_subpoly2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

echoi $e -n "Determining consensus centroid..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -f $DIR_LOCAL/sql/consensus_centroid2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

############################################
# Save threshold parameters
############################################

echoi $e -n "Saving threshold parameters..."
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user  -d $DB_GVS --set ON_ERROR_STOP=1 -q -v tbl_user_data=${tbl_user_data} -v MAX_DIST=$MAX_DIST -v MAX_DIST_REL=$MAX_DIST_REL -f $DIR_LOCAL/sql/save_params2.sql"
eval $cmd
source "$DIR/includes/check_status.sh"

############################################
# Export the results
############################################

echoi $e -n "Dumping results to file '$outfile'..."
metacmd="\COPY ( SELECT id, latitude_verbatim, longitude_verbatim, latitude, longitude, user_id, gid_0, country, gid_1, state, gid_2, county, country_cent_dist, country_cent_dist_relative, country_cent_type, country_cent_dist_max, is_country_centroid, state_cent_dist, state_cent_dist_relative, state_cent_type, state_cent_dist_max, is_state_centroid, county_cent_dist, county_cent_dist_relative, county_cent_type, county_cent_dist_max, is_county_centroid, subpoly_cent_dist, subpoly_cent_dist_relative, subpoly_cent_type, subpoly_cent_dist_max, is_subpoly_centroid, centroid_dist_km, centroid_dist_relative, centroid_type, centroid_dist_max_km, centroid_poldiv, max_dist, max_dist_rel, latlong_err, coordinate_decimal_places, coordinate_inherent_uncertainty_m FROM ${tbl_user_data} ) TO '${outfile}' CSV HEADER"
cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -c \"$metacmd\""
eval $cmd
echoi $e "done"


# Drop the job-specific user data table if requested
if [ "$DROP_USER_DATA" == "true" ]; then
	echoi $e -n "Dropping temporary user data table..."
	sql="DROP TABLE $tbl_user_data"
	cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_GVS --set ON_ERROR_STOP=1 -q -c \"$sql\""
	eval $cmd
	source "$DIR/includes/check_status.sh"
fi

######################################################
# Report total elapsed time and exit if running solo
######################################################

if [ -z ${master+x} ]; then source "$DIR/includes/finish.sh"; fi

######################################################
# End script
######################################################