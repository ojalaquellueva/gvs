# Centroid Detection Service (CDS)

Author: Brad Boyle (bboyle@email.arizona.edu)  
Date created: 24 March 2020  


## Contents

[Overview](#overview)  
[Software](#software)  
[Dependencies](#dependencies)  
[Permissions](#permissions)  
[Installation and configuration](#installation-and-configuration)  
[Usage](#usage)  

## Overview

Detects and flags coordinates which are potentially political division centroids. Input is a CSV file of coordinates: latitude, longitude, user_id (optional). Returns coordinates, user_id (if supplied), associated political divisions, various metrics assessing the probability that the coordinate pairs is a centroid of one or more political divisions, and a final consensus assessment is_centroid (0,1). Political division used from validation from Global Admininstrative Division Database (GADM; `https://gadm.org`) with political division names standardized against the geonames database (https://`www.geonames.org`) using the Geographic Name Resolution Service (GNRS; `https://github.com/ojalaquellueva/gnrs.git`)


## Software

Ubuntu 16.04 or higher  
PostgreSQL/psql 12.2, or higher (PostGIS extension installed by this script)

## Dependencies

Requires access to BIEN validation service GNRS (`https://github.com/ojalaquellueva/gnrs.git`) either as API or local batch service.

## Permissions

This script must be run by a user with sudo and authorization to connect to postgres (as specified in `pg_hba` file). The admin-level and read-only Postgres users for the gadm database (specified in `params.sh`) should already exist and must be authorized to connect to postgres (as specified in pg_hba file).

## Installation and configuration
* Recommend the following setup:

```
# Create application base directory (call it whatever you want)
mkdir -p cds
cd cds

# Create application code directory
mkdir src

# Install application code
cd src
git clone https://github.com/ojalaquellueva/cds

# Move data and sensitive parameters directories outside of code directory
# Be sure to change paths to these directories (in params.sh) accordingly
mv data ../
mv config ../
```

## Usage

### Building the CDS Database
See README in `cds_db/`.

### CDS

1. Set parameters in `params.sh`.
2. Set passwords and other sensitive parameters in `config/db_config.sh`.
2. Run the master script, `cds.sh`.

#### Syntax

```
./cds.sh [options]
```

#### Options
-m: Send notification emails  
-n: No warnings: suppress confirmations but not progress messages  
-s: Silent mode: suppress all confirmations & progress messages  

#### Example:

```
./cds.sh -m -s
```
* Runs silently without terminal echo
* Sends notification message at start and completion


