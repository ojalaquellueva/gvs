ALTER TABLE centroid_county_parish
DROP COLUMN centroid_lat,
DROP COLUMN centroid_long,
DROP COLUMN centroid_pos_lat,
DROP COLUMN centroid_pos_long,
DROP COLUMN centroid_bb_lat,
DROP COLUMN centroid_bb_long
;

ALTER TABLE centroid_county_parish
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

CREATE INDEX centroid_county_parish_centroid_main_idx ON centroid_county_parish USING GIST (centroid_main);
CREATE INDEX centroid_county_parish_centroid_main_pos_idx ON centroid_county_parish USING GIST (centroid_main_pos);
CREATE INDEX centroid_county_parish_centroid_main_bb_idx ON centroid_county_parish USING GIST (centroid_main_bb);
