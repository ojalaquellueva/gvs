<?php

////////////////////////////////////////////////////////
// Queries database with supplied sql ($sql)
////////////////////////////////////////////////////////

require_once 'params.php';			// general parameters 
// require_once 'api_params.php';		// API option parameters

include $CONFIG_DIR.'db_config.php';

// include '../../config/db_config.php';
// $sql="SELECT db_version, build_date, code_version FROM meta";
// $err_show_sql=TRUE;


// On error, display SQL if request (turn off for production!)
if ( $err_show_sql ) {
	$sql_disp = $sql;
} else {
	$sql_disp = "";
}

// connect to the db
$conn_string = "host=$HOST port=5432 dbname=$DB user=$USER_W password=$PWD_USER_W";
$dbconn = pg_connect($conn_string);

if (!$dbconn) {
	$err_msg="ERROR: Failed to connect to database\r\n";
	$err_code=500;	
} elseif (!$qy_results = pg_query($dbconn, $sql)) {
	pg_close($dbconn); 
	$err_msg="ERROR: Query failed (mode '$mode')\r\n";
// 	$err_msg=$err_msg."DB: $DB \r\n";
// 	$err_msg=$err_msg."SQL: $sql \r\n";
	$err_code=400;	
} else {
	// Create associative array of the query results
	$results_array = array();
	if(pg_num_rows($qy_results)) {
		while($result = pg_fetch_assoc($qy_results)) {
			//$results_array[] = array($mode=>$result); // Include $mode
			$results_array[] = $result;					// Omit $mode
		}
	}
	pg_close($dbconn); 
}

?>