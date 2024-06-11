-- -----------------------------------------------------------------
-- Populate table of counties (county_parish) and their centroids
-- -----------------------------------------------------------------

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

-- Populate the geography column
UPDATE centroid_county_parish
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
UPDATE centroid_county_parish
SET centroid=ST_Centroid(geom)
;

/*
Point-on-surface centroid
Guaranteed to be inside polygon
But: not sure how handles multipolygons.
See https://postgis.net/docs/ST_Centroid.html
*/
UPDATE centroid_county_parish
SET centroid_pos=ST_PointOnSurface(geom)
;

/*
Bounding box centroid
*/
UPDATE centroid_county_parish
SET centroid_bb=ST_Centroid(ST_Envelope(geom))
;

-- 
-- Non-spatial indexes
-- 

CREATE INDEX centroid_county_parish_gid_0_idx ON centroid_county_parish 
	USING btree (gid_0);
CREATE INDEX centroid_county_parish_country_idx ON centroid_county_parish 
	USING btree (country);
CREATE INDEX centroid_county_parish_gid_1_idx ON centroid_county_parish 
	USING btree (gid_1);
CREATE INDEX centroid_county_parish_state_province_idx ON centroid_county_parish 
	USING btree (state_province);
CREATE INDEX centroid_county_parish_gid_2_idx ON centroid_county_parish 
	USING btree (gid_2);
CREATE INDEX centroid_county_parish_county_parish_idx ON centroid_county_parish 
	USING btree (county_parish);
	

--
-- Centroids of largest polygon
-- 

-- Standard centroid
UPDATE centroid_county_parish a
SET centroid_main=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_2, (ST_Dump(geom)).geom AS geom 
    FROM centroid_county_parish
)
SELECT DISTINCT ON (gid_2) gid_2, ST_Centroid(geom) AS geom
FROM geoms
ORDER BY gid_2 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_2=b.gid_2
;

-- POS centroid
UPDATE centroid_county_parish a
SET centroid_main_pos=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_2, (ST_Dump(geom)).geom AS geom 
    FROM centroid_county_parish
)
SELECT DISTINCT ON (gid_2) gid_2, ST_PointOnSurface(geom) AS geom
FROM geoms
ORDER BY gid_2 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_2=b.gid_2
;

-- Bounding box centroid 
UPDATE centroid_county_parish a
SET centroid_main_bb=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_2, (ST_Dump(geom)).geom AS geom 
    FROM centroid_county_parish
)
SELECT DISTINCT ON (gid_2) gid_2, ST_Centroid(ST_Envelope(geom)) AS geom
FROM geoms
ORDER BY gid_2 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_2=b.gid_2
;

--
-- Longest distance from centroid to shape perimeter
--

UPDATE centroid_county_parish
SET cent_dist_max=ST_MaxDistance(centroid, geom)
;
UPDATE centroid_county_parish
SET cent_pos_dist_max=ST_MaxDistance(centroid_pos, geom)
;
UPDATE centroid_county_parish
SET cent_bb_dist_max=ST_MaxDistance(centroid_bb, geom)
;
UPDATE centroid_county_parish
SET cent_main_dist_max=ST_MaxDistance(centroid_main, geom)
;
UPDATE centroid_county_parish
SET cent_main_pos_dist_max=ST_MaxDistance(centroid_main_pos, geom)
;
UPDATE centroid_county_parish
SET cent_main_bb_dist_max=ST_MaxDistance(centroid_main_bb, geom)
;

--
-- Spatial indexes
-- 

CREATE INDEX centroid_county_parish_geom_idx ON centroid_county_parish 
	USING GIST (geom);
CREATE INDEX centroid_county_parish_geog_idx ON centroid_county_parish 
	USING GIST (geog);
CREATE INDEX centroid_county_parish_centroid_idx ON centroid_county_parish 
	USING GIST (centroid);
CREATE INDEX centroid_county_parish_centroid_pos_idx ON centroid_county_parish 
	USING GIST (centroid_pos);
CREATE INDEX centroid_county_parish_centroid_bb_idx ON centroid_county_parish 
	USING GIST (centroid_bb);


