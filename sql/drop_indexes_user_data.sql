-- 
-- Drop all indexes on table user_data
--

-- List all potential single-column indexes to cover all bases
-- Probably most of these won't exist
-- Don't include ID
DROP INDEX IF EXISTS user_data_job_idx;
DROP INDEX IF EXISTS user_data_latitude_verbatim_idx;
DROP INDEX IF EXISTS user_data_longitude_verbatim_idx;
DROP INDEX IF EXISTS user_data_latitude_idx;
DROP INDEX IF EXISTS user_data_longitude_idx;
DROP INDEX IF EXISTS user_data_user_id_idx;
DROP INDEX IF EXISTS user_data_gid_0_idx;
DROP INDEX IF EXISTS user_data_country_idx;
DROP INDEX IF EXISTS user_data_gid_1_idx;
DROP INDEX IF EXISTS user_data_state_idx;
DROP INDEX IF EXISTS user_data_gid_2_idx;
DROP INDEX IF EXISTS user_data_county_idx;
DROP INDEX IF EXISTS user_data_country_cent_dist_idx;
DROP INDEX IF EXISTS user_data_country_cent_dist_relative_idx;
DROP INDEX IF EXISTS user_data_country_cent_type_idx;
DROP INDEX IF EXISTS user_data_country_max_uncertainty_idx;
DROP INDEX IF EXISTS user_data_state_cent_dist_idx;
DROP INDEX IF EXISTS user_data_state_cent_dist_relative_idx;
DROP INDEX IF EXISTS user_data_state_cent_type_idx;
DROP INDEX IF EXISTS user_data_state_max_uncertainty_idx;
DROP INDEX IF EXISTS user_data_county_cent_dist_idx;
DROP INDEX IF EXISTS user_data_county_cent_dist_relative_idx;
DROP INDEX IF EXISTS user_data_county_cent_type_idx;
DROP INDEX IF EXISTS user_data_county_max_uncertainty_idx;
DROP INDEX IF EXISTS user_data_is_centroid_idx;
DROP INDEX IF EXISTS user_data_centroid_dist_relative_idx;
DROP INDEX IF EXISTS user_data_centroid_poldiv_idx;
DROP INDEX IF EXISTS user_data_centroid_type_idx;
DROP INDEX IF EXISTS user_data_centroid_max_uncertainty_idx;
DROP INDEX IF EXISTS user_data_latlong_err_idx;