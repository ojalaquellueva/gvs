-- -----------------------------------------------------------------
-- Create table of states (state_province) and their centroids
-- -----------------------------------------------------------------

-- Create table
DROP TABLE IF EXISTS centroid_state_province;
CREATE TABLE centroid_state_province (
id bigserial not null primary key,
gid_0 text,
country text,
gid_1 text,
state_province text,
geom geometry,
centroid geometry(Point,4326),
centroid_pos geometry(Point,4326),
centroid_bb geometry(Point,4326)
);

-- Insert country polygons
INSERT INTO centroid_state_province (
gid_0,
country,
gid_1,
state_province,
geom
)
SELECT 
gid_0,
name_0,
gid_1,
name_1,
ST_Union(geom)
FROM gadm
WHERE name_1 IS NOT NULL
GROUP BY gid_0, name_0, gid_1, name_1
;

/*
Regular centroid
For calculation of additional centroid types using ST_PointOnSurface
and ST_GeometricMedian, see https://postgis.net/docs/ST_Centroid.html
Also, consider using geography column instead
*/
UPDATE centroid_state_province
SET centroid=ST_Centroid(geom)
;

/*
Point-on-surface centroid
Guaranteed to be inside polygon
But: not sure how handles multipolygons.
See https://postgis.net/docs/ST_Centroid.html
*/
UPDATE centroid_state_province
SET centroid_pos=ST_PointOnSurface(geom)
;

/*
Bounding box centroid
*/
UPDATE centroid_state_province
SET centroid_bb=ST_Centroid(ST_Envelope(geom))
;

/*
Convenience decimal lat & long columns for each centroid type
*/
ALTER TABLE centroid_state_province
ADD COLUMN centroid_lat NUMERIC,
ADD COLUMN centroid_long NUMERIC,
ADD COLUMN centroid_pos_lat NUMERIC,
ADD COLUMN centroid_pos_long NUMERIC,
ADD COLUMN centroid_bb_lat NUMERIC,
ADD COLUMN centroid_bb_long NUMERIC
;

UPDATE centroid_state_province
SET
centroid_lat=ST_Y(centroid),
centroid_long=ST_X(centroid),
centroid_pos_lat=ST_Y(centroid_pos),
centroid_pos_long=ST_X(centroid_pos),
centroid_bb_lat=ST_Y(centroid_bb),
centroid_bb_long=ST_X(centroid_bb)
;
