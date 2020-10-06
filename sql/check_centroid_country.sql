-- ----------------------------------------------------------
-- Perform country centroid checks
-- 
-- Requires parameter :job	
-- ----------------------------------------------------------

UPDATE user_data a
SET country_cent_dist=mindist.dist/1000,  -- convert to km
country_cent_type=mindist.cent_type,
country_cent_dist_relative=mindist.pdistmax
FROM 
(
SELECT DISTINCT ON (id) id, cent_type, dist, pdistmax
FROM 
(
(SELECT a.id, 'std' AS cent_type, ST_Distance(a.geom::geography,b.centroid::geography) AS dist,
ST_Distance(a.geom,b.centroid)/b.cent_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'pos' AS cent_type, ST_Distance(a.geom::geography,b.centroid_pos::geography) AS dist,
ST_Distance(a.geom,b.centroid_pos)/b.cent_pos_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'bb' AS cent_type, ST_Distance(a.geom::geography,b.centroid_bb::geography) AS dist,
ST_Distance(a.geom,b.centroid_bb)/b.cent_bb_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'std_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main::geography) AS dist,
ST_Distance(a.geom,b.centroid_main)/b.cent_main_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'pos_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_pos::geography) AS dist,
ST_Distance(a.geom,b.centroid_main_pos)/b.cent_main_pos_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'bb_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_bb::geography) AS dist,
ST_Distance(a.geom,b.centroid_main_bb)/b.cent_main_bb_dist_max as pdistmax
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
) dists
ORDER BY id, dist ASC
) mindist
WHERE a.id=mindist.id
AND job=:'job'
;

-- Populate _cent_dist_max 
UPDATE user_data
SET country_cent_dist_max=country_cent_dist/country_cent_dist_relative
WHERE country_cent_dist IS NOT NULL AND country_cent_dist_relative IS NOT NULL
AND job=:'job'
;

-- Flag potential true centroids
UPDATE user_data
SET is_country_centroid=1
WHERE country_cent_dist<=:MAX_DIST 
AND country_cent_dist_relative<=:MAX_DIST_REL
AND job=:'job'
;