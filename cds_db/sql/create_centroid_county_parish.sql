-- -----------------------------------------------------------------
-- Create table of counties (county_parish) and their centroids
-- -----------------------------------------------------------------

-- Create table
DROP TABLE IF EXISTS centroid_county_parish;
CREATE TABLE centroid_county_parish (
id bigserial not null primary key,
gid_0 text,
country text,
gid_1 text,
state_province text,
gid_2 text,
county_parish text,
geom geometry
);

-- Insert country polygons
INSERT INTO centroid_county_parish (
gid_0,
country,
gid_1,
state_province,
gid_2,
county_parish,
geom
)
SELECT 
gid_0,
name_0,
gid_1,
name_1,
gid_2,
name_2,
ST_Union(geom)
FROM gadm
WHERE name_2 IS NOT NULL
GROUP BY gid_0, name_0, gid_1, name_1, gid_2, name_2
;

/*
Regular centroid
For calculation of additional centroid types using ST_PointOnSurface
and ST_GeometricMedian, see https://postgis.net/docs/ST_Centroid.html
Also, consider using geography column instead
*/
ALTER TABLE centroid_county_parish
ADD COLUMN centroid geometry(Point,4326)
;

UPDATE centroid_county_parish
SET centroid=ST_Centroid(geom)
;

/*
Point-on-surface centroid
Guaranteed to be inside polygon
But: not sure how handles multipolygons.
See https://postgis.net/docs/ST_Centroid.html
*/
ALTER TABLE centroid_county_parish
ADD COLUMN centroid_pos geometry(Point,4326)
;

UPDATE centroid_county_parish
SET centroid_pos=ST_PointOnSurface(geom)
;

/*
Convenience decimal lat & long columns for each centroid type
*/
ALTER TABLE centroid_county_parish
ADD COLUMN centroid_lat NUMERIC(11, 8),
ADD COLUMN centroid_long NUMERIC(11, 8),
ADD COLUMN centroid_pos_lat NUMERIC(11, 8),
ADD COLUMN centroid_pos_long NUMERIC(11, 8)
;

UPDATE centroid_county_parish
SET
centroid_lat=ST_Y(centroid),
centroid_long=ST_X(centroid),
centroid_pos_lat=ST_Y(centroid_pos),
centroid_pos_long=ST_X(centroid_pos)
;

