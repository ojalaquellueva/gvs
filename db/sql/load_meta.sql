-- -----------------------------------------------------------------
-- Create & populate main metadata table "meta"
-- -----------------------------------------------------------------

INSERT INTO meta (
db_version,
code_version,
build_date,
citation,
publication,
logo_path,
version_comments
) 
VALUES (
:'DB_VERSION',
:'VERSION',
now()::date,
CONCAT('@misc{gvs, author = {Boyle, B. L. and Maitner, B. and Enquist, B. J.}, journal = {Botanical Information and Ecology Network}, title = {Geocoordinate Validation Service}, year = ', to_char(now()::date, 'YYYY'), ', url = {https://gvs.biendata.org/}, note = {Accessed ', to_char(now()::date, 'Mon DD, YYYY'), '}}'),
NULL,
'images/gvs.png',
:'VERSION_COMMENTS'
);
