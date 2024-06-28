-- -----------------------------------------------------------------
-- Create data dictionary table of GVS output values & definitions
-- -----------------------------------------------------------------

/* Values & definitions of selected output fields with constrained vocabulary */

DROP TABLE IF EXISTS dd_output_values;
CREATE TABLE dd_output_values (
mode text not null,
col_name text not null,
"value" text not null,
description text default null,
ordinal_position integer not null,
PRIMARY KEY (mode, col_name)
);
ALTER TABLE dd_output_values OWNER TO bien;

INSERT INTO dd_output_values (mode, col_name, "value", description, ordinal_position)
VALUES 
('resolve','latlong_err','Coordinates non-numeric	','Submitted values contain text and are therefore not decimal coordinates',1),
('resolve','latlong_err','Coordinate values out of bounds','Submitted values are numeric but one or both are outside the range [-90:90] required for latitude and [-180:180] required for longitude.',2),
('resolve','latlong_err','Possible centroid','Point may be a political division centroid rather than an exact location of observation, as indicated by one or more centroid tests exceeding either or both threshold values max_dist and max_dist_rel. See consensus centroid fields for details (centroid_dist_km, centroid_dist_relative, centroid_type, centroid_dist_max_km, centroid_poldiv)',3),
('resolve','latlong_err','In ocean','Point is in the ocean. May or may not be an error, depending on context',4)
;

DROP INDEX IF EXISTS dd_output_values_mode_idx;
CREATE INDEX dd_output_values_mode_idx ON dd_output_values (mode);

DROP INDEX IF EXISTS dd_output_values_col_name_idx;
CREATE INDEX dd_output_values_col_name_idx ON dd_output_values (col_name);

DROP INDEX IF EXISTS dd_output_values_value_idx;
CREATE INDEX dd_output_values_value_idx ON dd_output_values ("value");
