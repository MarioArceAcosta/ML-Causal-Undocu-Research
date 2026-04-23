*** SET DIRECTORIES 
global data "G:/Shared drives/Undocu Research/Data"			// Set your data file path here
global dofiles "G:/Shared drives/Undocu Research/Code"		// Set your do file path here	

*create mismatch variable
*save full dataset

*keep undocu (the machine learning sample)
*save machine learning dataset


cd "$data"
use "EO_B.dta", clear

drop if degfield==9999
***********************************************
*******Additional Variable Creation************
***********************************************
sort occ adj_hourly

** STRICT HORIZONTAL MATCH (Actual degree match - used to calculate true baseline wages)
gen strict_hmatched = 1 if (degfield==namode1_deg | degfield==namode2_deg)
replace strict_hmatched = 0 if (degfield!=namode1_deg & degfield!=namode2_deg)

** HORIZONTALLY MATCHED identifier (Includes Li & Lu 15% rule for general occupations)
gen hmatched = 1 if strict_hmatched == 1 | general_occ == 1
replace hmatched = 0 if strict_hmatched == 0 & general_occ == 0

** VERTICALLY MATCHED identifier (dummy variable)
gen vmatched_att = edu_att==mode_att
gen vmatched_yrs =yrsed==med_yrs_by_occ

*VERTICAL MISMATCH (YRS) difference and identifier, + means overmatched, -means undermatched
gen vmismatched_yrs= yrsed-med_yrs_by_occ
gen vmismatched_att = edu_att!=mode_att


*COUNTS AND PROPORTIONS of people per occupation and Undocu-likely by occ
egen occ_count=count(occ), by(occ)
egen deg_count=count(degfield), by(degfield)

**Create count of people who are horizontally matched and proportion, as well as those with college degree
egen hcount=sum(hmatched), by(occ)
by occ, sort: gen hproportion = hcount/occ_count
gen hmproportion=1-hproportion

egen hcount_deg=sum(hmatched), by(degfield)
by degfield, sort: gen hproportion_deg = hcount_deg/deg_count
gen hmproportion_deg=1-hproportion_deg

**Create count of vertically matched people and proportion
egen vcount=sum(vmismatched_att), by(occ)
by occ, sort: gen vproportion = vcount/occ_count

egen vmean_occ_yrs= mean(vmismatched_yrs), by(occ)
egen vmean_deg_yrs= mean(vmismatched_yrs), by(degfield)

*Generates needed wage but only attaches to strict_hmatched observations to avoid general occ dilution
sort occ
by occ: egen med_wage_hmatched_by_occ_temp = median(adj_hourly) if strict_hmatched==1
*Next line of code extends the med_wage to other observations with the same occ
egen hmatched_med_wage_by_occ = mean(med_wage_hmatched_by_occ_temp), by (occ)
drop med_wage_hmatched_by_occ_temp

**Same hmatched median wage but by degfield (using STRICT matches to establish professional baseline)
sort degfield
by degfield: egen med_wage_hmatched_by_degfield = median(adj_hourly) if strict_hmatched==1
*Next line of code extends the med_wage to other observations with the same degfield
egen hmatched_med_wage_by_degfield = mean(med_wage_hmatched_by_degfield), by (degfield)
drop med_wage_hmatched_by_degfield

**For vmatched by degfield
sort degfield
by degfield: egen med_wage_vmatched_by_degfield_temp = median(adj_hourly) if vmatched_att==1
egen vmatched_med_wage_by_degfield = mean(med_wage_vmatched_by_degfield_temp), by (degfield)
drop med_wage_vmatched_by_degfield_temp

*Create med_wage for vmatched people within occupation (by attaintment)
sort occ
by occ: egen med_wage_vmatched_by_occ_temp = median(adj_hourly) if vmatched_att==1
egen vmatched_med_wage_by_occ = mean(med_wage_vmatched_by_occ_temp), by (occ)
drop med_wage_vmatched_by_occ_temp


***HORIZONTAL UNDERMATCH AND OVERMATCH binary variable creation***
* Only defined for college grads (col==1) who are NOT matched (hmatched==0). 
gen hundermatched=1 if hmatched==0 & col==1 & med_hourly_occ<hmatched_med_wage_by_degfield
replace hundermatched=0 if (hmatched==1) | (hmatched==0 & col==1 & med_hourly_occ>hmatched_med_wage_by_degfield)

gen hovermatched=1 if (hmatched==0)&(col==1)&(med_hourly_occ>hmatched_med_wage_by_degfield)
replace hovermatched=0 if (hmatched==1) | (hmatched==0 & col==1 & med_hourly_occ<hmatched_med_wage_by_degfield)

**COUNTS of h. undermatch and overmatch by occ**
egen hundercount=sum(hundermatched), by(occ)
by occ, sort: gen hunderproportion = hundercount/occ_count
egen hovercount=sum(hovermatched), by(occ)
by occ, sort: gen hoverproportion = hovercount/occ_count

**COUNTS of h. undermatch and overmatch by degfield**
egen hundercount_deg=sum(hundermatched), by(degfield)
by degfield, sort: gen hunderproportion_deg = hundercount_deg/deg_count
egen hovercount_deg=sum(hovermatched), by(degfield)
by degfield, sort: gen hoverproportion_deg = hovercount_deg/deg_count

************STEM Categorization**************
***For degfield***
egen stem_count=sum(stem_deg), by(occ)
by occ, sort: gen stem_proportion = stem_count/occ_count
by occ, sort: gen stem_primary_deg_by_occ=(stem_proportion>0.5)
***For occ***

************Category Variables for tables**********************
label define stem_deg_label 0 "non-STEM degree graduates" 1 "STEM degree graduates" 
label values stem_deg stem_deg_label 

label var for_cit "Foreign Citizen"
label var immig_by_ten "Immigrated before 10 yrs of age"
label var stem_deg "STEM Degree"

******************Descriptive Statistics***************************
gen vmismatched=vmatched_att!=1
gen hmismatched=hmatched!=1
gen matched = vmismatched!=1 & hmismatched!=1

label define vmismatched_label 0 "Not Vertically Mismatched" 1 "Vertically Mismatched" 
label values vmismatched vmismatched_label 

label define hmismatched_label 0 "Not Horizontally Mismatched" 1 "Horizontally Mismatched" 
label values hmismatched hmismatched_label

label define matched_label 0 "Not Matched" 1 "Mismatched" 
label values matched matched_label

label var vmismatched "Vertically Mismatched"
label var hmismatched "Horizontally Mismatched"
label var hundermatched "Horizontally Undermatched"
label var hovermatched "Horizontally Overmatched"
label var incwage "Wage and Salary income"
label var adj_hourly "Inflation-adjusted Hourly wage"


save "EO_C.dta", replace

// Creates ML Training sample after creating mismatch indicators
keep if undocu==1
export delimited using "ML Training Sample.csv", replace
