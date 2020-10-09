-- ----------------------------------------------------------
-- Save threshold parameters to user_data
-- 
-- Requires parameters:
--	job
--	MAX_DIST	
--	MAX_DIST_REL
-- ----------------------------------------------------------

UPDATE user_data a
SET max_dist=:MAX_DIST,
max_dist_rel=:MAX_DIST_REL
WHERE job=:'job'
;
