-- ----------------------------------------------------------
-- Load user data from job-specific temp raw data table to 
-- table user_data
-- 
-- Requires parameters:
-- 	job					job #
-- 	raw_data_tbl_temp	Name of temp table
-- ----------------------------------------------------------

-- Insert raw data
-- TRUNCATE user_data;
INSERT INTO user_data (
job,
date_created,
latitude_verbatim,
longitude_verbatim,
user_id
)
SELECT 
:'job',
now(),
latitude,
longitude,
user_id
FROM :raw_data_tbl_temp
;
