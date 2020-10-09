# Centroid Detection Service (CDS) API

## Contents

[Introduction](#introduction)  
[Dependencies](#dependencies)  
[Required OS and software](#software)  
[Setup & configuration](#setup)  
[Usage](#usage)  
[Example scripts](#examples)  
[Centroid types](#centroid-types)  
[Centroid thresholds](#thresholds)  
[Raw input](#input)  
[Output & definitions](#output)  

<a name="introduction"></a>
## Introduction

The CDS API is an API wrapper for cds.sh, the master script of the Centroid Detection Service (CDS). 

The CDS accepts a point of observation (PO; pair of latitude, longitude coordinates in decimal degrees) and returns the country, state and county in which the point is located. It also calculates the distance between the OP and six different types of centroids for each of the three political divisions (see [Centroid Types](#centroid_types)) and indicates for each political division if it is small enough for the OP itself to potentially be a centroid (see [Distance Thresholds](#thresholds). Finally, the CDS indicates which of the three potential political division centroids is the most likely, if any, based on the threshold parameter MAX\_DIST (distance to the actual centroid) and MAX\_DIST_REL (relative distance: distance to actual centroid / distance from actual centroid to the farthest point in the political division). In addition, the CDS validates the submitted coordinates and reports errors such as non-numeric values and values out of bounds. Valid coordinates which do not join to any political division are flagged as "Point in ocean".

The CDS API accept comma separate pairs of latitude and longitude in decimal degrees. It accepts multiple coordinates at once, with each pair of coordinates on its own line. Each request is sent to the API as a POST, with options and data included in the request body as JSON.

In addition to the coordinate resolution, the CDS offers metadata responses describing current code and database versions, and formatted acknowledgements and citations.


<a name="dependencies"></a>
## Dependencies
* **GADM**

<a name="software"></a>
## Required OS and software
* Ubuntu 18.04.2 LTS 
* Perl 5.26.1
* PHP 7.2.19
* PostgreSQL 10.14
* PostGIS 2.5.5
* Apache 2.4.29
* Makeflow 4.0.0 (released 02/06/2018)
(Not tested on earlier versions)

PHP extensions:
  * php-cli
  * php-mbstring
  * php-curl
  * php-xml
  * php-json
  * php-services-json


<a name="usage"></a>
## Usage

#### Input data

Input data should be organized as a UTF-8 CSV file with one pair of coordinates per line, separated by a single comma. Optionally, a header may be included; it will be ignored.
> 
latitude,longitude  
36.580435,-96.53331  
39.8081822436996,-91.6228915663878  
46.0,25.0  
52.92755,4.7864  
52.54731,-2.49544  
-23.62,-65.43  
    
Input data must be converted to JSON and combined as element "data" with the CDS options (element "opts"; see Options, below). The combined JSON object is sent to the API as POST data in the request body. The scripts below provide examples of how to do this in PHP and R. 

#### Options

The API accepts the following CDS options, which must be converted to JSON and combined as element "opts" along with the data (element "data") in the request body POST data.


| Mode | Meaning | Notes |
| ------ | ------- |  -----|
| resolve | Resolve coordinates | 
| maxdist | Set threshold parameter MAX\_DIST | Maximum distance in km from actual centroid to quality as centroid. Uses default value (in params.sh) if not set.
| maxdistrel | Set threshold parameter MAX\_DIST_REL | Maximum relative distance: distance from actual centroid divided by distance from centroid to farthes point in political division. Uses default value if not set.
| meta | Return application metadata | Code version, database version and build date.

<a name="examples"></a>
## Example scripts

#### PHP

Example syntax for interacting with API using php\_curl is given in `cds_api_example.php`. To run the test script:

```
php cds_api_example.php
```
* Set parameters directly in script; no command line parameters
* Also see API parameters section at start of `cds_api_example.php `
* For CDS options and defaults, see `params.php`
* Make sure that input file (`cds_testfile.csv`) is available in `$DATADIR` (as set in `params.php`)

#### R

* See example script `cds_api_example.R`. 
* Make sure that input file (`cds_testfile.csv`) is available in the same directory as the R script, or adjust file path in the R code.

<a name="centroid-types"></a>
## Centroid types

| Abbreviation | Meaning | Notes |
| ------ | ---------- | -------- |
| centroid | Regular geometric centroid | Geometric center of polgon. May fall outside all polygon for multipolygons  
| centroid_pos | Point-on-surface | Guaranteed to fall within polygon, even for irregular shapes  
| centroid_bb | Bounding box centroid | Geometric centroid of minimum bounding box fit to polygon or set of multipolgons  
| centroid_main | Regular geometric centroid of main polygon | Centroid of largest polygon for multipolygons; synonymous with centroid for simple polygons  
| centroid_main_pos | Point-on-surface centroid of main polygon | POS centroid of largest polygon for multipolygons; synonymous with centroid_pos for simple polygons  
| centroid_main_bb | Bounding box centroid of main polygon | BBox centroid of largest polygon for multipolygons; synonymous with centroid_bb for simple polygons  

<a name="thresholds"></a>
## Centroid thresholds

The following are the thresholds for a point of observation (PO) to qualify as a "likely centroid"

| Parameter | Full name | Value | Meaning |
| ------ | ----- | ---------- | -------- |
| MAX\_DIST | Maximum distance to centroid | 5.0 | Maximum distance in km from actual centroid
| MAX\_DIST\_REL | Relative maximum distance to centroid | 0.01 | Maximum value of distance from cetroid to PO and centroid to farthest possible point in polygon  

<a name="input"></a>
## Raw input

Raw input is a plain text file of decimal coordinates (latitude first, then longitude, comma separated), with one pair of coordinate per line, as shown below. If you include a header, it will be treated as invalid coordinate values, with latlong_err="Coordinates non-numeric". 

> 36.580435, -96.53331   
39.80818224, -91.62289157   
52.92755, 4.7864   
52.54731, -2.49544   
-23.62, -65.43   
-29.17865102, 149.269218   
-29.23147803, 152.13519   
51.81171, -3.8879   

<a name="output"></a>
## Output & definitions

Below is a list of fields returned by the API and their definitions. GADM: Global administrative Divisions )https://gadm.org/).

| Field  | Definition | Units (if applicable)
| ------ | ---- | ----------
| id | Unique integer ID, assigned by CDS |  
| latitude_verbatim | Verbatim latitude, as submitted |  
| longitude_verbatim | Verbatim longitude, as submitted |  
| latitude | Decimal latitude |  
| longitude | Decimal longitude |  
| user_id | (internal use) |  
| gid_0 | GADM ID of country |  
| country | GADM name of country |  
| gid_1 | GADM ID of state |  
| state | GADM name of state |  
| gid_2 | GADM ID of county |  
| county | GADM name of country |  
| country\_cent\_dist | Distance to closest country centroid |  km
| country\_cent\_dist\_relative | Distance from centroid to observation, relative to distance from centroid to farther point in country |  
| country\_cent\_type | Centroid type |  
| country\_cent\_dist\_max | Distance from centroid to farther point in country |  km
| is\_country_centroid | Do coordinates fall within likely centroid thresholds? |  
| state\_cent_dist | Distance to closest state centroid |  km 
| state\_cent\_dist\_relative | Distance from centroid to observation, relative to distance from centroid to farther point in state |  
| state\_cent_type | Centroid type |  
| state\_cent\_dist_max | Distance from centroid to farther point in country |  km
| is\_state_centroid | Do coordinates fall within likely centroid thresholds? |  
| county\_cent_dist | Distance to closest county centroid |  km 
| county\_cent\_dist_relative | Distance from centroid to observation, relative to distance from centroid to farther point in county |  
| county\_cent_type | Centroid type  |  
| county\_cent\_dist_max | Distance from centroid to farther point in country |  km
| is\_county\_centroid | Do coordinates fall within likely centroid thresholds? |  
| centroid\_dist\_km | Distance to centroid of most likely political division centroid (i.e., where is\_[poldiv]\_centroid=1 |  km 
| centroid\_dist\_relative | Distance from centroid to observation, relative to distance from centroid to farther point in political division, of most likely political division centroid |  
| centroid\_type | Centroid type, of most likely political division centroid |  
| centroid\_dist\_max\_km | Distance from centroid to farther point in political division, of most likely political division centroid |  km
| centroid\_poldiv | Political division type of most likely political division centroid |  
| max_dist | Threshold parameter MAX\_DIST. Maximum distance in km from actual centroid to quality as likely centroid | km
| max\_dist_rel  | Threshold parameter MAX\_DIST_REL. Relative maximum distance to quality as centroid (distance to centroid divided by distance from centroid to farthest possible point in polygon) | 
| latlong\_err | Type of error of invalid coordinates |  
| coordinate\_decimal\_places | Minimum decimal places of the verbatim lat, long values |  
| coordinate\_inherent\_uncertainty\_m | Inherent uncertainty of the coordinates, due to the number of decimal places used |  m

