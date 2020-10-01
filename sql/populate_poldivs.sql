-- ----------------------------------------------------------
-- Populate political divisions
-- 
-- Requires parameter :job	
-- Requires custom function isnumeric
-- ----------------------------------------------------------

-- country
UPDATE user_data a JOIN centroid_country B
ON (ST_Intersects(
SET


WHERE 


AND job=:'job'
;


SELECT ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) from user_data
