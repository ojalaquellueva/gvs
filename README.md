# Centroid Detection Service (CDS)

Author: Brad Boyle (bboyle@email.arizona.edu)  
Date created: 24 March 2020  


## Contents

[Overview](#overview)  
[Software](#software)  
[Dependencies](#dependencies)  
[Permissions](#permissions)  
[Installation and configuration](#installation-and-configuration)  
[Usage](#usage):  
[I. Build the CDS Database ](#I-build-cds-db)  
[II. CDS batch application](#II-cds-batch)  
[III. CDS parallel processing application](#II-cds-parallel)

<a name="overview"></a>
## Overview

Detects and flags coordinates which may be political division centroids. Input is a CSV file of coordinates: latitude, longitude. Returns coordinates, associated political divisions, various metrics assessing the probability that the coordinate pairs is a centroid of one or more political divisions, and a final consensus assessment is_centroid (0,1). Political divisions used from validation from Global Admininstrative Division Database (GADM; `https://gadm.org`) with political division names standardized against the geonames database (https://`www.geonames.org`) using the Geographic Name Resolution Service (GNRS; `https://github.com/ojalaquellueva/gnrs.git`)

<a name="software"></a>
## Software

Ubuntu 16.04 or higher  
PostgreSQL/psql 12.2, or higher (PostGIS extension installed by this script)

<a name="dependencies"></a>
## Dependencies

Requires access to the GNRS (`https://github.com/ojalaquellueva/gnrs.git`) either as API or local batch service. Version in this repository uses the BIEN GNRS API (http://vegbiendev.nceas.ucsb.edu:8875/gnrs_ws.php).

<a name="permissions"></a>
## Permissions

This script must be run by a user with sudo and authorization to connect to postgres (as specified in `pg_hba` file). The admin-level and read-only Postgres users for the gadm database (specified in `params.sh`) should already exist and must be authorized to connect to postgres (as specified in pg_hba file).

<a name="installation-and-configuration"></a>
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

<a name="usage"></a>
## Usage

<a name="I-build-cds-db"></a>
### I. Build the CDS Database
See README in `cds_db/`.

<a name="II-cds-batch"></a>
### II. CDS batch application
* Processes file of geocoordinates in single batch

#### Syntax

```
./cds.sh -f <input_filename_and_path> [other options]
```

#### Options

Option | Meaning | Required? | Default value | 
------ | ------- | -------  | ---------- | 
-f     | Input file and path | Yes | |
-o     | Output file and path | No | [input\_file\_name]\_cds\_results.csv | 
-s     | Silent mode | No | Verbose/interactive mode by default |
-m     | Send notification message at start and completion, or on fail | No (must be followed by valid email if included) | 

#### Example:

```
./cds.sh -f myfile.csv -m bboyle@email.arizona.edu
```

<a name="II-cds-parallel"></a>
### III. CDS parallel processing application
* Processes file of geocoordinates in parallel mode (multiple batches)
* If you get a permission error, try running as sudo

#### Syntax

```
./cdspar.pl -in <input_filename_and_path> -out <output_filename_and_path> -nbatch <batches> -opt <makeflow_options>
```

#### Options

Option | Meaning | Required? | Default value | 
------ | ------- | -------  | ---------- | 
-in     | Input file and path | Yes | |
-out     | Output file and path | No | [input\_file\_name]\_cds\_results.csv | 
-nbatch     | Number of batches | Yes |  |
-opt     | Makeflow options | No | 

#### Example:

```
./cdspar.pl -in "data/cds_testfile.csv" -nbatch 3
```
