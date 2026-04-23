********************************************************************************
* 02_everify_wage_main.do
* Main wage results and wage event study
********************************************************************************
do "Code/(Step 4) Regression Analysis/00_everify_setup.do"
use "Data/everify_stack_baseline.dta", clear

* Build interaction-control macros after loading the stacked dataset
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

local table_notes "Standard errors [in brackets] are clustered at the state level. The row 'Undocumented' refers to the specific sub-population identified in the column header. Alabama and Indiana are excluded from treated-event cohorts because restrictive E-Verify adoption is bundled with omnibus restrictions in their event year. Control states are defined using clean E-Verify timing only: never-treated and not-yet-treated states may serve as controls, but already-treated states and states treated within the stack window may not. Other IPC policies enter flexibly through group-specific policy interactions. The main specification uses raw ACS person weights (perwt)."

reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store wage_logical

reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store wage_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store wage_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) ///
    vce(cluster statefip) poolsize(1)
estadd ysumm
est store wage_lowprob

esttab wage_logical wage_highprob wage_highrecall wage_lowprob using "Output/Tables/wage_everify_main.tex", replace ///
    label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "$triple_label" trend_post_fb "$fb_label") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("Impact of E-Verify Mandates on Log Adjusted Earnings") ///
    b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes( ///
    "Standard errors [in brackets] are clustered at the state level. The row `Undocumented' refers to" ///
    "the specific sub-population identified in the column header. Alabama and Indiana are excluded" ///
    "because restrictive E-Verify is bundled with omnibus restrictions in their event year. Control" ///
    "states are defined using clean E-Verify timing only: never-treated and not-yet-treated states" ///
    "may serve as controls, but already-treated states and states treated within the stack window may" ///
    "not. Other IPC policies enter flexibly through group-specific policy interactions. All models" ///
    "include stack-specific fixed effects." ///
)

* Wage event study
reghdfe ln_adj es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
    es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_undocu [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) ///
    vce(cluster statefip) poolsize(1)
coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(2.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical") ytitle("Log wage") name(g_wage_logical, replace)

reghdfe ln_adj es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
    es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_prob [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) ///
    vce(cluster statefip) poolsize(1)
coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(2.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("High Prob") ytitle("Log wage") name(g_wage_highprob, replace)

reghdfe ln_adj es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
    es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_recall [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) ///
    vce(cluster statefip) poolsize(1)
coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(2.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("High Recall") ytitle("Log wage") name(g_wage_highrecall, replace)

reghdfe ln_adj es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
    es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_low_prob [pweight=perwt], ///
    absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) ///
    vce(cluster statefip) poolsize(1)
coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(2.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("Low Prob") ytitle("Log wage") name(g_wage_lowprob, replace)

graph combine g_wage_logical g_wage_highprob g_wage_highrecall g_wage_lowprob, ///
    rows(2) cols(2) iscale(.8) imargin(tiny) ycommon commonscheme scheme(s1color) ///
    note("Ref year: -1. Panels: Logical, High Prob, High Recall, Low Prob.")
graph export "Output/Figures/event_everify_wage.png", replace
