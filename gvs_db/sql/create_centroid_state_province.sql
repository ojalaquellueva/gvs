-- -----------------------------------------------------------------
-- Populate table of states (state_province) and their centroids
-- -----------------------------------------------------------------

-- Insert state polygons
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

-- Populate the geography column
UPDATE centroid_state_province
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

-- Non-spatial indexes
CREATE INDEX centroid_state_province_gid_0_idx ON centroid_state_province 
	USING btree (gid_0);
CREATE INDEX centroid_state_province_country_idx ON centroid_state_province 
	USING btree (country);
CREATE INDEX centroid_state_province_gid_1_idx ON centroid_state_province 
	USING btree (gid_1);
CREATE INDEX centroid_state_province_state_province_idx ON centroid_state_province 
	USING btree (state_province);

--
-- Centroids of largest polygon
-- 

-- Standard centroid
UPDATE centroid_state_province a
SET centroid_main=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_1, (ST_Dump(geom)).geom AS geom 
    FROM centroid_state_province
)
SELECT DISTINCT ON (gid_1) gid_1, ST_Centroid(geom) AS geom
FROM geoms
ORDER BY gid_1 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_1=b.gid_1
;

-- POS centroid
UPDATE centroid_state_province a
SET centroid_main_pos=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_1, (ST_Dump(geom)).geom AS geom 
    FROM centroid_state_province
)
SELECT DISTINCT ON (gid_1) gid_1, ST_PointOnSurface(geom) AS geom
FROM geoms
ORDER BY gid_1 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_1=b.gid_1
;

-- Bounding box centroid 
UPDATE centroid_state_province a
SET centroid_main_bb=b.geom
FROM
(
WITH geoms AS (
    SELECT gid_1, (ST_Dump(geom)).geom AS geom 
    FROM centroid_state_province
)
SELECT DISTINCT ON (gid_1) gid_1, ST_Centroid(ST_Envelope(geom)) AS geom
FROM geoms
ORDER BY gid_1 ASC, ST_Area(geom) DESC
) b
WHERE a.gid_1=b.gid_1
;

--
-- Longest distance from centroid to shape perimeter
--

UPDATE centroid_state_province
SET cent_dist_max=ST_MaxDistance(centroid, geom)
;
UPDATE centroid_state_province
SET cent_pos_dist_max=ST_MaxDistance(centroid_pos, geom)
;
UPDATE centroid_state_province
SET cent_bb_dist_max=ST_MaxDistance(centroid_bb, geom)
;
UPDATE centroid_state_province
SET cent_main_dist_max=ST_MaxDistance(centroid_main, geom)
;
UPDATE centroid_state_province
SET cent_main_pos_dist_max=ST_MaxDistance(centroid_main_pos, geom)
;
UPDATE centroid_state_province
SET cent_main_bb_dist_max=ST_MaxDistance(centroid_main_bb, geom)
;


-- Spatial indexes
CREATE INDEX centroid_state_province_geom_idx ON centroid_state_province 
	USING GIST (geom);
CREATE INDEX centroid_state_province_geog_idx ON centroid_state_province 
	USING GIST (geog);
CREATE INDEX centroid_state_province_centroid_idx ON centroid_state_province 
	USING GIST (centroid);
CREATE INDEX centroid_state_province_centroid_pos_idx ON centroid_state_province 
	USING GIST (centroid_pos);
CREATE INDEX centroid_state_province_centroid_bb_idx ON centroid_state_province 
	USING GIST (centroid_bb);

CREATE INDEX centroid_state_province_centroid_main_idx ON centroid_state_province USING GIST (centroid_main);
CREATE INDEX centroid_state_province_centroid_main_pos_idx ON centroid_state_province USING GIST (centroid_main_pos);
CREATE INDEX centroid_state_province_centroid_main_bb_idx ON centroid_state_province USING GIST (centroid_main_bb);


