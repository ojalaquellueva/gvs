-- -----------------------------------------------------------------
-- Alter schema of table meta
--
-- Main features:
-- 1. Richer metadata (more columns)
-- 2. Version history
--
-- Implemented in DB pipeline:
-- * Table creation
--
-- Not yet implemented in DB pipeline:
-- * Table population
-- * Carry-forward of version history
-- -----------------------------------------------------------------

\c gvs_dev	-- Private development
-- \c gvs		-- Public development and production

ALTER TABLE meta RENAME TO meta_orig;

DROP TABLE IF EXISTS meta;
CREATE TABLE meta (
id SERIAL NOT NULL PRIMARY KEY,
db_version TEXT DEFAULT NULL,
db_version_comments TEXT DEFAULT NULL,
db_build_date date,
code_version TEXT DEFAULT NULL,
code_version_comments TEXT DEFAULT NULL,
code_release_date date,
citation TEXT DEFAULT NULL,
publication TEXT DEFAULT NULL,
logo_path TEXT DEFAULT NULL 
);

-- Copy over original metadata
INSERT INTO meta (
db_version, 
code_version, 
db_build_date
)
SELECT 
db_version, 
code_version, 
build_date
FROM meta_orig
;
DROP TABLE meta_orig;

-- Insert metadata for current version
INSERT INTO META (
db_version,
db_version_comments,
db_build_date,
code_version,
code_version_comments,
code_release_date,
citation,
publication,
logo_path
)
VALUES (
'1.0',
'Main content identical to DB v0.1, but non backwards-compatible schema changes to table meta, hence major version increment',
'2022-05-06',
'2.0',
'First full release as GVS',
'2022-05-06',
'@misc{gvs, author = {Boyle, B. L. and Maitner, B. and Enquist, B. J.}, journal = {Botanical Information and Ecology Network}, title = {Geocoordinate Validation Service}, year = 2022, url = {https://gvs.biendata.org/}} ',
NULL,
NULL
);

ALTER TABLE meta OWNER TO bien;

