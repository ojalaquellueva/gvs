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

# The name of this file. Tells sourced scripts not to reload general  
# parameters and command line options as they are being called by  
# another script. Allows component scripts to be called individually  
# if needed
master=`basename "$0"`

# Get working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Set includes directory path, relative to $DIR
includes_dir=$DIR"/../includes"

# Load parameters, functions and get command-line options
source "$includes_dir/startup_master.sh"

# Set process name and confirm operation
pname="Build centroid validation database $db_cds"
source "$includes_dir/confirm.sh"

# Set local directories to same as main
data_dir_local=$data_base_dir
DIR_LOCAL=$DIR

#########################################################################
# Main
#########################################################################

# Disable full rebuild while develop final components
: <<'COMMENT_BLOCK_1'

############################################
# Create database in admin role & reassign
# to principal non-admin user of database
############################################

# Run pointless command to trigger sudo password request, 
# needed below. Should remain in effect for all
# sudo commands in this script, regardless of sudo timeout
sudo pwd >/dev/null

# Check if db already exists
# Warn to drop manually. This is safer.
if psql -lqt | cut -d \| -f 1 | grep -qw "$db_cds"; then
	# Reset confirmation message
	msg="Database '$db_cds' already exists! Please drop first."
	echo $msg; exit 1
fi

echoi $e -n "Creating database '$db_cds'..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "CREATE DATABASE $db_cds" 
source "$includes_dir/check_status.sh"  

echoi $e -n "Changing owner to 'bien'..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "ALTER DATABASE $db_cds OWNER TO bien" 
source "$includes_dir/check_status.sh"  

echoi $e -n "Granting permissions..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
\set ON_ERROR_STOP on
REVOKE CONNECT ON DATABASE $db_cds FROM PUBLIC;
GRANT CONNECT ON DATABASE $db_cds TO bien;
GRANT CONNECT ON DATABASE $db_cds TO public_bien;
GRANT ALL PRIVILEGES ON DATABASE $db_cds TO bien;
\c $db_cds
GRANT USAGE ON SCHEMA public TO public_bien;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO public_bien;
EOF
echoi $i "done"

echoi $e "Installing extensions:"

echoi $e -n "- fuzzystrmatch..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS fuzzystrmatch;
CREATE EXTENSION fuzzystrmatch;
EOF
echoi $i "done"

# For trigram fuzzy matching
echoi $e -n "- pg_trgm..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS pg_trgm;
CREATE EXTENSION pg_trgm;
EOF
echoi $i "done"

# For generating unaccented versions of text
echoi $e -n "- unaccent..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS unaccent;
CREATE EXTENSION unaccent;
EOF
echoi $i "done"

# POSTGIS
echoi $e -n "- postgis..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS postgis;
CREATE EXTENSION postgis;
EOF
echoi $i "done"

############################################
# TEMPORARY HACK
# Import existing world_geom table
# TEMPORARY HACK until code loading of GADM
# from scratch
############################################

echoi $e "Importing existing table \"world_geom\" from schema \"$sch_main\" in DB \"$db_main\":"

# Dump table from source databse
echoi $e -n "- Creating dumpfile..."
dumpfile="/tmp/cds_world_geom.sql"
sudo -Hiu postgres pg_dump --no-owner -t "${sch_main}.world_geom" "$db_main" > $dumpfile
source "$includes_dir/check_status.sh"	

# Correct schema references. 
echoi $e -n "- Correcting schema references in dumpfile..."
sed -i -e "s/${sch_main}./public./g" $dumpfile
sed -i -e "s/Schema: ${sch_main};/Schema: public;/g" $dumpfile
sed -i -e "s/ postgis./ public./g" $dumpfile
source "$includes_dir/check_status.sh"	

# Import table from dumpfile to target db & schema
echoi $e -n "- Importing table from dumpfile..."
PGOPTIONS='--client-min-messages=warning' psql -q --set ON_ERROR_STOP=1 $db_cds < $dumpfile >/dev/null
source "$includes_dir/check_status.sh"	

echoi $e -n "- Removing dumpfile..."
rm $dumpfile
source "$includes_dir/check_status.sh"	

COMMENT_BLOCK_1


############################################
# Build core tables
############################################

echoi $e -n "Creating core tables..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR/sql/create_core_tables.sql
source "$includes_dir/check_status.sh"  





# Skip everything else for now
: <<'COMMENT_BLOCK_2'

############################################
# Build political division tables
############################################

echoi $e "Creating poldiv tables in DB $db_geonames:"

echoi $e -n "- Dropping previous GNRS tables if any..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/drop_gnrs_tables.sql
source "$includes_dir/check_status.sh"  

echoi $e -n "- Country..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/country.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Fixing errors..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/fix_errors_country.sql
source "$includes_dir/check_status.sh"

echoi $e -n "- State/province..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/state_province.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Adding & populating column state_province_std...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/state_province_std.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Fixing errors..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/fix_errors_state_province.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Adding & populating column state_province_code2..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/state_province_code2.sql
source "$includes_dir/check_status.sh"

echoi $e -n "- County/parish..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/county_parish.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Adding & populating column county_parish_std...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/county_parish_std.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Fixing errors...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/fix_errors_county_parish.sql
source "$includes_dir/check_status.sh"

echoi $e -n "-- Adding & populating column county_parish_code2..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/county_parish_code2.sql
source "$includes_dir/check_status.sh"

echoi $e -n "- Adjusting permissions for new tables..."
PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -d  $db_geonames -v user_adm=$user_admin -v user_read=$user_read -f $DIR_LOCAL/sql/set_permissions_geonames.sql
source "$includes_dir/check_status.sh"	

echoi $e -n "- Reassigning ownership to postgres..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $db_geonames --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/gnrs_tables_change_owner.sql
source "$includes_dir/check_status.sh"  


############################################
# Import geonames tables
############################################

echoi $e "Importing tables from DB $db_geonames to DB $db_cds:"

# Dump table from source databse
echoi $e -n "- Creating dumpfile..."
dumpfile="/tmp/gnrs_geonames_extract.sql"
sudo -Hiu postgres pg_dump --no-owner -t country -t country_name -t state_province -t state_province_name -t county_parish -t county_parish_name 'geonames' > $dumpfile
source "$includes_dir/check_status.sh"	

# Import table from dumpfile to target db & schema
echoi $e -n "- Importing tables from dumpfile..."
PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 $db_cds < $dumpfile > /dev/null >> $tmplog
source "$includes_dir/check_status.sh"	

echoi $e -n "- Removing dumpfile..."
rm $dumpfile
source "$includes_dir/check_status.sh"	

############################################
# Import BIEN2 legacy data
# Includes HASC codes, among other goodies
############################################

echoi $e "Importing legacy BIEN2 data:"

echoi $e -n "- Creating tables...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/create_bien2_tables.sql
source "$includes_dir/check_status.sh"

# Import metadata file to temp table
echoi $i -n "- Inserting to state_province_bien2..."
sql="
\COPY state_province_bien2 FROM '${data_dir_local}/${state_province_bien2_file}' DELIMITER ',' CSV HEADER;
"
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
$sql
EOF
echoi $i "done"

echoi $i -n "- Inserting to county_parish_bien2..."
sql="
\COPY county_parish_bien2 FROM '${data_dir_local}/${county_parish_bien2_file}' DELIMITER ',' CSV HEADER;
"
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds -q << EOF
\set ON_ERROR_STOP on
$sql
EOF
echoi $i "done"

############################################
# Transfer information from bien2 tables
############################################

echoi $e -n "Correcting known issues...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/correct_errors.sql
source "$includes_dir/check_status.sh"

echoi $e -n "Transferring HASC codes from BIEN2 tables..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/update_hasc_codes.sql
source "$includes_dir/check_status.sh"

echoi $e -n "Dropping BIEN2 tables..."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/drop_bien2_tables.sql
source "$includes_dir/check_status.sh"

############################################
# Add any missing names from main table to
# name table
############################################

echoi $e "Adding missing names to table:"

echoi $e -n "- country_name...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/country_name_add_missing.sql
source "$includes_dir/check_status.sh"

echoi $e -n "- state_province_name...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/state_province_name_add_missing.sql
source "$includes_dir/check_status.sh"

echoi $e -n "- county_parish_name...."
PGOPTIONS='--client-min-messages=warning' psql -d $db_cds --set ON_ERROR_STOP=1 -q -f $DIR_LOCAL/sql/county_parish_name_add_missing.sql
source "$includes_dir/check_status.sh"

############################################
# Adjust permissions
############################################

echoi $e -n "Adjusting permissions..."
for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" $db_cds` ; do  psql -c "alter table \"$tbl\" owner to bien" $db_cds > /dev/null >> $tmplog; done
source "$includes_dir/check_status.sh"

COMMENT_BLOCK_2

######################################################
# Report total elapsed time and exit
######################################################

source "$includes_dir/finish.sh"
