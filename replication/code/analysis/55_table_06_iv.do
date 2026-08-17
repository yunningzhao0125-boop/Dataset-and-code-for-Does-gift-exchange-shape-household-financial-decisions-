* Table 6: parent-party IV, exclusion diagnostics, and Lewbel.
version 18.0
set more off
quietly do "config/01_paths.do"
adopath ++ "$IRFA_PACKAGE_ROOT/ado"

* Remove obsolete observable-path diagnostics from earlier runs.
capture erase "$IRFA_EVIDENCE/table06_observable_paths.dta"
capture erase "$IRFA_EVIDENCE/table06_observable_paths.csv"

global X "gift_exchange_ln"
global Z "parent_party"
global C "age age_squared female family_size_w party_member rural_hukou rural_residence household_assets_10k_w household_income_pc_10k_w"
global FE "i.province_id i.year"
global VCE "vce(cluster city_id_stable)"

use "$IRFA_FINAL_DTA", clear
keep if sample_submission_positive == 1 & !missing(parent_party)
assert _N == 26249
assert gift_exchange_yuan > 0 & !missing(gift_exchange_yuan)
tempfile ivsample
save `ivsample'

tempname diag
postfile `diag' str24 panel str32 specification str8 outcome long observations ///
    double coefficient clustered_se p_value kp_f effective_f effective_f_cv10 ar_p ///
    bp_chi2 bp_p ///
    using "$IRFA_EVIDENCE/table06_iv_diagnostics.dta", replace

* -----------------------------------------------------------------------------
* Panel A. First stage and baseline 2SLS
* -----------------------------------------------------------------------------
local stock_yogo_cv10 = 16.38
quietly regress $X $Z $C $FE, $VCE
estadd scalar Observations=e(N)
estadd scalar AdjustedR2=e(r2_a)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store iv_first

quietly ivreg2 stock_participation $C $FE ($X=$Z), ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __iv_stock
quietly weakivtest
local eff=r(F_eff)
local cv10=r(c_TSLS_10)
assert `eff' > `cv10'
local panelA_kp=`kp'
local panelA_eff=`eff'
local panelA_cv10=`cv10'
local panelA_eff_text = strtrim(string(`panelA_eff', "%9.3f"))
local panelA_cv10_text = strtrim(string(`panelA_cv10', "%9.3f"))
quietly regress stock_participation $Z $C $FE, $VCE
quietly test $Z
local arp=r(p)
estimates restore __iv_stock
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store iv_stock
estimates drop __iv_stock
post `diag' ("A") ("baseline") ("Stock") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

quietly ivreg2 risky_asset_participation $C $FE ($X=$Z), ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __iv_risky
quietly weakivtest
local eff=r(F_eff)
local cv10=r(c_TSLS_10)
assert `eff' > `cv10'
quietly regress risky_asset_participation $Z $C $FE, $VCE
quietly test $Z
local arp=r(p)
estimates restore __iv_risky
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store iv_risky
estimates drop __iv_risky
post `diag' ("A") ("baseline") ("Risky") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

estimates restore iv_first
estadd scalar KPF=`panelA_kp'
estadd scalar StockYogoCV10=`stock_yogo_cv10'
estadd scalar EffectiveF=`panelA_eff'
estadd scalar EffectiveFCV10=`panelA_cv10'
estimates store iv_first_report

esttab iv_first_report iv_stock iv_risky ///
    using "$IRFA_REPRODUCED/Table_06_Instrumental_Variables.rtf", replace rtf label nogaps ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) keep(parent_party gift_exchange_ln) ///
    coeflabels(parent_party "Parent CPC member" gift_exchange_ln "Gift") ///
    mtitles("First stage" "2SLS: Stock" "2SLS: Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE AdjustedR2 KPF StockYogoCV10 EffectiveF EffectiveFCV10 ARp Observations, ///
        fmt(0 0 0 4 3 2 3 3 6 0) labels("Controls" "Province FE" "Year FE" ///
        "Adjusted R2" "Kleibergen-Paap rk Wald F" "Stock-Yogo 10% critical value" "Effective F" ///
        "Effective F 10% critical value" "Anderson-Rubin p-value" "Observations")) ///
    title("Table 6. IV regression results: Panel A. IV regression results")
estimates clear

* -----------------------------------------------------------------------------
* Panel B. Add Education and Financial literacy
* -----------------------------------------------------------------------------
local add "education_code financial_literacy"
quietly ivreg2 stock_participation $C `add' $FE ($X=$Z), ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __aug_stock
local eff=.
local cv10=.
local arp=.
estimates restore __aug_stock
estadd scalar KPF=`kp'
estadd scalar EffectiveF=`eff'
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store aug_stock
estimates drop __aug_stock
post `diag' ("B") ("augmented_controls") ("Stock") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

quietly ivreg2 risky_asset_participation $C `add' $FE ($X=$Z), ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __aug_risky
local eff=.
local cv10=.
local arp=.
estimates restore __aug_risky
estadd scalar KPF=`kp'
estadd scalar EffectiveF=`eff'
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store aug_risky
estimates drop __aug_risky
post `diag' ("B") ("augmented_controls") ("Risky") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

esttab aug_stock aug_risky using "$IRFA_REPRODUCED/Table_06_Instrumental_Variables.rtf", ///
    append rtf label nogaps cells(b(star fmt(4)) se(par fmt(4))) ///
    collabels(none) eqlabels(none) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(gift_exchange_ln education_code financial_literacy) ///
    order(gift_exchange_ln education_code financial_literacy) ///
    coeflabels(gift_exchange_ln "Gift" education_code "Education" ///
        financial_literacy "Financial literacy") ///
    mtitles("2SLS: Stock" "2SLS: Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE Observations, ///
        fmt(0 0 0 0) labels("Controls" "Province FE" "Year FE" "Observations")) ///
    title("Panel B. Additional controls based on IV regression")
estimates clear

* -----------------------------------------------------------------------------
* Panel C. Exclude government and SOE households
* -----------------------------------------------------------------------------
quietly ivreg2 stock_participation $C $FE ($X=$Z) if public_sector_broad==0, ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __b_stock
local eff=.
local cv10=.
local arp=.
estimates restore __b_stock
estadd scalar KPF=`kp'
estadd scalar EffectiveF=`eff'
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store b_stock
estimates drop __b_stock
post `diag' ("C") ("exclude_government_soe") ("Stock") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

quietly ivreg2 risky_asset_participation $C $FE ($X=$Z) if public_sector_broad==0, ///
    cluster(city_id_stable) small endog($X)
quietly test $X
local p=r(p)
local b=_b[$X]
local se=_se[$X]
local kp=e(widstat)
local n=e(N)
estimates store __b_risky
local eff=.
local cv10=.
local arp=.
estimates restore __b_risky
estadd scalar KPF=`kp'
estadd scalar EffectiveF=`eff'
estadd scalar ARp=`arp'
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store b_risky
estimates drop __b_risky
post `diag' ("C") ("exclude_government_soe") ("Risky") (`n') (`b') (`se') (`p') (`kp') (`eff') (`cv10') (`arp') (.) (.)

esttab b_stock b_risky ///
    using "$IRFA_REPRODUCED/Table_06_Instrumental_Variables.rtf", append rtf label nogaps ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) keep(gift_exchange_ln) ///
    coeflabels(gift_exchange_ln "Gift") ///
    mtitles("Stock" "Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE Observations, ///
        fmt(0 0 0 0) labels("Controls" "Province FE" "Year FE" "Observations")) ///
    title("Panel C. Exclude households with political capital channels")
estimates clear

* -----------------------------------------------------------------------------
* Panel D. Lewbel's 2SLS estimation results
* -----------------------------------------------------------------------------
use "$IRFA_FINAL_DTA", clear
keep if sample_submission_positive == 1
generate double gx=asinh(gift_exchange_yuan/10000)
local source_controls "$C"
local short_controls ""
local j=0
foreach v of local source_controls {
    local ++j
    clonevar c`j'=`v'
    local short_controls "`short_controls' c`j'"
}
quietly tabulate province_id, generate(pf_)
quietly tabulate year, generate(yf_)
drop pf_1 yf_1
unab lewbel_fe : pf_* yf_*
local lewbel_exog "`short_controls' `lewbel_fe'"
local generated : word count `lewbel_exog'
assert `generated' == 39

quietly regress gx `lewbel_exog'
quietly estat hettest, rhs iid
local bp_chi2=r(chi2)
local bp_p=r(p)
local bp_stars ""
if `bp_p' < 0.10 local bp_stars "*"
if `bp_p' < 0.05 local bp_stars "**"
if `bp_p' < 0.01 local bp_stars "***"
local bp_display = strtrim(string(`bp_chi2', "%9.3f")) + "`bp_stars'"

quietly ivreg2h stock_participation `lewbel_exog' (gx=), ///
    cluster(city_id_stable) small robust
quietly test gx
local p=r(p)
local b=_b[gx]
local se=_se[gx]
local n=e(N)
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local BPTest "`bp_display'"
estimates store lewbel_stock
post `diag' ("D") ("ivreg2h_ihs") ("Stock") (`n') (`b') (`se') (`p') (.) (.) (.) (.) (`bp_chi2') (`bp_p')

quietly ivreg2h risky_asset_participation `lewbel_exog' (gx=), ///
    cluster(city_id_stable) small robust
quietly test gx
local p=r(p)
local b=_b[gx]
local se=_se[gx]
local n=e(N)
estadd scalar Observations=`n'
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local BPTest "`bp_display'"
estimates store lewbel_risky
post `diag' ("D") ("ivreg2h_ihs") ("Risky") (`n') (`b') (`se') (`p') (.) (.) (.) (.) (`bp_chi2') (`bp_p')
postclose `diag'

esttab lewbel_stock lewbel_risky ///
    using "$IRFA_REPRODUCED/Table_06_Instrumental_Variables.rtf", append rtf label nogaps ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) keep(gx) ///
    coeflabels(gx "Gift") ///
    mtitles("Stock" "Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE BPTest Observations, fmt(0 0 0 0 0) ///
        labels("Controls" "Province FE" "Year FE" ///
        "Breusch-Pagan test for heteroskedasticity" "Observations")) ///
    title("Panel D. Lewbel's 2SLS estimation results") ///
    addnotes("{\i Note:} This table reports IV regression results. Panel A reports the IV estimation results using parental CCP membership. Panel B further controls for households{\u8217?} education and financial literacy. Panel C excludes households whose members are employed in government or state-owned enterprises. Panel D conducts the Lewbel (2012) IV approach. Standard errors are in parentheses. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively. See Table 1 for variable definitions.")
estimates clear

use "$IRFA_EVIDENCE/table06_iv_diagnostics.dta", clear
sort panel specification outcome
export delimited using "$IRFA_EVIDENCE/table06_iv_diagnostics.csv", replace

display "TABLE_06=PASS"
