-- -----------------------------------------------------------------
-- Update app metadata & increment version
-- -----------------------------------------------------------------

\c gvs_dev	-- Private development
-- \c gvs		-- Public development and production


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
'1.1',
'Add metadata tables and data dictionary (dd_output)',
'2024-06-10',
'2.1',
'Add metadata tables to GVS DB',
'2024-06-1',
'@misc{gvs, author = {Boyle, B. L. and Maitner, B. and Enquist, B. J.}, journal = {Botanical Information and Ecology Network}, title = {Geocoordinate Validation Service}, year = 2024, url = {https://gvs.biendata.org/}} ',
NULL,
NULL
);
