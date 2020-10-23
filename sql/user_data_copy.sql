-- ----------------------------------------------------------
-- Create temporary copy of table user_data
-- 
-- For testing only
-- For species, only timestamp field is indexed
-- ----------------------------------------------------------

DROP TABLE IF EXISTS user_data_copy;
CREATE TABLE user_data_copy (LIKE user_data);

-- Change timestamp column to date to keep current dates
ALTER TABLE user_data_copy
ALTER COLUMN date_created TYPE date;

INSERT INTO user_data_copy SELECT * FROM user_data;

DROP INDEX IF EXISTS user_data_copy_date_created_idx;
CREATE INDEX user_data_copy_date_created_idx ON user_data_copy (date_created);