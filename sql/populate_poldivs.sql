-- ----------------------------------------------------------
-- Populate political divisions
-- 
-- Requires parameter :job	
-- ----------------------------------------------------------

-- country
UPDATE user_data 
SET country=pip.country, gid_0=pip.gid_0
FROM 
(
    SELECT user_data.id, centroid_country.gid_0, centroid_country.country 
    FROM user_data INNER JOIN centroid_country 
    ON st_contains(centroid_country.geom,user_data.geom)
) pip 
WHERE pip.id=user_data.id
AND user_data.geom IS NOT NULL
AND job=:'job'
;

-- Add error message if country is null
UPDATE user_data
SET latlong_err='In ocean'
WHERE geom IS NOT NULL AND country IS NULL
AND job=:'job'
;

-- state
UPDATE user_data 
SET state=pip.state_province, gid_1=pip.gid_1
FROM 
(
    SELECT user_data.id, centroid_state_province.gid_1, centroid_state_province.state_province 
    FROM user_data INNER JOIN centroid_state_province 
    ON st_contains(centroid_state_province.geom,user_data.geom)
) pip 
WHERE pip.id=user_data.id
AND user_data.geom IS NOT NULL
AND job=:'job'
;

-- county
UPDATE user_data 
SET county=pip.county_parish, gid_2=pip.gid_2
FROM 
(
    SELECT user_data.id, centroid_county_parish.gid_2, centroid_county_parish.county_parish 
    FROM user_data INNER JOIN centroid_county_parish 
    ON st_contains(centroid_county_parish.geom,user_data.geom)
) pip 
WHERE pip.id=user_data.id
AND user_data.geom IS NOT NULL
AND job=:'job'
;

