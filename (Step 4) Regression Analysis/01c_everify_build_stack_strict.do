********************************************************************************
* 01c_everify_build_stack_strict.do
* Build cleaner-window strict stack:
* - treated cohorts exclude Alabama and Indiana
* - window is shortened to t-1 through t+2
* - treated states are excluded if any policy in $policy_covars shifts within
*   that state's own event window
* - controls must have no restrictive E-Verify and no shifts in the same policy set
*   within the event window
********************************************************************************
do "Code/(Step 4) Regression Analysis/00_everify_setup.do"

use "Data/EO_Final.dta", clear

capture confirm variable age_squared
if _rc != 0 {
    gen age_squared = age^2
}

capture confirm string variable secure_communities
if _rc == 0 {
    replace secure_communities = "0" if secure_communities == "NA" | trim(secure_communities) == ""
    destring secure_communities, replace
}
else {
    replace secure_communities = 0 if missing(secure_communities)
}

foreach p of global policy_covars {
    recode `p' (-1 = 1) (0 = 2) (1 = 3)
}

drop if state == "Rhode Island"
gen is_inc = (e_verify < 0)

preserve
    keep state statefip year is_inc $covars
    duplicates drop
    sort statefip year
    by statefip: gen switch = (is_inc == 1 & is_inc[_n-1] == 0) if _n > 1
    gen switch_yr = year if switch == 1
    by statefip: egen treat_year = min(switch_yr)

    * Symmetric treated-side screen under the shorter t-1 to t+2 window
    gen ref_year = year - treat_year
    gen in_window = ref_year >= -1 & ref_year <= 2 if treat_year < .

    gen any_policy_shift = 0
    foreach p of global policy_covars {
        by statefip: replace any_policy_shift = 1 if `p' != `p'[_n-1] & _n > 1
    }
    replace any_policy_shift = 0 if missing(any_policy_shift)

    gen shift_in_window = any_policy_shift if in_window == 1
    by statefip: egen max_shift_in_window = max(shift_in_window)

    * Alabama and Indiana are always excluded because E-Verify is bundled
    * with omnibus restrictions in their treatment year.
    drop if inlist(state, "Alabama", "Indiana")

    * Drop treated states with any full-policy-set shift in their own window
    drop if treat_year < . & max_shift_in_window == 1

    keep statefip treat_year
    duplicates drop
    save "Data/everify_treat_lookup_strict.dta", replace
restore

merge m:1 statefip using "Data/everify_treat_lookup_strict.dta", nogenerate

keep state statefip year perwt treat_year e_verify is_inc ///
     undocu gbm_high_prob gbm_high_recall gbm_low_prob bpl_foreign ///
     hundermatched vmismatched ln_adj ///
     degfield_broader occ_category classwkr classwkrd ///
     $covars

save "Data/everify_clean_master_strict.dta", replace

tempfile stack1 stack2 stack3 stack4

* 2010 cohort
use "Data/everify_clean_master_strict.dta", clear
gen ref_year = year - 2010
keep if ref_year >= -1 & ref_year <= 2
gen in_cohort = (treat_year == 2010)
egen max_inc_in_window = max(is_inc), by(statefip)
gen any_policy_shift = 0
sort statefip year
foreach p of global policy_covars {
    by statefip: replace any_policy_shift = 1 if `p' != `p'[_n-1] & _n > 1
}
replace any_policy_shift = 0 if missing(any_policy_shift)
egen max_shift_in_window = max(any_policy_shift), by(statefip)
gen pot_control = (max_inc_in_window == 0) & (max_shift_in_window == 0)
keep if in_cohort == 1 | pot_control == 1
gen stack_id = 1
foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    gen norm_w_`g' = perwt
    quietly summarize norm_w_`g' if `g' == 1, meanonly
    local t_mass = r(sum)
    quietly summarize norm_w_`g' if `g' == 0, meanonly
    local c_mass = r(sum)
    replace norm_w_`g' = norm_w_`g' * (`t_mass' / `c_mass') if `g' == 0 & `c_mass' > 0
}
save `stack1'

* 2011 cohort
use "Data/everify_clean_master_strict.dta", clear
gen ref_year = year - 2011
keep if ref_year >= -1 & ref_year <= 2
gen in_cohort = (treat_year == 2011)
egen max_inc_in_window = max(is_inc), by(statefip)
gen any_policy_shift = 0
sort statefip year
foreach p of global policy_covars {
    by statefip: replace any_policy_shift = 1 if `p' != `p'[_n-1] & _n > 1
}
replace any_policy_shift = 0 if missing(any_policy_shift)
egen max_shift_in_window = max(any_policy_shift), by(statefip)
gen pot_control = (max_inc_in_window == 0) & (max_shift_in_window == 0)
keep if in_cohort == 1 | pot_control == 1
gen stack_id = 2
foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    gen norm_w_`g' = perwt
    quietly summarize norm_w_`g' if `g' == 1, meanonly
    local t_mass = r(sum)
    quietly summarize norm_w_`g' if `g' == 0, meanonly
    local c_mass = r(sum)
    replace norm_w_`g' = norm_w_`g' * (`t_mass' / `c_mass') if `g' == 0 & `c_mass' > 0
}
save `stack2'

* 2012 cohort
use "Data/everify_clean_master_strict.dta", clear
gen ref_year = year - 2012
keep if ref_year >= -1 & ref_year <= 2
gen in_cohort = (treat_year == 2012)
egen max_inc_in_window = max(is_inc), by(statefip)
gen any_policy_shift = 0
sort statefip year
foreach p of global policy_covars {
    by statefip: replace any_policy_shift = 1 if `p' != `p'[_n-1] & _n > 1
}
replace any_policy_shift = 0 if missing(any_policy_shift)
egen max_shift_in_window = max(any_policy_shift), by(statefip)
gen pot_control = (max_inc_in_window == 0) & (max_shift_in_window == 0)
keep if in_cohort == 1 | pot_control == 1
gen stack_id = 3
foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    gen norm_w_`g' = perwt
    quietly summarize norm_w_`g' if `g' == 1, meanonly
    local t_mass = r(sum)
    quietly summarize norm_w_`g' if `g' == 0, meanonly
    local c_mass = r(sum)
    replace norm_w_`g' = norm_w_`g' * (`t_mass' / `c_mass') if `g' == 0 & `c_mass' > 0
}
save `stack3'

* 2015 cohort
use "Data/everify_clean_master_strict.dta", clear
gen ref_year = year - 2015
keep if ref_year >= -1 & ref_year <= 2
gen in_cohort = (treat_year == 2015)
egen max_inc_in_window = max(is_inc), by(statefip)
gen any_policy_shift = 0
sort statefip year
foreach p of global policy_covars {
    by statefip: replace any_policy_shift = 1 if `p' != `p'[_n-1] & _n > 1
}
replace any_policy_shift = 0 if missing(any_policy_shift)
egen max_shift_in_window = max(any_policy_shift), by(statefip)
gen pot_control = (max_inc_in_window == 0) & (max_shift_in_window == 0)
keep if in_cohort == 1 | pot_control == 1
gen stack_id = 4
foreach g in undocu gbm_high_prob gbm_high_recall gbm_low_prob {
    gen norm_w_`g' = perwt
    quietly summarize norm_w_`g' if `g' == 1, meanonly
    local t_mass = r(sum)
    quietly summarize norm_w_`g' if `g' == 0, meanonly
    local c_mass = r(sum)
    replace norm_w_`g' = norm_w_`g' * (`t_mass' / `c_mass') if `g' == 0 & `c_mass' > 0
}
save `stack4'

use `stack1', clear
append using `stack2'
append using `stack3'
append using `stack4'

gen post = (ref_year >= 0)
gen did_undocu      = in_cohort * post * undocu
gen did_highprob    = in_cohort * post * gbm_high_prob
gen did_highrecall  = in_cohort * post * gbm_high_recall
gen did_lowprob     = in_cohort * post * gbm_low_prob
gen trend_post_fb   = in_cohort * post * bpl_foreign

save "Data/everify_stack_strict.dta", replace
