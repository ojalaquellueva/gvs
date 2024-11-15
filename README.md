# Geocordinate Validation Service (GVS)

Author: Brad Boyle (bboyle@email.arizona.edu)  

## Contents

- [Overview](#overview)  
- [Installation and configuration](#installation-and-configuration)  
  * [Software](#software)  
  * [Dependencies](#dependencies)  
  * [Permissions](#permissions)  
  * [Setup](#setup)  
- [Input](#input)  
  * [Raw data](#rawdata)  
  * [Input format](#format)  
- [Output](#output)  
  * [Data dictionary](#dict)  
  * [Constrained values](#values)  
- [Usage](#usage):  
  * [Build the GSV Database ](#build-gvs-db)  
  * [GVS batch application](#gvs-batch)  
  * [GVS parallel processing application](#gvs-parallel)
- [Interfaces](#interfaces):  
  * [API](#api)  
  * [GVS R package](#rgvs)  
  * [GVS web interface](#gvsweb)  

<a name="overview"></a>
## Overview

The Geocoordinate Validation Service (GVS) performs quality checks on decimal geocoordinates (georeferenced points represented as pairs of decimal latitude and longitude values). In addition to detecting common georeferencing errors, the GVS calculates the probability that a given point represents a political division centroid, as opposed to a directly measured point on the Earth's surface. The GVS also returns the country, state- and country-level political divisions in which the point is located. Political divisions are determined with reference to the GADM database of world administrative divisions (Global Admininstrative Divisions; https://gadm.org). For an online interface to the GVS, see https://gvs.biendata.org/.

Information returned by the GVS includes:
* Estimate of inherent precision implied by the number of decimals places in the original coordinates
* Brief descriptions of the types errors detected (e.g., "Coordinates our of range")
* Flagging of points in the ocean
* Names and GADM identifiers of the admin_0, admin_1 and admin_2 political divisions (e.g., country, state, county) in which a point is located
* Absolute and relative distance to the centroid of each political division (see full list of output fields below)
* Probability that the point is a centroid, and, if applicable, the type of centroid and political division (country, state or county) of the likeliest centroid.
* Flagging of points with a high probability of being a centroid, above a certain threshold (threshold can be adjusted by user)

This service may be used in combination with the BIEN Geographic Name Resolution Service (GNRS; `https://github.com/ojalaquellueva/gnrs.git`) to perform "political geovalidation" of georeferenced biodiversity observations. Political geovalidation checks if all detected political divisions (i.e., the country, state and county polygons in which the coordinates are located) match the declared political divisions (country, state and county names) of the original observation record. Operationally, this validation can be performed by checking that the GADM administrative division identifiers returned by the GVS match the GADM identifiers returned by the GNRS.

**GVS, CDS...what's the difference?**

The GVS was previously developed under the name CVS (Centroid Detection Service) as an application for the detection of political division centroids. It has been renamed to reflect the wider range of features currently available. 

<a name="installation-and-configuration"></a>
## Installation and configuration

<a name="software"></a>
### Software

Ubuntu 16.04 or higher  
PostgreSQL/psql 10 or higher (PostGIS extension installed by this script)

<a name="dependencies"></a>
### Dependencies

Requires access to the GNRS (`https://github.com/ojalaquellueva/gnrs.git`) either as API or local batch service. Version in this repository uses the BIEN GNRS API (http://vegbiendev.nceas.ucsb.edu:8875/gnrs_ws.php).

<a name="permissions"></a>
### Permissions

This script must be run by a user with authorization to connect to postgres (as specified in `pg_hba` file). The admin-level and read-only Postgres users for the gadm database (specified in `params.sh`) should already exist and must be authorized to connect to postgres (as specified in pg_hba file).

<a name="setup"></a>
### Recommended setup

```
# Create application base directory
mkdir -p gvs
cd gvs

# Create application code directory
mkdir src

# Install application code from repository
cd src
git clone https://github.com/ojalaquellueva/gvs

# Move data and sensitive parameters directories outside of code directory
mv data ../
mv config ../
```

### Installation notes

* After moving the config directory:
   * Rename all config files by removing "example" from file names
   * Set all passwords, paths and other parameter values in the config files
* The temporary application data directory `/tmp/gvs` is now installed on the fly by the application. You no longer need to install it manually.

<a name="input"></a>
## Input data

<a name="rawdata"></a>
### Raw data
Raw data for the CSV is one or more pairs of coordinates in decimal format, separated by a single comma, with latitude first. E.g., 

```
latitude,longitude
36.580435,-96.53331
39.8081822436996,-91.6228915663878
46.0,25.0
52.92755,4.7864
-23.62,-65.43
-29.178651024973867,149.269218
-29.231478025060987,152.13519
51.81171,-3.8879
```

<a name="format"></a>
### Format

Data are submitted to the GVS via the shell command line as a CSV (comma delimitted) text file, formatted as above in [Input](#input). Data submitted via the API or GVS R package must be converted to JSON and attached to the body of a POST request (see API documentation in this repository, and the separate RCDS (=GVS) repository https://github.com/EnquistLab/RCDS). 

<a name="output"></a>
## Output

<a name="dict"></a>
### Data dictionary

Field name | Meaning | Data type | Constrained values | Can be NULL? | Notes
:--------- | :------ | :-------- | :----------------- | :----------: | :----
id | Unique identifier | Integer |  | No | Assigned by GVS
latlong\_verbatim | Coordinates submitted | Text |  |  | Coordinate pair exactly as submitted
latitude\_verbatim | Latitude submitted | Text |  |  | Latitude portion only
longitude\_verbatim | Longitude submitted | Text |  |  | Latitude portion only
latitude | Latitude extracted from input | Decimal |  |  | Decimal latitude to original number of decimal places
longitude | Longitude extracted from input | Decimal |  |  | Decimal longitude to original number of decimal places
country | Country in which point located | Text |  |  | 
state | State/province in which point located | Text |  |  | 
county | County/parish in which point located | Text |  |  | 
gid\_0 | GADM identier of country | Text |  |  | 
gid\_1 | GADM identier of state/province | Text |  |  | 
gid\_2 | GADM identier of county/parish | Text |  |  | 
country\_cent\_dist | Distance in km to country centroid | Decimal |  |  | 
country\_cent\_dist\_relative | Relative distance to country centroid | Decimal |  |  | country\_cent\_dist / country\_cent\_dist\_max
country\_cent\_type | Type of centroid | Text | bb, bb\_main, pos, pos\_main, std, std\_main* | Yes | 
country\_cent\_dist\_max | Maximum distance to centroid within country | Decimal |  |  | Distance from centroid to farthest point along political division perimeter.
is\_country\_centroid | Is point likely a country centroid? | Integer | 1 | Yes | Equals 1 (yes) if country\_cent\_dist\_relative < max\_dist\_rel 
state\_cent\_dist | Distance in km to state centroid | Decimal |  |  | 
state\_cent\_dist\_relative | Relative distance to state centroid | Decimal |  |  | state\_cent\_dist / state\_cent\_dist\_max
state\_cent\_type | Type of centroid | Text | bb, bb\_main, pos, pos\_main, std, std\_main* | Yes | 
state\_cent\_dist\_max | Maximum possible distance to centroid within state | Decimal |  |  | Distance from centroid to farthest point along political division perimeter.
is\_state\_centroid | Is point likely a state centroid? | Integer | 1 | Yes | Equals 1 (yes) if state\_cent\_dist\_relative < max\_dist\_rel 
county\_cent\_dist | Distance in km to county centroid | Decimal |  |  | 
county\_cent\_dist\_relative | Relative distance to county centroid | Decimal |  |  | county\_cent\_dist / county\_cent\_dist\_max
county\_cent\_type | Type of centroid | Text | bb, bb\_main, pos, pos\_main, std, std\_main* | Yes | 
county\_cent\_dist\_max | Maximum possible distance to centroid within county | Decimal |  |  | Distance from centroid to farthest point along political division perimeter.
is\_county\_centroid | Is point likely a county centroid? | Integer | 1 | Yes | Equals 1 (yes) if county\_cent\_dist\_relative < max\_dist\_rel 
subpoly\_cent\_dist | Distance in km to country subpolygon centroid | Decimal |  |  | Smallest distance to a spatially separate country subpolygon, such as an offshore island.
subpoly\_cent\_dist\_relative | Relative distance to country subpolygon centroid | Decimal |  |  | subpoly\_cent\_dist / subpoly\_cent\_dist\_max
subpoly\_cent\_type | Type of centroid | Text | bb, pos, std* | Yes | 
subpoly\_cent\_dist\_max | Maximum distance to centroid within country subpolygon | Decimal |  |  | Distance from centroid to farthest point along  subpolygon perimeter.
is\_subpoly\_centroid | Is point likely a country  subpolygon centroid? | Integer | 1 | Yes | Equals 1 (yes) if subpoly\_cent\_dist\_relative < max\_dist\_rel 
centroid\_dist\_km | Distance in km to consensus centroid, if any | Decimal |  |  | This and the other "centroid\_" fields only populated if country, state, county or subpolygon is flagged as a likely centroid. 
centroid\_dist\_relative | Relative distance to consensus centroid | Decimal |  |  | 
centroid\_type | Type of centroid | Text | bb, bb\_main, pos, pos\_main, std, std\_main* | Yes | 
centroid\_dist\_max\_km | Maximum distance to centroid within political division of consensus centroid | Decimal |  |  | 
centroid\_poldiv | Most likely (consensus) centroid, if any | Text | country, county, state, other | Yes | other=separate subpolygon other than a political division (e.g., island)
max\_dist\_rel | Maximum relative distance threshold | Decimal |  | No | Parameter, can be set by user. Default=0.002
latlong\_err | Points out of range or in ocean | Text | "Coordinates non-numeric", "Coordinate values out of bounds", "One or more missing coordinates", "In ocean" | Yes | NULL if no errors detected
coordinate\_decimal\_places | Smallest number of decimal places detected in verbatim latitude and longitude | Integer |  |  | Up to 14 decimal places detected
coordinate\_inherent\_uncertainty\_m | Inherent uncertainty in km due to decimal places used | Decimal |  |  | Difference in radius between the smallest and largest circles centered on point and consistent with decimal places used.
user\_id | Optional user-supplied identifier | Text |  |  | May be any value or none. Not used by GVS.

`* See Constrained Values`

<a name="values"></a>
### Constrained values

Category | Value | Meaning | Notes
:------- | :---- | :------ | :----
Centroid type | bb | Bounding box | 
Centroid type | bb\_main | Bounding box, largest subpolygon | Same as bb if only one polygon
Centroid type | pos | Point on surface | Centroid guaranteed inside perimeter for irregularly-shaped polygons
Centroid type | pos\_main | Point on surface, largest subpolygon | Same as std if only one polygon
Centroid type | std | Standard centroid-of-mass | May fall outside perimeter of irregularly-shaped polygons
Centroid type | std\_main | Standard centroid-of-mass, largest subpolygon | Same as std if only one polygon
latlong\_error | Coordinates non-numeric | Latitude or longitude not a decimal number | 
latlong\_error | Coordinate values out of bounds | Latitude out of range [-90:90] or longitude out of range [-180:180] | 
latlong\_error | One or more missing coordinates | Latitude or longitude or both are missing | 
latlong\_error | In ocean | Point in ocean | 

<a name="usage"></a>
## Usage

<a name="build-gvs-db"></a>
### Build the GVS Database
See README in `gvs_db/`.

<a name="gvs-batch"></a>
### GVS batch application
* Processes file of geocoordinates in single batch

#### Syntax

```
./gvs.sh -f <input_filename_and_path> [other options]
```

#### Options

Option | Meaning | Required? | Default value | 
------ | ------- | -------  | ---------- | 
-f     | Input file and path | Yes | |
-o     | Output file and path | No | [input\_file\_name]\_gvs\_results.csv | 
-s     | Silent mode | No | Verbose/interactive mode by default |
-m     | Send notification message at start and completion, or on fail | No (must be followed by valid email if included) | 

#### Example:

```
./gvs.sh -f myfile.csv -m bboyle@email.arizona.edu
```

<a name="gvs-parallel"></a>
### GVS parallel processing application
* Processes file of geocoordinates in parallel mode (multiple batches)
* If you get a permission error, try running as sudo

#### Syntax

```
./gvspar.pl -in <input_filename_and_path> -out <output_filename_and_path> -nbatch <batches> -opt <makeflow_options>
```

#### Options

Option | Meaning | Required? | Default value | 
------ | ------- | -------  | ---------- | 
-in     | Input file and path | Yes | |
-out     | Output file and path | No | [input\_file\_name]\_gvs\_results.csv | 
-nbatch     | Number of batches | Yes |  |
-opt     | Makeflow options | No | 

#### Example:
* On some operating system configurations you may need to run using sudo to enable access to temp folder `/tmp/gvs`, especially if this directory doesn't exist (in which case, the application will attempt to create it). Test first without sudo.

```
./gvspar.pl -in "data/gvs_testfile.csv" -nbatch 3
```

<a name="interfaces"></a>
## GVS interfaces

<a name="api"></a>
### GVS API

#### General documentation

See `https://github.com/ojalaquellueva/gvs/tree/master/api#readme`. 

#### Example API usage in R

https://github.com/ojalaquellueva/gvs/blob/master/api/example_scripts/gvs_api_example.R`

<a name="rgvs"></a>
### GVS R package
https://github.com/EnquistLab/RCDS 

*  Note: The GVS R package is currently called "RCDS"

<a name="gvsweb"></a>
### GVS graphical user interface
***Web:*** https://gvs.biendata.org`  
***Repository:*** https://github.com/EnquistLab/GVSweb  

