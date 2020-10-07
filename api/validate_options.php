<?php

//////////////////////////////////////////////
// Validate options passed to API
//
// Note that if multiple errors detected, only
// the last gets reported
//////////////////////////////////////////////

// For testing only
$mode_bak = $opt_arr['mode'];

// Processing mode
if (array_key_exists('mode', $opt_arr)) {
	$mode = $opt_arr['mode'];
	
	if ( trim($mode) == "" ) {
		$mode = $DEF_MODE;
	} else {
		$valid = in_array($mode, $MODES);
		if ( $valid === false ) {
			$err_msg="ERROR: Invalid option '$mode' for 'mode'\r\n"; 
			$err_code=400; $err=true;
		}
	}
} else {
	$mode = $TNRS_DEF_MODE;
}


/////////////////////////////////////////////
// Other options
/////////////////////////////////////////////

// Number of batches for makeflow threads
// If not set, uses default $NBATCH
if (array_key_exists('batches', $opt_arr)) {
	$batches = $opt_arr['batches'];
	
	if ( $batches==intval($batches) ) {
		$NBATCH = $batches;
	} else {
		$err_msg="ERROR: Invalid value '$batches' for option 'batches': must be an integer\r\n"; $err_code=400; $err=true;
	}
}

?>