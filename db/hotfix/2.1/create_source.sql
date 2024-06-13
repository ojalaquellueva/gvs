\c gvs_dev

DROP TABLE IF EXISTS source;
CREATE TABLE source (
"id" serial primary key,
"source_name" text not null,
"source_name_full" text,
"source_url" text,
"description" text,
"data_url" text,
"source_version" text,
"source_release_date" date,
"date_accessed" date,
"citation" text,
"logo_path" text
);

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

alter table source owner to bien;