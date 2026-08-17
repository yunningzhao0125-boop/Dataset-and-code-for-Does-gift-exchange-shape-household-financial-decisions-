* Reviewer replication note
* Purpose: clean the CHFS 2017 roster, household, and master files.
* Inputs: three separate 2017 supplier DTA files under data/raw/chfs.
* Outputs: one labeled 2017 household working DTA feeding manuscript Tables 1-11.
version 18.0
clear all
set more off
set maxvar 32767
set varabbrev off
set linesize 255
capture log close _all

quietly do "config/01_paths.do"
local raw "$IRFA_RAW_ROOT"
local out "$IRFA_WORK_ROOT"
local hh "`raw'/chfs2017_hh_202206.dta"
local ind "`raw'/chfs2017_ind_202206.dta"
local master "`raw'/chfs2017_master_202206.dta"

log using "`out'/logs/03_clean_2017.log", text replace name(w2017)
display "WAVE_BUILD_START=2017"

tempfile roster master_household

use "`ind'", clear
assert _N == 127012
isid hhid pline
gen byte __valid_member = !missing(hhid) & !missing(pline)
bysort hhid: egen int family_size = total(__valid_member)
bysort hhid: egen byte head_count = total(hhead == 1)
bysort hhid: egen int head_flag_missing_count = total(missing(hhead))
gen byte __is_head = hhead == 1

local head_source pline a2005 a2003 a2015 a2022 a2012 a2025b
local head_target head_pline head_birth_year head_sex_raw head_party_raw head_hukou_raw education_code health_code
local head_n : word count `head_source'
forvalues i = 1/`head_n' {
    local source : word `i' of `head_source'
    local target : word `i' of `head_target'
    gen double __head_value = `source' if __is_head == 1 & head_count == 1
    bysort hhid: egen double `target' = max(__head_value)
    drop __head_value
}
gen byte head_anomaly = head_count != 1
bysort hhid: keep if _n == 1
keep hhid family_size head_count head_flag_missing_count head_* education_code health_code
isid hhid
assert _N == 40011
assert head_anomaly == 0
save `roster'

* The 2017 master is person-level; household payload must agree within hhid.
use "`master'", clear
assert _N == 127012
isid hhid pline
foreach v in prov prov_code city_lab county_lab hhcid rural weight_hh total_asset total_income {
    bysort hhid: assert `v' == `v'[1]
}
bysort hhid: gen int master_person_count = _N
bysort hhid: keep if _n == 1
keep hhid prov prov_code city_lab county_lab hhcid rural weight_hh total_asset total_income master_person_count
rename prov province_name
rename prov_code province_id
rename city_lab city_id_source
rename county_lab county_id_source
rename hhcid community_id
rename rural rural_residence
rename weight_hh survey_weight
rename total_asset asset
isid hhid
assert _N == 40011
save `master_household'

use "`hh'", clear
assert _N == 40011
isid hhid
isid hhid_2017
keep hhid hhid_2013 hhid_2015 hhid_2017 track a1111 a2000a a2000b ///
    d3101 d4101b d5102 d6100a h1001 h1004a_1 h1004a_2 g2001 g2004a_1 g2004a_2 ///
    h3380 h3110 h3111 h3112 h3113 d1103 d1103b ///
    b3030_2 c1000bf_7_mc k2101 b3045_2 c3004a_*_mc ///
    b3047_2 c3007_1 c3007_2 c3007_3 c3007_4 c3007_5 c3007_6 k2122 ///
    h2003_1_mc h2003_6_mc h2003_7788_mc

merge 1:1 hhid using `roster', generate(_merge_roster)
assert _merge_roster == 3
merge 1:1 hhid using `master_household', generate(_merge_master)
assert _merge_master == 3

clonevar __final_hhid = hhid_2017
rename hhid link_hhid_generic
rename hhid_2013 source_hhid_2013
rename hhid_2015 source_hhid_2015
rename hhid_2017 source_hhid_2017
rename __final_hhid hhid
gen int year = 2017

gen double hhsize_questionnaire = a1111 if !missing(a1111) & a1111 >= 0 & a1111 == floor(a1111)
gen double hhsize_difference = family_size - hhsize_questionnaire if !missing(hhsize_questionnaire)
gen byte hhsize_discrepancy = hhsize_difference != 0 if !missing(hhsize_difference)

gen double age = year - head_birth_year if head_count == 1 & inrange(head_birth_year, 1900, year)
gen double age_squared = age^2 if !missing(age)
gen byte female = .
replace female = 0 if head_sex_raw == 1
replace female = 1 if head_sex_raw == 2
gen byte party_member = .
replace party_member = 1 if head_party_raw == 2
replace party_member = 0 if inlist(head_party_raw, 1, 3, 4)
gen byte rural_hukou = .
replace rural_hukou = 1 if head_hukou_raw == 1
replace rural_hukou = 0 if inlist(head_hukou_raw, 2, 3, 4)

gen byte stock_participation = .
replace stock_participation = 1 if d3101 == 1
replace stock_participation = 0 if d3101 == 2
gen byte fund_participation = .
replace fund_participation = 1 if d5102 == 1
replace fund_participation = 0 if d5102 == 2
gen byte bond_participation = .
replace bond_participation = 0 if strtrim(d4101b) == ""
replace bond_participation = 1 if !inlist(strtrim(d4101b), "", ".d", ".e", ".n", ".r")
gen byte derivative_participation = .
replace derivative_participation = 1 if d6100a > 0 & d6100a < .
replace derivative_participation = 0 if d6100a == 0 | d6100a == .
gen byte risky_asset_participation = .
replace risky_asset_participation = 1 if stock_participation == 1 | bond_participation == 1 | fund_participation == 1 | derivative_participation == 1
replace risky_asset_participation = 0 if stock_participation == 0 & bond_participation == 0 & fund_participation == 0 & derivative_participation == 0

rename h1001 gift_received_gate
rename g2001 gift_given_gate
rename h1004a_1 gift_received_holiday_yuan
rename h1004a_2 gift_received_ceremony_yuan
rename g2004a_1 gift_given_holiday_yuan
rename g2004a_2 gift_given_ceremony_yuan

gen double gift_received_yuan = .
replace gift_received_yuan = 0 if gift_received_gate == 2 & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
replace gift_received_yuan = cond(missing(gift_received_holiday_yuan), 0, gift_received_holiday_yuan) + cond(missing(gift_received_ceremony_yuan), 0, gift_received_ceremony_yuan) if gift_received_gate == 1 & (!missing(gift_received_holiday_yuan) | !missing(gift_received_ceremony_yuan)) & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
gen byte gift_received_missing_reason = .
replace gift_received_missing_reason = 0 if !missing(gift_received_yuan)
replace gift_received_missing_reason = 1 if missing(gift_received_gate)
replace gift_received_missing_reason = 2 if !missing(gift_received_gate) & !inlist(gift_received_gate, 1, 2)
replace gift_received_missing_reason = 3 if gift_received_gate == 1 & missing(gift_received_holiday_yuan) & missing(gift_received_ceremony_yuan)
replace gift_received_missing_reason = 4 if inlist(gift_received_gate, 1, 2) & ((!missing(gift_received_holiday_yuan) & gift_received_holiday_yuan < 0) | (!missing(gift_received_ceremony_yuan) & gift_received_ceremony_yuan < 0))

gen double gift_received_yuan_strict = .
replace gift_received_yuan_strict = 0 if gift_received_gate == 2
replace gift_received_yuan_strict = gift_received_holiday_yuan + gift_received_ceremony_yuan if gift_received_gate == 1 & !missing(gift_received_holiday_yuan, gift_received_ceremony_yuan) & gift_received_holiday_yuan >= 0 & gift_received_ceremony_yuan >= 0

gen double gift_given_yuan = .
replace gift_given_yuan = 0 if gift_given_gate == 2 & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)
replace gift_given_yuan = cond(missing(gift_given_holiday_yuan), 0, gift_given_holiday_yuan) + cond(missing(gift_given_ceremony_yuan), 0, gift_given_ceremony_yuan) if gift_given_gate == 1 & (!missing(gift_given_holiday_yuan) | !missing(gift_given_ceremony_yuan)) & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)
gen byte gift_given_missing_reason = .
replace gift_given_missing_reason = 0 if !missing(gift_given_yuan)
replace gift_given_missing_reason = 1 if missing(gift_given_gate)
replace gift_given_missing_reason = 2 if !missing(gift_given_gate) & !inlist(gift_given_gate, 1, 2)
replace gift_given_missing_reason = 3 if gift_given_gate == 1 & missing(gift_given_holiday_yuan) & missing(gift_given_ceremony_yuan)
replace gift_given_missing_reason = 4 if inlist(gift_given_gate, 1, 2) & ((!missing(gift_given_holiday_yuan) & gift_given_holiday_yuan < 0) | (!missing(gift_given_ceremony_yuan) & gift_given_ceremony_yuan < 0))

gen double gift_given_yuan_strict = .
replace gift_given_yuan_strict = 0 if gift_given_gate == 2
replace gift_given_yuan_strict = gift_given_holiday_yuan + gift_given_ceremony_yuan if gift_given_gate == 1 & !missing(gift_given_holiday_yuan, gift_given_ceremony_yuan) & gift_given_holiday_yuan >= 0 & gift_given_ceremony_yuan >= 0

gen double gift_exchange_yuan = gift_received_yuan + gift_given_yuan if !missing(gift_received_yuan, gift_given_yuan)
gen double gift_exchange_ln = ln(gift_exchange_yuan + 1) if gift_exchange_yuan >= 0 & !missing(gift_exchange_yuan)
gen double gift_received_ln = ln(gift_received_yuan + 1) if gift_received_yuan >= 0 & !missing(gift_received_yuan)
gen double gift_given_ln = ln(gift_given_yuan + 1) if gift_given_yuan >= 0 & !missing(gift_given_yuan)
gen byte gift_exchange_positive = gift_exchange_yuan > 0 if !missing(gift_exchange_yuan)
gen byte gift_exchange_observed = !missing(gift_exchange_yuan)

gen double gift_exchange_yuan_strict = gift_received_yuan_strict + gift_given_yuan_strict if !missing(gift_received_yuan_strict, gift_given_yuan_strict)
gen double gift_exchange_ln_strict = ln(gift_exchange_yuan_strict + 1) if gift_exchange_yuan_strict >= 0 & !missing(gift_exchange_yuan_strict)
gen double gift_received_ln_strict = ln(gift_received_yuan_strict + 1) if gift_received_yuan_strict >= 0 & !missing(gift_received_yuan_strict)
gen double gift_given_ln_strict = ln(gift_given_yuan_strict + 1) if gift_given_yuan_strict >= 0 & !missing(gift_given_yuan_strict)
gen byte gift_exchange_positive_strict = gift_exchange_yuan_strict > 0 if !missing(gift_exchange_yuan_strict)
gen byte gift_exchange_observed_strict = !missing(gift_exchange_yuan_strict)

gen double household_assets_yuan = asset if !missing(asset) & asset >= 0
gen double household_assets_10k = household_assets_yuan / 10000 if !missing(household_assets_yuan)
gen double household_income_yuan = total_income if !missing(total_income)
gen double household_income_10k = household_income_yuan / 10000 if !missing(household_income_yuan)
gen double household_income_pc_10k = household_income_yuan / family_size / 10000 if !missing(household_income_yuan) & family_size > 0
gen byte household_income_negative = household_income_yuan < 0 if !missing(household_income_yuan)

gen double trust_ordinal = 6 - h3380 if inrange(h3380, 1, 5)
gen byte financial_literacy_risk = .
replace financial_literacy_risk = 1 if h3111 == 1
replace financial_literacy_risk = 0 if inrange(h3111, 2, 6)
gen byte formal_financial_access = .
replace formal_financial_access = 0 if d1103 == 0
replace formal_financial_access = 1 if d1103 > 0 & !missing(d1103)
gen byte informal_credit_candidate = .
replace informal_credit_candidate = 1 if b3030_2 == 1 | c1000bf_7_mc == 1 | k2101 == 1
replace informal_credit_candidate = 0 if k2101 == 2 & informal_credit_candidate != 1
local paper_credit_mc
forvalues loan = 1/6 {
    forvalues source = 1/5 {
        local paper_credit_mc `paper_credit_mc' c3004a_`loan'_`source'_mc
    }
}
egen byte __paper_credit_mc = rowmax(`paper_credit_mc')
gen byte informal_credit_paper = .
replace informal_credit_paper = 1 if inrange(b3045_2, 1, 5) | __paper_credit_mc == 1 | k2101 == 1
replace informal_credit_paper = 0 if k2101 == 2 & missing(informal_credit_paper)
gen byte require_interest_paper = .
replace require_interest_paper = 1 if b3047_2 == 1 | c3007_1 == 1 | c3007_2 == 1 | c3007_3 == 1 | c3007_4 == 1 | c3007_5 == 1 | c3007_6 == 1 | k2122 == 1
replace require_interest_paper = 0 if missing(require_interest_paper) & (b3047_2 == 2 | c3007_1 == 2 | c3007_2 == 2 | c3007_3 == 2 | c3007_4 == 2 | c3007_5 == 2 | c3007_6 == 2 | k2122 == 2)
drop __paper_credit_mc
gen byte lottery_observed = !missing(h2003_1_mc, h2003_6_mc, h2003_7788_mc)
gen byte lottery_participation = .
replace lottery_participation = 1 if lottery_observed == 1 & (h2003_1_mc == 1 | h2003_6_mc == 1)
replace lottery_participation = 0 if lottery_observed == 1 & h2003_1_mc == 0 & h2003_6_mc == 0

gen byte network_size_available = 0
gen byte social_interaction_available = 0
gen byte formal_bank_loan_available = 0
gen byte institutional_trust_available = 0
gen byte safe_asset_available = 0

drop a1111 a2000a a2000b asset total_income d3101 d4101b d5102 d6100a h3380 h3110 h3111 h3112 h3113 d1103 d1103b b3030_2 c1000bf_7_mc k2101 h2003_1_mc h2003_6_mc h2003_7788_mc _merge_roster _merge_master ///
    b3045_2 c3004a_*_mc b3047_2 c3007_1 c3007_2 c3007_3 c3007_4 ///
    c3007_5 c3007_6 k2122

label data "IRFA CHFS 2017 household working data"
label variable hhid "Wave-specific household identifier"
label variable year "Survey year"
label variable family_size "Roster household size"
label variable age "Household head age"
label variable age_squared "Household head age squared"
label variable female "Female household head"
label variable party_member "CCP household head"
label variable rural_hukou "Rural hukou household head"
label variable stock_participation "Household holds a stock account"
label variable risky_asset_participation "Household holds any mapped risky asset"
label variable gift_exchange_ln "Log of total gift exchange plus one"
label variable gift_received_yuan_strict "Strict gifts received, RMB"
label variable gift_given_yuan_strict "Strict gifts given, RMB"
label variable gift_exchange_yuan_strict "Strict total gift exchange, RMB"
label variable gift_received_ln_strict "Strict log gifts received plus one"
label variable gift_given_ln_strict "Strict log gifts given plus one"
label variable gift_exchange_ln_strict "Strict log total gift exchange plus one"
label variable gift_exchange_positive_strict "Strict total gift exchange is positive"
label variable gift_exchange_observed_strict "Strict total gift exchange is observed"
label variable household_assets_10k "Total household assets, RMB 10,000"
label variable household_income_pc_10k "Per-capita household income, RMB 10,000"
label variable rural_residence "Household resides in a rural area"
label variable province_id "Province code"
label variable city_id_source "Source city identifier"
label variable community_id "Community identifier"
label variable survey_weight "Household survey weight"
label variable trust_ordinal "Interpersonal trust, higher is more trust"
label variable financial_literacy_risk "Correct stock versus fund risk item"
label variable formal_financial_access "Household has a formal bank account"
label variable informal_credit_candidate "Broad informal-credit candidate measure"
label variable informal_credit_paper "Paper-mapped informal-credit proxy"
label variable require_interest_paper "Any mapped informal loan carries interest"
label variable lottery_observed "Gambling-income item is observed"
label variable master_person_count "Master person rows in household"

order hhid year source_hhid_2013 source_hhid_2015 source_hhid_2017 link_hhid_generic track province_id province_name city_id_source county_id_source community_id rural_residence survey_weight head_count head_anomaly family_size master_person_count
sort hhid
isid hhid
assert _N == 40011
compress
save "`out'/data/intermediate/irfa_2017_household_working.dta", replace

display "WAVE_BUILD_RESULT=PASS WAVE=2017 N=" _N
display "WAVE_BUILD_2017=PASS"
log close w2017
