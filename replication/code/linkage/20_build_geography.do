* Build the stable household-city key used for fixed effects and clustering.
version 18.0
clear all
set more off
set varabbrev off

quietly do "config/01_paths.do"
capture log close geography
log using "$IRFA_LOGS/20_build_geography.log", text replace name(geography)

foreach f in "$IRFA_CITY13_DTA" "$IRFA_CITY15_DTA" ///
    "$IRFA_CITY17_DTA" "$IRFA_DENSITY_DTA" {
    confirm file "`f'"
}

tempfile city13 city15_raw city15 city17 city_crosswalk conflict13 density

* 2013 contains a small set of internally conflicting household-city records.
use "$IRFA_CITY13_DTA", clear
keep hhid city county
drop if missing(hhid)
bysort hhid city: gen byte __city_first = _n == 1 & city != ""
bysort hhid: egen int __city_levels = total(__city_first)
bysort hhid county: gen byte __county_first = _n == 1 & county != ""
bysort hhid: egen int __county_levels = total(__county_first)
gen byte geo_conflict_2013 = __city_levels > 1 | __county_levels > 1
egen byte __hh_tag = tag(hhid)
quietly count if geo_conflict_2013 == 1 & __hh_tag == 1
assert r(N) == 19
preserve
keep if geo_conflict_2013 == 1 & __hh_tag == 1
keep hhid geo_conflict_2013
gen int year = 2013
isid hhid year
save `conflict13'
restore
drop if geo_conflict_2013 == 1
bysort hhid (city county): keep if _n == 1
rename city city_raw
rename county county_raw
gen int year = 2013
keep hhid year city_raw county_raw
isid hhid year
save `city13'

* 2015 city IDs use the generic household key retained in the analysis file.
use "$IRFA_CITY15_DTA", clear
keep hhid city county
isid hhid
rename hhid link_hhid_generic
rename city city_raw
rename county county_raw
save `city15_raw'

use "$IRFA_INPUT_DTA", clear
keep if year == 2015
keep hhid link_hhid_generic
isid hhid
isid link_hhid_generic
merge 1:1 link_hhid_generic using `city15_raw', gen(_merge_city15)
quietly count if _merge_city15 == 3
assert r(N) == 37193
quietly count if _merge_city15 == 1
assert r(N) == 96
quietly count if _merge_city15 == 2
assert r(N) == 0
keep if _merge_city15 == 3
drop _merge_city15 link_hhid_generic
gen int year = 2015
isid hhid year
save `city15'

use "$IRFA_CITY17_DTA", clear
keep hhid city county
isid hhid
rename city city_raw
rename county county_raw
gen int year = 2017
isid hhid year
save `city17'

use `city13', clear
append using `city15' `city17'
isid hhid year
gen str60 city_norm = ustrtrim(city_raw)
replace city_norm = ustrregexra(city_norm, "[[:space:]]+", "")
save `city_crosswalk'

* Normalize the separate 2017 density file with the same city key.
use "$IRFA_DENSITY_DTA", clear
rename city city_raw
gen str60 city_norm = ustrtrim(city_raw)
replace city_norm = ustrregexra(city_norm, "[[:space:]]+", "")
isid city_norm year
keep city_norm year pop_density
save `density'

use "$IRFA_INPUT_DTA", clear
assert _N == $IRFA_EXPECTED_N
isid hhid year
merge 1:1 hhid year using `conflict13', gen(_merge_conflict)
drop if _merge_conflict == 2
replace geo_conflict_2013 = 0 if missing(geo_conflict_2013)
drop _merge_conflict

merge 1:1 hhid year using `city_crosswalk', gen(_merge_city)
drop if _merge_city == 2
gen byte city_name_matched = _merge_city == 3
drop _merge_city
assert _N == $IRFA_EXPECTED_N
isid hhid year

* Fill a missing city only when its wave-province-source key maps uniquely.
clonevar city_norm_direct = city_norm
gen byte city_source_key_excluded = ///
    year == 2013 & province_id == 52 & city_id_source == "043"
bysort year province_id city_id_source city_norm: gen byte __source_first = ///
    _n == 1 & !missing(city_norm) & city_source_key_excluded == 0
bysort year province_id city_id_source: egen int __source_count = total(__source_first)
bysort year province_id city_id_source (city_norm): gen str60 __source_unique = ///
    city_norm[_N] if __source_count == 1
gen byte city_norm_unique_fill = missing(city_norm) & ///
    !missing(__source_unique) & city_source_key_excluded == 0
replace city_norm = __source_unique if city_norm_unique_fill == 1
gen byte city_norm_unresolved = missing(city_norm)

quietly count if missing(city_norm_direct)
assert r(N) == 211
quietly count if city_norm_unique_fill == 1
assert r(N) == 193
quietly count if city_norm_unresolved == 1
assert r(N) == 18

egen long city_id_stable = group(city_norm)
replace city_id_stable = . if missing(city_norm)
egen byte __city_tag = tag(city_id_stable) if sample_gift_observed_common == 1
quietly count if __city_tag == 1 & !missing(city_id_stable)
assert r(N) == $IRFA_STABLE_CITY_CLUSTERS
drop __city_tag

clonevar sample_head_age_valid = age_primary_valid
gen byte sample_semantic_valid = !missing(city_id_stable) & sample_head_age_valid == 1
gen byte sample_submission_full_age = ///
    sample_gift_observed_common == 1 & !missing(city_id_stable)
gen byte sample_submission_primary = ///
    sample_gift_observed_common == 1 & sample_semantic_valid == 1
gen byte sample_submission_positive = ///
    sample_baseline_common == 1 & sample_semantic_valid == 1

quietly count if sample_submission_full_age == 1
assert r(N) == $IRFA_SUBMISSION_FULL_AGE_N
quietly count if sample_submission_primary == 1
assert r(N) == $IRFA_SUBMISSION_PRIMARY_N
quietly count if sample_submission_positive == 1
assert r(N) == $IRFA_POSITIVE_N

drop __source_first __source_count __source_unique
merge m:1 city_norm year using `density', gen(_merge_density)
drop if _merge_density == 2
gen byte density_matched = _merge_density == 3
drop _merge_density
assert _N == $IRFA_EXPECTED_N
isid hhid year

label variable city_id_stable "Stable numeric city identifier"
label variable sample_submission_primary "Observed-Gift analysis sample"
label variable sample_submission_positive "Positive-Gift analysis sample"
compress
save "$IRFA_INTERMEDIATE/irfa_geography_augmented.dta", replace

display "GEOGRAPHY_BUILD=PASS"
log close geography
