* Reviewer replication note
* Purpose: clean the CHFS 2015 roster, household, and master files.
* Inputs: three separate 2015 supplier DTA files under data/raw/chfs.
* Outputs: one labeled 2015 household working DTA feeding manuscript Tables 1-11.
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
local hh "`raw'/chfs2015_hh_20191120_version14.dta"
local ind "`raw'/chfs2015_ind_20191120_version14.dta"
local master "`raw'/chfs2015_master_202203.dta"

log using "`out'/logs/02_clean_2015.log", text replace name(w2015)
display "WAVE_BUILD_START=2015"

tempfile roster master_household

* hhid_2015 is the complete current-wave person-to-household key.
use "`ind'", clear
assert _N == 133183
isid hhid_2015 pline
gen byte __valid_member = !missing(hhid_2015) & !missing(pline)
bysort hhid_2015: egen int family_size = total(__valid_member)
bysort hhid_2015: egen byte head_count = total(hhead == 1)
bysort hhid_2015: egen int head_flag_missing_count = total(missing(hhead))
gen byte __is_head = hhead == 1

local head_source pline a2005 a2003 a2015 a2022 a2012 a2025b
local head_target head_pline head_birth_year head_sex_raw head_party_raw head_hukou_raw education_code health_code
local head_n : word count `head_source'
forvalues i = 1/`head_n' {
    local source : word `i' of `head_source'
    local target : word `i' of `head_target'
    gen double __head_value = `source' if __is_head == 1 & head_count == 1
    bysort hhid_2015: egen double `target' = max(__head_value)
    drop __head_value
}
gen byte head_anomaly = head_count != 1
bysort hhid_2015: keep if _n == 1
keep hhid_2015 family_size head_count head_flag_missing_count head_* education_code health_code
isid hhid_2015
assert _N == 37289
assert head_anomaly == 0
save `roster'

* The 2015 master uses generic hhid, not hhid_2015.
use "`master'", clear
assert _N == 37289
isid hhid
keep hhid province prov_CHN city_lab hhcid rural swgt
rename province province_id
rename prov_CHN province_name
rename city_lab city_code_source
tostring city_code_source, generate(city_id_source) format(%03.0f) force
rename hhcid community_id
rename rural rural_residence
rename swgt survey_weight
save `master_household'

use "`hh'", clear
assert _N == 37289
isid hhid
isid hhid_2015
assert !missing(hhid_2013) if track == 1
assert missing(hhid_2013) if track == 0
keep hhid hhid_2013 hhid_2015 track a1111 a2000a a2000b asset total_income ///
    d3101 d4101a d5102 d6100a h1001 h1004a_1 h1004a_2 g2001 g2004a_1 g2004a_2 ///
    a4015 a4007aa d1101 b3030_1 b3030_2 c3001 c7047 k2101 ///
    b3045_1 b3045_2 c3004a_1_mc c3004a_2_mc c3004a_3_mc ///
    c3004a_4_mc c3004a_5_mc b3047_1 b3047_2 c3007 k2122 ///
    h2003_1_mc h2003_6_mc h2003_8_mc

merge 1:1 hhid_2015 using `roster', generate(_merge_roster)
assert _merge_roster == 3
merge 1:1 hhid using `master_household', generate(_merge_master)
assert _merge_master == 3

clonevar __final_hhid = hhid_2015
rename hhid link_hhid_generic
rename hhid_2013 source_hhid_2013
rename hhid_2015 source_hhid_2015
rename __final_hhid hhid
gen str10 source_hhid_2017 = ""
gen int year = 2015

gen double hhsize_questionnaire = 1 + a2000a + a2000b if !missing(a2000a, a2000b) & a2000a >= 0 & a2000b >= 0 & a2000a == floor(a2000a) & a2000b == floor(a2000b)
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
replace bond_participation = 0 if strtrim(d4101a) == ""
replace bond_participation = 1 if !inlist(strtrim(d4101a), "", ".d", ".e", ".n", ".r")
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

gen double trust_ordinal = 6 - a4015 if inrange(a4015, 1, 5)
gen byte financial_literacy_risk = .
replace financial_literacy_risk = 1 if a4007aa == 1
replace financial_literacy_risk = 0 if inrange(a4007aa, 2, 5)
gen byte formal_financial_access = .
replace formal_financial_access = 1 if d1101 == 1
replace formal_financial_access = 0 if d1101 == 2
gen byte informal_credit_candidate = .
replace informal_credit_candidate = 1 if b3030_1 == 1 | b3030_2 == 1 | c3001 == 1 | c7047 == 1 | k2101 == 1
replace informal_credit_candidate = 0 if k2101 == 2 & informal_credit_candidate != 1
egen byte __paper_credit_mc = rowmax(c3004a_1_mc c3004a_2_mc c3004a_3_mc c3004a_4_mc c3004a_5_mc)
gen byte informal_credit_paper = .
replace informal_credit_paper = 1 if inrange(b3045_1, 1, 5) | inrange(b3045_2, 1, 5) | __paper_credit_mc == 1 | k2101 == 1
replace informal_credit_paper = 0 if k2101 == 2 & missing(informal_credit_paper)
gen byte require_interest_paper = .
replace require_interest_paper = 1 if b3047_1 == 1 | b3047_2 == 1 | c3007 == 1 | k2122 == 1
replace require_interest_paper = 0 if missing(require_interest_paper) & (b3047_1 == 2 | b3047_2 == 2 | c3007 == 2 | k2122 == 2)
drop __paper_credit_mc
gen byte lottery_observed = !missing(h2003_1_mc, h2003_6_mc, h2003_8_mc)
gen byte lottery_participation = .
replace lottery_participation = 1 if lottery_observed == 1 & (h2003_1_mc == 1 | h2003_6_mc == 1)
replace lottery_participation = 0 if lottery_observed == 1 & h2003_1_mc == 0 & h2003_6_mc == 0

gen byte network_size_available = 0
gen byte social_interaction_available = 0
gen byte formal_bank_loan_available = 0
gen byte institutional_trust_available = 0
gen byte safe_asset_available = 0

drop a1111 a2000a a2000b asset total_income d3101 d4101a d5102 d6100a a4015 a4007aa d1101 b3030_1 b3030_2 c3001 c7047 k2101 h2003_1_mc h2003_6_mc h2003_8_mc _merge_roster _merge_master ///
    b3045_1 b3045_2 c3004a_1_mc c3004a_2_mc c3004a_3_mc ///
    c3004a_4_mc c3004a_5_mc b3047_1 b3047_2 c3007 k2122

label data "IRFA CHFS 2015 household working data"
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

order hhid year source_hhid_2013 source_hhid_2015 source_hhid_2017 link_hhid_generic track province_id province_name city_id_source community_id rural_residence survey_weight head_count head_anomaly family_size
sort hhid
isid hhid
assert _N == 37289
compress
save "`out'/data/intermediate/irfa_2015_household_working.dta", replace

display "WAVE_BUILD_RESULT=PASS WAVE=2015 N=" _N
display "WAVE_BUILD_2015=PASS"
log close w2015
