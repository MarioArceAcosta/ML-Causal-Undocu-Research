********************************************************************************
* 00_everify_setup.do
* Shared paths and globals for the E-Verify pipeline
********************************************************************************
clear all
set more off
set scheme s1color
set maxvar 30000
set matsize 10000
set emptycells drop

global drive "/Users/verosovero/Library/CloudStorage/GoogleDrive-vsovero@ucr.edu"
global main "$drive/Shared drives/Undocu Research"
cd "$main"

cap mkdir "Output"
cap mkdir "Output/Tables"
cap mkdir "Output/Figures"

global demo_covars age age_squared hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed
global policy_covars drivers_license professional_licensure cooperation_federal_immigration secure_communities omnibus
global covars $demo_covars $policy_covars

* Table labels
global triple_label "E-Verify $\times$ Post $\times$ Undocumented"
global fb_label     "E-Verify $\times$ Post $\times$ Foreign-Born (All)"
