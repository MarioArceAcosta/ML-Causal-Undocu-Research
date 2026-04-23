********************************************************************************
* GRAND MASTER SCRIPT: RUN ALL EVERIFY ANALYSIS
********************************************************************************
clear all
set more off

* --- 1. SET MAIN DIRECTORY ---
* (This ensures Stata knows where to look for your do-files)
global drive "/Users/verosovero/Library/CloudStorage/GoogleDrive-vsovero@ucr.edu" 
global main "$drive/Shared drives/Undocu Research"
cd "$main"


do "Code/(Step 4) Regression Analysis/00_everify_setup.do"
do "Code/(Step 4) Regression Analysis/01a_everify_build_stack_baseline.do"
do "Code/(Step 4) Regression Analysis/01b_everify_build_stack_never.do"
do "Code/(Step 4) Regression Analysis/01c_everify_build_stack_strict.do"
do "Code/(Step 4) Regression Analysis/02_everify_wage_main.do"
do "Code/(Step 4) Regression Analysis/03_everify_wage_robustness.do"
do "Code/(Step 4) Regression Analysis/04_everify_secondary_outcomes.do"
