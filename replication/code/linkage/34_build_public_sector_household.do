* Build household-level public-sector employment flags from all household members.
* Official questionnaire mapping:
* 2013: A3014=1/2 government/public institution; A3014=3 & A3016=1 state-owned.
* 2015: A3014a=1/2 government/public institution; A3014a=3 state-owned.
* 2017: A3106=1 government/public institution; A3106=2 state-owned.
version 18.0
clear all
set more off
set varabbrev off
capture log close _all

quietly do "config/01_paths.do"
log using "$IRFA_LOGS/34_build_public_sector_household.log", text replace name(public_sector)

tempfile sector13 sector15 sector17 map17
tempname audit coding
postfile `audit' int year long households households_with_unit_code ///
    narrow_households broad_households using "$IRFA_EVIDENCE/public_sector_household_audit.dta", replace
postfile `coding' int year str16 unit_field str16 ownership_field ///
    str80 narrow_definition str120 broad_definition str40 questionnaire_page ///
    using "$IRFA_EVIDENCE/public_sector_coding_map.dta", replace

* 2013: unit type and ownership are separate fields.
use "$IRFA_RAW_ROOT/chfs2013_ind_20191120_version14.dta", clear
isid hhid_2013 pline
gen byte __unit_observed = !missing(a3014)
gen byte __narrow_member = inlist(a3014, 1, 2)
gen byte __broad_member = __narrow_member | (a3014 == 3 & a3016 == 1)
bysort hhid_2013: egen int employment_unit_observed_members = total(__unit_observed)
bysort hhid_2013: egen byte public_sector_narrow = max(__narrow_member)
bysort hhid_2013: egen byte public_sector_broad = max(__broad_member)
bysort hhid_2013: keep if _n == 1
rename hhid_2013 hhid
gen int year = 2013
quietly count
local households = r(N)
quietly count if employment_unit_observed_members > 0
local covered = r(N)
quietly count if public_sector_narrow == 1
local narrow = r(N)
quietly count if public_sector_broad == 1
local broad = r(N)
post `audit' (2013) (`households') (`covered') (`narrow') (`broad')
post `coding' (2013) ("a3014") ("a3016") ///
    ("A3014 in 1,2") ("narrow or A3014=3 and A3016=1") ("Chinese questionnaire pp. 27-28")
keep hhid year public_sector_narrow public_sector_broad employment_unit_observed_members
save `sector13'

* 2015: government/public institution and state ownership share A3014a.
use "$IRFA_RAW_ROOT/chfs2015_ind_20191120_version14.dta", clear
isid hhid_2015 pline
gen byte __unit_observed = !missing(a3014a)
gen byte __narrow_member = inlist(a3014a, 1, 2)
gen byte __broad_member = inlist(a3014a, 1, 2, 3)
bysort hhid_2015: egen int employment_unit_observed_members = total(__unit_observed)
bysort hhid_2015: egen byte public_sector_narrow = max(__narrow_member)
bysort hhid_2015: egen byte public_sector_broad = max(__broad_member)
bysort hhid_2015: keep if _n == 1
drop hhid
rename hhid_2015 hhid
gen int year = 2015
quietly count
local households = r(N)
quietly count if employment_unit_observed_members > 0
local covered = r(N)
quietly count if public_sector_narrow == 1
local narrow = r(N)
quietly count if public_sector_broad == 1
local broad = r(N)
post `audit' (2015) (`households') (`covered') (`narrow') (`broad')
post `coding' (2015) ("a3014a") ("") ///
    ("A3014a in 1,2") ("A3014a in 1,2,3") ("Chinese questionnaire pp. 35-36")
keep hhid year public_sector_narrow public_sector_broad employment_unit_observed_members
save `sector15'

* 2017: map the generic household ID in the individual file to hhid_2017.
use "$IRFA_RAW_ROOT/chfs2017_hh_202206.dta", clear
isid hhid
isid hhid_2017
keep hhid hhid_2017
save `map17'

use "$IRFA_RAW_ROOT/chfs2017_ind_202206.dta", clear
isid hhid pline
merge m:1 hhid using `map17', assert(match) nogen
gen byte __unit_observed = !missing(a3106)
gen byte __narrow_member = a3106 == 1
gen byte __broad_member = inlist(a3106, 1, 2)
bysort hhid_2017: egen int employment_unit_observed_members = total(__unit_observed)
bysort hhid_2017: egen byte public_sector_narrow = max(__narrow_member)
bysort hhid_2017: egen byte public_sector_broad = max(__broad_member)
bysort hhid_2017: keep if _n == 1
drop hhid
rename hhid_2017 hhid
gen int year = 2017
quietly count
local households = r(N)
quietly count if employment_unit_observed_members > 0
local covered = r(N)
quietly count if public_sector_narrow == 1
local narrow = r(N)
quietly count if public_sector_broad == 1
local broad = r(N)
post `audit' (2017) (`households') (`covered') (`narrow') (`broad')
post `coding' (2017) ("a3106") ("") ///
    ("A3106=1") ("A3106 in 1,2") ("Chinese questionnaire p. 19")
keep hhid year public_sector_narrow public_sector_broad employment_unit_observed_members
save `sector17'

postclose `audit'
postclose `coding'

use `sector13', clear
append using `sector15' `sector17'
isid hhid year
assert inlist(public_sector_narrow, 0, 1)
assert inlist(public_sector_broad, 0, 1)
assert public_sector_broad >= public_sector_narrow
label variable public_sector_narrow "Any member in government or public institution"
label variable public_sector_broad "Any member in government, public institution, or SOE"
label variable employment_unit_observed_members "Members with observed current-employer type"
sort year hhid
save "$IRFA_INTERMEDIATE/irfa_public_sector_household.dta", replace

use "$IRFA_EVIDENCE/public_sector_household_audit.dta", clear
sort year
export delimited using "$IRFA_EVIDENCE/public_sector_household_audit.csv", replace
use "$IRFA_EVIDENCE/public_sector_coding_map.dta", clear
sort year
export delimited using "$IRFA_EVIDENCE/public_sector_coding_map.csv", replace

display "PUBLIC_SECTOR_HOUSEHOLD_BUILD=PASS"
display "PUBLIC_SECTOR_MODULE=PASS"
log close public_sector
exit 0
