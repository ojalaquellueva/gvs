-- -----------------------------------------------------------------
-- Creates all remaining tables not derived from geonames
-- -----------------------------------------------------------------

DROP TABLE IF EXISTS meta;
CREATE TABLE meta (
db_version text DEFAULT NULL,
code_version text DEFAULT NULL,
build_date timestamp
);

DROP TABLE IF EXISTS user_data_raw;
CREATE TABLE user_data_raw (
latitude text DEFAULT NULL,
longitude text DEFAULT NULL,
user_id text DEFAULT NULL
);


DROP TABLE IF EXISTS user_data;
CREATE TABLE user_data (
id BIGSERIAL NOT NULL PRIMARY KEY,
job text DEFAULT NULL,
latitude_verbatim text DEFAULT NULL,
longitude_verbatim text DEFAULT NULL,
latitude numeric DEFAULT NULL,
longitude numeric DEFAULT NULL,
user_id text DEFAULT NULL,
gid_0 text DEFAULT NULL,
country text DEFAULT NULL,
gid_1 text DEFAULT NULL,
state text DEFAULT NULL,
gid_2 text DEFAULT NULL,
county text DEFAULT NULL,
country_cent_dist numeric DEFAULT NULL,
country_cent_dist_relative numeric DEFAULT NULL,
country_cent_type text DEFAULT NULL,
country_max_uncertainty numeric DEFAULT NULL,
state_cent_dist numeric DEFAULT NULL,
state_cent_dist_relative numeric DEFAULT NULL,
state_cent_type text DEFAULT NULL,
state_max_uncertainty numeric DEFAULT NULL,
county_cent_dist numeric DEFAULT NULL,
county_cent_dist_relative numeric DEFAULT NULL,
county_cent_type text DEFAULT NULL,
county_max_uncertainty numeric DEFAULT NULL,
is_centroid smallint DEFAULT NULL,
centroid_dist_relative numeric DEFAULT NULL,
centroid_poldiv text DEFAULT NULL,
centroid_type text DEFAULT NULL,
centroid_max_uncertainty numeric DEFAULT NULL,
latlong_err text DEFAULT NULL
) 
;
