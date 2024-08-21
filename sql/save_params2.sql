-- ----------------------------------------------------------
-- Save threshold parameters to user_data
-- 
-- Requires parameters:
--	:tbl_user_data
--	:MAX_DIST	
--	:MAX_DIST_REL
-- ----------------------------------------------------------

UPDATE :tbl_user_data a
SET max_dist=:MAX_DIST,
max_dist_rel=:MAX_DIST_REL
;
