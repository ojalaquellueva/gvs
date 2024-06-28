<?php

/////////////////////////////////////////////////
// API tuning parameters
/////////////////////////////////////////////////

// Return offending SQL on error? (true|false)
// TURN OFF FOR PRODUCTION! ($err_show_sql=false)
$err_show_sql=false;

// Maximum permitted input rows per request
// For no limit, set to 0
$MAX_ROWS=5001;	
					
// Number of batches
$NBATCH=20;				

//////////////////////////////////////////////////
// API user options
//////////////////////////////////////////////////

# Possible values of $mode
$MODES = array("resolve","meta","citations","collaborators","sources","dd","dd_vals");


//////////////////////////////////////////////////
// default options
//////////////////////////////////////////////////

$DEF_MODE = "resolve";		// Processing mode

?>
