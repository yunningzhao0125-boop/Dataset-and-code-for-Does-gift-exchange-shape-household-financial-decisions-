* Reviewer replication note
* Purpose: append three cleaned waves and construct harmonized analysis variables.
* Inputs: 2013, 2015, and 2017 household working DTA files.
* Outputs: fully English-labeled working/final DTA files and sample-flow evidence.
version 18.0
clear all
set more off
set maxvar 32767
set varabbrev off
set linesize 255
capture log close _all

quietly do "config/01_paths.do"
local out "$IRFA_WORK_ROOT"
log using "`out'/logs/04_append_construct.log", text replace name(append)
display "APPEND_START"

tempfile cutoffs groupcuts sampleflow
tempname cutoffh grouph flowh

use "`out'/data/intermediate/irfa_2013_household_working.dta", clear
append using "`out'/data/intermediate/irfa_2015_household_working.dta" ///
    "`out'/data/intermediate/irfa_2017_household_working.dta"

assert _N == 105441
count if year == 2013
assert r(N) == 28141
count if year == 2015
assert r(N) == 37289
count if year == 2017
assert r(N) == 40011
assert inlist(year, 2013, 2015, 2017)
isid hhid year

assert survey_weight > 0 if !missing(survey_weight)
bysort year: egen double survey_weight_wave_mean = mean(survey_weight)
gen double survey_weight_wave_norm = survey_weight / survey_weight_wave_mean if survey_weight > 0
bysort year: egen double __weight_norm_mean = mean(survey_weight_wave_norm)
assert abs(__weight_norm_mean - 1) < 1e-10
drop __weight_norm_mean

replace county_id_source = "" if missing(county_id_source)
gen str24 city_cluster_key = ""
replace city_cluster_key = string(province_id, "%02.0f") + "_" + city_id_source if !missing(province_id) & !missing(city_id_source)
egen long city_id = group(city_cluster_key)
replace city_id = . if missing(city_cluster_key)
label variable city_cluster_key "Legacy wave-specific province-city source key"
label variable city_id "Legacy numeric city identifier; not stable across waves"
label variable city_code_source "Source numeric city identifier"

* Preserve raw fields and create pooled P1/P99 versions used by analysis code.
postfile `cutoffh' str32 variable double p1 p99 long nonmissing_n using `cutoffs', replace
local rawvars family_size household_assets_10k household_income_pc_10k
local winvars family_size_w household_assets_10k_w household_income_pc_10k_w
local nvars : word count `rawvars'
forvalues i = 1/`nvars' {
    local rawvar : word `i' of `rawvars'
    local winvar : word `i' of `winvars'
    quietly count if !missing(`rawvar')
    local nonmissing_n = r(N)
    quietly _pctile `rawvar' if !missing(`rawvar'), p(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    gen double `winvar' = `rawvar'
    replace `winvar' = `p1' if `winvar' < `p1' & !missing(`winvar')
    replace `winvar' = `p99' if `winvar' > `p99' & !missing(`winvar')
    post `cutoffh' ("`rawvar'") (`p1') (`p99') (`nonmissing_n')
}
postclose `cutoffh'
preserve
use `cutoffs', clear
export delimited using "`out'/evidence/pooled_p1_p99_cutoffs.csv", replace
restore

label variable family_size_w "Roster household size, pooled P1/P99"
label variable household_assets_10k_w "Total household assets, pooled P1/P99"
label variable household_income_pc_10k_w "Per-capita income, pooled P1/P99"

* Manuscript-defined heterogeneity groups are frozen before estimation.
postfile `grouph' str32 variable double cutoff str24 rule using `groupcuts', replace
quietly summarize household_assets_10k_w if head_anomaly == 0, meanonly
local assets_mean = r(mean)
gen byte high_assets_mean = household_assets_10k_w >= `assets_mean' if !missing(household_assets_10k_w)
post `grouph' ("household_assets_10k_w") (`assets_mean') ("pooled_head_valid_mean")
quietly summarize household_income_pc_10k_w if head_anomaly == 0, meanonly
local income_mean = r(mean)
gen byte high_income_mean = household_income_pc_10k_w >= `income_mean' if !missing(household_income_pc_10k_w)
post `grouph' ("household_income_pc_10k_w") (`income_mean') ("pooled_head_valid_mean")
postclose `grouph'
preserve
use `groupcuts', clear
export delimited using "`out'/evidence/heterogeneity_cutoffs.csv", replace
restore

gen byte small_family = family_size <= 3 if !missing(family_size)
gen byte head_age_group = .
replace head_age_group = 1 if age < 45 & !missing(age)
replace head_age_group = 2 if inrange(age, 45, 59)
replace head_age_group = 3 if age >= 60 & !missing(age)
label define head_age_group_lbl 1 "Young (<45)" 2 "Middle-aged (45-59)" 3 "Older (60+)"
label values head_age_group head_age_group_lbl
gen byte head_age_under18 = age < 18 if !missing(age)
gen byte head_age_over100 = age > 100 if !missing(age)
gen byte age_primary_valid = inrange(age, 18, 100) if !missing(age)
gen byte trust_binary = trust_ordinal >= 3 if !missing(trust_ordinal)
clonevar high_trust = trust_binary

gen byte sample_head_valid = head_count == 1 & head_anomaly == 0
egen int core_outcome_missing_n = rowmiss(stock_participation risky_asset_participation)
egen int core_control_missing_n = rowmiss(age female family_size_w party_member rural_hukou household_assets_10k_w household_income_pc_10k_w rural_residence province_id city_id)
gen byte sample_core_outcomes = core_outcome_missing_n == 0
gen byte sample_core_controls = sample_head_valid == 1 & core_control_missing_n == 0
gen byte sample_gift_observed_common = sample_core_outcomes == 1 & sample_core_controls == 1 & gift_exchange_observed == 1 & !missing(gift_exchange_ln)
gen byte sample_baseline_common = sample_gift_observed_common == 1 & gift_exchange_positive == 1
gen byte sample_gift_strict_common = sample_core_outcomes == 1 & sample_core_controls == 1 & gift_exchange_observed_strict == 1 & !missing(gift_exchange_ln_strict)
gen byte sample_gift_strict_positive = sample_gift_strict_common == 1 & gift_exchange_positive_strict == 1
gen byte sample_incremental_literacy = sample_baseline_common == 1 & !missing(financial_literacy_risk)
gen byte sample_incremental_access = sample_baseline_common == 1 & !missing(formal_financial_access)
gen byte sample_mechanism_credit = sample_baseline_common == 1 & !missing(informal_credit_candidate)
gen byte sample_mechanism_credit_paper = sample_baseline_common == 1 & !missing(informal_credit_paper)
gen byte sample_mechanism_interest = sample_baseline_common == 1 & !missing(require_interest_paper)
gen byte sample_mechanism_trust = sample_baseline_common == 1 & !missing(trust_binary)

assert inlist(stock_participation, 0, 1) if !missing(stock_participation)
assert inlist(risky_asset_participation, 0, 1) if !missing(risky_asset_participation)
assert inlist(female, 0, 1) if !missing(female)
assert inlist(party_member, 0, 1) if !missing(party_member)
assert inlist(rural_hukou, 0, 1) if !missing(rural_hukou)
assert inlist(rural_residence, 0, 1) if !missing(rural_residence)
assert gift_received_yuan == 0 if gift_received_gate == 2 & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
assert gift_given_yuan == 0 if gift_given_gate == 2 & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)
assert missing(gift_received_yuan) if gift_received_gate == 2 & ((!missing(gift_received_holiday_yuan) & gift_received_holiday_yuan < 0) | (!missing(gift_received_ceremony_yuan) & gift_received_ceremony_yuan < 0))
assert missing(gift_given_yuan) if gift_given_gate == 2 & ((!missing(gift_given_holiday_yuan) & gift_given_holiday_yuan < 0) | (!missing(gift_given_ceremony_yuan) & gift_given_ceremony_yuan < 0))
assert gift_exchange_yuan >= 0 if !missing(gift_exchange_yuan)
assert gift_exchange_positive == (gift_exchange_yuan > 0) if !missing(gift_exchange_yuan)

* Compatibility aliases allow the corrected data to replace the old dataset in legacy regressions.
clonevar Stock = stock_participation
clonevar Risky_Financial_Assets = risky_asset_participation
clonevar gift2 = gift_exchange_ln
clonevar giftin2 = gift_received_ln
clonevar giftout2 = gift_given_ln
clonevar gift_dummy = gift_exchange_positive
clonevar age2 = age_squared
clonevar family_member = family_size_w
clonevar hukou = rural_hukou
clonevar asset1 = household_assets_10k_w
clonevar total_income1 = household_income_pc_10k_w
clonevar rural = rural_residence
clonevar proid = province_id
clonevar Borrowing_or_lending = informal_credit_paper
clonevar Require_interest = require_interest_paper
clonevar trust = trust_binary
clonevar lottery = lottery_participation

label variable source_hhid_2013 "Official 2013 household link identifier"
label variable source_hhid_2015 "Official 2015 household link identifier"
label variable source_hhid_2017 "Official 2017 household link identifier"
label variable link_hhid_generic "Source generic household identifier"
label variable track "Official follow-up household indicator"
label variable province_name "Province name"
label variable county_id_source "Source county identifier"
label variable community_id "Community identifier"
label variable head_count "Number of documented household heads"
label variable head_flag_missing_count "Missing head flags in household roster"
label variable head_pline "Household head person line number"
label variable head_birth_year "Household head birth year"
label variable head_sex_raw "Raw household head sex code"
label variable head_party_raw "Raw household head party code"
label variable head_hukou_raw "Raw household head hukou code"
label variable education_code "Raw household head education code"
label variable health_code "Raw household head health code"
label variable head_anomaly "Household does not have exactly one head"
label variable hhsize_questionnaire "Questionnaire household-size comparator"
label variable hhsize_difference "Roster minus questionnaire household size"
label variable hhsize_discrepancy "Roster and questionnaire sizes differ"
label variable bond_participation "Household holds a mapped bond"
label variable fund_participation "Household holds a fund"
label variable derivative_participation "Household holds a derivative"
label variable gift_received_gate "Raw gift-received gate code"
label variable gift_given_gate "Raw gift-given gate code"
label variable gift_received_holiday_yuan "Received holiday gifts, nominal RMB"
label variable gift_received_ceremony_yuan "Received ceremony gifts, nominal RMB"
label variable gift_given_holiday_yuan "Given holiday gifts, nominal RMB"
label variable gift_given_ceremony_yuan "Given ceremony gifts, nominal RMB"
label variable gift_received_yuan "Gate-aware received gifts, nominal RMB"
label variable gift_given_yuan "Gate-aware given gifts, nominal RMB"
label variable gift_exchange_yuan "Gate-aware total gift exchange, nominal RMB"
label variable survey_weight_wave_mean "Mean household survey weight within wave"
label variable survey_weight_wave_norm "Household survey weight normalized to wave mean one"
label variable gift_received_ln "Log of received gifts plus one"
label variable gift_given_ln "Log of given gifts plus one"
label variable gift_exchange_positive "Gate-aware gift exchange is positive"
label variable gift_exchange_observed "Gate-aware gift exchange is observed"
label variable gift_received_missing_reason "Reason gate-aware received gifts are missing"
label variable gift_given_missing_reason "Reason gate-aware given gifts are missing"
label variable household_assets_yuan "Total household assets, nominal RMB"
label variable household_income_yuan "Total household income, nominal RMB"
label variable household_income_10k "Total household income, RMB 10,000"
label variable household_income_negative "Total household income is negative"
label variable lottery_participation "Household reports mapped gambling activity"
label variable lottery_observed "Gambling-income item is observed"
label variable network_size_available "Network-size measure is available"
label variable social_interaction_available "Social-interaction measure is available"
label variable formal_bank_loan_available "Formal bank-loan measure is available"
label variable institutional_trust_available "Institutional-trust measure is available"
label variable safe_asset_available "Safe-asset measure is available"
label variable high_assets_mean "Assets at or above pooled mean"
label variable high_income_mean "Per-capita income at or above pooled mean"
label variable small_family "Household has three or fewer members"
label variable head_age_group "Household head age group"
label variable head_age_under18 "Household head is younger than 18"
label variable head_age_over100 "Household head is older than 100"
label variable age_primary_valid "Household-head age is between 18 and 100"
label variable high_trust "Interpersonal trust score at least three"
label variable trust_binary "High interpersonal trust indicator"
label variable sample_head_valid "Exactly one documented household head"
label variable sample_core_outcomes "Both core outcomes are observed"
label variable sample_core_controls "All baseline controls are observed"
label variable sample_gift_observed_common "Common complete sample with observed Gift"
label variable sample_baseline_common "Common baseline sample with positive Gift"
label variable sample_gift_strict_common "Common complete sample with observed strict Gift"
label variable sample_gift_strict_positive "Common complete sample with positive strict Gift"
label variable sample_incremental_literacy "Baseline sample with stock-fund risk item"
label variable sample_incremental_access "Baseline sample with formal access"
label variable sample_mechanism_credit "Baseline sample with broad credit candidate"
label variable sample_mechanism_credit_paper "Baseline sample with paper credit proxy"
label variable sample_mechanism_interest "Baseline sample with interest proxy"
label variable sample_mechanism_trust "Baseline sample with interpersonal trust"
label variable core_outcome_missing_n "Missing core outcome count"
label variable core_control_missing_n "Missing baseline control count"
label variable Stock "Legacy alias: stock participation"
label variable Risky_Financial_Assets "Legacy alias: risky asset participation"
label variable gift2 "Legacy alias: gate-aware log gift exchange"
label variable giftin2 "Legacy alias: gate-aware log gifts received"
label variable giftout2 "Legacy alias: gate-aware log gifts given"
label variable gift_dummy "Legacy alias: gate-aware positive gift exchange"
label variable age2 "Legacy alias: household head age squared"
label variable family_member "Legacy alias: winsorized household size"
label variable hukou "Legacy alias: rural hukou"
label variable asset1 "Legacy alias: winsorized total assets"
label variable total_income1 "Legacy alias: winsorized per-capita income"
label variable rural "Legacy alias: rural residence"
label variable proid "Legacy alias: province code"
label variable Borrowing_or_lending "Legacy alias: paper informal-credit proxy"
label variable Require_interest "Legacy alias: informal loan carries interest"
label variable trust "Legacy alias: high interpersonal trust"
label variable lottery "Legacy alias: mapped gambling activity"

sort hhid year
isid hhid year
label data "IRFA CHFS 2013-2017 household-year working data"
compress
save "`out'/data/irfa_household_year_working.dta", replace

postfile `flowh' str40 stage long observations using `sampleflow', replace
post `flowh' ("working_all_households") (_N)
quietly count if sample_head_valid == 1
post `flowh' ("unique_head_households") (r(N))
quietly count if sample_core_outcomes == 1
post `flowh' ("both_outcomes_observed") (r(N))
quietly count if sample_core_controls == 1
post `flowh' ("baseline_controls_complete") (r(N))
quietly count if sample_head_valid == 1 & gift_exchange_observed == 1
post `flowh' ("analysis_gate_aware_gift_observed") (r(N))
quietly count if sample_head_valid == 1 & gift_exchange_positive == 1
post `flowh' ("analysis_gate_aware_gift_positive") (r(N))
quietly count if sample_head_valid == 1 & gift_exchange_observed_strict == 1
post `flowh' ("analysis_strict_gift_observed") (r(N))
quietly count if sample_head_valid == 1 & gift_exchange_positive_strict == 1
post `flowh' ("analysis_strict_gift_positive") (r(N))
quietly count if sample_gift_observed_common == 1
post `flowh' ("common_gift_observed") (r(N))
quietly count if sample_baseline_common == 1
post `flowh' ("common_positive_gift") (r(N))
quietly count if sample_gift_strict_common == 1
post `flowh' ("strict_common_gift_observed") (r(N))
quietly count if sample_gift_strict_positive == 1
post `flowh' ("strict_common_positive_gift") (r(N))
postclose `flowh'
preserve
use `sampleflow', clear
export delimited using "`out'/evidence/sample_flow.csv", replace
restore

keep if sample_head_valid == 1
assert head_anomaly == 0
isid hhid year
label data "IRFA CHFS 2013-2017 head-valid analysis data"
compress
save "`out'/data/irfa_household_year_analysis.dta", replace

display "APPEND_RESULT=PASS WORKING_N=105441 ANALYSIS_N=" _N
display "APPEND_CONSTRUCT=PASS"
log close append
