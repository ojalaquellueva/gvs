-- -----------------------------------------------------------------
-- Populate data source metadata table "source"
-- -----------------------------------------------------------------

-- GADM
INSERT INTO source (
source_name, 
source_name_full, 
source_url, 
description, 
data_url, 
source_version, 
source_release_date, 
date_accessed, 
citation, 
logo_path
)
VALUES
(
'GADM', 
'Global Administrative Areas Database', 
'https://gadm.org/', 
'GADM provides maps and spatial data for all countries and their sub-divisions.', 
'https://gadm.org/data.html', 
'4.0', 
NULL, 
'2022-05-06', 
'@misc{gadm, author= {{University of California, Berkeley, Museum of Vertebrate Zoology}}, title = {Global Administrative Areas}, url = {https://gadm.org/}, note = {Accessed May 6, 2022}}', 
''
)
;