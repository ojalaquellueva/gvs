# Centroid Detection Service (CDS) API

## Contents

[Introduction](#introduction)  
[Dependencies](#dependencies)  
[Required OS and software](#software)  
[Setup & configuration](#setup)  
[Usage](#usage)  
[Example scripts](#examples)  
[Related applications](#related)  
[References](#references)  

<a name="introduction"></a>
## Introduction

The CDS API is an API wrapper for cds.sh, the master script of the Centroid Detection Service (CDS). 

The CDS accepts a point of observation (PO; pair of latitude, longitude coordinates in decimal degrees) and returns the country, state and county in which the point is located, and calculates the distance between the OP the six different types of centroids for each of the three political divisions (see [Centroid Types](#centroid_types)) and indicates for each distance if it is small enough for the OP itself to potentially be a centroid (see [Distance Thresholds](#thresholds). Finally, the CDS indicates which of the the potential PO centroids is the most likely, if any, based on distance to the centroid (DC) and the relative distance (DC / DC.max, the distance from the centroid to the farthest possible point within the political division). In addition, the CDS validates the submitted coordinates and reports errors such as non-numeric values and values out of bounds. Valid coordinates which do not join to any political division are flagged as "Point in ocean".

The CDS API accept comma separate pairs of latitude and longitude in decimal degrees. It can submit multiple coordinates at once, with each pair of coordinates on its own line. Optionally, the user can include a final, third value on each line (for example, a unique ID to simplify joining the API response rows back to the original dataset. Each request is sent to the API as a POST, with options and data included in the request body as JSON.

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
| meta | Return application metadata | 


<a name="examples"></a>
## Example scripts

#### PHP

Example syntax for interacting with API using php\_curl is given in `cds_api_example.php`. To run the test script:

```
php cds_api_example.php
```
* Adjust parameters as desired in file `params.php`
* Also see API parameters section at start of `cds_api_example.php `
* For CDS options and defaults, see `params.php`
* Make sure that input file (`cds_testfile.csv`) is available in `$DATADIR` (as set in `params.php`)

#### R

* See example script `cds_api_example.R`. 
* Make sure that input file (`cds_testfile.csv`) is available in the same directory as the R script, or adjust file path in the R code.

<a name="centroid_types"></a>
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
