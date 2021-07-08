* **********************************************************************
* Installs dependencies (user-written Stata programs) in a local directory
* **********************************************************************

* Dependencies
	* add required packages/commands
    local ssc_install   "estout winsor2 diff outreg2 spmap sepscatter lgraph kmatch reghdfe ftools"
	local net_install   "speccurve" 
    local userpack      "StataConfig"
    local styles        "blindschemes"
	
* TO DO:

* **********************************************************************
* 0 - Run config file to establish path names
* **********************************************************************
    /* include "config.do" */

* **********************************************************************
* 1 - Decide if you want to update ado files (otherwise set adoUpdate to 0)
* **********************************************************************
* Set $adoUpdate to 0 to skip updating ado files
        global adoUpdate    0

* **********************************************************************
* 2 - Check if required packages are installed
* **********************************************************************
* Packages from SSC
    foreach package in `ssc_install' {
    	capture : which `package', all
    	if (_rc) {
            capture window stopbox rusure "You are missing some packages." "Do you want to install `package'?"
            if _rc == 0 {
                quietly capture ssc install `package', replace
                if (_rc) {
                    window stopbox rusure `"This package is not on SSC. Do you want to proceed without it?"'
                }
            }
            else {
                exit 199
            }
    	}
    }
	
* Speccurve
capture confirm file ${scripts}/ado/plus/s/speccurve.ado
	if _rc != 0 {
        capture window stopbox rusure "You are missing some packages." "Do you want to install speccurve (does not work well for earlier than Stata 16)?"
        if _rc == 0 {
            capture qui: net install speccurve, replace from("https://raw.githubusercontent.com/martin-andresen/speccurve/master")
        }
        else {
        	exit 199
        }
	}
	
* Emilia's custom save ado file //check with Emilia what StataConfig does 
capture confirm file ${scripts}/ado/plus/c/customSave.sthlp
	if _rc != 0 {
        capture window stopbox rusure "You are missing some packages." "Do you want to install StataConfig?"
        if _rc == 0 {
            capture qui: net install StataConfig, replace from(https://raw.githubusercontent.com/etjernst/Materials/master/stata/)
        }
        else {
        	exit 199
        }
	}

* Schemes don't have .ado files so -which- doesn't work
capture confirm file ${scripts}/ado/plus/b/blindschemes.sthlp
	if _rc != 0 {
        capture window stopbox rusure "You are missing some packages." "Do you want to install blindschemes?"
        if _rc == 0 {
            capture qui: ssc install blindschemes
        }
        else {
        	exit 199
        }
	}

* Update all ado files
    if $adoUpdate == 1 {
        ado update, update
    }
