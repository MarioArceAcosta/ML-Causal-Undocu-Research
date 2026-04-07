********************************************************************************
* MASTER SCRIPT: IMPACT OF DRIVER'S LICENSES ON LABOR MARKET MATCHING
* DESIGN: STACKED TRIPLE-DIFFERENCE (DDD) + FULL EVENT STUDIES
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

global covars hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed metropolitan medicaid

* --- 2. PREPARE TREATMENT LOOKUP ---
use "Data/EO_Final.dta", clear
* Removed NY and WI drops - they are valid for Driver's Licenses!
gen is_inc = (drivers_license > 0)

preserve
    keep statefip year is_inc
    duplicates drop
    sort statefip year
    by statefip: gen switch = (is_inc == 1 & is_inc[_n-1] == 0) if _n > 1
    gen switch_yr = year if switch == 1
    collapse (min) treat_year = switch_yr, by(statefip)
    tempfile treat_lookup
    save `treat_lookup'
restore

merge m:1 statefip using `treat_lookup', nogenerate

* --- 3. CREATE THE STACKED DATASET ---
tempfile stacked_master
local stack_count = 0
levelsof treat_year, local(cohorts)

foreach c of local cohorts {
    preserve
        use "Data/EO_Final.dta", clear
        * Removed NY and WI drops
        gen is_inc = (drivers_license > 0)
        
        merge m:1 statefip using `treat_lookup', nogenerate
        gen ref_year = year - `c'
        keep if ref_year >= -3 & ref_year <= 3
        gen in_cohort = (treat_year == `c')
        egen max_inc_in_window = max(is_inc), by(statefip)
        gen pot_control = (max_inc_in_window == 0)
        keep if in_cohort == 1 | pot_control == 1
        quietly count if in_cohort == 1
        if r(N) > 0 {
            local stack_count = `stack_count' + 1
            gen stack_id = `stack_count'
            tempfile stack`stack_count'
            save `stack`stack_count''
        }
    restore
}

use `stack1', clear
forvalues i = 2/`stack_count' {
    append using `stack`i''
}

* --- 4. VARIABLE CONSTRUCTION ---
cap drop post
gen post = (ref_year >= 0)


* DDD Interactions
gen did_undocu      = in_cohort * post * undocu
gen did_highprob    = in_cohort * post * gbm_high_prob
gen did_highrecall  = in_cohort * post * gbm_high_recall
gen did_lowprob     = in_cohort * post * gbm_low_prob
gen trend_post_fb   = in_cohort * post * bpl_foreign

* Event Study Dummies (Reference Year = -1)
foreach g in undocu highprob highrecall lowprob {
    local v = "`g'"
    if "`g'" == "highprob"   local v "gbm_high_prob"
    if "`g'" == "highrecall" local v "gbm_high_recall"
    if "`g'" == "lowprob"    local v "gbm_low_prob"

    foreach t in n3 n2 n1 p0 p1 p2 p3 {
        local r = subinstr("`t'", "n", "-", 1)
        local r = subinstr("`r'", "p", "", 1)
        gen es_`g'_`t' = (ref_year == `r') * in_cohort * `v'
    }
}

* Foreign-Born Trend Dummies (Always included in event studies)
forvalues r = -3/3 {
    local s = cond(`r' < 0, "n" + string(abs(`r')), "p" + string(`r'))
    gen es_fb_`s' = (ref_year == `r') * in_cohort * bpl_foreign
}


********************************************************************************
* DDD REGRESSIONS: 3 OUTCOMES (4x3)
********************************************************************************

* --- TABLE 1: HORIZONTAL UNDERMATCH (HUNDERMATCHED) ---
reghdfe hundermatched did_undocu trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)
estadd ysumm
est store h_logical

reghdfe hundermatched did_highprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store h_highprob

reghdfe hundermatched did_highrecall trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)
estadd ysumm
est store h_highrecall

reghdfe hundermatched did_lowprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store h_lowprob

esttab h_logical h_highprob h_highrecall h_lowprob using "Output/Tables/hundermatch_dl_ddd_regressions.tex", replace label booktabs drop($covars _cons) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
         mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "In\_Cohort $\times$ Post $\times$ Undocu" trend_post_fb "In\_Cohort $\times$ Post $\times$ Foreign-Born") ///
    stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Impact of Driver's Licenses on Horizontal Undermatch") r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01)

* --- TABLE 2: VERTICAL UNDERMATCH (VMISMATCHED) ---
reghdfe vmismatched did_undocu trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)
estadd ysumm
est store v_logical

reghdfe vmismatched did_highprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store v_highprob

reghdfe vmismatched did_highrecall trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)
estadd ysumm
est store v_highrecall

reghdfe vmismatched did_lowprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store v_lowprob

esttab v_logical v_highprob v_highrecall v_lowprob using "Output/Tables/vmismatched_dl_ddd_regressions.tex", replace label booktabs drop($covars _cons) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
         mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "In\_Cohort $\times$ Post $\times$ Undocu" trend_post_fb "In\_Cohort $\times$ Post $\times$ Foreign-Born") ///
    stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Impact of Driver's Licenses on Vertical Undermatch") r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01)

* --- TABLE 3: LOG EARNINGS (LN_ADJ) ---
reghdfe ln_adj did_undocu trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)
estadd ysumm
est store l_logical

reghdfe ln_adj did_highprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store l_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)
estadd ysumm
est store l_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)
estadd ysumm
est store l_lowprob

esttab l_logical l_highprob l_highrecall l_lowprob using "Output/Tables/wage_dl_ddd_regressions.tex", replace label booktabs drop($covars _cons) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
     mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "In\_Cohort $\times$ Post $\times$ Undocu" trend_post_fb "In\_Cohort $\times$ Post $\times$ Foreign-Born") ///
    stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Impact of Driver's Licenses on Log Adjusted Earnings") r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01)


********************************************************************************
* EVENT STUDIES
********************************************************************************

* --- OUTCOME: HORIZONTAL ---

* 1. Logical Edits
reghdfe hundermatched es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
                      es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                      $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)

coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("H Undermatch") note("") xlabel(, labsize(small)) name(g_H_undocu, replace)

* 2. High Prob
reghdfe hundermatched es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
                      es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                      $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("H Undermatch") note("") xlabel(, labsize(small)) name(g_H_highprob, replace)

* 3. High Recall
reghdfe hundermatched es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
                      es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                      $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("H Undermatch") note("") xlabel(, labsize(small)) name(g_H_highrecall, replace)

* 4. Low Prob
reghdfe hundermatched es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
                      es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                      $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob ") ytitle("H Undermatch") note("") xlabel(, labsize(small)) name(g_H_lowprob, replace)


* --- OUTCOME: VERTICAL ---

* 1. Logical Edits
reghdfe vmismatched es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
                    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                    $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)

coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("VMismatch") note("") xlabel(, labsize(small)) name(g_V_undocu, replace)

* 2. High Prob
reghdfe vmismatched es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
                    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                    $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("VMismatch") note("") xlabel(, labsize(small)) name(g_V_highprob, replace)

* 3. High Recall
reghdfe vmismatched es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
                    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                    $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("VMismatch") note("") xlabel(, labsize(small)) name(g_V_highrecall, replace)

* 4. Low Prob
reghdfe vmismatched es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
                    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
                    $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob") ytitle("VMismatch") note("") xlabel(, labsize(small)) name(g_V_lowprob, replace)


* --- OUTCOME: EARNINGS ---

* 1. Logical Edits
reghdfe ln_adj es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
               es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
               $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu age degfield_broader) vce(cluster statefip)

coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("Log Wage") note("") xlabel(, labsize(small)) name(g_L_undocu, replace)

* 2. High Prob
reghdfe ln_adj es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
               es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
               $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("Log Wage") note("") xlabel(, labsize(small)) name(g_L_highprob, replace)

* 3. High Recall
reghdfe ln_adj es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
               es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
               $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall age degfield_broader) vce(cluster statefip)

coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("Log Wage") note("") xlabel(, labsize(small)) name(g_L_highrecall, replace)

* 4. Low Prob
reghdfe ln_adj es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
               es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
               $covars [pweight=perwt], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob age degfield_broader) vce(cluster statefip)

coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob") ytitle("Log Wage") note("") xlabel(, labsize(small)) name(g_L_lowprob, replace)

********************************************************************************
* STEP 2: COMBINE 
********************************************************************************

graph combine g_L_undocu g_L_highprob g_L_highrecall g_L_lowprob, ///
    rows(2) cols(2) iscale(.8) ///
    imargin(tiny) ///
    ycommon ///
    commonscheme scheme(s1color) ///
    title("Event Study: Log Adjusted Earnings") ///
    subtitle("Impact of Driver's Licenses by Group") ///
    note("Ref year: -1. Panels: Logical, High Prob, High Recall, Low Prob.")

graph export "Output/Figures/event_dl_earnings.png", replace

graph combine g_H_undocu g_H_highprob g_H_highrecall g_H_lowprob, ///
    rows(2) cols(2) iscale(.8) ///
    imargin(tiny) ///
    ycommon ///
    commonscheme scheme(s1color) ///
    title("Event Study: Horiz. Undermatch") ///
    subtitle("Impact of Driver's Licenses by Group") ///
    note("Ref year: -1. Panels: Logical, High Prob, High Recall, Low Prob.")

graph export "Output/Figures/event_dl_Hunder.png", replace

graph combine g_V_undocu g_V_highprob g_V_highrecall g_V_lowprob, ///
    rows(2) cols(2) iscale(.8) ///
    imargin(tiny) ///
    ycommon ///
    commonscheme scheme(s1color) ///
    title("Event Study: Vertical Mismatch") ///
    subtitle("Impact of Driver's Licenses by Group") ///
    note("Ref year: -1. Panels: Logical, High Prob, High Recall, Low Prob.")

graph export "Output/Figures/event_dl_Vmismatch.png", replace
