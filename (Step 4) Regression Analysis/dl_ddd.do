********************************************************************************
* MASTER SCRIPT: IMPACT OF DRIVER'S LICENSE ACCESS ON LABOR MARKET MATCHING
* DESIGN: STACKED TRIPLE-DIFFERENCE (DDD) + FULL EVENT STUDIES
* UPDATES: BALANCED [-3, +3] WINDOW, WEIGHT BALANCING, CLEAN DL RESTRICTIONS
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

* Covariates and interactions
global covars age hisp asian black male bpl_foreign immig_by_ten nonfluent yrsed 

* --- 2. PREPARE TREATMENT LOOKUP ---
use "Data/EO_Final.dta", clear

********************************************************************************
* SEQUENTIAL CONFOUNDER RULE
********************************************************************************
* Rhode Island dropped for E-Verify repeal instability
drop if state == "Rhode Island"

* Identify the DL treatment variable
gen is_inc = (drivers_license > 0)

preserve
    * 1. PREVENT CONFOUNDED STATES FROM BECOMING TREATMENT COHORTS
    drop if inlist(state, "California", "Connecticut", "DC", "New Jersey", "New Mexico", "New York", "Oregon")
    
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

tempfile clean_master
save `clean_master', replace

* --- 3. CREATE THE STACKED DATASET ---
tempfile stacked_master
local stack_count = 0
levelsof treat_year, local(cohorts)

foreach c of local cohorts {
    preserve
        use `clean_master', clear
        
        gen ref_year = year - `c'
        
        * WINDOW: BALANCED AT [-3, +3]
        keep if ref_year >= -3 & ref_year <= 3
        
        gen in_cohort = (treat_year == `c')
        
        * ----------------------------------------------------------------------
        * PRINCIPLED EXCLUSION RESTRICTION (STRICT CLEAN CONTROL GROUP)
        * ----------------------------------------------------------------------
        egen max_inc_in_window = max(is_inc), by(statefip)
        
        gen core_labor_shift = 0
        sort statefip year
        foreach p in e_verify professional_licensure cooperation_federal_immigration omnibus {
            by statefip: replace core_labor_shift = 1 if `p' != `p'[_n-1] & _n > 1
        }
        
        egen max_labor_shift_in_window = max(core_labor_shift), by(statefip)
        gen pot_control = (max_inc_in_window == 0) & (max_labor_shift_in_window == 0)
        
        keep if in_cohort == 1 | pot_control == 1
        quietly count if in_cohort == 1
        
        if r(N) > 0 {
            local stack_count = `stack_count' + 1
            gen stack_id = `stack_count'
            
            * NORMALIZED WEIGHT BALANCING WITHIN STACK
            foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
                gen norm_w_`g' = perwt
                su norm_w_`g' if `g' == 1, meanonly
                local t_mass = r(sum)
                su norm_w_`g' if `g' == 0, meanonly
                local c_mass = r(sum)
                replace norm_w_`g' = norm_w_`g' * (`t_mass' / `c_mass') if `g' == 0
            }
            
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

* Foreign-Born Trend Dummies
forvalues r = -3/3 {
    local s = cond(`r' < 0, "n" + string(abs(`r')), "p" + string(`r'))
    gen es_fb_`s' = (ref_year == `r') * in_cohort * bpl_foreign
}

* SATURATED COVARIATE INTERACTIONS
foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    local cov_`g' ""
    foreach v of global covars {
        local cov_`g' "`cov_`g'' c.`v'#i.`g'"
    }
    local cov_`g' "`cov_`g'' i.degfield_broader#i.`g'"
    global int_`g' `cov_`g''
}

********************************************************************************
* DDD REGRESSIONS: 3 OUTCOMES (EXPLICIT)
********************************************************************************

local triple_label "Drivers License $\times$ Post $\times$ Undocumented"
local fb_label      "Drivers License $\times$ Post $\times$ Foreign-Born (All)"
local table_notes "Standard errors [in brackets] are clustered at the state level. Models use a clean sample of standalone DL access policies, dropping confounding states from the treatment cohort. All models include stack-specific fixed effects."

* --- TABLE 1: HORIZONTAL UNDERMATCH ---
reghdfe hundermatched did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
estadd ysumm
est store h_logical

reghdfe hundermatched did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
estadd ysumm
est store h_highprob

reghdfe hundermatched did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
estadd ysumm
est store h_highrecall

reghdfe hundermatched did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
estadd ysumm
est store h_lowprob

esttab h_logical h_highprob h_highrecall h_lowprob using "Output/Tables/hundermatch_dl_ddd.tex", replace label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "`triple_label'" trend_post_fb "`fb_label'") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("DL Access and Horizontal Undermatch") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `table_notes'")

* --- TABLE 2: VERTICAL MISMATCH ---
reghdfe vmismatched did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
estadd ysumm
est store v_logical

reghdfe vmismatched did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
estadd ysumm
est store v_highprob

reghdfe vmismatched did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
estadd ysumm
est store v_highrecall

reghdfe vmismatched did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
estadd ysumm
est store v_lowprob

esttab v_logical v_highprob v_highrecall v_lowprob using "Output/Tables/vmismatch_dl_ddd.tex", replace label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "`triple_label'" trend_post_fb "`fb_label'") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("DL Access and Vertical Mismatch") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `table_notes'")

* --- TABLE 3: LOG EARNINGS ---
reghdfe ln_adj did_undocu trend_post_fb $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
estadd ysumm
est store l_logical

reghdfe ln_adj did_highprob trend_post_fb $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
estadd ysumm
est store l_highprob

reghdfe ln_adj did_highrecall trend_post_fb $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
estadd ysumm
est store l_highrecall

reghdfe ln_adj did_lowprob trend_post_fb $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
estadd ysumm
est store l_lowprob

esttab l_logical l_highprob l_highrecall l_lowprob using "Output/Tables/wage_dl_ddd.tex", replace label booktabs drop($covars _cons *#* *degfield_broader*) ///
    rename(did_undocu "TRIPLE" did_highprob "TRIPLE" did_highrecall "TRIPLE" did_lowprob "TRIPLE") ///
    mlabel("Logical" "High Prob" "High Recall" "Low Prob") ///
    varlabels(TRIPLE "`triple_label'" trend_post_fb "`fb_label'") ///
    stats(ymean r2 N, labels("Mean DepVar" "R-squared" "N") fmt(%9.3f %9.3f %9.0fc)) ///
    title("DL Access and Log Earnings") b(3) se(3) brackets star(* .1 ** .05 *** .01) ///
    addnotes("Notes: `table_notes'")


********************************************************************************
* EVENT STUDIES (EXPLICIT)
********************************************************************************

* --- OUTCOME: EARNINGS (L) ---
reghdfe ln_adj es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("Log Wage") name(g_L_undocu, replace)

reghdfe ln_adj es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("Log Wage") name(g_L_highprob, replace)

reghdfe ln_adj es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("Log Wage") name(g_L_highrecall, replace)

reghdfe ln_adj es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob") ytitle("Log Wage") name(g_L_lowprob, replace)

* --- OUTCOME: HORIZONTAL UNDERMATCH (H) ---
reghdfe hundermatched es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("H Undermatch") name(g_H_undocu, replace)

reghdfe hundermatched es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("H Undermatch") name(g_H_highprob, replace)

reghdfe hundermatched es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("H Undermatch") name(g_H_highrecall, replace)

reghdfe hundermatched es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob") ytitle("H Undermatch") name(g_H_lowprob, replace)

* --- OUTCOME: VERTICAL MISMATCH (V) ---
reghdfe vmismatched es_undocu_n3 es_undocu_n2 o.es_undocu_n1 es_undocu_p0 es_undocu_p1 es_undocu_p2 es_undocu_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_undocu [pweight=norm_w_undocu], absorb(stack_id#statefip#year stack_id#statefip#undocu stack_id#year#undocu) vce(cluster statefip) compact
coefplot, keep(es_undocu_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_undocu_n3="-3" es_undocu_n2="-2" es_undocu_n1="-1" es_undocu_p0="0" es_undocu_p1="1" es_undocu_p2="2" es_undocu_p3="3") ///
    title("Logical Edits") ytitle("VMismatch") name(g_V_undocu, replace)

reghdfe vmismatched es_highprob_n3 es_highprob_n2 o.es_highprob_n1 es_highprob_p0 es_highprob_p1 es_highprob_p2 es_highprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_prob [pweight=norm_w_gbm_high_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_prob stack_id#year#gbm_high_prob) vce(cluster statefip) compact
coefplot, keep(es_highprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highprob_n3="-3" es_highprob_n2="-2" es_highprob_n1="-1" es_highprob_p0="0" es_highprob_p1="1" es_highprob_p2="2" es_highprob_p3="3") ///
    title("GBM High Prob") ytitle("VMismatch") name(g_V_highprob, replace)

reghdfe vmismatched es_highrecall_n3 es_highrecall_n2 o.es_highrecall_n1 es_highrecall_p0 es_highrecall_p1 es_highrecall_p2 es_highrecall_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_high_recall [pweight=norm_w_gbm_high_recall], absorb(stack_id#statefip#year stack_id#statefip#gbm_high_recall stack_id#year#gbm_high_recall) vce(cluster statefip) compact
coefplot, keep(es_highrecall_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_highrecall_n3="-3" es_highrecall_n2="-2" es_highrecall_n1="-1" es_highrecall_p0="0" es_highrecall_p1="1" es_highrecall_p2="2" es_highrecall_p3="3") ///
    title("GBM High Recall") ytitle("VMismatch") name(g_V_highrecall, replace)

reghdfe vmismatched es_lowprob_n3 es_lowprob_n2 o.es_lowprob_n1 es_lowprob_p0 es_lowprob_p1 es_lowprob_p2 es_lowprob_p3 ///
    es_fb_n3 es_fb_n2 o.es_fb_n1 es_fb_p0 es_fb_p1 es_fb_p2 es_fb_p3 ///
    $covars i.degfield_broader $int_gbm_low_prob [pweight=norm_w_gbm_low_prob], absorb(stack_id#statefip#year stack_id#statefip#gbm_low_prob stack_id#year#gbm_low_prob) vce(cluster statefip) compact
coefplot, keep(es_lowprob_*) omitted vertical yline(0) xline(3.5, lpattern(dash)) legend(off) ///
    coeflabels(es_lowprob_n3="-3" es_lowprob_n2="-2" es_lowprob_n1="-1" es_lowprob_p0="0" es_lowprob_p1="1" es_lowprob_p2="2" es_lowprob_p3="3") ///
    title("GBM Low Prob") ytitle("VMismatch") name(g_V_lowprob, replace)

* COMBINE & EXPORT
graph combine g_L_undocu g_L_highprob g_L_highrecall g_L_lowprob, rows(2) cols(2) iscale(.8) imargin(tiny) ycommon commonscheme scheme(s1color) title("Event Study: Log Adjusted Earnings") subtitle("Impact of DL Access by Group")
graph export "Output/Figures/event_dl_earnings_balanced.png", replace

graph combine g_H_undocu g_H_highprob g_H_highrecall g_H_lowprob, rows(2) cols(2) iscale(.8) imargin(tiny) ycommon commonscheme scheme(s1color) title("Event Study: Horiz. Undermatch") subtitle("Impact of DL Access by Group")
graph export "Output/Figures/event_dl_Hunder_balanced.png", replace

graph combine g_V_undocu g_V_highprob g_V_highrecall g_V_lowprob, rows(2) cols(2) iscale(.8) imargin(tiny) ycommon commonscheme scheme(s1color) title("Event Study: Vertical Mismatch") subtitle("Impact of DL Access by Group")
graph export "Output/Figures/event_dl_Vmismatch_balanced.png", replace
