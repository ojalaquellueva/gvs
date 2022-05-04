-- -----------------------------------------------------------------
-- Creates core tables other than gadm
-- -----------------------------------------------------------------

DROP TABLE IF EXISTS meta;
CREATE TABLE meta (
db_version text DEFAULT NULL,
code_version text DEFAULT NULL,
build_date date
);

DROP TABLE IF EXISTS centroid_country;
CREATE TABLE centroid_country (
id bigserial not null primary key,
gid_0 text,
country text,
geom geometry(Geometry,4326),
geog geography,
centroid geometry(Point,4326),
centroid_pos geometry(Point,4326),
centroid_bb geometry(Point,4326),
centroid_main geometry(Point,4326),
centroid_main_pos geometry(Point,4326),
centroid_main_bb geometry(Point,4326),
cent_dist_max numeric DEFAULT NULL,
cent_pos_dist_max numeric DEFAULT NULL,
cent_bb_dist_max numeric DEFAULT NULL,
cent_main_dist_max numeric DEFAULT NULL,
cent_main_pos_dist_max numeric DEFAULT NULL,
cent_main_bb_dist_max numeric DEFAULT NULL
);

DROP TABLE IF EXISTS centroid_subpoly;
CREATE TABLE centroid_subpoly (
id bigserial not null primary key,
gid_0 text,
country text,
geom geometry(Geometry,4326),
geog geography,
centroid geometry(Point,4326),
centroid_pos geometry(Point,4326),
centroid_bb geometry(Point,4326),
cent_dist_max numeric DEFAULT NULL,
cent_pos_dist_max numeric DEFAULT NULL,
cent_bb_dist_max numeric DEFAULT NULL
);

DROP TABLE IF EXISTS centroid_state_province;
CREATE TABLE centroid_state_province (
id bigserial not null primary key,
gid_0 text,
country text,
gid_1 text,
state_province text,
geom geometry(Geometry,4326),
geog geography,
centroid geometry(Point,4326),
centroid_pos geometry(Point,4326),
centroid_bb geometry(Point,4326),
centroid_main geometry(Point,4326),
centroid_main_pos geometry(Point,4326),
centroid_main_bb geometry(Point,4326),
cent_dist_max numeric DEFAULT NULL,
cent_pos_dist_max numeric DEFAULT NULL,
cent_bb_dist_max numeric DEFAULT NULL,
cent_main_dist_max numeric DEFAULT NULL,
cent_main_pos_dist_max numeric DEFAULT NULL,
cent_main_bb_dist_max numeric DEFAULT NULL
);

DROP TABLE IF EXISTS centroid_county_parish;
CREATE TABLE centroid_county_parish (
id bigserial not null primary key,
gid_0 text,
country text,
gid_1 text,
state_province text,
gid_2 text,
county_parish text,
geom geometry(Geometry,4326),
geog geography,
centroid geometry(Point,4326),
centroid_pos geometry(Point,4326),
centroid_bb geometry(Point,4326),
centroid_main geometry(Point,4326),
centroid_main_pos geometry(Point,4326),
centroid_main_bb geometry(Point,4326),
cent_dist_max numeric DEFAULT NULL,
cent_pos_dist_max numeric DEFAULT NULL,
cent_bb_dist_max numeric DEFAULT NULL,
cent_main_dist_max numeric DEFAULT NULL,
cent_main_pos_dist_max numeric DEFAULT NULL,
cent_main_bb_dist_max numeric DEFAULT NULL
);

DROP TABLE IF EXISTS user_data_raw;
CREATE TABLE user_data_raw (
job text DEFAULT NULL,
latitude text DEFAULT NULL,
longitude text DEFAULT NULL,
user_id text DEFAULT NULL
);

-- Remove testing columns when done
DROP TABLE IF EXISTS user_data;
CREATE TABLE user_data (
id BIGSERIAL NOT NULL PRIMARY KEY,
job text DEFAULT NULL,
date_created TIMESTAMP WITH TIME ZONE,
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
country_cent_dist_max numeric DEFAULT NULL,
is_country_centroid smallint DEFAULT NULL, 
state_cent_dist numeric DEFAULT NULL,
state_cent_dist_relative numeric DEFAULT NULL,
state_cent_type text DEFAULT NULL,
state_cent_dist_max numeric DEFAULT NULL,
is_state_centroid smallint DEFAULT NULL, 
county_cent_dist numeric DEFAULT NULL,
county_cent_dist_relative numeric DEFAULT NULL,
county_cent_type text DEFAULT NULL,
county_cent_dist_max numeric DEFAULT NULL,
is_county_centroid smallint DEFAULT NULL, 
subpoly_cent_dist numeric DEFAULT NULL,
subpoly_cent_dist_relative numeric DEFAULT NULL,
subpoly_cent_type text DEFAULT NULL,
subpoly_cent_dist_max numeric DEFAULT NULL,
is_subpoly_centroid smallint DEFAULT NULL, 
centroid_dist_km numeric DEFAULT NULL,
centroid_dist_relative numeric DEFAULT NULL,
centroid_type text DEFAULT NULL,
centroid_dist_max_km numeric DEFAULT NULL,
centroid_poldiv text DEFAULT NULL,
max_dist integer DEFAULT NULL,
max_dist_rel numeric DEFAULT NULL,
latlong_err text DEFAULT NULL,
coordinate_decimal_places smallint DEFAULT NULL,
coordinate_inherent_uncertainty_m numeric DEFAULT NULL,
geog GEOGRAPHY(Point)
) 
;
-- Add the wgs84 point geometry column, including constraints
-- See: https://postgis.net/docs/AddGeometryColumn.html
-- Also: https://gis.stackexchange.com/questions/8699/creating-spatial-tables-with-postgis
SELECT AddGeometryColumn ('public','user_data','geom',4326,'POINT',2, false);

--
-- Add indexes
--


-- Non-spatial indexes
CREATE INDEX user_data_job_idx ON user_data USING btree (job);
CREATE INDEX user_data_gid_0_idx ON user_data USING btree (gid_0);
CREATE INDEX user_data_gid_1_idx ON user_data USING btree (gid_1);
CREATE INDEX user_data_gid_2_idx ON user_data USING btree (gid_2);
CREATE INDEX user_data_date_created_idx ON user_data USING btree (date_created);

-- Spatial index
CREATE INDEX user_data_geom_idx ON user_data USING GIST (geom);
CREATE INDEX user_data_geog_idx ON user_data USING GIST (geog);
