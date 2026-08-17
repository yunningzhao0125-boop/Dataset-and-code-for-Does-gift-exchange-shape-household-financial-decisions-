* Merge all analysis supplements and save the single final analysis data set.
version 18.0
clear all
set more off
set varabbrev off

quietly do "config/01_paths.do"
capture log close prepare
log using "$IRFA_LOGS/40_prepare_analysis_data.log", text replace name(prepare)

tempfile local_controls
use "$IRFA_LOCAL_DTA", clear
assert _N == 900
rename city city_raw_local
gen str60 city_norm = ustrtrim(city_raw_local)
replace city_norm = ustrregexra(city_norm, "[[:space:]]+", "")
isid city_norm year
gen double local_gdp_log = ln(gdp) if gdp > 0 & !missing(gdp)
rename finance_level local_finance_level
rename pop_density local_population_density
keep city_norm year local_gdp_log local_finance_level local_population_density
save `local_controls'

use "$IRFA_INTERMEDIATE/irfa_geography_augmented.dta", clear
assert _N == $IRFA_EXPECTED_N
isid hhid year

merge 1:1 hhid year using ///
    "$IRFA_INTERMEDIATE/irfa_household_year_variable_supplement.dta", ///
    assert(match) nogen

merge 1:1 hhid year using "$IRFA_PARENT_PARTY", gen(_merge_parent)
quietly count if _merge_parent == 2
assert r(N) == 6
drop if _merge_parent == 2
assert _N == $IRFA_EXPECTED_N
drop _merge_parent

merge 1:1 hhid year using ///
    "$IRFA_INTERMEDIATE/irfa_public_sector_household.dta", ///
    gen(_merge_sector)
quietly count if _merge_sector == 2
assert r(N) == 6
drop if _merge_sector == 2
assert _N == $IRFA_EXPECTED_N
assert _merge_sector == 3
drop _merge_sector

rename pop_density population_density_2017
merge m:1 city_norm year using `local_controls', keep(master match) gen(_merge_local)
gen byte local_controls_matched = _merge_local == 3
drop _merge_local
gen double population_density = local_population_density
replace population_density = population_density_2017 ///
    if missing(population_density) & year == 2017
gen byte local_controls_complete = ///
    !missing(local_gdp_log, local_finance_level, population_density)

label variable stock_participation "Stock"
label variable risky_asset_participation "Risky Financial Assets"
label variable lottery_participation "Lottery"
label variable gift_exchange_ln "Gift"
label variable gift_given_ln "Gift expenditure"
label variable age "Age"
label variable age_squared "Age2"
label variable female "Female"
label variable household_assets_10k_w "Asset"
label variable household_income_pc_10k_w "Total income"
label variable family_size_w "Family member"
label variable rural_residence "Rural"
label variable party_member "Party member"
label variable rural_hukou "Hukou"
label variable education_code "Education"
label variable informal_credit_paper "Informal credit"
label variable trust_01 "Interpersonal trust"
label variable safe_assets "Safe Assets"
label variable financial_literacy "Financial literacy"
label variable network_size "Network size"
label variable formal_financial_access "Financial access"
label variable formal_bank_loan "Formal Bank Loan"
label variable institutional_trust "Institutional trust"
label variable local_gdp_log "GDP"
label variable local_finance_level "Finance level"
label variable population_density "Pop density"
label variable parent_party "Parent CPC member"

isid hhid year
assert _N == $IRFA_EXPECTED_N
quietly count if sample_submission_primary == 1
assert r(N) == $IRFA_SUBMISSION_PRIMARY_N
quietly count if sample_submission_positive == 1
assert r(N) == $IRFA_POSITIVE_N
quietly count if sample_submission_primary == 1 & local_controls_complete == 1
assert r(N) == 65190

compress
save "$IRFA_EMPIRICAL_AUGMENTED", replace
save "$IRFA_FINAL_DTA", replace

display "ANALYSIS_DATA_BUILD=PASS"
log close prepare
