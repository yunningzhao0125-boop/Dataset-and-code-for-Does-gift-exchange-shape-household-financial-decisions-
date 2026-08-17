* Tables 1-5: definitions, descriptives, baseline, and robustness.
version 18.0
set more off
quietly do "config/01_paths.do"
adopath ++ "$IRFA_PACKAGE_ROOT/ado"

global X "gift_exchange_ln"
global C "age age_squared female family_size_w party_member rural_hukou rural_residence household_assets_10k_w household_income_pc_10k_w"
global FE "i.province_id i.year"
global VCE "vce(cluster city_id_stable)"

use "$IRFA_FINAL_DTA", clear
isid hhid year

* -----------------------------------------------------------------------------
* Table 1. Variable definitions
* -----------------------------------------------------------------------------
file open t01 using "$IRFA_REPRODUCED/Table_01_Variable_Definitions.rtf", write replace
file write t01 "{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}\fs20" _n
file write t01 "\b Table 1. Variable definitions\b0\par" _n
file write t01 "\trowd\trgaph80\clbrdrt\brdrw10\brdrs\clbrdrb\brdrw10\brdrs\cellx3000\clbrdrt\brdrw10\brdrs\clbrdrb\brdrw10\brdrs\cellx12500" _n
file write t01 "\pard\intbl\b Variable\cell Definition\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl\b Dependent variables\b0\cell\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Stock\cell A dummy variable that equals one if a household owns stocks, and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Risky Financial Assets\cell A dummy variable that equals one if a household owns any stocks, funds, high-yield bonds, investment real estate, futures, or other derivatives and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl\b Independent variables\b0\cell\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Gift\cell The logarithm of the sum of the gift of money exchanges and holiday gift exchange in the previous year\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Gift expenditure\cell The logarithm of the sum of the gift of money expense and holiday gift expense in the previous year\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl\b Other variables\b0\cell\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Age\cell Age of household head\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Age2\cell The squared term of the household head's age\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Female\cell A dummy variable that equals one if the head of household is female and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Asset\cell The household's total assets (Unit: 10 thousands)\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Total income\cell The average income per person in a household (Unit: 10 thousands)\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Family member\cell Number of household members\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Rural\cell A dummy variable that equals one if the head of household lives in a rural area and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Party member\cell A dummy variable that equals one if the head of household is a member of the Communist Party of China (CPC) and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Hukou\cell A dummy variable that equals one if the head of household has a rural household registration (hukou) and zero otherwise\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Education\cell Household head's educational attainment. A categorical variable ranging from 0 to 9, where 0 indicates no formal education and 9 indicates a doctoral degree.\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Informal credit\cell A dummy variable that equals one if a household has borrowed from or lent money to friends and relatives in the past year\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Interpersonal trust\cell The normalized response to the question 'How much do you trust strangers?', with 0 meaning very distrustful and 1 meaning very trustful\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Financial literacy\cell A dummy equal to one if the household head can correctly answer a question about compound interest\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Network size\cell Local-kin network-size category from 0 to 3\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl GDP\cell The logarithm of annual gross domestic product of each province\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Finance level\cell The balance of deposits and loans of financial institutions at the end of the year / Regional GDP\cell\row" _n
file write t01 "\trowd\trgaph80\cellx3000\cellx12500\pard\intbl Pop density\cell The number of inhabitants per square kilometer in the province\cell\row" _n
file write t01 "\trowd\trgaph80\clbrdrb\brdrw10\brdrs\cellx3000\clbrdrb\brdrw10\brdrs\cellx12500\pard\intbl Parent CCP member\cell A dummy variable that equals one if either observed parent is coded as a CPC member; equals zero only when both parent responses are observed and neither is coded as a CPC member\cell\row" _n
file write t01 "}" _n
file close t01

* -----------------------------------------------------------------------------
* Table 2. Summary statistics, with variable-specific nonmissing N
* -----------------------------------------------------------------------------
keep if sample_submission_positive == 1
local t02vars stock_participation risky_asset_participation gift_exchange_ln ///
    gift_given_ln age female household_assets_10k_w household_income_pc_10k_w ///
    family_size_w rural_residence party_member rural_hukou informal_credit_paper ///
    trust_01 local_gdp_log local_finance_level population_density parent_party
estpost summarize `t02vars'
esttab using "$IRFA_REPRODUCED/Table_02_Summary_Statistics.rtf", replace rtf ///
    label nonumber nomtitle cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    collabels("N" "Mean" "SD" "Min" "Max") order(`t02vars') ///
    title("Table 2. Summary statistics") ///
    addnotes("{\i Note:} This table reports the descriptive statistics for our main variables, including the mean, standard deviation (SD), minimum (Min), and maximum (Max) values. See Table 1 for variable definitions.")

* -----------------------------------------------------------------------------
* Table 3. Zero-Gift versus positive-Gift comparison; no clustered standard errors
* -----------------------------------------------------------------------------
use "$IRFA_FINAL_DTA", clear
keep if sample_submission_primary == 1
gen byte gift_high = gift_exchange_yuan > 0 if !missing(gift_exchange_yuan)
assert inlist(gift_high,0,1)
file open t03 using "$IRFA_REPRODUCED/Table_03_Gift_Group_Comparison.rtf", write replace
file write t03 "{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}\fs20" _n
file write t03 "\b Table 3. High gift exchange vs Low gift exchange\b0\par" _n
file write t03 "\trowd\trgaph80\clbrdrt\brdrw10\brdrs\cellx2700\clbrdrt\brdrw10\brdrs\cellx4100\clbrdrt\brdrw10\brdrs\cellx5500\clbrdrt\brdrw10\brdrs\cellx6900\clbrdrt\brdrw10\brdrs\cellx8300\clbrdrt\brdrw10\brdrs\cellx10000" _n
file write t03 "\pard\intbl\ql\b Variables\b0\cell\qc Low gift exchange\cell\cell High gift exchange\cell\cell\cell\row" _n
file write t03 "\trowd\trgaph80\clbrdrb\brdrw10\brdrs\cellx2700\clbrdrb\brdrw10\brdrs\cellx4100\clbrdrb\brdrw10\brdrs\cellx5500\clbrdrb\brdrw10\brdrs\cellx6900\clbrdrb\brdrw10\brdrs\cellx8300\clbrdrb\brdrw10\brdrs\cellx10000" _n
file write t03 "\pard\intbl\ql\cell\qc N\cell Mean\cell N\cell Mean\cell MeanDiff\cell\row" _n
local row : variable label stock_participation
quietly summarize stock_participation if gift_high == 0
local n0=r(N)
local m0=r(mean)
quietly summarize stock_participation if gift_high == 1
local n1=r(N)
local m1=r(mean)
quietly regress stock_participation gift_high
quietly lincom -gift_high
local d=r(estimate)
local p=r(p)
local stars=cond(`p'<=.01,"***",cond(`p'<=.05,"**",cond(`p'<=.10,"*","")))
local n0t : display %12.0f `n0'
local n1t : display %12.0f `n1'
local m0t : display %9.3f `m0'
local m1t : display %9.3f `m1'
local dt : display %9.3f `d'
file write t03 "\trowd\trgaph80\cellx2700\cellx4100\cellx5500\cellx6900\cellx8300\cellx10000" _n
file write t03 "\pard\intbl\ql `row'\cell\qc `n0t'\cell `m0t'\cell `n1t'\cell `m1t'\cell `dt'`stars'\cell\row" _n

local row : variable label risky_asset_participation
quietly summarize risky_asset_participation if gift_high == 0
local n0=r(N)
local m0=r(mean)
quietly summarize risky_asset_participation if gift_high == 1
local n1=r(N)
local m1=r(mean)
quietly regress risky_asset_participation gift_high
quietly lincom -gift_high
local d=r(estimate)
local p=r(p)
local stars=cond(`p'<=.01,"***",cond(`p'<=.05,"**",cond(`p'<=.10,"*","")))
local n0t : display %12.0f `n0'
local n1t : display %12.0f `n1'
local m0t : display %9.3f `m0'
local m1t : display %9.3f `m1'
local dt : display %9.3f `d'
file write t03 "\trowd\trgaph80\cellx2700\cellx4100\cellx5500\cellx6900\cellx8300\cellx10000" _n
file write t03 "\pard\intbl\ql `row'\cell\qc `n0t'\cell `m0t'\cell `n1t'\cell `m1t'\cell `dt'`stars'\cell\row" _n

local row : variable label informal_credit_paper
quietly summarize informal_credit_paper if gift_high == 0
local n0=r(N)
local m0=r(mean)
quietly summarize informal_credit_paper if gift_high == 1
local n1=r(N)
local m1=r(mean)
quietly regress informal_credit_paper gift_high
quietly lincom -gift_high
local d=r(estimate)
local p=r(p)
local stars=cond(`p'<=.01,"***",cond(`p'<=.05,"**",cond(`p'<=.10,"*","")))
local n0t : display %12.0f `n0'
local n1t : display %12.0f `n1'
local m0t : display %9.3f `m0'
local m1t : display %9.3f `m1'
local dt : display %9.3f `d'
file write t03 "\trowd\trgaph80\cellx2700\cellx4100\cellx5500\cellx6900\cellx8300\cellx10000" _n
file write t03 "\pard\intbl\ql `row'\cell\qc `n0t'\cell `m0t'\cell `n1t'\cell `m1t'\cell `dt'`stars'\cell\row" _n

local row : variable label trust_01
quietly summarize trust_01 if gift_high == 0
local n0=r(N)
local m0=r(mean)
quietly summarize trust_01 if gift_high == 1
local n1=r(N)
local m1=r(mean)
quietly regress trust_01 gift_high
quietly lincom -gift_high
local d=r(estimate)
local p=r(p)
local stars=cond(`p'<=.01,"***",cond(`p'<=.05,"**",cond(`p'<=.10,"*","")))
local n0t : display %12.0f `n0'
local n1t : display %12.0f `n1'
local m0t : display %9.3f `m0'
local m1t : display %9.3f `m1'
local dt : display %9.3f `d'
file write t03 "\trowd\trgaph80\clbrdrb\brdrw10\brdrs\cellx2700\clbrdrb\brdrw10\brdrs\cellx4100\clbrdrb\brdrw10\brdrs\cellx5500\clbrdrb\brdrw10\brdrs\cellx6900\clbrdrb\brdrw10\brdrs\cellx8300\clbrdrb\brdrw10\brdrs\cellx10000" _n
file write t03 "\pard\intbl\ql `row'\cell\qc `n0t'\cell `m0t'\cell `n1t'\cell `m1t'\cell `dt'`stars'\cell\row" _n
file write t03 "\pard\par {\i Note:} This table compares financial-market participation between low- and high- gift exchange groups within the survey year. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively.\par}" _n
file close t03

* -----------------------------------------------------------------------------
* Table 4. Probit coefficients and average marginal effects
* -----------------------------------------------------------------------------
use "$IRFA_FINAL_DTA", clear
keep if sample_submission_positive == 1
quietly probit stock_participation $X $C $FE, $VCE
local n=e(N)
local r2=e(r2_p)
estadd scalar Observations=`n'
estadd scalar PseudoR2=`r2'
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t4_stock
quietly margins, dydx($X $C) post
estadd scalar Observations=`n'
estadd scalar PseudoR2=`r2'
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t4_stock_ame

quietly probit risky_asset_participation $X $C $FE, $VCE
local n=e(N)
local r2=e(r2_p)
estadd scalar Observations=`n'
estadd scalar PseudoR2=`r2'
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t4_risky
quietly margins, dydx($X $C) post
estadd scalar Observations=`n'
estadd scalar PseudoR2=`r2'
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t4_risky_ame

esttab t4_stock t4_stock_ame t4_risky t4_risky_ame ///
    using "$IRFA_REPRODUCED/Table_04_Baseline.rtf", replace rtf label nogaps ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep($X $C _cons) order($X $C _cons) coeflabels(_cons "Constant") ///
    mtitles("Stock" "Marginal Effects" "Risky Financial Assets" "Marginal Effects") ///
    stats(ProvinceFE YearFE PseudoR2 Observations, fmt(0 0 4 0) ///
        labels("Province FE" "Year FE" "Pseudo R2" "Observations")) ///
    title("Table 4. Gift exchange and financial-market participation") ///
    addnotes("{\i Note:} This table presents the main regression results of the relationship between gift exchange and risky financial investment. Columns (1) and (3) report Probit coefficients; columns (2) and (4) report average marginal effects for Gift and all controls. Standard errors are in parentheses. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively. See Table 1 for variable definitions.")
estimates clear

* -----------------------------------------------------------------------------
* Table 5, Panel A. Alternative variables
* -----------------------------------------------------------------------------
use "$IRFA_FINAL_DTA", clear
quietly probit stock_participation $X $C $FE if sample_submission_primary==1, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5a_s0
quietly probit risky_asset_participation $X $C $FE if sample_submission_primary==1, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5a_r0
quietly probit stock_participation gift_given_ln $C $FE if sample_submission_positive==1, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5a_sg
quietly probit risky_asset_participation gift_given_ln $C $FE if sample_submission_positive==1, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5a_rg
esttab t5a_s0 t5a_r0 t5a_sg t5a_rg ///
    using "$IRFA_REPRODUCED/Table_05_Robustness.rtf", replace rtf nogaps compress ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) keep(gift_exchange_ln gift_given_ln) ///
    coeflabels(gift_exchange_ln "Gift" gift_given_ln "Gift expenditure") ///
    mtitles("Stock" "Risky Financial Assets" "Stock" "Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE PseudoR2 Observations, fmt(0 0 0 4 0) ///
        labels("Controls" "Province FE" "Year FE" "Pseudo R2" "Observations")) ///
    title("Table 5. Robustness tests: Panel A. Alternative variables")
estimates clear

* -----------------------------------------------------------------------------
* Table 5, Panel B. Alternative specifications
* -----------------------------------------------------------------------------
keep if sample_submission_positive == 1
egen long household_cluster = group(link_hhid_generic)
quietly logit stock_participation $X $C $FE, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_sl
quietly regress stock_participation $X $C $FE, $VCE
estadd scalar AdjustedR2=e(r2_a)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_so
quietly probit stock_participation $X $C $FE, vce(cluster household_cluster)
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_sh
quietly probit stock_participation $X local_gdp_log local_finance_level population_density $C i.city_id_stable i.year, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "No"
estadd local YearFE "Yes"
estadd local CityFE "Yes"
estimates store t5b_sc

quietly logit risky_asset_participation $X $C $FE, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_rl
quietly regress risky_asset_participation $X $C $FE, $VCE
estadd scalar AdjustedR2=e(r2_a)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_ro
quietly probit risky_asset_participation $X $C $FE, vce(cluster household_cluster)
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estadd local CityFE "No"
estimates store t5b_rh
quietly probit risky_asset_participation $X local_gdp_log local_finance_level population_density $C i.city_id_stable i.year, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "No"
estadd local YearFE "Yes"
estadd local CityFE "Yes"
estimates store t5b_rc
esttab t5b_sl t5b_so t5b_sh t5b_sc t5b_rl t5b_ro t5b_rh t5b_rc ///
    using "$IRFA_REPRODUCED/Table_05_Robustness.rtf", append rtf nogaps compress ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(gift_exchange_ln local_gdp_log local_finance_level population_density) ///
    coeflabels(gift_exchange_ln "Gift" local_gdp_log "GDP" ///
        local_finance_level "Financial level" population_density "Population density") ///
    mtitles("Logit" "LPM" "Household cluster" "City FE" ///
        "Logit" "LPM" "Household cluster" "City FE") ///
    stats(Controls ProvinceFE YearFE CityFE PseudoR2 AdjustedR2 Observations, ///
        fmt(0 0 0 0 4 4 0) labels("Controls" "Province FE" "Year FE" "City FE" ///
        "Pseudo R2" "Adjusted R2" "Observations")) ///
    title("Panel B. Alternative specifications")
estimates clear

* -----------------------------------------------------------------------------
* Table 5, Panel C. Alternative explanations on a common sample
* -----------------------------------------------------------------------------
gen byte common_proxy = !missing(network_size, financial_literacy)
quietly probit stock_participation $X network_size $C $FE if common_proxy, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5c_sn
quietly probit stock_participation $X financial_literacy $C $FE if common_proxy, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5c_sl
quietly probit risky_asset_participation $X network_size $C $FE if common_proxy, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5c_rn
quietly probit risky_asset_participation $X financial_literacy $C $FE if common_proxy, $VCE
estadd scalar PseudoR2=e(r2_p)
estadd scalar Observations=e(N)
estadd local Controls "Yes"
estadd local ProvinceFE "Yes"
estadd local YearFE "Yes"
estimates store t5c_rl
esttab t5c_sn t5c_sl t5c_rn t5c_rl ///
    using "$IRFA_REPRODUCED/Table_05_Robustness.rtf", append rtf nogaps compress label ///
    cells(b(star fmt(4)) se(par fmt(4))) collabels(none) eqlabels(none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(gift_exchange_ln network_size financial_literacy) ///
    coeflabels(gift_exchange_ln "Gift" network_size "Network size" ///
        financial_literacy "Financial literacy") ///
    mtitles("Stock" "Stock" "Risky Financial Assets" "Risky Financial Assets") ///
    stats(Controls ProvinceFE YearFE PseudoR2 Observations, fmt(0 0 0 4 0) ///
        labels("Controls" "Province FE" "Year FE" "Pseudo R2" "Observations")) ///
    title("Panel C. Alternative explanations") ///
    addnotes("{\i Note:} This table presents the results of robust checks. Panel A shows the results using alternative samples and alternative measures of gift exchange and risky financial investment. Panel B reports the results using alternative specifications, including alternative models, clustering, and controlling for local economic conditions and city fixed effects. Panel C shows the results of alternative explanations. Standard errors are in parentheses. ***, **, and * indicate significance at 1%, 5%, and 10%, respectively. See Table 1 for variable definitions.")
estimates clear

display "TABLES_01_05=PASS"
