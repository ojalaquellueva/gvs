-- ----------------------------------------------------------
-- Perform state centroid checks
-- 
-- Requires parameter :tbl_user_data	
-- ----------------------------------------------------------

UPDATE :tbl_user_data a
SET state_cent_dist=mindist.dist/1000,  -- convert to km
state_cent_type=mindist.cent_type,
state_cent_dist_relative=mindist.pdistmax
FROM 
(
SELECT DISTINCT ON (id) id, cent_type, dist, pdistmax
FROM 
(
(SELECT a.id, 'std' AS cent_type, ST_Distance(a.geom::geography,b.centroid::geography) AS dist,
ST_Distance(a.geom,b.centroid)/b.cent_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
UNION ALL
(SELECT a.id, 'pos' AS cent_type, ST_Distance(a.geom::geography,b.centroid_pos::geography) AS dist,
ST_Distance(a.geom,b.centroid_pos)/b.cent_pos_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
UNION ALL
(SELECT a.id, 'bb' AS cent_type, ST_Distance(a.geom::geography,b.centroid_bb::geography) AS dist,
ST_Distance(a.geom,b.centroid_bb)/b.cent_bb_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
UNION ALL
(SELECT a.id, 'std_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main::geography) AS dist,
ST_Distance(a.geom,b.centroid_main)/b.cent_main_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
UNION ALL
(SELECT a.id, 'pos_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_pos::geography) AS dist,
ST_Distance(a.geom,b.centroid_main_pos)/b.cent_main_pos_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
UNION ALL
(SELECT a.id, 'bb_main' AS cent_type, ST_Distance(a.geom::geography,b.centroid_main_bb::geography) AS dist,
ST_Distance(a.geom,b.centroid_main_bb)/b.cent_main_bb_dist_max as pdistmax
FROM :tbl_user_data a JOIN centroid_state_province b
ON a.gid_1=b.gid_1
)
) dists
ORDER BY id, dist ASC
) mindist
WHERE a.id=mindist.id
;

-- Populate _cent_dist_max 
UPDATE :tbl_user_data
SET state_cent_dist_max=
CASE 
WHEN state_cent_dist_relative=0 THEN 0
ELSE state_cent_dist/state_cent_dist_relative
END
WHERE state_cent_dist IS NOT NULL AND state_cent_dist_relative IS NOT NULL
;

-- Flag potential true centroids
UPDATE :tbl_user_data
SET is_state_centroid=1
WHERE state_cent_dist<=:MAX_DIST 
AND state_cent_dist_relative<=:MAX_DIST_REL
;
