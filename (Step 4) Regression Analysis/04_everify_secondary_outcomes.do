********************************************************************************
* 04_everify_secondary_outcomes.do
* Secondary outcomes: mismatch and occupation-controlled wages
* Secondary-outcome tables retain all four undocumented definitions.
********************************************************************************
do "Code/(Step 4) Regression Analysis/00_everify_setup.do"
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


********************************************************************************
* HORIZONTAL MISMATCH
********************************************************************************
reghdfe hundermatched did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) poolsize(1)
estadd ysumm
est store h_logical

reghdfe hundermatched did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) poolsize(1)
estadd ysumm
est store h_highprob

reghdfe hundermatched did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) poolsize(1)
estadd ysumm
est store h_highrecall

reghdfe hundermatched did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) poolsize(1)
estadd ysumm
est store h_lowprob

esttab h_logical h_highprob h_highrecall h_lowprob using "Output/Tables/everify_horizontal_mismatch.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01)

********************************************************************************
* VERTICAL MISMATCH
********************************************************************************
reghdfe vmismatched did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) poolsize(1)
estadd ysumm
est store v_logical

reghdfe vmismatched did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) poolsize(1)
estadd ysumm
est store v_highprob

reghdfe vmismatched did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) poolsize(1)
estadd ysumm
est store v_highrecall

reghdfe vmismatched did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) poolsize(1)
estadd ysumm
est store v_lowprob

esttab v_logical v_highprob v_highrecall v_lowprob using "Output/Tables/everify_vertical_mismatch.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01)

********************************************************************************
* OCCUPATION-CONTROLLED WAGE CHECK
********************************************************************************

    reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader i.occ_category $int_undocu [pweight=norm_w_undocu], ///
        absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) poolsize(1)
    estadd ysumm
    est store wage_occ_logical

    reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader i.occ_category $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], ///
        absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) poolsize(1)
    estadd ysumm
    est store wage_occ_highprob

    reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader i.occ_category $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], ///
        absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) poolsize(1)
    estadd ysumm
    est store wage_occ_highrecall

    reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader i.occ_category $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], ///
        absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) poolsize(1)
    estadd ysumm
    est store wage_occ_lowprob

    esttab wage_occ_logical wage_occ_highprob wage_occ_highrecall wage_occ_lowprob using "Output/Tables/wage_everify_occ_controls.tex", replace ///
        label booktabs drop($covars _cons *#* *degfield_broader* *occ_category*) ///
        rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
        mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
        varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
        stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
        b(3) se(3) brackets star(* .1 ** .05 *** .01)

