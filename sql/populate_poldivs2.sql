-- ----------------------------------------------------------
-- Populate political divisions
-- 
-- Requires parameter :tbl_user_data	
-- ----------------------------------------------------------

-- country
UPDATE :tbl_user_data 
SET country=pip.country, gid_0=pip.gid_0
FROM 
(
    SELECT :"tbl_user_data".id, centroid_country.gid_0, centroid_country.country 
    FROM :tbl_user_data INNER JOIN centroid_country 
    ON st_contains(centroid_country.geom,:"tbl_user_data".geom)
) pip 
WHERE pip.id=:"tbl_user_data".id
AND :"tbl_user_data".geom IS NOT NULL
;

-- Add error message if country is null
UPDATE :tbl_user_data
SET latlong_err=
CASE
WHEN latlong_err IS NULL OR TRIM(latlong_err)='' THEN 'In ocean'
ELSE TRIM(latlong_err) || ', In ocean'
END
WHERE geom IS NOT NULL AND country IS NULL
;

-- state
UPDATE :tbl_user_data 
SET state=pip.state_province, gid_1=pip.gid_1
FROM 
(
    SELECT :"tbl_user_data".id, centroid_state_province.gid_1, centroid_state_province.state_province 
    FROM :tbl_user_data INNER JOIN centroid_state_province 
    ON st_contains(centroid_state_province.geom,:"tbl_user_data".geom)
) pip 
WHERE pip.id=:"tbl_user_data".id
AND :"tbl_user_data".geom IS NOT NULL
;

-- county
UPDATE :tbl_user_data 
SET county=pip.county_parish, gid_2=pip.gid_2
FROM 
(
    SELECT :"tbl_user_data".id, centroid_county_parish.gid_2, centroid_county_parish.county_parish 
    FROM :tbl_user_data INNER JOIN centroid_county_parish 
    ON st_contains(centroid_county_parish.geom,:"tbl_user_data".geom)
) pip 
WHERE pip.id=:"tbl_user_data".id
AND :"tbl_user_data".geom IS NOT NULL
;

