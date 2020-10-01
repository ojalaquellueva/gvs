-- ----------------------------------------------------------
-- Populate political divisions
-- 
-- Requires parameter :job	
-- Requires custom function isnumeric
-- ----------------------------------------------------------

-- country
UPDATE user_data 
SET country = pip.country 
FROM 
(
    SELECT user_data.id, centroid_country.country 
    FROM user_data INNER JOIN centroid_country 
    ON st_contains(centroid_country.geom,user_data.geom)
) pip 
WHERE pip.id = user_data.id
AND user_data.geom IS NOT NULL
AND job=:'job'
;

-- Add error message if country is null
UPDATE user_data
SET latlong_err="In ocean"
WHERE geom IS NOT NULL AND country IS NULL
AND job=:'job'
;
