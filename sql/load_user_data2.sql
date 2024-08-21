-- ----------------------------------------------------------
-- Load user data from job-specific raw data table to 
-- job-specific user_data table
-- 
-- Requires parameters:
-- 	job					job #
-- 	tbl_user_data_raw	Name of raw user data table
-- 	tbl_user_data		Name of final user data table
-- ----------------------------------------------------------

-- Insert raw data
-- TRUNCATE user_data;
INSERT INTO :tbl_user_data (
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
FROM :tbl_user_data_raw
;
