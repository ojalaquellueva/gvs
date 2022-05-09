ALTER TABLE centroid_country RENAME COLUMN gid TO gid_0;
DROP INDEX centroid_country_bak_gid_idx;

ALTER TABLE centroid_country
DROP COLUMN centroid_lat,
DROP COLUMN centroid_long,
DROP COLUMN centroid_pos_lat,
DROP COLUMN centroid_pos_long,
DROP COLUMN centroid_bb_lat,
DROP COLUMN centroid_bb_long,
DROP COLUMN centroid_geog
;

ALTER TABLE centroid_country
ADD COLUMN centroid_main geometry(Point,4326),
ADD COLUMN centroid_main_pos geometry(Point,4326),
ADD COLUMN centroid_main_bb geometry(Point,4326),
ADD COLUMN cent_dist_max numeric DEFAULT NULL,
ADD COLUMN cent_pos_dist_max numeric DEFAULT NULL,
ADD COLUMN cent_bb_dist_max numeric DEFAULT NULL,
ADD COLUMN cent_main_dist_max numeric DEFAULT NULL,
ADD COLUMN cent_main_pos_dist_max numeric DEFAULT NULL,
ADD COLUMN cent_main_bb_dist_max numeric DEFAULT NULL
;

ALTER TABLE country
DROP COLUMN centroid_lat,
centroid_long,
centroid_pos_lat,
centroid_pos_long,
centroid_bb_lat,
centroid_bb_long
;

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

UPDATE centroid_country
SET cent_dist_max=ST_MaxDistance(centroid, geom)
;
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

CREATE INDEX centroid_country_centroid_main_idx ON centroid_country USING GIST (centroid_main);
CREATE INDEX centroid_country_centroid_main_pos_idx ON centroid_country USING GIST (centroid_main_pos);
CREATE INDEX centroid_country_centroid_main_bb_idx ON centroid_country USING GIST (centroid_main_bb);
