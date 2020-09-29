-- ----------------------------------------------------------
-- Load raw data to table user_data
-- This step is source-specific
-- ----------------------------------------------------------

-- Insert raw data
-- TRUNCATE user_data;
INSERT INTO user_data (
job,
latitude_verbatim,
longitude_verbatim,
user_id
)
SELECT 
:'job',
latitude,
longitude,
user_id
FROM user_data_raw
;

-- Index job
DROP INDEX IF EXISTS user_data_job_idx;
CREATE INDEX user_data_job_idx ON user_data (job);

