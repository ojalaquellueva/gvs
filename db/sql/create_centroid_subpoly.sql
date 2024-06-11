-- -----------------------------------------------------------------
-- Populate table of country component polygons and their centroids
-- Applied only to countries which are multipolygons
-- -----------------------------------------------------------------

--
-- Insert component polygons
--

INSERT INTO centroid_subpoly (
gid_0,
country,
geom
)
SELECT 
gid_0,
country, 
(ST_Dump(geom)).geom
FROM centroid_country
WHERE ST_GeometryType(geom)='ST_MultiPolygon'
;

-- Populate the geography column
UPDATE centroid_subpoly
SET geog=Geography(ST_Transform(geom,4326))
WHERE geom IS NOT NULL
;

--
-- Centroids
-- 

/*
Regular centroid
For calculation of additional centroid types using ST_PointOnSurface
and ST_GeometricMedian, see https://postgis.net/docs/ST_Centroid.html
Also, consider using geography column instead
*/
UPDATE centroid_subpoly
SET centroid=ST_Centroid(geom)
;

/*
Point-on-surface centroid
Guaranteed to be inside polygon
But: not sure how handles multipolygons.
See https://postgis.net/docs/ST_Centroid.html
*/
UPDATE centroid_subpoly
SET centroid_pos=ST_PointOnSurface(geom)
;

/*
Bounding box centroid
*/
UPDATE centroid_subpoly
SET centroid_bb=ST_Centroid(ST_Envelope(geom))
;

--
-- Longest distance from centroid to shape perimeter, in degrees
--

UPDATE centroid_subpoly
SET cent_dist_max=ST_MaxDistance(centroid, geom);

UPDATE centroid_subpoly
SET cent_pos_dist_max=ST_MaxDistance(centroid_pos, geom)
;
UPDATE centroid_subpoly
SET cent_bb_dist_max=ST_MaxDistance(centroid_bb, geom)
;

--
-- Add indexes
--

-- Non-spatial indexes
CREATE INDEX centroid_subpoly_country_idx ON centroid_subpoly 
	USING btree (country);
CREATE INDEX centroid_subpoly_gid_0_idx ON centroid_subpoly 
	USING btree (gid_0);
	
-- Spatial indexes
CREATE INDEX centroid_subpoly_geom_idx ON centroid_subpoly USING GIST (geom);
CREATE INDEX centroid_subpoly_geog_idx ON centroid_subpoly USING GIST (geog);
CREATE INDEX centroid_subpoly_centroid_idx ON centroid_subpoly USING GIST (centroid);
CREATE INDEX centroid_subpoly_centroid_pos_idx ON centroid_subpoly USING GIST (centroid_pos);
CREATE INDEX centroid_subpoly_centroid_bb_idx ON centroid_subpoly USING GIST (centroid_bb);

-- Indexes on distance columns
CREATE INDEX centroid_subpoly_cent_dist_max_idx ON centroid_subpoly USING btree (cent_dist_max);
CREATE INDEX centroid_subpoly_cent_pos_dist_max_idx ON centroid_subpoly USING btree (cent_pos_dist_max);
CREATE INDEX centroid_subpoly_cent_bb_dist_max_idx ON centroid_subpoly USING btree (cent_bb_dist_max);




