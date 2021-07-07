* Note: Users can edit file path to the project in config.do
* All subsequent files are referred to using dynamic, absolute filepaths
* **********************************************************************
* does
    /* This code runs all do-files needed for data work. */

* TO DO:
    *

* **********************************************************************
* 0 - General setup
* **********************************************************************
  global user et    /* Change to your username; same as you set in config.do */
  include config.do

* Specify Stata version in use
  global stataVersion 16.1    // set Stata version
  version $stataVersion

**********************************************************************
* 1 - Run setup code & set some additional preferences
***********************************************************************
	include ${scripts}/0_setup.do

* Set graph and Stata preferences
  set scheme plotplain

* include ${scripts}/1_cleanData.do     /* add .do files here */
