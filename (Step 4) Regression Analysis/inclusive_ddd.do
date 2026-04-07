********************************************************************************
* MASTER SCRIPT: IMPACT OF INCLUSIVE POLICIES ON LABOR MARKET MATCHING
* DESIGN: BINNED POLICY REGIMES TRIPLE-DIFFERENCE (DDD)
********************************************************************************
clear all
set more off
set scheme s1color
set maxvar 30000

* --- 1. DIRECTORIES & GLOBALS ---
global drive "/Users/verosovero/Library/CloudStorage/GoogleDrive-vsovero@ucr.edu" 
global main "$drive/Shared drives/Undocu Research"
cd "$main"

cap mkdir "Output"
cap mkdir "Output/Tables"
cap mkdir "Output/Figures"

* --- 2. LOAD DATA & CREATE THEORETICAL BINNED TREATMENT INTERACTIONS ---
use "Data/EO_Final.dta", clear

* Convert the string "NA" to numeric missing (.), then destring the variable
destring secure_communities, replace ignore("NA")

* Replace the missing values with 0 (neutral/inactive policy)
replace secure_communities = 0 if missing(secure_communities)

* Create the narrow Labor Market Index
gen labor_index = e_verify + professional_licensure + drivers_license + ///
                  secure_communities + omnibus + cooperation_federal_immigration

* Create the categorical variable for Policy Bins
* Hostile (<= -2), Neutral (-1 to 0), Inclusive (>= 1)
gen policy_bin = .
replace policy_bin = 1 if labor_index <= -2                  
replace policy_bin = 2 if labor_index >= -1 & labor_index <= 0 
replace policy_bin = 3 if labor_index >= 1                   

* Create binary dummies (Neutral is the omitted baseline)
gen bin_hostile   = (policy_bin == 1)
gen bin_inclusive = (policy_bin == 3)

* --- CREATE TRIPLE DIFFERENCE INTERACTIONS ---

* 1. Baseline Foreign-Born Spillover
gen hostile_fb   = bin_hostile * bpl_foreign
gen inclusive_fb = bin_inclusive * bpl_foreign

* 2. Documentation Group Interactions
gen hostile_undocu   = bin_hostile * undocu
gen inclusive_undocu = bin_inclusive * undocu

gen hostile_highprob   = bin_hostile * gbm_high_prob
gen inclusive_highprob = bin_inclusive * gbm_high_prob

gen hostile_highrecall   = bin_hostile * gbm_high_recall
gen inclusive_highrecall = bin_inclusive * gbm_high_recall

gen hostile_lowprob   = bin_hostile * gbm_low_prob
gen inclusive_lowprob = bin_inclusive * gbm_low_prob


* --- 3. BUILD MEMORY-EFFICIENT ABSORB MACROS ---
* We define the categorical variables once, then build the absorb lists for all 4 subgroups.
local cat_vars hisp asian black male bpl_foreign immig_by_ten nonfluent age metropolitan medicaid degfield_broader

* 1. Logical Edits Absorb List
global abs_undocu "statefip#year statefip#undocu year#undocu statefip#bpl_foreign year#bpl_foreign"
foreach v of local cat_vars {
    global abs_undocu "$abs_undocu `v' `v'#undocu"
}

* 2. High Prob Absorb List
global abs_highprob "statefip#year statefip#gbm_high_prob year#gbm_high_prob statefip#bpl_foreign year#bpl_foreign"
foreach v of local cat_vars {
    global abs_highprob "$abs_highprob `v' `v'#gbm_high_prob"
}

* 3. High Recall Absorb List
global abs_highrecall "statefip#year statefip#gbm_high_recall year#gbm_high_recall statefip#bpl_foreign year#bpl_foreign"
foreach v of local cat_vars {
    global abs_highrecall "$abs_highrecall `v' `v'#gbm_high_recall"
}

* 4. Low Prob Absorb List
global abs_lowprob "statefip#year statefip#gbm_low_prob year#gbm_low_prob statefip#bpl_foreign year#bpl_foreign"
foreach v of local cat_vars {
    global abs_lowprob "$abs_lowprob `v' `v'#gbm_low_prob"
}


********************************************************************************
* BINNED DDD REGRESSIONS: 3 OUTCOMES (4x3)
********************************************************************************

local inc_label "Inclusive Regime $\times$ Group"
local hos_label "Hostile Regime $\times$ Group"
local inc_fb_label "Inclusive Regime $\times$ Foreign-Born"
local hos_fb_label "Hostile Regime $\times$ Foreign-Born"

local table_notes "Standard errors [in brackets] are clustered at the state level. The omitted baseline policy climate is 'Neutral' (Index scores of -1 and 0). 'Inclusive Regime' represents state scores $\ge$ 1, and 'Hostile Regime' represents scores $\le$ -2. The 'Group' interaction represents the differential effect on the specific sub-population identified in the column header. All models include state-year, state-group, state-foreign, year-group, and year-foreign fixed effects. Demographic covariates are fully interacted with documentation groups."


* --- TABLE 1: HORIZONTAL UNDERMATCH (HUNDERMATCHED) ---
preserve
    drop if missing(hundermatched)
    keep hundermatched hostile_* inclusive_* ///
         hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed age metropolitan medicaid degfield_broader ///
         perwt statefip year undocu gbm_high_prob gbm_high_recall gbm_low_prob

    reghdfe hundermatched inclusive_undocu hostile_undocu inclusive_fb hostile_fb c.yrsed c.yrsed#i.undocu [pweight=perwt], absorb($abs_undocu) vce(cluster statefip) compact
    estadd ysumm
    est store h_logical

    reghdfe hundermatched inclusive_highprob hostile_highprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_prob [pweight=perwt], absorb($abs_highprob) vce(cluster statefip) compact
    estadd ysumm
    est store h_highprob

    reghdfe hundermatched inclusive_highrecall hostile_highrecall inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_recall [pweight=perwt], absorb($abs_highrecall) vce(cluster statefip) compact
    estadd ysumm
    est store h_highrecall

    reghdfe hundermatched inclusive_lowprob hostile_lowprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_low_prob [pweight=perwt], absorb($abs_lowprob) vce(cluster statefip) compact
    estadd ysumm
    est store h_lowprob
restore

esttab h_logical h_highprob h_highrecall h_lowprob using "Output/Tables/hundermatch_ipc_bins.tex", replace label booktabs keep(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    rename(inclusive_undocu "INC_GRP" inclusive_highprob "INC_GRP" inclusive_highrecall "INC_GRP" inclusive_lowprob "INC_GRP" ///
           hostile_undocu "HOS_GRP" hostile_highprob "HOS_GRP" hostile_highrecall "HOS_GRP" hostile_lowprob "HOS_GRP") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(INC_GRP "`inc_label'" HOS_GRP "`hos_label'" inclusive_fb "`inc_fb_label'" hostile_fb "`hos_fb_label'") ///
    order(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("Binned Policy Regime Effect on Horizontal Undermatch") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("\noalign{\smallskip}\multicolumn{5}{p{14cm}}{\footnotesize Notes: `table_notes'}")


* --- TABLE 2: VERTICAL MISMATCH (VMISMATCHED) ---
preserve
    drop if missing(vmismatched)
    keep vmismatched hostile_* inclusive_* ///
         hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed age metropolitan medicaid degfield_broader ///
         perwt statefip year undocu gbm_high_prob gbm_high_recall gbm_low_prob

    reghdfe vmismatched inclusive_undocu hostile_undocu inclusive_fb hostile_fb c.yrsed c.yrsed#i.undocu [pweight=perwt], absorb($abs_undocu) vce(cluster statefip) compact
    estadd ysumm
    est store v_logical

    reghdfe vmismatched inclusive_highprob hostile_highprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_prob [pweight=perwt], absorb($abs_highprob) vce(cluster statefip) compact
    estadd ysumm
    est store v_highprob

    reghdfe vmismatched inclusive_highrecall hostile_highrecall inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_recall [pweight=perwt], absorb($abs_highrecall) vce(cluster statefip) compact
    estadd ysumm
    est store v_highrecall

    reghdfe vmismatched inclusive_lowprob hostile_lowprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_low_prob [pweight=perwt], absorb($abs_lowprob) vce(cluster statefip) compact
    estadd ysumm
    est store v_lowprob
restore

esttab v_logical v_highprob v_highrecall v_lowprob using "Output/Tables/vmismatched_ipc_bins.tex", replace label booktabs keep(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    rename(inclusive_undocu "INC_GRP" inclusive_highprob "INC_GRP" inclusive_highrecall "INC_GRP" inclusive_lowprob "INC_GRP" ///
           hostile_undocu "HOS_GRP" hostile_highprob "HOS_GRP" hostile_highrecall "HOS_GRP" hostile_lowprob "HOS_GRP") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(INC_GRP "`inc_label'" HOS_GRP "`hos_label'" inclusive_fb "`inc_fb_label'" hostile_fb "`hos_fb_label'") ///
    order(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("Binned Policy Regime Effect on Vertical Mismatch") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("\noalign{\smallskip}\multicolumn{5}{p{14cm}}{\footnotesize Notes: `table_notes'}")


* --- TABLE 3: LOG EARNINGS (LN_ADJ) ---
preserve
    drop if missing(ln_adj)
    keep ln_adj hostile_* inclusive_* ///
         hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed age metropolitan medicaid degfield_broader ///
         perwt statefip year undocu gbm_high_prob gbm_high_recall gbm_low_prob

    reghdfe ln_adj inclusive_undocu hostile_undocu inclusive_fb hostile_fb c.yrsed c.yrsed#i.undocu [pweight=perwt], absorb($abs_undocu) vce(cluster statefip) compact
    estadd ysumm
    est store l_logical

    reghdfe ln_adj inclusive_highprob hostile_highprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_prob [pweight=perwt], absorb($abs_highprob) vce(cluster statefip) compact
    estadd ysumm
    est store l_highprob

    reghdfe ln_adj inclusive_highrecall hostile_highrecall inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_high_recall [pweight=perwt], absorb($abs_highrecall) vce(cluster statefip) compact
    estadd ysumm
    est store l_highrecall

    reghdfe ln_adj inclusive_lowprob hostile_lowprob inclusive_fb hostile_fb c.yrsed c.yrsed#i.gbm_low_prob [pweight=perwt], absorb($abs_lowprob) vce(cluster statefip) compact
    estadd ysumm
    est store l_lowprob
restore

esttab l_logical l_highprob l_highrecall l_lowprob using "Output/Tables/wage_ipc_bins.tex", replace label booktabs keep(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    rename(inclusive_undocu "INC_GRP" inclusive_highprob "INC_GRP" inclusive_highrecall "INC_GRP" inclusive_lowprob "INC_GRP" ///
           hostile_undocu "HOS_GRP" hostile_highprob "HOS_GRP" hostile_highrecall "HOS_GRP" hostile_lowprob "HOS_GRP") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(INC_GRP "`inc_label'" HOS_GRP "`hos_label'" inclusive_fb "`inc_fb_label'" hostile_fb "`hos_fb_label'") ///
    order(INC_GRP HOS_GRP inclusive_fb hostile_fb) ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("Binned Policy Regime Effect on Log Adjusted Earnings") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("\noalign{\smallskip}\multicolumn{5}{p{14cm}}{\footnotesize Notes: `table_notes'}")

di "All Binned Regime tables completed successfully!"
