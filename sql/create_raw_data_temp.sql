-- ----------------------------------------------------------
-- Create temporary raw user data
--
-- Requires parameter:
--	$raw_data_tbl_temp --> :raw_data_tbl_temp (job-specific temp table)
-- ----------------------------------------------------------

-- Create job-specific raw data table
DROP TABLE IF EXISTS :raw_data_tbl_temp;
CREATE TABLE :raw_data_tbl_temp (
latitude text DEFAULT NULL,
longitude text DEFAULT NULL,
user_id text DEFAULT NULL
)
;
