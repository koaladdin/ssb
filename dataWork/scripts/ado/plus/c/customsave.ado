*! version 2.0.3 01may2020  Emilia Tjernström

* **********************************************************************

cap prog drop customsave

program customsave , rclass
    syntax , IDVARname(varlist) filename(string) path(string) DOFILEname(string) [description(string) user(string) noidok]

qui {
		preserve
        local origversion "`c(version)'"
		version 16.0

* **********************************************************************
* Checking that user only supplied one id variable
	if `:list sizeof idvarname' > 1 {
		noi di as error "{phang} You should not have multiple ID variables in idvarname(`idvarname').{p_end}"
		noi di ""
		error 103
		exit
	}
* **********************************************************************
* Test potential issues with id variable

* 1 - check whether idvarname uniquely identifies observations in the data
qui: capture isid `idvarname'
local isid_rc = _rc

    if (`isid_rc') {
        // Test missing
        qui: capture assert !missing(`idvarname')
    		if _rc {
    			count if missing(`idvarname')
    			noi di as error "{phang}`r(N)' observation(s) are missing the ID variable `idvarname'. Specifying the {it:noidok} option will let you proceed, but it's not good practice."
    			noi di ""
            }
	}

    * 2 - check for duplicates in idvarname
		// Test duplicates
		tempvar mydup

    * Count how many duplicates there are
		qui: duplicates tag `idvarname', gen(`mydup')
		qui: count if `mydup' != 0
        local dupnumber = `r(N)'
		if r(N) > 0 {
			sort `idvarname'
            if "`noidok'" != "" {
                noi di as error "{phang}The ID variable `idvarname' has duplicate observations in `dupnumber' values. Specifying the {it:noidok} option will let you proceed, but it's not good practice. These are the duplicates:{p_end} "
			    noi list `idvarname' if `mydup' != 0
            }
		}
		noi di ""
        if "`noidok'" != "" {
            error 148
            exit
        }


    restore

* **********************************************************************
* Metadata output
	* Store the name of idvar in dataset characteristics and in notes
		char  _dta[config_idvar] "`idvarname'"
            local idOut "Observations in this data set are identified by `idvarname'. "

	* Store Stata version that generated the data
		char  _dta[config_version] "`origversion'"
		local versOut "This data set was created with .do file `dofilename'"

	* Date
		char  _dta[config_date] "`c(current_date)'"
		local dateOut " | Last modified on `c(current_date)'"

	* User
        if "`user'" == "" {
            char  _dta[config_user] "`c(username)'"
            local user "`c(username)'"
        }
		char  _dta[config_host] "`c(hostname)'"
		local userOut " by user `user' using computer `c(hostname)'"

    * More description
        if "`description'" != "" {
            local descOut " | Further description: `description'""
        }

* **********************************************************************
* 5 - Add metadata (data label and notes) and save

    char _dta[config_boilsave] "`idOut'`versOut' `userOut'`dateOut'"
    label data "`versOut' `dateOut' `userOut'"

    * Add a note to the data (useful for tracking edits over time)
    note: Dataset `filename' | `versOut' `dateOut' `userOut' `descOut'

    * Save
    save "`path'/`filename'", replace
}
    display "`idOut' `versOut' `userOut' `dateOut'"

	end
