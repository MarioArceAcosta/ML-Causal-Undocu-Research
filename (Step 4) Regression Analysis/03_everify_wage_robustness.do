********************************************************************************
* 03_everify_wage_robustness.do
* Wage-only robustness checks
*
* Paper-facing robustness tables:
*   1. Never-treated-only controls (all four undocumented definitions)
*   2. Constructed stack-balancing weights instead of raw ACS pweights (all four definitions)
*
* Reference-only block retained:
*   - fully symmetric strict exclusion specification
*     (not for paper; sample collapses too much)
********************************************************************************
do "Code/(Step 4) Regression Analysis/00_everify_setup.do"

********************************************************************************
* 1. NEVER-TREATED-ONLY CONTROLS
* Uses raw ACS pweights, matching the updated main specification.
********************************************************************************
use "Data/everify_stack_never.dta", clear

foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    local group_covs ""
    foreach v of global demo_covars {
        local group_covs "`group_covs' c.`v'#i.`g'"
    }
    foreach p of global policy_covars {
        local group_covs "`group_covs' ib2.`p'#i.`g'"
    }
    local group_covs "`group_covs' i.degfield_broader#i.`g'"
    global int_`g' `group_covs'
}

local note1_never "Standard errors [in brackets] are clustered at the state level. This specification restricts the" 
local note2_never "control pool to never-treated states only. All columns use raw ACS person weights (perwt)," 
local note3_never "matching the main specification."

reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader $int_undocu ///
    [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store never_logical

reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob ///
    [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store never_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall ///
    [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store never_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob ///
    [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store never_lowprob

esttab never_logical never_highprob never_highrecall never_lowprob using "Output/Tables/wage_everify_never_treated.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("E-Verify Robustness: Never-Treated Controls Only (Log Earnings)") ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `note1_never'" " `note2_never'" " `note3_never'")

********************************************************************************
* 2. CONSTRUCTED STACK-BALANCING WEIGHTS
* Same baseline clean-control sample, but use the constructed balancing weights
* instead of raw ACS pweights.
********************************************************************************
use "Data/everify_stack_baseline.dta", clear

foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    local group_covs ""
    foreach v of global demo_covars {
        local group_covs "`group_covs' c.`v'#i.`g'"
    }
    foreach p of global policy_covars {
        local group_covs "`group_covs' ib2.`p'#i.`g'"
    }
    local group_covs "`group_covs' i.degfield_broader#i.`g'"
    global int_`g' `group_covs'
}

local note1_bal "Standard errors [in brackets] are clustered at the state level. This specification uses the" 
local note2_bal "constructed stack-balancing weights instead of raw ACS person weights."

reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader $int_undocu ///
    [pweight=norm_w_undocu], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store bal_logical

reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob ///
    [pweight=norm_w_gbm_high_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store bal_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall ///
    [pweight=norm_w_gbm_high_recall], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store bal_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob ///
    [pweight=norm_w_gbm_low_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store bal_lowprob

esttab bal_logical bal_highprob bal_highrecall bal_lowprob using "Output/Tables/wage_everify_balanced_weights.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("E-Verify Robustness: Constructed Stack-Balancing Weights (Log Earnings)") ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `note1_bal'" " `note2_bal'")

********************************************************************************
* 3. REFERENCE ONLY: FULLY SYMMETRIC STRICT-EXCLUSION SPECIFICATION
* NOT FOR PAPER. Sample collapses too much.
********************************************************************************
use "Data/everify_stack_strict.dta", clear

foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    local group_covs ""
    foreach v of global demo_covars {
        local group_covs "`group_covs' c.`v'#i.`g'"
    }
    foreach p of global policy_covars {
        local group_covs "`group_covs' ib2.`p'#i.`g'"
    }
    local group_covs "`group_covs' i.degfield_broader#i.`g'"
    global int_`g' `group_covs'
}

local note1_strict "Standard errors [in brackets] are clustered at the state level. This fully symmetric strict" 
local note2_strict "specification excludes treated states and control-state windows whenever any selected" 
local note3_strict "immigration-policy control shifts within the event window. This model is retained for" 
local note4_strict "reference only and is not intended for the paper because the sample collapses too sharply."

reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader $int_undocu ///
    [pweight=norm_w_undocu], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store strict_logical

reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob ///
    [pweight=norm_w_gbm_high_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store strict_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall ///
    [pweight=norm_w_gbm_high_recall], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store strict_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob ///
    [pweight=norm_w_gbm_low_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store strict_lowprob

esttab strict_logical strict_highprob strict_highrecall strict_lowprob using "Output/Tables/wage_everify_strict_exclusion_reference_only.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("E-Verify Robustness: Fully Symmetric Strict Exclusions (Reference Only)") ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `note1_strict'" " `note2_strict'" " `note3_strict'" " `note4_strict'")
