#!/bin/bash

#########################################################################
# pud: "Purge user_data"
#  
# Purpose: Purges rows from table user_data according to various 
# 	parameters, typically rows older than a given data_created. Can be
# 	cron'd to regularly purge old data, or run directly to clear the 
# 	entire table. 
#
# Usage: ./pud.sh [options]
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

pname="Purge user_data"

###########################################################
# Get options
###########################################################

# Set defaults
delwhat=""				# What to delete; see below
silent="false"			# off; sets both $e and $i to false if true
i="true"				# Interactive mode on by default
e="true"				# Echo on by default
appendlog="false"		# Append to existing logfile 


while [ "$1" != "" ]; do
    case $1 in
        -d | --delete )			shift
                                delwhat=$1
                                ;;
        -n | --nowarnings )		i="false"
        						;;
        -e | --echo )			e="true"
        						;;
        -s | --silent )			silent="true"
        						e="false"
        						i="false"
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

# Time deletion parameter
# Get number of days or weeks
if [ ! "$delwhat" == "" ]; then
	deleteall="false"
	
	if [ "$delwhat" == "all" ]; then
		deleteall="true"
	else
		tunit=${delwhat: -1}		# Get last character: must be d or w
		tnum=${delwhat%?}			# Remove last character; rest must integer
		
		if [ "$tunit" == "d" ] || [ "$tunit" == "w" ] ; then
			if ! test "$tnum" -gt 0 2> /dev/null ; then
				echo "ERROR: deletion parameter must begin with positive integer"
				exit 1
			fi
		else
			echo "ERROR: Bad deletion parameter: must be 'all' or positive integer followed by 'd' or 'w'"
			exit 1
		fi
	fi
else 
	echo "ERROR: Missing deletion parameter"
	exit 1
fi

######################################################
# Custom confirmation message. 
# Will only be displayed if -s (silent) option not used.
######################################################

if [ "$deleteall" == "true" ]; then
	delmsg="all"
elif [ "$tunit" == "d" ]; then
	delmsg="Older than $tnum days"
	tunitfull="days"
else
	delmsg="Older than $tnum weeks"
	tunitfull="weeks"
fi

if [ "$i" == "true" ]; then

	# Reset confirmation message
	msg_conf="$(cat <<-EOF

	Run process '$pname' using the following parameters: 

	Records to delete:	$delmsg

EOF
	)"		
	confirm "$msg_conf"
fi

# Start time, send mail if requested and echo begin message
# Start timing & process ID
starttime="$(date)"
start=`date +%s%N`; prev=$start
pid=$$

if [ "$i" == "true" ]; then
	echoi $e ""; echoi $e "------ Process started at $starttime ------"
	echoi $e ""
fi

#########################################################################
# Main
#########################################################################

# Copy table (for testing only)
# echoi $e -n "Creating duplicate table user_data_copy for testing..."
# cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_CDS --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/user_data_copy.sql"
# eval $cmd
# source "$DIR/includes/check_status.sh"

echoi $e "Purging table user_data"

if [ "$deleteall" == "true" ]; then
	# Empty entire table
	echoi $e -n "- Clearing user_data..."
	sql="TRUNCATE user_data RESTART IDENTITY"
	cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_CDS --set ON_ERROR_STOP=1 -q -c \"$sql\""
	eval $cmd
	source "$DIR/includes/check_status.sh"
else
	# Delete records older than requested time interval
	intvl="$tnum $tunitfull"
	echoi $e -n "- Clearing records older than $intvl..."
	sql="DELETE FROM user_data WHERE date_created < NOW() - INTERVAL '"$intvl"'"
	cmd="$opt_pgpassword PGOPTIONS='--client-min-messages=warning' psql $opt_user -d $DB_CDS --set ON_ERROR_STOP=1 -q -c \"$sql\""
	eval $cmd
	source "$DIR/includes/check_status.sh"
fi

######################################################
# Report total elapsed time
######################################################

source "$DIR/includes/finish.sh"

######################################################
# End script
######################################################
