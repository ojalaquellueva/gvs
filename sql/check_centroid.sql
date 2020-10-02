-- ----------------------------------------------------------
-- Perform centroid checks
-- 
-- Requires parameter :job	
-- ----------------------------------------------------------

-- --------------------
-- country
-- --------------------

UPDATE user_data a
SET country_cent_dist=mindist.dist,
country_cent_type=mindist.cent_type
FROM 
(
SELECT DISTINCT ON (id) id, cent_type, dist
FROM 
(
(SELECT a.id, 'std' AS cent_type, ST_Distance(a.geom::geography,b.centroid::geography) AS dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'pos' AS cent_type, ST_Distance(a.geom::geography,b.centroid_pos::geography) AS centroid_pos_dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'bb' AS cent_type, ST_Distance(a.geom::geography,b.centroid_bb::geography) AS centroid_bb_dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'std_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main::geography) AS centroid_main_dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'pos_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_pos::geography) AS centroid_main_pos_dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
UNION ALL
(SELECT a.id, 'bb_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_bb::geography) AS centroid_main_bb_dist
FROM user_data a JOIN centroid_country b
ON a.gid_0=b.gid_0
WHERE job=:'job') 
) dists
ORDER BY id, dist ASC
) mindist
WHERE a.id=mindist.id
AND job=:'job'
;

-- Convert m to km
UPDATE user_data
SET country_cent_dist=country_cent_dist/1000
WHERE country_cent_dist IS NOT NULL
;