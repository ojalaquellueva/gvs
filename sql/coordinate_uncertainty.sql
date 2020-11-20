-- ----------------------------------------------------------
-- Determine coordinate precision and estimate inherent
-- uncertainty due to decimal places used
-- 
-- Requires external parameter job
-- ----------------------------------------------------------

-- 
-- Set coordinate max precision constants
--
-- Note the use of \gset to set constant to result of query
-- See: https://stackoverflow.com/a/32597876/275782
--

-- Total decimal places
-- Also used to set "scale" parameter for numeric data type cast
\set DMAX 15

-- Total digits latitude; sets "precision" numeric() parameter
SELECT :DMAX+2 AS "PLAT" \gset

-- Total digits longitude; sets "precision" numeric() parameter
SELECT :DMAX+3 AS "PLONG" \gset

--
-- Calculate precision
--

UPDATE user_data a
SET coordinate_decimal_places=b.digits
FROM (
SELECT id, LEAST(
LENGTH(SPLIT_PART(latitude_verbatim,'.',2)),
LENGTH(SPLIT_PART(longitude_verbatim,'.',2))
) AS digits
FROM user_data
WHERE latlong_err IS NULL
) b
WHERE a.id=b.id
AND job=:'job'
;


--
-- Estimate inherent uncertainty in m
--
-- Calculates maximum distance between coordinates using verbatim 
-- decimal places and same coordinates padded with 9s on the right,
-- to DMAX decimal places
-- 
-- For each coordinate, first CASE statement is special handling for 
-- zero decimal places, and second CASE statement omits padding with 9s
-- when decimal places of verbatim value is greater than DMAX 
--

UPDATE user_data a
SET coordinate_inherent_uncertainty_m=max_err_m
FROM (
SELECT geog_maxmin.id, 
ST_Distance(geog_maxmin.geog_longmax_latmin, geog_maxmin.geog_longmin_latmax) AS max_err_m
FROM
(
SELECT id, 
ST_GeogFromText('SRID=4326;POINT(' || 
CONCAT(
CASE
WHEN longitude_verbatim NOT LIKE '%.%' THEN longitude_verbatim || '.'
ELSE longitude_verbatim
END,
CASE
WHEN LENGTH(SPLIT_PART(REPLACE(longitude_verbatim,'-',''),'.',2))<:DMAX
THEN (10^(:DMAX-LENGTH(SPLIT_PART(longitude_verbatim,'.',2)))-1)::text
ELSE ''
END::text
)
 || ' ' || 
latitude::numeric(:PLAT,:DMAX)
 || ')') AS geog_longmax_latmin, 
ST_GeogFromText('SRID=4326;POINT(' || 
longitude::numeric(:PLONG,:DMAX)
 || ' ' || 
CONCAT(
CASE
WHEN latitude_verbatim NOT LIKE '%.%' THEN latitude_verbatim || '.'
ELSE latitude_verbatim
END,
CASE
WHEN LENGTH(SPLIT_PART(REPLACE(latitude_verbatim,'-',''),'.',2))<:DMAX
THEN (10^(:DMAX-LENGTH(SPLIT_PART(latitude_verbatim,'.',2)))-1)::text
ELSE ''
END::text
)
 || ')') AS geog_longmin_latmax
FROM user_data
WHERE latlong_err IS NULL
AND job=:'job'
) AS geog_maxmin
) AS b
WHERE a.id=b.id
;
