-- ----------------------------------------------------------
-- Validate verbatim coordinates & convert to numeric and wkt
-- as applicable
-- 
-- Requires parameter :job	
-- Requires custom function isnumeric
-- ----------------------------------------------------------


-- Check missing coordinates
UPDATE user_data
SET latlong_err='One or more missing coordinates'
WHERE (
coalesce(latitude_verbatim, '')='' OR coalesce(longitude_verbatim, '')=''
)
AND job=:'job'
;

-- Verify that verbatim coordinates are numeric
UPDATE user_data
SET latlong_err='Coordinates non-numeric'
WHERE (
isnumeric(latitude_verbatim)='f' OR  isnumeric(longitude_verbatim)='f'
)
AND latlong_err IS NULL
AND job=:'job'
;

-- Copy numeric verbatim coordinates to numeric columns
UPDATE user_data
SET latitude=latitude_verbatim::numeric,
longitude=longitude_verbatim::numeric
WHERE latlong_err IS NULL
AND job=:'job'
;

-- Check invalid values
UPDATE user_data
SET latlong_err='Coordinate values out of bounds'
WHERE (
latitude>90 OR latitude<-90 OR longitude<-180 OR longitude>180
)
AND latlong_err IS NULL
AND job=:'job'
;

-- Convert valid coordinates to geometry
UPDATE user_data
SET geom=ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
WHERE latlong_err IS NULL
AND job=:'job'
;
-- Convert geometry to separate geography column
UPDATE user_data
SET geog=ST_Transform(geom,4326)
WHERE geom IS NOT NULL
AND job=:'job'
;
