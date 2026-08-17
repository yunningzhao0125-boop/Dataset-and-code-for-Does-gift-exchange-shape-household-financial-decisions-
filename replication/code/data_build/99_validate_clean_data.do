* Reviewer replication note
* Purpose: enforce row, key, sample, construction, and English-label invariants.
* Inputs: rebuilt working/final DTA files and data-build evidence CSVs.
* Outputs: a clean validation log required before any manuscript table is estimated.
version 18.0
clear all
set more off
set varabbrev off
capture log close _all

quietly do "config/01_paths.do"
local out "$IRFA_WORK_ROOT"
log using "`out'/logs/99_validate_clean_data.log", text replace name(validate)
display "VALIDATION_START"

confirm file "`out'/data/irfa_household_year_working.dta"
confirm file "`out'/data/irfa_household_year_analysis.dta"
confirm file "`out'/evidence/pooled_p1_p99_cutoffs.csv"
confirm file "`out'/evidence/sample_flow.csv"

use "`out'/data/irfa_household_year_working.dta", clear
assert _N == 105441
isid hhid year
assert inlist(year, 2013, 2015, 2017)
count if year == 2013
assert r(N) == 28141
count if year == 2015
assert r(N) == 37289
count if year == 2017
assert r(N) == 40011

confirm variable stock_participation
confirm variable risky_asset_participation
confirm variable gift_exchange_ln
confirm variable gift_received_yuan_strict
confirm variable gift_given_yuan_strict
confirm variable gift_exchange_yuan_strict
confirm variable gift_received_ln_strict
confirm variable gift_given_ln_strict
confirm variable gift_exchange_ln_strict
confirm variable gift_exchange_positive_strict
confirm variable gift_exchange_observed_strict
confirm variable age
confirm variable age_squared
confirm variable female
confirm variable family_size
confirm variable party_member
confirm variable rural_hukou
confirm variable household_assets_10k_w
confirm variable household_income_pc_10k_w
confirm variable rural_residence
confirm variable province_id
confirm variable city_id_source
confirm variable city_id
confirm variable informal_credit_candidate
confirm variable trust_ordinal
confirm variable financial_literacy_risk
confirm variable formal_financial_access
confirm variable informal_credit_paper
confirm variable require_interest_paper
confirm variable trust_binary
confirm variable lottery_observed
confirm variable head_age_under18
confirm variable head_age_over100
confirm variable age_primary_valid
confirm variable survey_weight_wave_norm
confirm variable Borrowing_or_lending
confirm variable Require_interest
confirm variable trust
confirm variable sample_baseline_common
confirm variable sample_gift_strict_common
confirm variable sample_gift_strict_positive
confirm variable sample_mechanism_credit_paper
confirm variable sample_mechanism_interest

foreach v in legacy_gift_received_yuan legacy_gift_given_yuan legacy_gift_exchange_ln {
    capture confirm variable `v'
    if !_rc {
        display as error "FORBIDDEN_LEGACY_GIFT_VARIABLE=`v'"
        exit 459
    }
}

assert inlist(stock_participation, 0, 1) if !missing(stock_participation)
assert inlist(risky_asset_participation, 0, 1) if !missing(risky_asset_participation)
assert inlist(female, 0, 1) if !missing(female)
assert inlist(party_member, 0, 1) if !missing(party_member)
assert inlist(rural_hukou, 0, 1) if !missing(rural_hukou)
assert inlist(rural_residence, 0, 1) if !missing(rural_residence)
assert inlist(informal_credit_paper, 0, 1) if !missing(informal_credit_paper)
assert inlist(require_interest_paper, 0, 1) if !missing(require_interest_paper)
assert inlist(trust_binary, 0, 1) if !missing(trust_binary)
assert inlist(lottery_observed, 0, 1)
assert head_age_under18 == (age < 18) if !missing(age)
assert head_age_over100 == (age > 100) if !missing(age)
assert missing(head_age_under18) if missing(age)
assert missing(head_age_over100) if missing(age)
assert age_primary_valid == inrange(age, 18, 100) if !missing(age)
assert missing(age_primary_valid) if missing(age)
assert inlist(lottery_participation, 0, 1) if lottery_observed == 1
assert missing(lottery_participation) if lottery_observed == 0
assert Borrowing_or_lending == informal_credit_paper
assert Require_interest == require_interest_paper
assert trust == trust_binary
assert inrange(trust_ordinal, 1, 5) if !missing(trust_ordinal)
assert !missing(family_size)
assert family_size >= 1 & family_size == floor(family_size)
assert household_assets_10k >= 0 if !missing(household_assets_10k)
assert missing(city_id) == (missing(province_id) | missing(city_id_source))
assert survey_weight > 0 if !missing(survey_weight)
assert reldif(survey_weight_wave_norm, survey_weight / survey_weight_wave_mean) < 1e-10 if !missing(survey_weight)
bysort year: egen double __weight_norm_mean = mean(survey_weight_wave_norm)
assert abs(__weight_norm_mean - 1) < 1e-10
drop __weight_norm_mean
gen double __expected_gift_received = .
replace __expected_gift_received = 0 if gift_received_gate == 2 & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
replace __expected_gift_received = cond(missing(gift_received_holiday_yuan), 0, gift_received_holiday_yuan) + cond(missing(gift_received_ceremony_yuan), 0, gift_received_ceremony_yuan) if gift_received_gate == 1 & (!missing(gift_received_holiday_yuan) | !missing(gift_received_ceremony_yuan)) & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
gen double __expected_gift_given = .
replace __expected_gift_given = 0 if gift_given_gate == 2 & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)
replace __expected_gift_given = cond(missing(gift_given_holiday_yuan), 0, gift_given_holiday_yuan) + cond(missing(gift_given_ceremony_yuan), 0, gift_given_ceremony_yuan) if gift_given_gate == 1 & (!missing(gift_given_holiday_yuan) | !missing(gift_given_ceremony_yuan)) & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)

assert reldif(gift_received_yuan, __expected_gift_received) < 1e-6 if !missing(__expected_gift_received)
assert missing(gift_received_yuan) if missing(__expected_gift_received)
assert reldif(gift_given_yuan, __expected_gift_given) < 1e-6 if !missing(__expected_gift_given)
assert missing(gift_given_yuan) if missing(__expected_gift_given)
assert gift_received_yuan == 0 if gift_received_gate == 2 & (missing(gift_received_holiday_yuan) | gift_received_holiday_yuan >= 0) & (missing(gift_received_ceremony_yuan) | gift_received_ceremony_yuan >= 0)
assert gift_given_yuan == 0 if gift_given_gate == 2 & (missing(gift_given_holiday_yuan) | gift_given_holiday_yuan >= 0) & (missing(gift_given_ceremony_yuan) | gift_given_ceremony_yuan >= 0)
assert missing(gift_received_yuan) if gift_received_gate == 2 & ((!missing(gift_received_holiday_yuan) & gift_received_holiday_yuan < 0) | (!missing(gift_received_ceremony_yuan) & gift_received_ceremony_yuan < 0))
assert missing(gift_given_yuan) if gift_given_gate == 2 & ((!missing(gift_given_holiday_yuan) & gift_given_holiday_yuan < 0) | (!missing(gift_given_ceremony_yuan) & gift_given_ceremony_yuan < 0))
assert gift_received_missing_reason == 0 if !missing(__expected_gift_received)
assert gift_given_missing_reason == 0 if !missing(__expected_gift_given)
assert gift_received_missing_reason == 1 if missing(gift_received_gate)
assert gift_given_missing_reason == 1 if missing(gift_given_gate)
assert gift_received_missing_reason == 2 if !missing(gift_received_gate) & !inlist(gift_received_gate, 1, 2)
assert gift_given_missing_reason == 2 if !missing(gift_given_gate) & !inlist(gift_given_gate, 1, 2)
assert gift_received_missing_reason == 3 if gift_received_gate == 1 & missing(gift_received_holiday_yuan) & missing(gift_received_ceremony_yuan)
assert gift_given_missing_reason == 3 if gift_given_gate == 1 & missing(gift_given_holiday_yuan) & missing(gift_given_ceremony_yuan)
assert gift_received_missing_reason == 4 if inlist(gift_received_gate, 1, 2) & ((!missing(gift_received_holiday_yuan) & gift_received_holiday_yuan < 0) | (!missing(gift_received_ceremony_yuan) & gift_received_ceremony_yuan < 0))
assert gift_given_missing_reason == 4 if inlist(gift_given_gate, 1, 2) & ((!missing(gift_given_holiday_yuan) & gift_given_holiday_yuan < 0) | (!missing(gift_given_ceremony_yuan) & gift_given_ceremony_yuan < 0))

gen double __expected_gift_received_strict = .
replace __expected_gift_received_strict = 0 if gift_received_gate == 2
replace __expected_gift_received_strict = gift_received_holiday_yuan + gift_received_ceremony_yuan if gift_received_gate == 1 & !missing(gift_received_holiday_yuan, gift_received_ceremony_yuan) & gift_received_holiday_yuan >= 0 & gift_received_ceremony_yuan >= 0
gen double __expected_gift_given_strict = .
replace __expected_gift_given_strict = 0 if gift_given_gate == 2
replace __expected_gift_given_strict = gift_given_holiday_yuan + gift_given_ceremony_yuan if gift_given_gate == 1 & !missing(gift_given_holiday_yuan, gift_given_ceremony_yuan) & gift_given_holiday_yuan >= 0 & gift_given_ceremony_yuan >= 0

assert reldif(gift_received_yuan_strict, __expected_gift_received_strict) < 1e-6 if !missing(__expected_gift_received_strict)
assert missing(gift_received_yuan_strict) if missing(__expected_gift_received_strict)
assert reldif(gift_given_yuan_strict, __expected_gift_given_strict) < 1e-6 if !missing(__expected_gift_given_strict)
assert missing(gift_given_yuan_strict) if missing(__expected_gift_given_strict)

gen double __expected_gift_exchange = __expected_gift_received + __expected_gift_given if !missing(__expected_gift_received, __expected_gift_given)
gen double __expected_gift_exchange_strict = __expected_gift_received_strict + __expected_gift_given_strict if !missing(__expected_gift_received_strict, __expected_gift_given_strict)

assert reldif(gift_exchange_yuan, __expected_gift_exchange) < 1e-6 if !missing(__expected_gift_exchange)
assert missing(gift_exchange_yuan) if missing(__expected_gift_exchange)
assert reldif(gift_exchange_yuan_strict, __expected_gift_exchange_strict) < 1e-6 if !missing(__expected_gift_exchange_strict)
assert missing(gift_exchange_yuan_strict) if missing(__expected_gift_exchange_strict)

assert reldif(gift_received_ln, ln(gift_received_yuan + 1)) < 1e-6 if !missing(gift_received_yuan)
assert reldif(gift_given_ln, ln(gift_given_yuan + 1)) < 1e-6 if !missing(gift_given_yuan)
assert reldif(gift_exchange_ln, ln(gift_exchange_yuan + 1)) < 1e-6 if !missing(gift_exchange_yuan)
assert reldif(gift_received_ln_strict, ln(gift_received_yuan_strict + 1)) < 1e-6 if !missing(gift_received_yuan_strict)
assert reldif(gift_given_ln_strict, ln(gift_given_yuan_strict + 1)) < 1e-6 if !missing(gift_given_yuan_strict)
assert reldif(gift_exchange_ln_strict, ln(gift_exchange_yuan_strict + 1)) < 1e-6 if !missing(gift_exchange_yuan_strict)
assert missing(gift_received_ln) if missing(gift_received_yuan)
assert missing(gift_given_ln) if missing(gift_given_yuan)
assert missing(gift_exchange_ln) if missing(gift_exchange_yuan)
assert missing(gift_received_ln_strict) if missing(gift_received_yuan_strict)
assert missing(gift_given_ln_strict) if missing(gift_given_yuan_strict)
assert missing(gift_exchange_ln_strict) if missing(gift_exchange_yuan_strict)
assert gift_exchange_observed == !missing(gift_exchange_yuan)
assert gift_exchange_positive == (gift_exchange_yuan > 0) if gift_exchange_observed == 1
assert missing(gift_exchange_positive) if gift_exchange_observed == 0
assert gift_exchange_observed_strict == !missing(gift_exchange_yuan_strict)
assert gift_exchange_positive_strict == (gift_exchange_yuan_strict > 0) if gift_exchange_observed_strict == 1
assert missing(gift_exchange_positive_strict) if gift_exchange_observed_strict == 0

count if gift_exchange_observed == 1
assert r(N) == 91063
count if gift_exchange_positive == 1
assert r(N) == 73170
count if gift_exchange_observed_strict == 1
assert r(N) == 36312
count if gift_exchange_positive_strict == 1
assert r(N) == 18601

drop __expected_gift_received __expected_gift_given __expected_gift_received_strict __expected_gift_given_strict __expected_gift_exchange __expected_gift_exchange_strict

assert reldif(household_assets_10k, household_assets_yuan / 10000) < 1e-6 if !missing(household_assets_yuan)
assert missing(household_assets_10k) if missing(household_assets_yuan)
assert reldif(household_income_10k, household_income_yuan / 10000) < 1e-6 if !missing(household_income_yuan)
assert reldif(household_income_pc_10k, household_income_yuan / family_size / 10000) < 1e-6 if !missing(household_income_yuan)
assert missing(household_income_pc_10k) if missing(household_income_yuan)
assert household_income_negative == (household_income_yuan < 0) if !missing(household_income_yuan)
assert missing(household_income_negative) if missing(household_income_yuan)

local rawvars family_size household_assets_10k household_income_pc_10k
local winvars family_size_w household_assets_10k_w household_income_pc_10k_w
local nvars : word count `rawvars'
forvalues i = 1/`nvars' {
    local rawvar : word `i' of `rawvars'
    local winvar : word `i' of `winvars'
    quietly _pctile `rawvar' if !missing(`rawvar'), p(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    gen double __expected_win = cond(`rawvar' < `p1', `p1', cond(`rawvar' > `p99', `p99', `rawvar')) if !missing(`rawvar')
    assert reldif(`winvar', __expected_win) < 1e-6 if !missing(`rawvar')
    assert missing(`winvar') if missing(`rawvar')
    drop __expected_win
}

gen byte __expected_head_valid = head_count == 1 & head_anomaly == 0
egen int __expected_outcome_missing_n = rowmiss(stock_participation risky_asset_participation)
egen int __expected_control_missing_n = rowmiss(age female family_size_w party_member rural_hukou household_assets_10k_w household_income_pc_10k_w rural_residence province_id city_id)
gen byte __expected_core_outcomes = __expected_outcome_missing_n == 0
gen byte __expected_core_controls = __expected_head_valid == 1 & __expected_control_missing_n == 0
gen byte __expected_gift_common = __expected_core_outcomes == 1 & __expected_core_controls == 1 & gift_exchange_observed == 1 & !missing(gift_exchange_ln)
gen byte __expected_baseline = __expected_gift_common == 1 & gift_exchange_positive == 1
gen byte __expected_gift_strict_common = __expected_core_outcomes == 1 & __expected_core_controls == 1 & gift_exchange_observed_strict == 1 & !missing(gift_exchange_ln_strict)
gen byte __expected_gift_strict_positive = __expected_gift_strict_common == 1 & gift_exchange_positive_strict == 1
assert sample_head_valid == __expected_head_valid
assert core_outcome_missing_n == __expected_outcome_missing_n
assert core_control_missing_n == __expected_control_missing_n
assert sample_core_outcomes == __expected_core_outcomes
assert sample_core_controls == __expected_core_controls
assert sample_gift_observed_common == __expected_gift_common
assert sample_baseline_common == __expected_baseline
assert sample_gift_strict_common == __expected_gift_strict_common
assert sample_gift_strict_positive == __expected_gift_strict_positive
assert sample_incremental_literacy == (sample_baseline_common == 1 & !missing(financial_literacy_risk))
assert sample_incremental_access == (sample_baseline_common == 1 & !missing(formal_financial_access))
assert sample_mechanism_credit == (sample_baseline_common == 1 & !missing(informal_credit_candidate))
assert sample_mechanism_credit_paper == (sample_baseline_common == 1 & !missing(informal_credit_paper))
assert sample_mechanism_interest == (sample_baseline_common == 1 & !missing(require_interest_paper))
assert sample_mechanism_trust == (sample_baseline_common == 1 & !missing(trust_binary))
drop __expected_head_valid __expected_outcome_missing_n __expected_control_missing_n __expected_core_outcomes __expected_core_controls __expected_gift_common __expected_baseline __expected_gift_strict_common __expected_gift_strict_positive

assert network_size_available == 0
assert social_interaction_available == 0
assert formal_bank_loan_available == 0
assert institutional_trust_available == 0
assert safe_asset_available == 0

assert Stock == stock_participation
assert Risky_Financial_Assets == risky_asset_participation
assert gift2 == gift_exchange_ln
assert giftin2 == gift_received_ln
assert giftout2 == gift_given_ln
assert gift_dummy == gift_exchange_positive
assert age2 == age_squared
assert family_member == family_size_w
assert hukou == rural_hukou
assert asset1 == household_assets_10k_w
assert total_income1 == household_income_pc_10k_w
assert rural == rural_residence
assert proid == province_id
assert lottery == lottery_participation

count if head_anomaly == 1
assert r(N) == 6
count if head_anomaly == 1 & year == 2013
assert r(N) == 6
count if head_anomaly == 1 & year != 2013
assert r(N) == 0
count if household_income_negative == 1
assert r(N) > 0
count if year == 2015 & hhsize_difference == 0
assert r(N) > 0
count if inlist(year, 2015, 2017) & !missing(derivative_participation)
assert r(N) > 0
count if sample_baseline_common == 1
assert r(N) == 60117
local baseline_n = r(N)
count if sample_gift_observed_common == 1
assert r(N) == 73598
local gift_common_n = r(N)
assert !missing(survey_weight_wave_norm) & survey_weight_wave_norm > 0 if sample_gift_observed_common == 1
count if sample_gift_strict_common == 1
assert r(N) == 29051
local gift_strict_common_n = r(N)
count if sample_gift_strict_positive == 1
assert r(N) == 15738
local gift_strict_positive_n = r(N)

ds
foreach v of varlist `r(varlist)' {
    local variable_label : variable label `v'
    if `"`variable_label'"' == "" {
        display as error "EMPTY_VARIABLE_LABEL=`v'"
        exit 459
    }
    if strlen(`"`variable_label'"') != ustrlen(`"`variable_label'"') {
        display as error "NON_ASCII_VARIABLE_LABEL=`v'"
        exit 459
    }
}

use "`out'/data/irfa_household_year_analysis.dta", clear
assert _N == 105435
isid hhid year
assert head_anomaly == 0
assert sample_head_valid == 1
count if gift_exchange_observed == 1
assert r(N) == 91057
count if gift_exchange_positive == 1
assert r(N) == 73164
count if gift_exchange_observed_strict == 1
assert r(N) == 36311
count if gift_exchange_positive_strict == 1
assert r(N) == 18600
count if sample_baseline_common == 1
assert r(N) == `baseline_n'
count if sample_gift_observed_common == 1
assert r(N) == `gift_common_n'
count if sample_gift_strict_common == 1
assert r(N) == `gift_strict_common_n'
count if sample_gift_strict_positive == 1
assert r(N) == `gift_strict_positive_n'

ds
foreach v of varlist `r(varlist)' {
    local variable_label : variable label `v'
    if `"`variable_label'"' == "" {
        display as error "EMPTY_ANALYSIS_VARIABLE_LABEL=`v'"
        exit 459
    }
    if strlen(`"`variable_label'"') != ustrlen(`"`variable_label'"') {
        display as error "NON_ASCII_ANALYSIS_VARIABLE_LABEL=`v'"
        exit 459
    }
}

display "ANALYSIS_ENGLISH_LABELS=PASS VARIABLES=" c(k)
display "CLEAN_DATA_VALIDATION=PASS"
log close validate
