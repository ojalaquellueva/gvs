-- ----------------------------------------------------------
-- Choses single most likely centroid, if any, from among the 
-- three political division centroids
-- 
-- Requires parameters:
-- 	job	- 
-- ----------------------------------------------------------

-- Reset all consensus values to NULL to be sure
UPDATE user_data a
SET centroid_dist_km=NULL,
centroid_dist_relative=NULL,
centroid_type=NULL,
centroid_dist_max_km=NULL,
centroid_poldiv=NULL
WHERE job=:'job'
;

UPDATE user_data a
SET 
centroid_dist_km=closest_centroid.dist,
centroid_dist_relative=closest_centroid.dist_relative,
centroid_type=closest_centroid.cent_type,
centroid_dist_max_km=closest_centroid.dist_max,
centroid_poldiv=closest_centroid.poldiv
FROM
(
	SELECT DISTINCT ON (id) id, dist, dist_relative, dist_max, cent_type, poldiv
	FROM
	(
		(
		SELECT id, 'country' AS poldiv, country_cent_dist AS dist, 
		country_cent_dist_relative AS dist_relative, 
		country_cent_dist_max AS dist_max, country_cent_type AS cent_type
		FROM user_data
		WHERE is_country_centroid=1
		AND job=:'job'
		)
		UNION ALL
		(
		SELECT id, 'state' AS poldiv, state_cent_dist AS dist, 
		state_cent_dist_relative AS dist_relative, 
		state_cent_dist_max AS dist_max, state_cent_type AS cent_type
		FROM user_data
		WHERE is_state_centroid=1
		AND job=:'job'
		)
		UNION ALL
		(
		SELECT id, 'county' AS poldiv, county_cent_dist AS dist, 
		county_cent_dist_relative AS dist_relative, 
		county_cent_dist_max AS dist_max, county_cent_type AS cent_type
		FROM user_data
		WHERE is_county_centroid=1
		AND job=:'job'
		)
		UNION ALL
		(
		SELECT id, 'other' AS poldiv, subpoly_cent_dist AS dist, 
		subpoly_cent_dist_relative AS dist_relative, 
		subpoly_cent_dist_max AS dist_max, subpoly_cent_type AS cent_type
		FROM user_data
		WHERE is_subpoly_centroid=1
		AND job=:'job'
		)
	) candidate_centroids
	ORDER BY id, dist ASC
) closest_centroid
WHERE a.id=closest_centroid.id
AND job=:'job'
;
