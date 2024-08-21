-- ----------------------------------------------------------
-- Create temporary raw user data
--
-- Requires parameter:
--	$tbl_user_data_raw --> :tbl_user_data_raw (job-specific raw user data table)
--	$tbl_user_data --> :tbl_user_data (job-specific user data table)
-- ----------------------------------------------------------

-- Create job-specific raw & final user data tables
DROP TABLE IF EXISTS :tbl_user_data_raw;
CREATE TABLE :tbl_user_data_raw ( LIKE user_data_raw_template INCLUDING ALL );

DROP TABLE IF EXISTS :tbl_user_data;
CREATE TABLE :tbl_user_data ( LIKE user_data_template INCLUDING ALL );
