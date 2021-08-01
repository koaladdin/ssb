* **********************************************************************
* Project:          SSB tax in the Philippines
* Created:          May 2021
* Last modified:    12 July 2021 by AK
* Stata v.15.1

* Note: file directory is set in section 0
* users only need to change the location of their path there
* or their initials

* **********************************************************************
* Note: Users can edit file path to the project in config.do
* All subsequent files are referred to using dynamic, absolute filepaths
* **********************************************************************
* does
    /* This code runs all do-files needed for data work. */

* TO DO:
    *

* **********************************************************************
* 0 - General setup - users, home directories, create folders
* **********************************************************************
  global  user ak    /* Change to your username; same as you set in config.do */
  include config.do

* Specify Stata version in use
  global stataVersion 15.1    // set Stata version
  version $stataVersion

**********************************************************************
* 1 - Run setup code & set some additional preferences
***********************************************************************
	include ${scripts}/0_setup.do

* Set graph and Stata preferences
  set scheme plotplain
  set more off
  set logtype text

* **********************************************************************
* 2 - Import data and generate FIES data sets for analysis
* **********************************************************************

  include ${scripts}/1_importprice.do
  include ${scripts}/2_importFIES.do

* **********************************************************************
* 3 - Analyze data 
* **********************************************************************

  include ${scripts}/3_analysis.do     

* **********************************************************************
* 4 - Create graphs and charts
* **********************************************************************

 include ${scripts}/4_graphs.do    
