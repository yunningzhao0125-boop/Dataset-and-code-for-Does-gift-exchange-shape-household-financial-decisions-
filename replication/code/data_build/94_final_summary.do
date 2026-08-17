* Reviewer replication note
* Purpose: report final sample, variable coverage, and age-range diagnostics.
* Inputs: rebuilt household-year analysis DTA.
* Outputs: a readable summary log supporting manuscript Tables 1-11.
version 18.0
clear all
set more off
set varabbrev off
capture log close _all

quietly do "config/01_paths.do"
local out "$IRFA_WORK_ROOT"
log using "`out'/logs/94_final_summary.log", text replace name(summary94)

use "`out'/data/irfa_household_year_analysis.dta", clear
display "FINAL_SUMMARY_START"
describe, short
tab year

foreach v in stock_participation risky_asset_participation gift_exchange_positive gift_exchange_observed_strict gift_exchange_positive_strict informal_credit_paper require_interest_paper trust_binary financial_literacy_risk formal_financial_access lottery_participation derivative_participation {
    quietly count if !missing(`v')
    local nonmissing_n = r(N)
    quietly count if `v' == 1
    local one_n = r(N)
    display "COVERAGE=`v' NONMISSING=" `nonmissing_n' " ONE=" `one_n'
}

foreach v in sample_core_outcomes sample_core_controls sample_gift_observed_common sample_baseline_common sample_gift_strict_common sample_gift_strict_positive sample_incremental_literacy sample_incremental_access sample_mechanism_credit_paper sample_mechanism_interest sample_mechanism_trust {
    quietly count if `v' == 1
    display "SAMPLE=`v' N=" r(N)
}

summarize gift_exchange_ln age family_size_w household_assets_10k_w household_income_pc_10k_w

foreach condition in "age < 18" "age > 100" "age < 18 & sample_baseline_common == 1" "age > 100 & sample_baseline_common == 1" {
    quietly count if `condition' & !missing(age)
    display "AGE_CHECK=`condition' N=" r(N)
}
list hhid year head_birth_year age sample_baseline_common if (age < 18 | age > 100) & !missing(age), noobs abbreviate(24)

display "FINAL_SUMMARY=PASS"
log close summary94
