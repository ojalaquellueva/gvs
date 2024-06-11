-- -----------------------------------------------------------------
-- Populate table of countries and their centroids
-- -----------------------------------------------------------------

-- Insert country polygons
-- This takes a LONG time!
INSERT INTO centroid_country (
gid_0,
country,
geom
)
SELECT 
gid_0,
name_0,
ST_Union(geom)
FROM gadm
GROUP BY gid_0, name_0
;

-- Populate the geography column
UPDATE centroid_country
SET geog=Geography(ST_Transform(geom,4326))
WHERE geom IS NOT NULL
;

--
-- Centroids of entire geometry
-- 

/*
Regular centroid
For calculation of additional centroid types using ST_PointOnSurface
and ST_GeometricMedian, see https://postgis.net/docs/ST_Centroid.html
Also, consider using geography column instead
*/
UPDATE centroid_country
SET centroid=ST_Centroid(geom)
;

/*
Point-on-surface centroid
Guaranteed to be inside polygon
But: not sure how handles multipolygons.
See https://postgis.net/docs/ST_Centroid.html
*/
UPDATE centroid_country
SET centroid_pos=ST_PointOnSurface(geom)
;

/*
Bounding box centroid
*/
UPDATE centroid_country
SET centroid_bb=ST_Centroid(ST_Envelope(geom))
;

--
-- Centroids of largest polygon
-- 

-- Standard centroid
UPDATE centroid_country a
SET centroid_main=b.geom
FROM
(
WITH geoms AS (
    SELECT country, (ST_Dump(geom)).geom AS geom 
    FROM centroid_country
)
SELECT DISTINCT ON (country) country, ST_Centroid(geom) AS geom
FROM geoms
ORDER BY country ASC, ST_Area(geom) DESC
) b
WHERE a.country=b.country
;

-- POS centroid
UPDATE centroid_country a
SET centroid_main_pos=b.geom
FROM
(
WITH geoms AS (
    SELECT country, (ST_Dump(geom)).geom AS geom 
    FROM centroid_country
)
SELECT DISTINCT ON (country) country, ST_PointOnSurface(geom) AS geom
FROM geoms
ORDER BY country ASC, ST_Area(geom) DESC
) b
WHERE a.country=b.country
;

-- Bounding box centroid 
UPDATE centroid_country a
SET centroid_main_bb=b.geom
FROM
(
WITH geoms AS (
    SELECT country, (ST_Dump(geom)).geom AS geom 
    FROM centroid_country
)
SELECT DISTINCT ON (country) country, ST_Centroid(ST_Envelope(geom)) AS geom
FROM geoms
ORDER BY country ASC, ST_Area(geom) DESC
) b
WHERE a.country=b.country
;

--
-- Longest distance from centroid to shape perimeter, in degrees
--

UPDATE centroid_country
SET cent_dist_max=ST_MaxDistance(centroid, geom);

UPDATE centroid_country
SET cent_pos_dist_max=ST_MaxDistance(centroid_pos, geom)
;
UPDATE centroid_country
SET cent_bb_dist_max=ST_MaxDistance(centroid_bb, geom)
;
UPDATE centroid_country
SET cent_main_dist_max=ST_MaxDistance(centroid_main, geom)
;
UPDATE centroid_country
SET cent_main_pos_dist_max=ST_MaxDistance(centroid_main_pos, geom)
;
UPDATE centroid_country
SET cent_main_bb_dist_max=ST_MaxDistance(centroid_main_bb, geom)
;

--
-- Add indexes
--

-- Non-spatial indexes
CREATE INDEX centroid_country_country_idx ON centroid_country 
	USING btree (country);
CREATE INDEX centroid_country_gid_0_idx ON centroid_country 
	USING btree (gid_0);
	
-- Spatial index
CREATE INDEX centroid_country_geom_idx ON centroid_country USING GIST (geom);
CREATE INDEX centroid_country_geog_idx ON centroid_country USING GIST (geog);
CREATE INDEX centroid_country_centroid_idx ON centroid_country USING GIST (centroid);
CREATE INDEX centroid_country_centroid_pos_idx ON centroid_country USING GIST (centroid_pos);
CREATE INDEX centroid_country_centroid_bb_idx ON centroid_country USING GIST (centroid_bb);
CREATE INDEX centroid_country_centroid_main_idx ON centroid_country USING GIST (centroid_main);
CREATE INDEX centroid_country_centroid_main_pos_idx ON centroid_country USING GIST (centroid_main_pos);
CREATE INDEX centroid_country_centroid_main_bb_idx ON centroid_country USING GIST (centroid_main_bb);




