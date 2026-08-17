* Reviewer replication note
* Purpose: define package-relative paths and immutable input identities.
* Inputs: extracted package root; optional undistributed local override.
* Outputs: globals used by all cleaning, linkage, estimation, and validation scripts.
version 18.0

* Run 00_run_all.do from the package root. A non-distributed
* config/01_paths.local.do may override raw, auxiliary, or work paths.
local __pkg = subinstr(c(pwd), char(92), "/", .)
global IRFA_PACKAGE_ROOT "`__pkg'"

confirm file "$IRFA_PACKAGE_ROOT/00_run_all.do"

global IRFA_RAW_ROOT "$IRFA_PACKAGE_ROOT/data/raw/chfs"
global IRFA_AUX_ROOT "$IRFA_PACKAGE_ROOT/data/raw/auxiliary"
global IRFA_WORK_ROOT "$IRFA_PACKAGE_ROOT/work"
global IRFA_RESULTS "$IRFA_PACKAGE_ROOT/tables"
global IRFA_REPRODUCED "$IRFA_PACKAGE_ROOT/tables"
global IRFA_LOGS "$IRFA_PACKAGE_ROOT/logs"
global IRFA_EVIDENCE "$IRFA_PACKAGE_ROOT/validation"

capture confirm file "$IRFA_PACKAGE_ROOT/config/01_paths.local.do"
if _rc == 0 {
    quietly do "$IRFA_PACKAGE_ROOT/config/01_paths.local.do"
}

global IRFA_DATA "$IRFA_WORK_ROOT/data"
global IRFA_INTERMEDIATE "$IRFA_DATA/intermediate"
global IRFA_INPUT_DTA "$IRFA_DATA/irfa_household_year_analysis.dta"
global IRFA_PARENT_PARTY "$IRFA_INTERMEDIATE/irfa_parent_party_supplement.dta"
global IRFA_EMPIRICAL_AUGMENTED "$IRFA_INTERMEDIATE/irfa_empirical_augmented.dta"
global IRFA_FINAL_DTA "$IRFA_PACKAGE_ROOT/data/final/IRFA_analysis_sample.dta"
global IRFA_LOCAL_DTA "$IRFA_AUX_ROOT/new.dta"

global IRFA_CITY13_DTA "$IRFA_AUX_ROOT/13city.dta"
global IRFA_CITY15_DTA "$IRFA_AUX_ROOT/15city.dta"
global IRFA_CITY17_DTA "$IRFA_AUX_ROOT/17city.dta"
global IRFA_DENSITY_DTA "$IRFA_AUX_ROOT/pop_density_2017.dta"

global IRFA_INPUT_SHA "53734D953341A34CA7D8BD25ACE2C0CA629DF143298709B83140F4B65248D878"
global IRFA_CITY13_SHA "E68A22DC72557617116BE2457F725E7C770DB3FC7CE193C77EEB2A4B9EAD015E"
global IRFA_CITY15_SHA "BFAAFF5A2FE9FC6C056899B549F21D75F2292655A7E665F2EC24A06758A65DA4"
global IRFA_CITY17_SHA "8164FC693B00B6CC44C32373462A8CFB710C4C73A41C1C62627B282AADF966A3"
global IRFA_DENSITY_SHA "9F272C7658AA1D303441F3ED56B051AB22AA2D520261BFD0E3652117651D8BD5"

global IRFA_EXPECTED_N 105435
global IRFA_BASELINE_N 73598
global IRFA_POSITIVE_N 60081
global IRFA_SUBMISSION_PRIMARY_N 73546
global IRFA_SUBMISSION_FULL_AGE_N 73581
global IRFA_STABLE_CITY_CLUSTERS 174
global IRFA_UNRESOLVED_CITY_N 17
global IRFA_AGE_TAIL_N 35

capture mkdir "$IRFA_WORK_ROOT"
capture mkdir "$IRFA_DATA"
capture mkdir "$IRFA_INTERMEDIATE"
capture mkdir "$IRFA_WORK_ROOT/logs"
capture mkdir "$IRFA_PACKAGE_ROOT/data/final"
capture mkdir "$IRFA_RESULTS"
capture mkdir "$IRFA_LOGS"
capture mkdir "$IRFA_PACKAGE_ROOT/validation"
