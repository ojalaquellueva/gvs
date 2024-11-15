<?php

////////////////////////////////////////////////////////
// Accepts batch API POST requests and submits to gvs.sh
////////////////////////////////////////////////////////

///////////////////////////////////
// Parameters
///////////////////////////////////

// Increase memory limit for this script only
// Allows sending of larger reponses
ini_set('memory_limit','1000M');

// parameters in ALL_CAPS set in the two params files
require_once 'params.php';	// server-specific parameters
require_once 'api_params.php';		// API option parameters

// Temporary data directory
$data_dir_tmp = $DATADIR;
$data_dir_tmp = "/tmp/gvs/";

// Input file name & path
// User JSON input saved to this file as pipe-delimited text
// Becomes input for tnrs_batch command (`./controller.pl [...]`)
$basename = "gvs_" . uniqid(rand(), true);

$filename_tmp = $basename . '_in.tsv';
$file_tmp = $data_dir_tmp . $filename_tmp;

// Results file name & path
$results_filename = $basename . "_out.csv";
//$results_filename = $basename . "_gvs_scrubbed.csv";

# Full path and name of results file
$results_file = $data_dir_tmp . $results_filename;
//$results_file = "/tmp/" . $results_filename;

///////////////////////////////////
// Functions
///////////////////////////////////

////////////////////////////////////////////////////////
// Loads results file as an asociative array
// 
// Options:
//	$filepath: path and name of file to import
//	$delim: field delimiter
////////////////////////////////////////////////////////

function file_to_array_assoc($filepath, $delim) {
	$array = $fields = array(); $i = 0;
	$handle = @fopen($filepath, "r");
	if ($handle) {
		while (($row = fgetcsv($handle, 4096, $delim , '"' , '"')) !== false) {
			// Load keys from header row & continue to next
			if (empty($fields)) {
				$fields = $row;
				continue;
			}
			
			// Load value for this row 
			foreach ($row as $k=>$value) {
				$array[$i][$fields[$k]] = $value;
			}
			$i++;
		}
		if (!feof($handle)) {
			echo "Error: unexpected fgets() fail\n";
		}
		fclose($handle);
	}
	
	return $array;
}

/////////////////////////////////////////////////////
// Send the POST response, with either data or error 
// message in body. Body MUST be json.
/////////////////////////////////////////////////////

function send_response($status, $body) {
	header("Access-Control-Allow-Origin: *");
	header('Content-type: application/json');
	http_response_code($status); 
	echo $body;
}

////////////////////////////////////////
// Receive & validate the POST request
////////////////////////////////////////

// Start by assuming no errors
// Any run time errors and this will be set to true
$err_code=200;
$err_msg="";
$err=false;

// Make sure request is a pre-flight request or POST
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
	// Send pre-flight response and quit
	//header("Access-Control-Allow-Origin: http://localhost:3000");	// Dev
	header("Access-Control-Allow-Origin: *"); // Production
	header("Access-Control-Allow-Methods: POST, OPTIONS");
	header("Access-Control-Allow-Headers: Content-type");
	header("Access-Control-Max-Age: 86400");
	exit;
} else if (strcasecmp($_SERVER['REQUEST_METHOD'], 'POST') != 0) {
	$err_msg="ERROR: Request method must be POST\r\n"; 
	$err_code=400; goto err;
}
 
// Make sure that the content type of the POST request has been 
// set to application/json
$contentType = isset($_SERVER["CONTENT_TYPE"]) ? trim($_SERVER["CONTENT_TYPE"]) : '';
if (strcasecmp($contentType, 'application/json') != 0) {
	$err_msg="ERROR: Content type must be: application/json\r\n"; 
	$err_code=400; goto err;
}
 
// Receive the RAW post data.
$input_json = trim(file_get_contents("php://input"));

///////////////////////////////////////////
// Convert post data to array and separate
// data from options
///////////////////////////////////////////

// Attempt to decode the incoming RAW post data from JSON.
$input_array = json_decode($input_json, true);

// If json_decode failed, the JSON is invalid.
if (!is_array($input_array)) {
	$err_msg="ERROR: Received content contained invalid JSON!\r\n";	
	$err_code=400; goto err;
}

///////////////////////////////////
// Inspect the JSON data and run 
// safety/security checks
///////////////////////////////////

// UNDER CONSTRUCTION!

///////////////////////////////////////////
// Extract & validate options
///////////////////////////////////////////

// Get options and data from JSON
if ( ! ( $opt_arr = isset($input_array['opts'])?$input_array['opts']:false ) ) {
	$err_msg="ERROR: No API options (see element 'opts' in JSON request)\r\n";	
	$err_code=400; goto err;
}

///////////////////////////////////////////
// Validate options and assign each to its 
// own parameter
///////////////////////////////////////////

include $APP_DIR . "validate_options.php";
if ($err) goto err;

///////////////////////////////////////////
// Check option $mode
// If "meta", ignore other options and begin
// processing metadata request. 
///////////////////////////////////////////

if ( $mode=="resolve" ) { 	// BEGIN mode_if

	///////////////////////////////////////////
	// Extract & validate data
	///////////////////////////////////////////

	// Get data from JSON
	if ( !( $data_arr = isset($input_array['data'])?$input_array['data']:false ) ) {
		$err_msg="ERROR: No data (element 'data' in JSON request)\r\n";	
		$err_code=400; goto err;
	}

	# Check payload size
	$rows = count($data_arr);
	if ( $rows>$MAX_ROWS && $MAX_ROWS>0 ) {
		$err_msg="ERROR: Requested $rows rows exceeds $MAX_ROWS row limit\r\n";	
		$err_code=413;	# 413 Payload Too Large
		goto err; 
	}

	# Validate data array structure
	# Should have 1 or more rows of exactly 2 elements each
	$rows=0;
	foreach ($data_arr as $row) {
		$rows++;
		$values=0;
		foreach($row as $value) $values++;
		if ($values<>2) {
			$err_msg="ERROR: Data has wrong number of columns in one or more rows, should be exactly 2\r\n"; $err_code=400; goto err;
		}
	}
	if ($rows==0) {
		$err_msg="ERROR: No data rows!\r\n"; $err_code=400; goto err; 
	}
	
	# Set threshold parameter options, if provided
// 	if ( isset($maxdist) ) $opt_maxdist = "-d $maxdist";
// 	if ( isset($maxdistrel) ) $opt_maxdistrel = "-r $maxdistrel";
	if ( isset($maxdist) ) $opt_maxdist = "-md $maxdist";
	if ( isset($maxdistrel) ) $opt_maxdistrel = "-mdr $maxdistrel";

	# Get parallel batch size, if set, otherwise use default
	if ( isset($batches) ) {
		$nbatches = $batches;
	} else {
		$nbatches = $NBATCH;
	}

	///////////////////////////////////////////
	// Save data array to temp directory as 
	// comma-delimited file, to be used as 
	// input for GVS core app
	///////////////////////////////////////////

	// Make temporary data directory & file in /tmp 
	$cmd="mkdir -p $data_dir_tmp";
	exec($cmd, $output, $status);
	if ($status) {
		$err_msg="ERROR: Unable to create temp data directory\r\n";	
		$err_code=500; goto err;
	}

	// Convert array to file & save
	$fp = fopen($file_tmp, "w");
	$i = 0;
	foreach ($data_arr as $row) {
		//if($i === 0) fputcsv($fp, array_keys($row));	// header
		fputcsv($fp, array_values($row), ',');	// data
		$i++;
	}
	fclose($fp);

	// Run dos2unix to fix stupid DOS/Mac/Excel/UTF-16 issues, if any
	$cmd = "dos2unix $file_tmp";
	exec($cmd, $output, $status);
	//if ($status) die("ERROR: tnrs_batch non-zero exit status");
	if ($status) {
		$err_msg="Failed file conversion: dos2unix\r\n";
		$err_code=500; goto err;
	}

	// Set the temp data directory
	$data_dir_tmp_full = $data_dir_tmp . "/";

	/////////////////////////////////////////////
	// Form the final core application command
	/////////////////////////////////////////////
	
	// Non-parallel batch command
	//$cmd = $BATCH_DIR . "gvs.sh -a $opt_maxdist $opt_maxdistrel -f '$file_tmp' -o '$results_file'";	// Single batch mode

	// Parallel processing command
	$cmd = $BATCH_DIR . "gvspar2.pl -in '$file_tmp'  -out '$results_file' -nbatch $nbatches $opt_maxdistrel $opt_maxdist ";		// Parallel mode
	
	/////////////////////////////////////////
	// Execute the core application command
	/////////////////////////////////////////	
	
	exec($cmd, $output, $status);
	if ($status) {
		$err_msg="ERROR: gvs exit status: $status\r\n";
		$err_code=500; goto err;
	}

	///////////////////////////////////
	// Retrieve the tab-delimited results
	// file and convert to JSON
	///////////////////////////////////
	
	// Import the results file (tab-delimitted) to array
	$results_array = file_to_array_assoc($results_file, ",");

} else {	// CONTINUE mode_if 
	// Metadata requests

	if ( $mode=="meta" ) { 
		$sql="
		SELECT *
		FROM meta
		WHERE id=(SELECT MAX(id) FROM meta)
		;
		";
	} elseif ( $mode=="sources" ) { // CONTINUE mode_if 
		$sql="
		SELECT id, source_name, source_name_full, source_url,
		description, data_url, logo_path,
		source_version as version, source_release_date, 
		date_accessed
		FROM source
		;
		";
	} elseif ( $mode=="citations" ) { // CONTINUE mode_if 
		$sql="
		SELECT 'gvs.app' AS source, citation
		FROM meta
		WHERE id=(SELECT MAX(id) FROM meta)
		UNION ALL
		SELECT source_name AS source, citation
		FROM source
		WHERE citation IS NOT NULL AND TRIM(citation)<>''
		;
		";
	} elseif ( $mode=="collaborators" ) { // CONTINUE mode_if 
		$sql="
		SELECT collaborator_name, collaborator_name_full, collaborator_url, 
		description, logo_path
		FROM collaborator
		;
		";
	} else if ( $mode=="dd" ) { 
		// Retrieve output data dictionary
		$sql="
		SELECT mode, col_name, ordinal_position, data_type, description 
		FROM dd_output 
		ORDER BY ordinal_position;
		";
	} else if ( $mode=="dd_vals" ) { 
		// Retrieve data dictionary for constrained vocabulary 
		$sql="
		SELECT mode, col_name, value, description, ordinal_position 
		FROM dd_output_values 
		ORDER BY ordinal_position;
		";
	} else {
		$err_msg="ERROR: Unknown value for parameter mode: '$mode'\r\n"; 
		$err_code=400; goto err;
	}
	
	// Run the query and save results as $results_array
	include("qy_db.php"); 
	if ( $err_code!=200 ) goto err;

}	// END mode_if

///////////////////////////////////
// Send the results
///////////////////////////////////

$results_json = json_encode($results_array);
// Status ($err_code) should be 200
send_response($err_code, $results_json);
exit;

///////////////////////////////////
// Error: return http status code
// and error message
///////////////////////////////////

err:
$err_json = json_encode($err_msg);
send_response($err_code, $err_json);

?>