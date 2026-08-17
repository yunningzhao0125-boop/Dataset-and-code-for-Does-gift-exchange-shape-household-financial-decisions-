* Reviewer replication note
* Purpose: construct requested trust, literacy, network, access, and safe-asset proxies.
* Inputs: separate CHFS household files and the rebuilt household-year authority DTA.
* Outputs: labeled supplemental-variable DTA used in Tables 7-10.
version 18.0
clear all
set more off
capture log close _all

quietly do "config/01_paths.do"
local raw2013 "$IRFA_RAW_ROOT/chfs2013_hh_20191120_version14.dta"
local raw2015 "$IRFA_RAW_ROOT/chfs2015_hh_20191120_version14.dta"
local raw2017 "$IRFA_RAW_ROOT/chfs2017_hh_202206.dta"
local authority "$IRFA_INPUT_DTA"
local target "$IRFA_INTERMEDIATE/irfa_household_year_variable_supplement.dta"
local build_log "$IRFA_LOGS/30_build_variable_supplement.log"

log using "`build_log'", text replace name(build_original_supplement)

confirm file "`raw2013'"
confirm file "`raw2015'"
confirm file "`raw2017'"
confirm file "`authority'"

tempfile wave2013 wave2015 wave2017 raw_supplement

use "`raw2013'", clear
assert _N == 28141
rename hhid_2013 hhid
isid hhid
generate int year = 2013

generate byte term_deposit = .
replace term_deposit = 1 if d2101 == 1
replace term_deposit = 0 if d2101 == 2

generate byte government_bond = .
replace government_bond = 1 if d4101_1_mc == 1 | d4101_2_mc == 1
replace government_bond = 0 if missing(government_bond) & ///
    (d4100a == 2 | (d4100a == 1 & d4101_1_mc == 0 & d4101_2_mc == 0))

generate byte safe_assets = .
replace safe_assets = 1 if term_deposit == 1 | government_bond == 1
replace safe_assets = 0 if term_deposit == 0 & government_bond == 0

generate byte financial_literacy = (a4004a == 3) if inrange(a4004a, 1, 4)
generate byte network_size = a2043 - 1 if inrange(a2043, 1, 4)
generate double institutional_trust = (h3042 - 1) / 4 if inrange(h3042, 1, 5)

generate byte formal_bank_loan = .
replace formal_bank_loan = 1 if b3001_1 == 1 | b3001_2 == 1 | ///
    c2024_1 == 1 | c2024_2 == 1 | c2024_3 == 1 | ///
    c7014_1 == 1 | c7014_2 == 1 | e1001 == 1
replace formal_bank_loan = 0 if missing(formal_bank_loan) & e1001 == 2

keep hhid year safe_assets financial_literacy network_size ///
    formal_bank_loan institutional_trust
isid hhid year
save "`wave2013'", replace

use "`raw2015'", clear
assert _N == 37289
drop hhid
rename hhid_2015 hhid
isid hhid
generate int year = 2015

generate byte term_deposit = .
replace term_deposit = 1 if d2101 == 1
replace term_deposit = 0 if d2101 == 2

generate byte government_bond = .
replace government_bond = 1 if d4101a_1_mc == 1 | d4101a_2_mc == 1
replace government_bond = 0 if missing(government_bond) & ///
    (d7113_1_mc == 0 | ///
    (d7113_1_mc == 1 & d4101a_1_mc == 0 & d4101a_2_mc == 0))

generate byte safe_assets = .
replace safe_assets = 1 if term_deposit == 1 | government_bond == 1
replace safe_assets = 0 if term_deposit == 0 & government_bond == 0

generate byte financial_literacy = (a4004a == 2) if inrange(a4004a, 1, 4)
generate byte network_size = a2043 - 1 if inrange(a2043, 1, 4)
generate double institutional_trust = (h3042 - 1) / 4 if inrange(h3042, 1, 5)

generate byte formal_bank_loan = .
replace formal_bank_loan = 1 if b3001_1 == 1 | b3001_2 == 1 | ///
    c2024 == 1 | c3019b == 1 | c7014 == 1 | e1001 == 1
replace formal_bank_loan = 0 if missing(formal_bank_loan) & e1001 == 2

keep hhid year safe_assets financial_literacy network_size ///
    formal_bank_loan institutional_trust
isid hhid year
save "`wave2015'", replace

use "`raw2017'", clear
assert _N == 40011
drop hhid
rename hhid_2017 hhid
isid hhid
generate int year = 2017

generate byte term_deposit = .
replace term_deposit = 1 if d2101 == 1
replace term_deposit = 0 if d2101 == 2

generate byte government_bond = .
replace government_bond = 1 if d4101b_1_mc == 1
replace government_bond = 0 if missing(government_bond) & ///
    (d7113_1_mc == 0 | (d7113_1_mc == 1 & d4101b_1_mc == 0))

generate byte safe_assets = .
replace safe_assets = 1 if term_deposit == 1 | government_bond == 1
replace safe_assets = 0 if term_deposit == 0 & government_bond == 0

generate byte financial_literacy = (h3105 == 2) if inrange(h3105, 1, 4)
generate byte network_size = .
generate double institutional_trust = .

generate byte formal_bank_loan = .
replace formal_bank_loan = 1 if b3001_2 == 1 | ///
    c2024_1 == 1 | c2024_2 == 1 | c2024_3 == 1 | ///
    c2024_4 == 1 | c2024_5 == 1 | c2024_6 == 1 | ///
    c3019b == 1 | e1001 == 1
replace formal_bank_loan = 0 if missing(formal_bank_loan) & e1001 == 2

keep hhid year safe_assets financial_literacy network_size ///
    formal_bank_loan institutional_trust
isid hhid year
save "`wave2017'", replace

use "`wave2013'", clear
append using "`wave2015'" "`wave2017'"
assert _N == 105441
isid hhid year
save "`raw_supplement'", replace

use "`authority'", clear
keep hhid year trust_ordinal
assert _N == 105435
isid hhid year

merge 1:1 hhid year using "`raw_supplement'", generate(_merge_supplement)
quietly count if _merge_supplement == 1
assert r(N) == 0
quietly count if _merge_supplement == 2
assert r(N) == 6
drop if _merge_supplement == 2
drop _merge_supplement
assert _N == 105435
isid hhid year

generate double trust_01 = (trust_ordinal - 1) / 4 if inrange(trust_ordinal, 1, 5)
drop trust_ordinal

label variable safe_assets "Safe Assets"
label variable trust_01 "Trust"
label variable financial_literacy "Financial literacy"
label variable network_size "Network size"
label variable formal_bank_loan "Formal Bank Loan"
label variable institutional_trust "Institutional trust"

note formal_bank_loan: Current/outstanding bank-loan proxy; not borrowing initiated in the previous year.
note institutional_trust: Government-pension-commitment trust proxy; available only in 2013 and 2015.

order hhid year safe_assets trust_01 financial_literacy network_size ///
    formal_bank_loan institutional_trust

foreach variable in safe_assets financial_literacy formal_bank_loan {
    assert inlist(`variable', 0, 1) | missing(`variable')
}
foreach variable in trust_01 institutional_trust {
    assert inrange(`variable', 0, 1) | missing(`variable')
}
assert missing(network_size) | ///
    (inrange(network_size, 0, 3) & network_size == floor(network_size))
quietly count if year == 2017 & !missing(network_size)
assert r(N) == 0
quietly count if year == 2017 & !missing(institutional_trust)
assert r(N) == 0

save "`target'", replace

local pass_marker = "BUILD_HOUSEHOLD_YEAR_VARIABLE_" + "SUPPLEMENT=PASS"
display as result "`pass_marker'"
local completion_marker = "__CODEX_STATA_" + "COMPLETE__"
display as result "`completion_marker'"

log close build_original_supplement
exit 0
