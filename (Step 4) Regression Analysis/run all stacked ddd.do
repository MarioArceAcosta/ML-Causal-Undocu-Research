********************************************************************************
* GRAND MASTER SCRIPT: RUN ALL POLICY EVENT STUDIES
********************************************************************************
clear all
set more off

* --- 1. SET MAIN DIRECTORY ---
* (This ensures Stata knows where to look for your do-files)
global drive "/Users/verosovero/Library/CloudStorage/GoogleDrive-vsovero@ucr.edu" 
global main "$drive/Shared drives/Undocu Research"
cd "$main"

* --- 2. EXECUTE DO-FILES ---
* Note: Adjust the file names/paths below if you saved them in a specific subfolder 
* like "Scripts/master_dl_ddd.do"


display "=================================================="
display "E-VERIFY MANDATES"
display "=================================================="
do "Code/(Step 4) Regression Analysis/everify_ddd.do"

display "=================================================="
display "FEDERAL COOPERATION (SANCTUARY)"
display "=================================================="
do "Code/(Step 4) Regression Analysis/coop_ddd.do"


display "=================================================="
display " Inclusive IPC"
display "=================================================="
do "Code/(Step 4) Regression Analysis/inclusive_ddd.do"


display "=================================================="
display "ALL SCRIPTS FINISHED SUCCESSFULLY!"
display "=================================================="
