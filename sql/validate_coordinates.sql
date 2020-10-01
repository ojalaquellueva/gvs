-- ----------------------------------------------------------
-- Validate verbatim coordinates
-- 
-- Requires parameter :job	
-- Requires custom function isnumeric
-- ----------------------------------------------------------

UPDATE user_data
SET latlong_err='Invalid coordinates: non-numeric'
WHERE (
isnumeric(latitude_verbatim)='f' OR  isnumeric(longitude_verbatim)='f'
)
AND job=:'job'
;

-- convert valid coordinates to numeric values
UPDATE user_data
SET latitude=latitude_verbatim::numeric,
longitude=longitude_verbatim::numeric
WHERE latlong_err IS NULL
AND job=:'job'
;

-- Check invalid valuesUPDATE user_data
UPDATE user_data
SET latlong_err='Invalid coordinates: values out of bounds'
WHERE (
latitude>90 OR latitude<-90 OR longitude<-180 OR longitude>180
)
AND job=:'job'
;
