-- ----------------------------------------------------------
-- Determine coordinate precision and estimate max uncertainty
-- 
-- Requires parameters:
--	job	- job #
-- Requires custom function isnumeric
-- ----------------------------------------------------------

-- Calculate precision
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

-- Estimate max uncertainty in m
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
longitude_verbatim,
(10^(15-LENGTH(SPLIT_PART(longitude_verbatim,'.',2)))-1)::text
)::numeric
 || ' ' || 
latitude::numeric(17,15)
 || ')') AS geog_longmax_latmin, 
ST_GeogFromText('SRID=4326;POINT(' || 
longitude::numeric(18,15)
 || ' ' || 
CONCAT(
latitude_verbatim,
(10^(15-LENGTH(SPLIT_PART(latitude_verbatim,'.',2)))-1)::text
)::numeric
 || ')') AS geog_longmin_latmax
FROM user_data
WHERE latlong_err IS NULL
AND job=:'job'
) AS geog_maxmin
) AS b
WHERE a.id=b.id
;