* Reviewer replication note
* Purpose: construct the parental-CCP-membership instrument from wave-specific CHFS household files.
* Inputs: package-contained 2013, 2015, and 2017 CHFS household DTA files.
* Outputs: household-year parent-party supplement, construction audit CSV, and a complete Stata log.
version 18.0
clear all
set more off
set varabbrev off
capture log close parent_party_build

quietly do "config/01_paths.do"
log using "$IRFA_LOGS/32_build_parent_party.log", text replace name(parent_party_build)
display "PARENT_PARTY_BUILD_START"

tempfile parent13 parent15 parent17
tempname audit_post
postfile `audit_post' int year long raw_n valid_n party_n nonparty_n missing_n ///
    int party_code str20 father_field str20 mother_field byte value_labels_present ///
    str80 questionnaire_file str12 questionnaire_pages str244 evidence_note ///
    using "$IRFA_EVIDENCE/parent_party_construction_audit.dta", replace

use "$IRFA_RAW_ROOT/chfs2013_hh_20191120_version14.dta", clear
assert _N == 28141
isid hhid_2013
assert inlist(a2033_1, 1, 2, 3) if !missing(a2033_1)
assert inlist(a2033_2, 1, 2, 3) if !missing(a2033_2)
local value_label_1 : value label a2033_1
local value_label_2 : value label a2033_2
local labels_present = (`"`value_label_1'"' != "" | `"`value_label_2'"' != "")
gen byte father_party = (a2033_1 == 1) if inlist(a2033_1, 1, 2, 3)
gen byte mother_party = (a2033_2 == 1) if inlist(a2033_2, 1, 2, 3)
gen byte parent_party = 1 if father_party == 1 | mother_party == 1
replace parent_party = 0 if father_party == 0 & mother_party == 0
quietly count if !missing(parent_party)
local valid_n = r(N)
quietly count if parent_party == 1
local party_n = r(N)
quietly count if parent_party == 0
local nonparty_n = r(N)
local missing_n = _N - `valid_n'
post `audit_post' (2013) (_N) (`valid_n') (`party_n') (`nonparty_n') (`missing_n') ///
    (1) ("a2033_1") ("a2033_2") (`labels_present') ///
    ("2013年家庭金融调查问卷.pdf") ("PDF 19") ///
    ("A2033 columns identify father then mother; codes are 1 CCP, 2 other party, 3 general public. The English questionnaire conflicts by listing CCP as code 2; Chinese questionnaire and observed DTA support code 1.")
gen int year = 2013
rename hhid_2013 hhid
keep hhid year parent_party father_party mother_party
save `parent13'

use "$IRFA_RAW_ROOT/chfs2015_hh_20191120_version14.dta", clear
assert _N == 37289
isid hhid_2015
assert inlist(a2033_1, 1, 2, 3, 4) if !missing(a2033_1)
assert inlist(a2033_2, 1, 2, 3, 4) if !missing(a2033_2)
local value_label_1 : value label a2033_1
local value_label_2 : value label a2033_2
local labels_present = (`"`value_label_1'"' != "" | `"`value_label_2'"' != "")
gen byte mother_party = (a2033_1 == 2) if inlist(a2033_1, 1, 2, 3, 4)
gen byte father_party = (a2033_2 == 2) if inlist(a2033_2, 1, 2, 3, 4)
gen byte parent_party = 1 if father_party == 1 | mother_party == 1
replace parent_party = 0 if father_party == 0 & mother_party == 0
quietly count if !missing(parent_party)
local valid_n = r(N)
quietly count if parent_party == 1
local party_n = r(N)
quietly count if parent_party == 0
local nonparty_n = r(N)
local missing_n = _N - `valid_n'
post `audit_post' (2015) (_N) (`valid_n') (`party_n') (`nonparty_n') (`missing_n') ///
    (2) ("a2033_2") ("a2033_1") (`labels_present') ///
    ("2015年家庭金融调查问卷20161130.pdf") ("PDF 24-25") ///
    ("A2033_1 is mother and A2033_2 is father; codes are 1 Youth League, 2 CCP, 3 other party, 4 general public.")
gen int year = 2015
drop hhid
rename hhid_2015 hhid
keep hhid year parent_party father_party mother_party
save `parent15'

use "$IRFA_RAW_ROOT/chfs2017_hh_202206.dta", clear
assert _N == 40011
isid hhid_2017
assert inlist(a2033_1, 1, 2, 3, 4) if !missing(a2033_1)
assert inlist(a2033_2, 1, 2, 3, 4) if !missing(a2033_2)
local value_label_1 : value label a2033_1
local value_label_2 : value label a2033_2
local labels_present = (`"`value_label_1'"' != "" | `"`value_label_2'"' != "")
gen byte mother_party = (a2033_1 == 2) if inlist(a2033_1, 1, 2, 3, 4)
gen byte father_party = (a2033_2 == 2) if inlist(a2033_2, 1, 2, 3, 4)
gen byte parent_party = 1 if father_party == 1 | mother_party == 1
replace parent_party = 0 if father_party == 0 & mother_party == 0
quietly count if !missing(parent_party)
local valid_n = r(N)
quietly count if parent_party == 1
local party_n = r(N)
quietly count if parent_party == 0
local nonparty_n = r(N)
local missing_n = _N - `valid_n'
post `audit_post' (2017) (_N) (`valid_n') (`party_n') (`nonparty_n') (`missing_n') ///
    (2) ("a2033_2") ("a2033_1") (`labels_present') ///
    ("2017年中国家庭金融调查（CHFS）问卷.pdf") ("PDF 18") ///
    ("A2033_1 is mother and A2033_2 is father; codes are 1 Youth League, 2 CCP, 3 other party, 4 general public.")
gen int year = 2017
drop hhid
rename hhid_2017 hhid
keep hhid year parent_party father_party mother_party
save `parent17'

postclose `audit_post'
use `parent13', clear
append using `parent15' `parent17'
assert _N == 105441
isid hhid year
label variable parent_party "Parent CCP member"
label variable father_party "Father CCP member"
label variable mother_party "Mother CCP member"
sort year hhid
save "$IRFA_PARENT_PARTY", replace

use "$IRFA_EVIDENCE/parent_party_construction_audit.dta", clear
sort year
export delimited using "$IRFA_EVIDENCE/parent_party_construction_audit.csv", replace
assert value_labels_present == 0
assert party_code == 1 & father_field == "a2033_1" & mother_field == "a2033_2" if year == 2013
assert party_code == 2 & father_field == "a2033_2" & mother_field == "a2033_1" if inlist(year, 2015, 2017)
assert questionnaire_pages == "PDF 19" if year == 2013
assert questionnaire_pages == "PDF 24-25" if year == 2015
assert questionnaire_pages == "PDF 18" if year == 2017

display "PARENT_PARTY_VALUE_LABEL_LIMITATION=RAW_DTA_LABELS_ABSENT"
display "PARENT_PARTY_QUESTIONNAIRE_CODING=PASS"
display "PARENT_PARTY_BUILD=PASS"
display "PARENT_PARTY_MODULE=PASS"
log close parent_party_build
