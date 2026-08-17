* Reviewer replication note
* Purpose: orchestrate the complete CHFS 2013/2015/2017 data build.
* Inputs: separate household, individual, and master DTA files for each wave.
* Outputs: labeled household-year analysis DTA used by manuscript Tables 1-11.
version 18.0
clear all
set more off
set varabbrev off

quietly do "config/01_paths.do"
local out "$IRFA_WORK_ROOT"

capture mkdir "`out'/logs"
capture mkdir "`out'/data"
capture mkdir "`out'/data/intermediate"
capture mkdir "`out'/evidence"

* Clean each wave independently, append, construct variables, and validate the result.
do "$IRFA_PACKAGE_ROOT/code/data_build/01_clean_2013.do"
do "$IRFA_PACKAGE_ROOT/code/data_build/02_clean_2015.do"
do "$IRFA_PACKAGE_ROOT/code/data_build/03_clean_2017.do"
do "$IRFA_PACKAGE_ROOT/code/data_build/04_append_construct.do"
do "$IRFA_PACKAGE_ROOT/code/data_build/99_validate_clean_data.do"
do "$IRFA_PACKAGE_ROOT/code/data_build/94_final_summary.do"

capture log close _all
log using "`out'/logs/00_master.log", text replace name(master)
confirm file "`out'/data/irfa_household_year_working.dta"
confirm file "`out'/data/irfa_household_year_analysis.dta"
display "MASTER_RESULT=PASS"
display "DATA_BUILD_MASTER=PASS"
log close master
exit 0
