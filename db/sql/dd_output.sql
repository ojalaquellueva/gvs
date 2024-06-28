-- -----------------------------------------------------------------
-- Create data dictionary of GVS output field definitions
-----------------------------------------------------------------

DROP TABLE IF EXISTS dd_output;
CREATE TABLE dd_output (
mode text not null,
col_name text not null,
ordinal_position integer not null,
data_type text default null,
description text default null,
PRIMARY KEY (mode, col_name)
);

INSERT INTO dd_output (mode, col_name, ordinal_position, data_type, description)
VALUES 
('resolve','id',1,'Integer','Unique sequential integer identifier, created by GVS'),
('resolve','latitude_verbatim',2,'Text','Verbatim latitude as submitted'),
('resolve','longitude_verbatim',3,'Text','Verbatim longitude as submitted'),
('resolve','latitude',4,'Floating-point numeric','Decimal latitude resolved by GVS'),
('resolve','longitude',5,'Floating-point numeric','Decimal longitude resolved by GVS'),
('resolve','user_id',6,'Text','User-provided identifier (optional)'),
('resolve','gid_0',7,'Text','GADM identifier of the country (admin 0)'),
('resolve','country',8,'Text','GADM country name'),
('resolve','gid_1',9,'Text','GADM identifier of the state/province (admin_1 political division)'),
('resolve','state',10,'Text','GADM state/province name'),
('resolve','gid_2',11,'Text','GADM identifier of the county/parish (admin_2 political division)'),
('resolve','county',12,'Text','GADM county/parish name'),
('resolve','country_cent_dist',13,'Floating-point numeric','Distance in km of the point from the country centroid'),
('resolve','country_cent_dist_relative',14,'Floating-point numeric','Distance of resolved point from centroid, relative to farthest point on country perimiter'),
('resolve','country_cent_type',15,'Text','Type of centroid'),
('resolve','country_cent_dist_max',16,'Floating-point numeric','Distance in km of the farthest possible point from the centroid, as measured along the country boundary.'),
('resolve','is_country_centroid',17,'Boolean (0|1) or NULL','Is the submitted point likely a country centroid? 1=Yes, NULL/blank=No.'),
('resolve','state_cent_dist',18,'Floating-point numeric','Distance in km of the point from the state centroid'),
('resolve','state_cent_dist_relative',19,'Floating-point numeric','Distance of resolved point from centroid, relative to farthest point on state perimiter'),
('resolve','state_cent_type',20,'Text','Type of centroid'),
('resolve','state_cent_dist_max',21,'Floating-point numeric','Distance in km of the farthest possible point from the centroid, as measured along the state boundary.'),
('resolve','is_state_centroid',22,'Boolean (0|1) or NULL','Is the submitted point likely a state centroid? 1=Yes, NULL/blank=No.'),
('resolve','county_cent_dist',23,'Floating-point numeric','Distance in km of the point from the county centroid'),
('resolve','county_cent_dist_relative',24,'Floating-point numeric','Distance of resolved point from centroid, relative to farthest point on county perimiter'),
('resolve','county_cent_type',25,'Text','Type of centroid'),
('resolve','county_cent_dist_max',26,'Floating-point numeric','Distance in km of the farthest possible point from the centroid, as measured along the county boundary.'),
('resolve','is_county_centroid',27,'Boolean (0|1) or NULL','Is the submitted point likely a county centroid? 1=Yes, NULL/blank=No.'),
('resolve','subpoly_cent_dist',28,'Floating-point numeric','Distance in km of the point from a subpolygon centroid, for countries consisting of discrete subpolygons, such as islands.'),
('resolve','subpoly_cent_dist_relative',29,'Floating-point numeric','Distance of resolved point from subpolygon centroid, relative to farthest point on the subpolygon perimiter'),
('resolve','subpoly_cent_type',30,'Text','Type of centroid'),
('resolve','subpoly_cent_dist_max',31,'Floating-point numeric','Distance in km of the farthest possible point from the centroid, as measured along the subpolygon boundary.'),
('resolve','is_subpoly_centroid',32,'Boolean (0|1) or NULL','Is the submitted point likely a subpolygon centroid? 1=Yes, NULL/blank=No.'),
('resolve','centroid_dist_km',33,'Floating-point numeric','Distance in km to the most likely centroid corresponding to the submitted point, if any'),
('resolve','centroid_dist_relative',34,'Floating-point numeric','Distance of resolved point from most likely centroid, relative to farthest point on political division perimiter'),
('resolve','centroid_type',35,'Text','Type of the most likely centroid corresponding to the submitted point, if any'),
('resolve','centroid_dist_max_km',36,'Floating-point numeric','Distance in km of the farthest possible point from the most likly centroid, as measured along the political division boundary.'),
('resolve','centroid_poldiv',37,'Text','Political division of the most likely centroid, if applicable'),
('resolve','max_dist',38,'Integer','Maximum absolute distance (km) to centroid for submitted point to qualify as centroid'),
('resolve','max_dist_rel',39,'Floating-point numeric','Maximum relative distance to centroid for submitted point to qualify as centroid (relative to distance from centroid to farthest point on political division boundary)'),
('resolve','latlong_err',40,'Text','Errors detected in submitted point, if any'),
('resolve','coordinate_decimal_places',41,'Integer','Number of decimal places of the submitted coordinates (lowest of the two values, if different)'),
('resolve','coordinate_inherent_uncertainty_m',42,'Floating-point numeric','Inherent uncertainty in m of the submitted geocoordinates, given the decimal places submitted.')
;

DROP INDEX IF EXISTS dd_output_col_name_idx;
CREATE INDEX dd_output_col_name_idx ON dd_output (col_name);
DROP INDEX IF EXISTS dd_output_mode_idx;
CREATE INDEX dd_output_mode_idx ON dd_output (mode);





