# Build CDS Database

Author: Brad Boyle (bboyle@email.arizona.edu)  

## Contents

[Overview](#overview)  
[Software](#software)  
[Dependencies](#dependencies)  
[Usage](#usage)  

<a name="overview"></a>
## Overview

Builds PostgreSQL database used by CDS (Centroid Detections Service). Political divisions spatial object from Global Admininstrative Division Database (GADM; `https://gadm.org`) with political division names standardized against the geonames database (https://`www.geonames.org`) using the Geographic Name Resolution Service (GNRS; `https://github.com/ojalaquellueva/gnrs.git`)

<a name="software"></a>
## Software

Ubuntu 16.04 or higher  
PostgreSQL/psql 12.2, or higher (PostGIS extension installed by this script)

<a name="dependencies"></a>
## Dependencies

* Access to GNRS (`https://github.com/ojalaquellueva/gnrs.git`) either as API or local batch service. Version in this repository uses the BIEN GNRS API (http://vegbiendev.nceas.ucsb.edu:8875/gnrs_ws.php).
* Access to the GNRS (`https://github.com/ojalaquellueva/gnrs.git`) either as API or local batch service. Version in this repository uses the BIEN GNRS API (http://vegbiendev.nceas.ucsb.edu:8875/gnrs_ws.php).
* Global Admininstrative Division Database (https://gadm.org)
* Geonames (https://www.geonames.org).

<a name="usage"></a>
## Usage

### Prepare


### Run

```
./cds_db.sh [options]
```

#### Options
-m: Send notification emails  
-n: Non-interactive: suppress confirmations but not progress messages  
-s: Silent mode: suppress all confirmations & progress messages  

#### Example:

```
./cds_db.sh -m -s
```
* Runs silently without terminal echo
* Sends notification message at start and completion




