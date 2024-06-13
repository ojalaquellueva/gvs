\c gvs_dev

DROP TABLE IF EXISTS collaborator;
CREATE TABLE collaborator (
collaborator_id SERIAL NOT NULL PRIMARY KEY,
collaborator_name TEXT DEFAULT NULL,
collaborator_name_full TEXT DEFAULT NULL,
collaborator_url TEXT DEFAULT NULL,
description TEXT DEFAULT NULL,
logo_path TEXT DEFAULT NULL
);

INSERT INTO collaborator (
collaborator_name,collaborator_name_full,collaborator_url,description,logo_path
)
VALUES
('BIEN','The Botanical Information and Ecology Network','https://bien.nceas.ucsb.edu/bien/',NULL,'images/bien.png'),
('NCEAS','The National Center for Ecological Analysis and Synthesis','https://www.nceas.ucsb.edu/',NULL,'images/nceas.png'),
('University of Arizona','The University of Arizona','https://www.arizona.edu/',NULL,'images/UA.png'),
('NSF','The National Science Foundation','https://www.nsf.gov/',NULL,'images/nsf.png')
;

alter table collaborator owner to bien;