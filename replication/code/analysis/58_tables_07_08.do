* Tables 7-8: channel-consistent associations and heterogeneity.
version 18.0
set more off
quietly do "config/01_paths.do"
adopath ++ "$IRFA_PACKAGE_ROOT/ado"

global X "gift_exchange_ln"
global C "age age_squared female family_size_w party_member rural_hukou rural_residence household_assets_10k_w household_income_pc_10k_w"
global FE "i.province_id i.year"
global VCE "vce(cluster city_id_stable)"
use "$IRFA_FINAL_DTA", clear

* -----------------------------------------------------------------------------
* Table 7. Informal credit and interpersonal trust
* -----------------------------------------------------------------------------
quietly probit informal_credit_paper $X $C $FE ///
    if sample_submission_positive==1 & !missing(informal_credit_paper), $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t7_credit

quietly probit trust_binary $X $C $FE ///
    if sample_submission_positive==1 & !missing(trust_binary), $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t7_trust

quietly ivreg2 informal_credit_paper $C $FE ($X=parent_party) ///
    if sample_submission_positive==1 & !missing(parent_party,informal_credit_paper), ///
    cluster(city_id_stable) small
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t7_credit_iv

quietly ivreg2 trust_binary $C $FE ($X=parent_party) ///
    if sample_submission_positive==1 & !missing(parent_party,trust_binary), ///
    cluster(city_id_stable) small
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t7_trust_iv

esttab t7_credit t7_trust t7_credit_iv t7_trust_iv ///
    using "$IRFA_REPRODUCED/Table_07_Mechanisms.rtf", ///
    replace rtf label nogaps cells(b(star fmt(4)) se(par fmt(4))) ///
    collabels(none) eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(gift_exchange_ln) coeflabels(gift_exchange_ln "Gift") ///
    mtitles("Probit: Informal credit" "Probit: Interpersonal trust" ///
        "2SLS: Informal credit" "2SLS: Interpersonal trust") ///
    stats(Controls ProvinceFE YearFE PseudoR2 Observations, ///
        fmt(0 0 0 4 0) labels("Controls" "Province FE" "Year FE" ///
        "Pseudo R2" "Observations")) ///
    title("Table 7. Gift exchange, informal credit, and interpersonal trust") ///
    addnotes("{\i Note:} This table presents the results of channel tests. Columns (1)-(2) report the effect of gift exchange on informal credit and interpersonal trust. Columns (3)-(4) report the 2SLS estimation results using parental CPC membership as an instrument variable for gift exchange. Baseline controls are included but not displayed. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively.")
estimates clear

* -----------------------------------------------------------------------------
* Table 8. Heterogeneity: Stock then Risky Financial Assets
* -----------------------------------------------------------------------------
keep if sample_submission_positive==1
bysort year: egen double income_median=median(household_income_pc_10k_w)
bysort year: egen double assets_median=median(household_assets_10k_w)
gen byte high_income=household_income_pc_10k_w>=income_median
gen byte high_assets=household_assets_10k_w>=assets_median
capture drop large_family
gen byte large_family=family_size_w>3 if !missing(family_size_w)

* Group-specific slopes are obtained from explicit interaction Probit models.
capture program drop store_slope
program define store_slope
    syntax, MODEL(name) EXPRESSION(string) NAME(name) CONDITION(string) TESTP(real)
    quietly estimates restore `model'
    local n=e(N)
    local r2=e(r2_p)
    quietly count if e(sample) & (`condition')
    local gn=r(N)
    quietly nlcom (Gift: `expression'), post
    local p_text ""
    if !missing(`testp') {
        if `testp' < 0.0001 local p_text "<0.0001"
        else local p_text = strtrim(string(`testp', "%9.4f"))
    }
    estadd scalar Observations=`n'
    estadd scalar GroupN=`gn'
    estadd scalar PseudoR2=`r2'
    estadd local InteractionPText "`p_text'"
    estadd local Controls "Yes"
    estadd local ProvinceFE "Yes"
    estadd local YearFE "Yes"
    estimates store `name'
end

* Exclude the grouping variable from each interaction model's control list.
local C_RURAL "age age_squared female family_size_w party_member rural_hukou household_assets_10k_w household_income_pc_10k_w"
local C_FAMILY "age age_squared female party_member rural_hukou rural_residence household_assets_10k_w household_income_pc_10k_w"

* Stock participation: five explicit interaction specifications.
quietly probit stock_participation c.gift_exchange_ln##i.rural_residence `C_RURAL' $FE, $VCE
quietly test 1.rural_residence#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.rural_residence#c.gift_exchange_ln]") name(hs1) condition("rural_residence==1") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hs2) condition("rural_residence==0") testp(`p')
estimates drop work

quietly probit stock_participation c.gift_exchange_ln##i.large_family `C_FAMILY' $FE, $VCE
quietly test 1.large_family#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hs3) condition("large_family==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.large_family#c.gift_exchange_ln]") name(hs4) condition("large_family==1") testp(`p')
estimates drop work

quietly probit stock_participation c.gift_exchange_ln##i.high_assets $C $FE, $VCE
quietly test 1.high_assets#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hs5) condition("high_assets==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.high_assets#c.gift_exchange_ln]") name(hs6) condition("high_assets==1") testp(`p')
estimates drop work

quietly probit stock_participation c.gift_exchange_ln##i.high_income $C $FE, $VCE
quietly test 1.high_income#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hs7) condition("high_income==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.high_income#c.gift_exchange_ln]") name(hs8) condition("high_income==1") testp(`p')
estimates drop work

quietly probit stock_participation c.gift_exchange_ln##i.head_age_group $C $FE, $VCE
quietly test 2.head_age_group#c.gift_exchange_ln 3.head_age_group#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hs9) condition("head_age_group==1") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[2.head_age_group#c.gift_exchange_ln]") name(hs10) condition("head_age_group==2") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[3.head_age_group#c.gift_exchange_ln]") name(hs11) condition("head_age_group==3") testp(`p')
estimates drop work

* Risky financial assets: the same five specifications, written explicitly.
quietly probit risky_asset_participation c.gift_exchange_ln##i.rural_residence `C_RURAL' $FE, $VCE
quietly test 1.rural_residence#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.rural_residence#c.gift_exchange_ln]") name(hr1) condition("rural_residence==1") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hr2) condition("rural_residence==0") testp(`p')
estimates drop work

quietly probit risky_asset_participation c.gift_exchange_ln##i.large_family `C_FAMILY' $FE, $VCE
quietly test 1.large_family#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hr3) condition("large_family==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.large_family#c.gift_exchange_ln]") name(hr4) condition("large_family==1") testp(`p')
estimates drop work

quietly probit risky_asset_participation c.gift_exchange_ln##i.high_assets $C $FE, $VCE
quietly test 1.high_assets#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hr5) condition("high_assets==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.high_assets#c.gift_exchange_ln]") name(hr6) condition("high_assets==1") testp(`p')
estimates drop work

quietly probit risky_asset_participation c.gift_exchange_ln##i.high_income $C $FE, $VCE
quietly test 1.high_income#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hr7) condition("high_income==0") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[1.high_income#c.gift_exchange_ln]") name(hr8) condition("high_income==1") testp(`p')
estimates drop work

quietly probit risky_asset_participation c.gift_exchange_ln##i.head_age_group $C $FE, $VCE
quietly test 2.head_age_group#c.gift_exchange_ln 3.head_age_group#c.gift_exchange_ln
local p=r(p)
estimates store work
store_slope, model(work) expression("_b[gift_exchange_ln]") name(hr9) condition("head_age_group==1") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[2.head_age_group#c.gift_exchange_ln]") name(hr10) condition("head_age_group==2") testp(.)
store_slope, model(work) expression("_b[gift_exchange_ln]+_b[3.head_age_group#c.gift_exchange_ln]") name(hr11) condition("head_age_group==3") testp(`p')
estimates drop work
local models_stock "hs1 hs2 hs3 hs4 hs5 hs6 hs7 hs8 hs9 hs10 hs11"
local models_risky "hr1 hr2 hr3 hr4 hr5 hr6 hr7 hr8 hr9 hr10 hr11"
local labels `""Rural" "Urban" "Small family" "Large family" "Low assets" "High assets" "Low income" "High income" "Young" "Middle-aged" "Older""'

esttab `models_stock' using "$IRFA_REPRODUCED/Table_08_Heterogeneity.rtf", ///
    replace rtf label nogaps compress cells(b(star fmt(4)) se(par fmt(4))) ///
    collabels(none) eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Gift) coeflabels(Gift "Gift") ///
    mtitles(`labels') stats(Controls ProvinceFE YearFE PseudoR2 InteractionPText GroupN, ///
        fmt(0 0 0 4 4 0) labels("Controls" "Province FE" "Year FE" ///
        "Pseudo R2" "Group-difference p-value" "Observations")) ///
    title("Table 8. Heterogeneity tests: Panel A. Stock")

esttab `models_risky' using "$IRFA_REPRODUCED/Table_08_Heterogeneity.rtf", ///
    append rtf label nogaps compress cells(b(star fmt(4)) se(par fmt(4))) ///
    collabels(none) eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(Gift) coeflabels(Gift "Gift") ///
    mtitles(`labels') stats(Controls ProvinceFE YearFE PseudoR2 InteractionPText GroupN, ///
        fmt(0 0 0 4 4 0) labels("Controls" "Province FE" "Year FE" ///
        "Pseudo R2" "Group-difference p-value" "Observations")) ///
    title("Panel B. Risky Financial Assets") ///
    addnotes("{\i Note:} This table reports the results on how the effect of gift exchange varies with households{\u8217?} place of residence, family size, wealth, and head age. Standard errors are in parentheses. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively. See Table 1 for variable definitions.")
estimates clear

display "TABLES_07_08=PASS"
