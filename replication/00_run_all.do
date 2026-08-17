* IRFA recommended replication package: raw CHFS files -> Tables 1-8.
* Run this file from the package root with Stata 18.
version 18.0
clear all
set more off
set varabbrev off
set maxvar 32767
set linesize 255
capture log close _all

local ROOT = subinstr(c(pwd), char(92), "/", .)
global IRFA_PACKAGE_ROOT "`ROOT'"
adopath ++ "`ROOT'/ado"
quietly do "config/01_paths.do"

capture mkdir "$IRFA_WORK_ROOT"
capture mkdir "$IRFA_WORK_ROOT/data"
capture mkdir "$IRFA_WORK_ROOT/data/intermediate"
capture mkdir "$IRFA_WORK_ROOT/logs"
capture mkdir "$IRFA_REPRODUCED"
capture mkdir "$IRFA_LOGS"
capture mkdir "$IRFA_EVIDENCE"

log using "$IRFA_LOGS/00_run_all.log", text replace name(master)
display "IRFA_REPLICATION_RUN=START"

* Data build: all substantive transformations are kept in numbered modules.
do "$IRFA_PACKAGE_ROOT/code/data_build/00_master.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)
do "$IRFA_PACKAGE_ROOT/code/linkage/20_build_geography.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)
do "$IRFA_PACKAGE_ROOT/code/linkage/30_build_variable_supplement.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)
do "$IRFA_PACKAGE_ROOT/code/linkage/32_build_parent_party.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)
do "$IRFA_PACKAGE_ROOT/code/linkage/34_build_public_sector_household.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)
do "$IRFA_PACKAGE_ROOT/code/analysis/40_prepare_analysis_data.do"
capture log close _all
log using "$IRFA_LOGS/00_run_all.log", text append name(master)

* Tables are estimated in the locked Table 1-8 order.
do "$IRFA_PACKAGE_ROOT/code/analysis/50_tables_01_05.do"
do "$IRFA_PACKAGE_ROOT/code/analysis/55_table_06_iv.do"
do "$IRFA_PACKAGE_ROOT/code/analysis/58_tables_07_08.do"

do "$IRFA_PACKAGE_ROOT/code/analysis/90_format_tables.do"

* Final table inventory and reproducibility assertions.
local required Table_01_Variable_Definitions.rtf ///
    Table_02_Summary_Statistics.rtf Table_03_Gift_Group_Comparison.rtf ///
    Table_04_Baseline.rtf Table_05_Robustness.rtf ///
    Table_06_Instrumental_Variables.rtf Table_07_Mechanisms.rtf ///
    Table_08_Heterogeneity.rtf
foreach f of local required {
    confirm file "$IRFA_REPRODUCED/`f'"
}
use "$IRFA_FINAL_DTA", clear
isid hhid year
assert _N == $IRFA_EXPECTED_N
quietly count if sample_submission_positive == 1
assert r(N) == $IRFA_POSITIVE_N
quietly count if sample_submission_positive == 1 & !missing(parent_party)
assert r(N) == 26249

display "TABLE_INVENTORY=PASS"
local pass_marker = "IRFA_REPLICATION_RUN=" + "PASS"
display "`pass_marker'"
local completion_marker = "__CODEX_STATA_" + "COMPLETE__"
display "`completion_marker'"
log close master
exit 0
