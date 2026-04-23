clear matrix
clear mata
clear
set more off
set scheme s1color

set maxvar 30000
set matsize 11000
set segmentsize 2g
set memory 8g
mata: mata set matafavor speed


// Set paths/directories here

*global drive "/Users/verosovero/Library/CloudStorage/GoogleDrive-vsovero@ucr.edu" //Sovero drive
global drive "G:\Shared drives\Undocu Research" // Mario drive

*global main "$drive/Shared drives/Undocu Research"
*cd "$main"
cd "$drive"


use "Data\EO_Final", clear


global covars hisp asian black male gov_worker bpl_foreign immig_by_ten nonfluent yrsed  metropolitan medicaid 
global undocu_vars undocu gbm_high_prob gbm_high_recall gbm_low_prob 

********************************************************************************
***************** Undocumented Individual Mismatch regressions *****************
********************************************************************************
// Vertical Mismatch 

eststo clear
set more off

***Logical edits V. mismatch model***
reghdfe vmismatched hundermatched hovermatched undocu   $covars  [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo logical_vmismatch

reghdfe vmismatched hundermatched hovermatched gbm_high_prob   $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmhigh_vmismatch

reghdfe vmismatched hundermatched hovermatched gbm_high_recall  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmrecall_vmismatch

reghdfe vmismatched hundermatched hovermatched gbm_low_prob  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmlow_vmismatch

esttab logical_vmismatch gbmhigh_vmismatch gbmrecall_vmismatch gbmlow_vmismatch ///
    using "Output/Tables/vmismatch_regressions_ml.tex", replace ///
    label booktabs ///
    drop($covars _cons) ///
    rename(hundermatched "Horizontal Undermatch" ///
           hovermatched "Horizontal Overmatch" ///
           undocu "Undocumented" ///
           gbm_high_prob "Undocumented" ///
           gbm_high_recall "Undocumented" ///
           gbm_low_prob "Undocumented") ///
    stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Regressions of Undocumented Status on Vertical Mismatch") ///
    mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01) ///
    note("Additional controls include:") ///
    addn("dummy age indicators, gender, Medicaid receipt, race/ethnicity, metropolitan residence," ///
         " government occupation, English-speaking fluency, foreign born, immigration by age 10," ///
         " broad degree category indicators, years of schooling, and state×year interaction fixed effects." ///
         " Robust standard errors are clustered by state.")


	

// Horizontal Undermatch 
clear matrix
set more off
eststo clear

reghdfe hundermatched vmismatched  undocu   $covars  [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo logical_hunder

reghdfe hundermatched vmismatched  gbm_high_prob   $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmhigh_hunder

reghdfe hundermatched vmismatched  gbm_high_recall  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmrecall_hunder

reghdfe hundermatched vmismatched  gbm_low_prob  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmlow_hunder

esttab logical_hunder gbmhigh_hunder gbmrecall_hunder gbmlow_hunder ///
    using "Output/Tables/hundermatch_regressions_ml.tex", replace ///
    label booktabs ///
     drop($covars _cons ) ///
    rename(hundermatched "Horizontal Undermatch" ///
           hovermatched "Horizontal Overmatch" ///
           undocu "Undocumented" ///
           gbm_high_prob "Undocumented" ///
           gbm_high_recall "Undocumented" ///
           gbm_low_prob "Undocumented") ///
    stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Regressions of Undocumented Status on Horizontal Undermatch") ///
    mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01) ///
    note("Additional controls include:") ///
    addn("dummy age indicators, gender, Medicaid receipt, race/ethnicity, metropolitan residence," ///
         " government occupation, English-speaking fluency, foreign born, immigration by age 10," ///
         " broad degree category indicators, years of schooling, and state×year interaction fixed effects." ///
         " Robust standard errors are clustered by state.")

	


**********************************************************************************	
****************Wage models with demographic columns/samples**************************
**************************************************************************************
clear matrix
set more off
eststo clear

reghdfe ln_adj vmismatched hundermatched hovermatched undocu   $covars  [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo logical_wage 

reghdfe ln_adj vmismatched hundermatched hovermatched gbm_high_prob   $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmhigh_wage 

reghdfe ln_adj vmismatched hundermatched hovermatched gbm_high_recall  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmrecall_wage

reghdfe ln_adj vmismatched hundermatched hovermatched gbm_low_prob  $covars    [pweight=perwt] , absorb(statefip##year age  degfield_broader) vce(cluster statefip)
estadd ysumm
eststo gbmlow_wage

esttab logical_wage gbmhigh_wage gbmrecall_wage gbmlow_wage ///
    using "Output/Tables/wage_regressions_ml.tex", replace ///
    label booktabs ///
      drop($covars _cons) ///
    rename(hundermatched "Horizontal Undermatch" ///
           hovermatched "Horizontal Overmatch" ///
           undocu "Undocumented" ///
           gbm_high_prob "Undocumented" ///
           gbm_high_recall "Undocumented" ///
           gbm_low_prob "Undocumented") ///
 stats(ymean r2 N, labels("Mean of Dep. Var." "R-squared" "N") fmt(%9.2f %9.2f %9.0fc)) ///
    title("Regressions of Undocumented Status on Log Wages") ///
    mlabel("Logical Edits" "High Prob" "High Recall" "Low Prob") ///
    r2(4) b(4) se(4) brackets star(* .1 ** .05 *** .01) ///
    note("Additional controls include:") ///
    addn("dummy age indicators, gender, Medicaid receipt, race/ethnicity, metropolitan residence," ///
         " government occupation, English-speaking fluency, foreign born, immigration by age 10," ///
         " broad degree category indicators, years of schooling, and state×year interaction fixed effects." ///
         " Robust standard errors are clustered by state.")

	
**Coefficient Plots****
/* 
*vertical mismatch
coefplot (logical_vmismatch, label(Logical Edits) ) (knn_vmismatch, label(KNN) ) (rf_vmismatch, label(Random Forest) ) ///
 ||, drop($covars hundermatched hovermatched )  xline(0)   ///
rename(elig_rf = "DACA-eligible" elig= "DACA-eligible" elig_knn= "DACA-eligible") ///
 xline(0) title("Vertical Mismatch")
  graph save elig_ipc_vmismatch, replace

 
 *horizontal undermatch
coefplot (logical_hunder, label(Logical Edits) ) (knn_hunder, label(KNN) ) (rf_hunder, label(Random Forest) ) ///
 ||, drop($covars vmismatched)  xline(0)   ///
rename(elig_rf = "DACA-eligible" elig= "DACA-eligible" elig_knn= "DACA-eligible") ///
 xline(0) title("Horizontal Undermatch")
   graph save elig_ipc_hunder, replace

 *wages
coefplot (logical_wage, label(Logical Edits) ) (knn_wage, label(KNN) ) (rf_wage, label(Random Forest)) ///
||, drop($covars vmismatched hundermatched hovermatched)  xline(0)   ///
rename(elig_rf = "DACA-eligible" elig= "DACA-eligible" elig_knn= "DACA-eligible") ///
 xline(0) title("Log Wage")
   graph save elig_ipc_wage, replace

*all together
coefplot (logical_vmismatch, label(Logical Edits) ) (knn_vmismatch, label(KNN) ) (rf_vmismatch, label(Random Forest) ), bylabel(Vertical Mismatch)  ///
||  (logical_hunder, label(Logical Edits) ) (knn_hunder, label(KNN) ) (rf_hunder, label(Random Forest) ), bylabel(Horizontal Undermatch) ///
||  (logical_wage, label(Logical Edits) ) (knn_wage, label(KNN) ) (rf_wage, label(Random Forest)), bylabel(Log Wage) ///
||, drop($covars vmismatched hundermatched hovermatched)  xline(0)  ///
rename(elig_rf = "DACA-eligible" elig= "DACA-eligible" elig_knn= "DACA-eligible") 
graph export elig_ipc_coeff.png, replace			
	
*/
	
