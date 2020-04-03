-- -----------------------------------------------------------------
-- Creates all remaining tables not derived from geonames
-- -----------------------------------------------------------------

DROP TABLE IF EXISTS centroid_country;
CREATE TABLE centroid_country (
id bigserial not null primary key,
gid text,
country text,
geom geometry
);

INSERT INTO centroid_country (
gid,
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

-- Add centroid column
-- For calculation of additional centroid types using ST_PointOnSurface
-- and ST_GeometricMedian, see https://postgis.net/docs/ST_Centroid.html
-- Also, consider using geography column instead
ALTER TABLE centroid_country
ADD COLUMN centroid geometry(Point,4326)
;

UPDATE centroid_country
SET centroid=ST_Centroid(geom)
;