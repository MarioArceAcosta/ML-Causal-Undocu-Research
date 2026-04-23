*** SET DIRECTORIES 
global data "G:/Shared drives/Undocu Research/Data"			// Set your data file path here
global dofiles "G:/Shared drives/Undocu Research/Code"		// Set your do file path here	

*** SET CODE
cap log close
set more off, perm

					 ***********************************************
************************ STEP 1: PREPARE MAIN CENSUS DATA ************************
					 ***********************************************

********************************
*** Read data from local file***
********************************
*"G:\Shared drives\Undocu Research\Data"
cd "$data"
use "usa_00041.dta", clear
describe

********* Clean data ***********



replace degfield =9999 if degfield==. | degfield==0
replace degfieldd =9999 if degfieldd==. | degfieldd==0


* 2. IDENTIFY FORMAL EMPLOYEES
* IPUMS classwkrd 20-28 covers Private, Non-Profit, and Government wage/salary workers
gen is_employee = inrange(classwkrd, 20, 28)

* 3. IDENTIFY SELF-EMPLOYED
* IPUMS classwkrd 13 = Not incorporated, 14 = Incorporated
gen is_selfemp = inrange(classwkrd, 13, 14)


* 5. SET STUDY TIMEFRAME
keep if year >= 2009 & year <= 2019

drop cbserial momloc poploc

/* Filters applied in Clean data section, includes:

1.) Dropped individuals with no occupation listed.
2.) Kept only employed individuals (empstat == 1).
3.) Kept only individuals NOT currently attending school (school == 1) to exclude "survival jobs."
4.) Created indicators (is_employee, is_selfemp) to explicitly separate formal wage/salary workers from the self-employed.
5.) Dropped missing wage observations (incwage == 999999) BUT kept zero-wage earners to preserve the unincorporated self-employed.
6.) Restricted the sample to the 2009-2019 study period.
*/


******************************
*** EXTRACT NEEDED FAMILY INFO, THEN KEEP YOUNG ADULTS ONLY
******************************

*** Indicators for individual behaviors associated with legality
gen vet = (vetstat==2)					
	replace vet=. if vetstat==9 | vetstat==0
gen medicaid = hinscaid==2
gen anywelfare = incwelfr>0
	replace anywelfare=. if incwelfr==99999
gen anyss = incss>0
	replace anyss=. if incss==99999
gen anyssi = incsupp>0
	replace anyssi=. if incsupp==99999
gen medicare = hinscare==2


gen healthins = (hcovany==2)
replace foodstmp = foodstmp-1
label var foodstmp "Food Stamp Recipient in HH"
label var healthins "Health Insurance"

*** Aggregate them to household level
bysort serial sample year: egen hhvet = max(vet)
bysort serial sample year: egen hhwelf = max(anywelfare)
bysort serial sample year: egen hhss = max(anyss)
bysort serial sample year: egen hhssi = max(anyssi)
bysort serial sample year: egen hhmedicare = max(medicare)
drop vetstat incwelfr incss incsupp vet anyss anyssi anywelfare

*** Legal if any of the above hold
egen hhlegal = rowtotal(hhvet hhss hhssi hhmedicare hhwelf)
tab hhlegal, m
replace hhlegal=1 if hhlegal>1 
drop hhvet hhss hhssi hhmedicare hhwelf

******************************
*** CLEAN/CREATE CONTROL VARS
******************************
gen all=1

*** Demographic variables
* Race/ethnicity
gen hisp = (hispan!=0)
replace hisp=. if hispan==.
gen nonhisp = 1-hisp
drop hispan

gen white = race==1
gen black = race==2
gen asian = race==4 | race==5 | race==6
for any white black asian: replace X=0 if hisp==1
gen other = hisp!=1 & white!=1 & black!=1 & asian!=1

label var white "White"
label var black "Black"
label var asian "Asian"
label var other "Other Race"
label var hisp "Hispanic"
label var nonhisp "Non-Hispanic"

* Gender
tab sex, m
gen fem = sex==2
gen male = sex!=2
drop sex
label var fem "Female"
label var male "Male"

* Marital status
gen married = marst==1 | marst==2
label var married "Married"
drop marst

* Birthplace Indicators
gen usaborn = bpl>=100 & bpl<=120
gen bpl_mex = (bpl==200) 								// Mexico
gen bpl_othspan = (bpl>=210 & bpl<=300) 			// Central and South America
gen bpl_euraus = ((bpl>=410 & bpl<=419) | (bpl>=700 & bpl<=710) ) | (bpl>450 & bpl<=499) 	// UK and Ireland; Australia, NZ, and Pac Islands; Europe
gen bpl_asia = (bpl>=500 & bpl<=600) 				// Asia
gen bpl_oth = (bpl>=800 & bpl<=999) | bpl==600 	// Africa or other

label var usaborn "Born in US Territory"
label var bpl_mex "Born in Mexico"
label var bpl_othspan "Born in Central/South America"
label var bpl_euraus "Born in Europe/Australia"
label var bpl_asia "Born in Asia"
label var bpl_oth "Born in Africa/Other"


* Country of birth and language
gen english = language==1
gen spanish = language==12
gen nonfluent = (speakeng==1 | speakeng==6)
drop language speakeng
label var english "English Primary Language"
label var spanish "Spanish Primary Language"
label var nonfluent "Poor English"




* Other Labels
label var age "Surveyed Age"
*label var nsibs "Number of Siblings"


******************************
*** CLEAN/CREATE OUTCOMES
******************************

*** Years of Education
gen yrsed = 0 if educd==2 | educd==11 | educd==12 			// 0 ed
replace yrsed = 2 if educd==10 									// nursery to grade 4
replace yrsed = 2.5 if educd==13 								// 1-4
replace yrsed = 1 if educd==14 									// 1
replace yrsed = 2 if educd==15 									// 2
replace yrsed = 3 if educd==16 									// 3
replace yrsed = 4 if educd==17 									// 4
replace yrsed = 6.5 if educd==20 								// 5-8
replace yrsed = 5.5 if educd==21 								// 5-6
replace yrsed = 5 if educd==22 									// 5
replace yrsed = 6 if educd==23 									// 6
replace yrsed = 7.5 if educd==24 								// 7-8
replace yrsed = 7 if educd==25 									// 7
replace yrsed = 8 if educd==26 									// 8
replace yrsed = 9 if educd==30 									// 9
replace yrsed = 10 if educd==40 									// 10
replace yrsed = 11 if educd==50 									// 11
replace yrsed = 12 if educd==60 | educd==61 | educd==62 | educd==63 | educd==64
replace yrsed = 12.5 if educd==65 								// less than a year of college
replace yrsed = 13 if educd==70 | educd==71 					// 13
replace yrsed = 14 if educd==80 | educd==81 | educd==82 | educd==83 // 14
replace yrsed = 15 if educd==90 									// 15
replace yrsed = 16 if educd==100 | educd==101 				// 16
replace yrsed = 17 if educd==110 								// 17
replace yrsed = 18 if educd==111 | educd==114 				// 18
replace yrsed = 19 if educd==112 | educd==115 				// 19
replace yrsed = 21 if educd==116 								// 21
label var yrsed "Years of Education"

*** HS degree or more
gen hs = yrsed>=12
replace hs=0 if educd==61
replace hs=. if yrsed==.
label var hs "HS Degree"

*** Some college and college
gen scol = yrsed>12
gen col = yrsed>=16
for any scol col: replace X=. if yrsed==.
label var scol "Some College"
label var col "College"

// drop no longer needed ed vars
gen edu_att = 4 if educd>=101
replace edu_att = 3 if educd<101
replace edu_att = 2 if educd<65
replace edu_att = 1 if educd<62

gen edu_attS = "College Diploma" if educd>=101
replace edu_attS = "HS Diploma and some college" if educd<101
replace edu_attS = "HS Diploma" if educd<65
replace edu_attS = "No HS Diploma" if educd<62

******************************
*** ELIGIBILITY & POST VARS
******************************

*** Foreign born
gen ageimmig = yrimmig-birthyr
tab ageimmig, m
replace ageimmig=. if ageimmig<0
tab ageimmig, m
label var ageimmig "Age at Immigration"
label var yrimmig "Year of Immigration"

gen eighteen_by_arrival = (ageimmig<=18 | ageimmig==.)
*** Citizen/non citizen
gen noncit=citizen==3
replace noncit=. if citizen==.

gen noncit_spouse=citizen_sp==3
replace noncit_spouse=. if citizen_sp==.
gen cit_spouse =noncit_spouse==0


*** Eligible: noncitizen, immigrated by 16 and 2007, less than 31 in June 2012
// Note: for most of our analysis, we de-fact compare citizens to noncizens
gen elig = (noncit==1 & ageimmig<=16 & yrimmig<=2007 & (2012.5-(birthyr+(birthqtr*.25)))<31) // i.e birthyr + birthqtr>1981.5
replace elig=0 if ageimmig==.
tab elig year, m
gen nonelig = 1-elig
label define noncitizlabel 0 "Citizen" 1 "Non-Citizen"
label values noncit noncitizlabel 
la var elig "Eligible"
la var nonelig "Ineligible"

****** POST 2012 variables*******
gen post = year>=2012
gen elig_post = elig*post
la var elig_post "Eligible*Post"

gen elig_post_male = elig_post*male
la var elig_post_male "Eligible*Post*Male"

* How many eligibles by year?
tab birthyr, sum(elig)

* How many eligibles that we think are legal?
tab hhlegal elig, m

******************************
*** Undocu/DACA/Immigrant Variables
******************************

*** High takeup (30% or higher) according to MIP: El Salvador, Mexico, Uruguay, Honduras, Bolivia, Brazil, Peru, Ecuador, Jamaica, Guatemala, Venezuela, Dominican Republic, Colombia
tab bpld elig if bpld==21030 | bpld==20000 | bpld==30060 | bpld==21050 | bpld==30010 | bpld==30015 | ///
	bpld==30050 | bpld==30030 | bpld==26030 | bpld==21040 | bpld==30065 | bpld==26010 | bpld==30025

gen htus = 1 if bpld==21030 | bpld==20000 | bpld==30060 | bpld==21050 | bpld==30010 | bpld==30015 | ///
	bpld==30050 | bpld==30030 | bpld==26030 | bpld==21040 | bpld==30065 | bpld==26010 | bpld==30025
replace htus=. if yrimmig==0 
tab ageimm htus, m  

***********************************************END OF KUKA et. al. EXACT REPLICATION CODE**************************

****************************************************************************
************ BORJAS H-1B NONIMMIGRANT FILTER MODIFICATION*******************
****************************************************************************
gen reside_immig = year-yrimmig if yrimmig!=0
gen H1B_likely = (reside_immig<=6) & ( occ==101  | 	 occ==110  | 	 occ==230  | 	 occ==300  | 	 occ==800  | 	 occ==1005  | 	 occ==1006  | 	 occ==1010  | 	 occ==1021  | 	 occ==1022  | 	 occ==1050  | 	 occ==1065  | 	 occ==1105  | 	 occ==1106  | 	 occ==1108  | 	 occ==1305  | 	 occ==1306  | 	 occ==1310  | 	 occ==1320  | 	 occ==1330  | 	 occ==1340  | 	 occ==1350  | 	 occ==1360  | 	 occ==1400  | 	 occ==1410  | 	 occ==1420  | 	 occ==1430  | 	 occ==1440  | 	 occ==1450  | 	 occ==1460  | 	 occ==1500  | 	 occ==1510  | 	 occ==1520  | 	 occ==1530  | 	 occ==1541  | 	 occ==1551  | 	 occ==1555  | 	 occ==1560  | 	 occ==2205  | 	 occ==4930  | 	 occ==5000  | 	 occ==5100  | 	 occ==5120  | 	 occ==5340  | 	 occ==5710  | 	 occ==5720  | 	 occ==5730  | 	 occ==5740  | 	 occ==5900  | 	 occ==5940  | 	 occ==7010  | 	 occ==7905  | 	 occ==8610  | 	 occ==9030  | 	 occ==9210  | 	 occ==9330  | 	 occ==100  | 	 occ==1020  | 	 occ==1060  | 	 occ==1107  | 	 occ==1300  | 	 occ==1550  | 	 occ==2200  | 	 occ==2900  | 	 occ==5700  | 	 occ==5800  | 	 occ==6320  | 	 occ==7900  | 	 occ==9200  | 	 occ==1000  | 	 occ==1040  | 	 occ==1100  | 	 occ==5930) & (col==1)

replace elig=0 if H1B_likely==1
*****************************************************************************

**Applying Kuka/Warren/Passel legal status filter**
replace elig=0 if elig==1 & hhlegal==1
**Important modification for regression analysis**
replace metro=. if metro==0
**Educational attainment categorical variable**
gen edu_cat="HS or less" if yrsed<=12
replace edu_cat="College" if yrsed>12

**Inflation adjustment of wage since 2009, using CPI of January of each year**
gen cpi = 211.933 if year==2009
replace cpi = 217.488 if year==2010
replace cpi = 221.187	if year==2011
replace cpi = 227.842	if year==2012
replace cpi = 231.679	if year==2013
replace cpi = 235.288	if year==2014
replace cpi = 234.747	if year==2015
replace cpi = 237.652	if year==2016
replace cpi = 243.618	if year==2017
replace cpi = 248.859	if year==2018
replace cpi = 252.561	if year==2019
replace cpi = 258.906	if year==2020
replace cpi = 262.518	if year==2021
replace cpi = 282.39	if year==2022
replace cpi = 300.356	if year==2023
replace cpi = 309.685	if year==2024
gen adj_incwage = incwage * 309.685 / cpi
format adj_incwage %7.0f

**Midpoint method for wkswork2 (intervalled weeks worked last year)**
gen wkswork_midpoint = 6 if wkswork2==1 & wkswork1==.
replace wkswork_midpoint = 20 if wkswork2==2 & wkswork1==.
replace wkswork_midpoint = 33 if wkswork2==3 & wkswork1==.
replace wkswork_midpoint = 43.5 if wkswork2==4 & wkswork1==.
replace wkswork_midpoint = 48.5 if wkswork2==5 & wkswork1==.
replace wkswork_midpoint = 51 if wkswork2==6 & wkswork1==.
replace wkswork_midpoint = wkswork1 if wkswork1!=.

**Inflation-adjusted hourly wage of worker**
gen adj_hourly = adj_incwage / (uhrswork * wkswork_midpoint)


***************************************************************************
************ IMPORTANT VARIABLES FOR REGRESSION ANALYSIS*******************
***************************************************************************
**Indicator for immigrating before the age of 10**
gen immig_by_ten=ageimmig<10
**Age squared**
gen age_squared=age^2
**Indicator for those born in the U.S.**
gen bpl_usa=bpl<=120
**Indicator for those born outside the U.S.**
gen bpl_foreign=bpl>120
**Log transformation of hourly wage of worker, following previous literature**
gen ln_adj = ln(adj_hourly)
**Binary indicator for residing in metropolitan area**
gen metropolitan = metro == 2 | metro == 3 | metro == 4
**Binary indicator for whether a worker is in a government position**
gen gov_worker = classwkrd == 24 | classwkrd == 25 | classwkrd == 26 | classwkrd == 27 | classwkrd == 28



*****Additional categorical variables for detail and descriptive statistics if needed****
**Age-ineligible noncitizens meeting all other criteria**
gen age_inelig = elig==0 & noncit==1 & yrimmig<=2007 & (ageimmig>16 | (2012.5-(birthyr+(birthqtr*.25)))>=31)
replace age_inelig=. if noncit==0
**Arrival-ineligible noncitizens meeting all other criteria**
gen arrival_inelig = elig==0 & noncit==1 & yrimmig>2007 & (ageimmig<=16  & (2012.5-(birthyr+(birthqtr*.25)))<31)
replace arrival_inelig=. if noncit==0
**Young, arrival-ineligible noncitizens meeting all other criteria**
gen arrival_inelig_16_20 =elig==0 & noncit==1 & yrimmig>2007 & (ageimmig<=16  & (2012.5-(birthyr+(birthqtr*.25)))<=20 & (2012.5-(birthyr+(birthqtr*.25)))>=16)
replace arrival_inelig_16_20=. if noncit==0
**Both age-ineligible and arrival-ineligible noncitizens meeting all other criteria**
gen both_inelig = elig==0 & noncit==1 & yrimmig>2007 & (ageimmig>16  | (2012.5-(birthyr+(birthqtr*.25)))>=31)
replace both_inelig=. if noncit==0

gen undocu = noncit==1 & H1B_likely==0 & hhlegal==0
**********************************************************


**Foreign Citizens, born abroad and then naturalized**
gen for_cit = noncit==0 & bpl_usa!=1
***** Occ variable labels and categorization (Beyond 5 categories)*****





label define occ_label 10 "Chief Executives"	20	"General and Operations Managers"	30	"Legislators"	40	"Advertising and Promotions Managers"	51	"Marketing Managers"	52	"Sales Managers"	60	"Public Relations and Fundraising Managers"	101	"Administrative Services Managers"	102	"Facilities Managers"	110	"Computer and Information Systems Managers"	120	"Financial Managers"	135	"Compensation and Benefits Managers"	136	"Human Resources Managers"	137	"Training and Development Managers"	140	"Industrial Production Managers"	150	"Purchasing Managers"	160	"Transportation, Storage, and Distribution Managers"	205	"Farmers, Ranchers, and Other Agricultural Managers"	220	"Construction Managers"	230	"Education and Childcare Administrators "	300	"Architectural and Engineering Managers"	310	"Food Service Managers"	325	"Funeral Home Managers"	335	"Entertainment and Recreation Managers"	340	"Lodging Managers"	350	"Medical and Health Services Managers"	360	"Natural Sciences Managers"	400	"Postmasters and Mail Superintendents"	410	"Property, Real Estate, and Community Association Managers"	420	"Social and Community Service Managers"	425	"Emergency Management Directors"	426	"Personal Service Managers, All Other"	440	"Managers, All Other"	500	"Agents and Business Managers of Artists, Performers, and Athletes"	510	"Buyers and Purchasing Agents, Farm Products"	520	"Wholesale and Retail Buyers, Except Farm Products"	530	"Purchasing Agents, Except Wholesale, Retail, and Farm Products"	540	"Claims Adjusters, Appraisers, Examiners, and Investigators"	565	"Compliance Officers"	600	"Cost Estimators"	630	"Human Resources Workers"	640	"Compensation, Benefits, and Job Analysis Specialists"	650	"Training and Development Specialists"	700	"Logisticians"	705	"Project Management Specialists"	710	"Management Analysts"	725	"Meeting, Convention, and Event Planners"	726	"Fundraisers"	735	"Market Research Analysts and Marketing Specialists"	750	"Business Operations Specialists, All Other"	800	"Accountants and Auditors"	810	"Property Appraisers and Assessors"	820	"Budget Analysts"	830	"Credit Analysts"	845	"Financial and Investment Analysts"	850	"Personal Financial Advisors"	860	"Insurance Underwriters"	900	"Financial Examiners"	910	"Credit Counselors and Loan Officers"	930	"Tax Examiners and Collectors, and Revenue Agents"	940	"Tax Preparers"	960	"Other Financial Specialists"	1005	"Computer and Information Research Scientists"	1006	"Computer Systems Analysts"	1007	"Information Security Analysts"	1010	"Computer Programmers"	1021	"Software Developers"	1022	"Software Quality Assurance Analysts and Testers"	1050	"Computer Support Specialists"	1065	"Database Administrators and Architects"	1031	"Web Developers"	1032	"Web and Digital Interface Designers"	1105	"Network and Computer Systems Administrators"	1106	"Computer Network Architects"	1108	"Computer Occupations, All Other"	1200	"Actuaries"	1210	"Mathematicians"	1220	"Operations Research Analysts"	1230	"Statisticians"	1240	"Other Mathematical Science Occupations"	1305	"Architects, Except Landscape and Naval"	1306	"Landscape Architects"	1310	"Surveyors, Cartographers, and Photogrammetrists"	1320	"Aerospace Engineers"	1330	"Agricultural Engineers"	1340	"Bioengineers and biomedical engineers"	1350	"Chemical Engineers"	1360	"Civil Engineers"	1400	"Computer Hardware Engineers"	1410	"Electrical and Electronics Engineers"	1420	"Environmental Engineers"	1430	"Industrial Engineers, including Health and Safety "	1440	"Marine Engineers and Naval Architects"	1450	"Materials Engineers"	1460	"Mechanical Engineers"	1500	"Mining and Geological Engineers, Including Mining Safety Engineers"	1510	"Nuclear Engineers"	1520	"Petroleum Engineers"	1530	"Engineers, All Other"	1541	"Architectural and Civil Drafters"	1545	"Other Drafters"	1551	"Electrical and Electronic Engineering Technologists and Technicians"	1555	"Other Engineering Technologists and Technicians, Except Drafters"	1560	"Surveying and Mapping Technicians"	1600	"Agricultural and Food Scientists"	1610	"Biological Scientists"	1640	"Conservation Scientists and Foresters"	1650	"Medical Scientists"	1660	"Life Scientists, All Other"	1700	"Astronomers and Physicists"	1710	"Atmospheric and Space Scientists"	1720	"Chemists and Materials Scientists"	1745	"Environmental Scientists and Specialists, Including Health"	1750	"Geoscientists and Hydrologists, Except Geographers"	1760	"Physical Scientists, All Other"	1800	"Economists"	1815	"Survey Researchers"	1821	"Clinical and Counseling Psychologists"	1822	"School Psychologists"	1825	"Other Psychologists"	1830	"Sociologists"	1840	"Urban and Regional Planners"	1860	"Miscellaneous Social Scientists and Related Workers"	1900	"Agricultural and Food Science Technicians"	1910	"Biological Technicians"	1920	"Chemical Technicians"	1935	"Environmental Science and Geoscience Technicians"	1940	"Nuclear Technicians"	1950	"Social Science Research Assistants"	1970	"Other Life, Physical, and Social Science Technicians"	1980	"Occupational Health and Safety Specialists and Technicians"	2001	"Substance Abuse and Behavioral Disorder Counselors"	2002	"Educational, Guidance, and Career Counselors and Advisors"	2003	"Marriage and Family Therapists"	2004	"Mental Health Counselors"	2005	"Rehabilitation Counselors"	2006	"Counselors, All Other"	2011	"Child, Family, and School Social Workers"	2012	"Healthcare Social Workers"	2013	"Mental Health and Substance Abuse Social Workers"	2014	"Social Workers, All Other"	2015	"Probation Officers and Correctional Treatment Specialists"	2016	"Social and Human Service Assistants"	2025	"Other Community and Social Service Specialists"	2040	"Clergy"	2050	"Directors, Religious Activities and Education"	2060	"Religious Workers, All Other"	2100	"Lawyers"	2105	"Judicial Law Clerks"	2110	"Judges, Magistrates, and Other Judicial Workers"	2145	"Paralegals and Legal Assistants"	2170	"Title Examiners, Abstractors, and Searchers"	2180	"Legal Support Workers, All Other"	2205	"Postsecondary Teachers"	2300	"Preschool and Kindergarten Teachers"	2310	"Elementary and Middle School Teachers"	2320	"Secondary School Teachers"	2330	"Special Education Teachers"	2350	"Tutors"	2360	"Other Teachers and Instructors"	2400	"Archivists, Curators, and Museum Technicians"	2435	"Librarians and Media Collections Specialists"	2440	"Library Technicians"	2545	"Teaching Assistants"	2555	"Other Educational Instruction and Library Workers"	2600	"Artists and Related Workers"	2631	"Commercial and Industrial Designers"	2632	"Fashion Designers"	2633	"Floral Designers"	2634	"Graphic Designers"	2635	"Interior Designers"	2636	"Merchandise Displayers and Window Trimmers"	2640	"Other Designers"	2700	"Actors"	2710	"Producers and Directors"	2721	"Athletes and Sports Competitors"	2722	"Coaches and Scouts"	2723	"Umpires, Referees, and Other Sports Officials"	2740	"Dancers and Choreographers"	2751	"Music Directors and Composers"	2752	"Musicians and Singers"	2755	"Disc jockeys, except radio "	2770	"Entertainers and Performers, Sports and Related Workers, All Other"	2805	"Broadcast Announcers and Radio Disc Jockeys"	2810	"News Analysts, Reporters, and Journalists"	2825	"Public Relations Specialists"	2830	"Editors"	2840	"Technical Writers"	2850	"Writers and Authors"	2861	"Interpreters and Translators"	2862	"Court Reporters and Simultaneous Captioners"	2865	"Media and Communication Workers, All Other"	2905	"Broadcast, Sound, and Lighting Technicians"	2910	"Photographers"	2920	"Television, Video, and Film Camera Operators and Editors"	2970	"Media and Communication Equipment Workers, All Other"	3000	"Chiropractors"	3010	"Dentists"	3030	"Dietitians and Nutritionists"	3040	"Optometrists"	3050	"Pharmacists"	3065	"Emergency Medicine Physicians"	3070	"Radiologists"	3090	"Other Physicians"	3100	"Surgeons"	3110	"Physician Assistants"	3120	"Podiatrists"	3140	"Audiologists"	3150	"Occupational Therapists"	3160	"Physical Therapists"	3200	"Radiation Therapists"	3210	"Recreational Therapists"	3220	"Respiratory Therapists"	3230	"Speech-Language Pathologists"	3235	"Exercise Physiologists"	3245	"Therapists, All Other"	3250	"Veterinarians"	3255	"Registered Nurses"	3256	"Nurse Anesthetists"	3257	"Nurse Midwives"	3258	"Nurse Practitioners"	3261	"Acupuncturists"	3270	"Healthcare Diagnosing or Treating Practitioners, All Other"	3300	"Clinical Laboratory Technologists and Technicians"	3310	"Dental Hygienists"	3321	"Cardiovascular Technologists and Technicians"	3322	"Diagnostic Medical Sonographers"	3323	"Radiologic Technologists and Technicians"	3324	"Magnetic Resonance Imaging Technologists"	3330	"Nuclear Medicine Technologists and Medical Dosimetrists"	3401	"Emergency Medical Technicians"	3402	"Paramedics"	3421	"Pharmacy Technicians"	3422	"Psychiatric Technicians"	3423	"Surgical Technologists"	3424	"Veterinary Technologists and Technicians"	3430	"Dietetic Technicians and Ophthalmic Medical Technicians"	3500	"Licensed Practical and Licensed Vocational Nurses"	3515	"Medical Records Specialists"	3520	"Opticians, Dispensing"	3545	"Miscellaneous Health Technologists and Technicians"	3550	"Other Healthcare Practitioners and Technical Occupations"	3601	"Home Health Aides"	3602	"Personal Care Aides"	3603	"Nursing Assistants"	3605	"Orderlies and Psychiatric Aides"	3610	"Occupational Therapy Assistants and Aides"	3620	"Physical Therapist Assistants and Aides"	3630	"Massage Therapists"	3640	"Dental Assistants"	3645	"Medical Assistants"	3646	"Medical Transcriptionists"	3647	"Pharmacy Aides"	3648	"Veterinary Assistants and Laboratory Animal Caretakers"	3649	"Phlebotomists"	3655	"Other Healthcare Support Workers"	3700	"First-Line Supervisors of Correctional Officers"	3710	"First-Line Supervisors of Police and Detectives"	3720	"First-Line Supervisors of Firefighting and Prevention Workers"	3725	"First-Line Supervisors of Security Workers"	3735	"First-Line Supervisors of Protective Service Workers, All Other"	3740	"Firefighters"	3750	"Fire Inspectors "	3801	"Bailiffs"	3802	"Correctional Officers and Jailers"	3820	"Detectives and Criminal Investigators"	3830	"Fish and Game Wardens"	3840	"Parking Enforcement Workers"	3870	"Police Officers"	3900	"Animal Control Workers"	3910	"Private Detectives and Investigators"	3930	"Security Guards and Gambling Surveillance Officers"	3940	"Crossing Guards and Flaggers"	3945	"Transportation Security Screeners"	3946	"School Bus Monitors"	3960	"Other Protective Service Workers"	4000	"Chefs and Head Cooks"	4010	"First-Line Supervisors of Food Preparation and Serving Workers"	4020	"Cooks"	4030	"Food Preparation Workers"	4040	"Bartenders"	4055	"Fast Food and Counter Workers"	4110	"Waiters and Waitresses"	4120	"Food Servers, Nonrestaurant"	4130	"Dining Room and Cafeteria Attendants and Bartender Helpers"	4140	"Dishwashers"	4150	"Hosts and Hostesses, Restaurant, Lounge, and Coffee Shop"	4160	"Food Preparation and Serving Related Workers, All Other"	4200	"First-Line Supervisors of Housekeeping and Janitorial Workers"	4210	"First-Line Supervisors of Landscaping, Lawn Service, and Groundskeeping Workers"	4220	"Janitors and Building Cleaners"	4230	"Maids and Housekeeping Cleaners"	4240	"Pest Control Workers"	4251	"Landscaping and Groundskeeping Workers"	4252	"Tree Trimmers and Pruners"	4255	"Other Grounds Maintenance Workers"	4330	"Supervisors of Personal Care and Service Workers"	4340	"Animal Trainers"	4350	"Animal Caretakers"	4400	"Gambling Services Workers"	4420	"Ushers, Lobby Attendants, and Ticket Takers"	4435	"Other Entertainment Attendants and Related Workers"	4461	"Embalmers, Crematory Operators and Funeral Attendants"	4465	"Morticians, Undertakers, and Funeral Arrangers"	4500	"Barbers"	4510	"Hairdressers, Hairstylists, and Cosmetologists"	4521	"Manicurists and Pedicurists"	4522	"Skincare Specialists"	4525	"Other Personal Appearance Workers"	4530	"Baggage Porters, Bellhops, and Concierges"	4540	"Tour and Travel Guides"	4600	"Childcare Workers"	4621	"Exercise Trainers and Group Fitness Instructors"	4622	"Recreation Workers"	4640	"Residential Advisors"	4655	"Personal Care and Service Workers, All Other"	4700	"First-Line Supervisors of Retail Sales Workers"	4710	"First-Line Supervisors of Non-Retail Sales Workers"	4720	"Cashiers"	4740	"Counter and Rental Clerks"	4750	"Parts Salespersons"	4760	"Retail Salespersons"	4800	"Advertising Sales Agents"	4810	"Insurance Sales Agents"	4820	"Securities, Commodities, and Financial Services Sales Agents"	4830	"Travel Agents"	4840	"Sales representatives of services, except advertising, insurance, financial services, and travel"	4850	"Sales Representatives, Wholesale and Manufacturing"	4900	"Models, Demonstrators, and Product Promoters"	4920	"Real Estate Brokers and Sales Agents"	4930	"Sales Engineers"	4940	"Telemarketers"	4950	"Door-to-Door Sales Workers, News and Street Vendors, and Related Workers"	4965	"Sales and Related Workers, All Other"	5000	"First-Line Supervisors of Office and Administrative Support Workers"	5010	"Switchboard Operators, Including Answering Service"	5020	"Telephone Operators"	5040	"Communications Equipment Operators, All Other"	5100	"Bill and Account Collectors"	5110	"Billing and Posting Clerks"	5120	"Bookkeeping, Accounting, and Auditing Clerks"	5130	"Gambling Cage Workers"	5140	"Payroll and Timekeeping Clerks"	5150	"Procurement Clerks"	5160	"Tellers"	5165	"Financial Clerks, All Other"	5200	"Brokerage Clerks"	5210	"Correspondence Clerks"	5220	"Court, Municipal, and License Clerks"	5230	"Credit Authorizers, Checkers, and Clerks"	5240	"Customer Service Representatives"	5250	"Eligibility Interviewers, Government Programs"	5260	"File Clerks"	5300	"Hotel, Motel, and Resort Desk Clerks"	5310	"Interviewers, Except Eligibility and Loan"	5320	"Library Assistants, Clerical"	5330	"Loan Interviewers and Clerks"	5340	"New Accounts Clerks"	5350	"Order Clerks"	5360	"Human Resources Assistants, Except Payroll and Timekeeping"	5400	"Receptionists and Information Clerks"	5410	"Reservation and Transportation Ticket Agents and Travel Clerks"	5420	"Information and Record Clerks, All Other"	5500	"Cargo and Freight Agents"	5510	"Couriers and Messengers"	5521	"Public Safety Telecommunicators"	5522	"Dispatchers, Except Police, Fire, and Ambulance"	5530	"Meter Readers, Utilities"	5540	"Postal Service Clerks"	5550	"Postal Service Mail Carriers"	5560	"Postal Service Mail Sorters, Processors, and Processing Machine Operators"	5600	"Production, Planning, and Expediting Clerks"	5610	"Shipping, Receiving, and Inventory Clerks"	5630	"Weighers, Measurers, Checkers, and Samplers, Recordkeeping"	5710	"Executive Secretaries and Executive Administrative Assistants"	5720	"Legal Secretaries and Administrative Assistants"	5730	"Medical Secretaries and Administrative Assistants"	5740	"Secretaries and Administrative Assistants, Except Legal, Medical, and Executive"	5810	"Data Entry Keyers"	5820	"Word Processors and Typists"	5830	"Desktop Publishers"	5840	"Insurance Claims and Policy Processing Clerks"	5850	"Mail Clerks and Mail Machine Operators, Except Postal Service"	5860	"Office Clerks, General"	5900	"Office Machine Operators, Except Computer"	5910	"Proofreaders and Copy Markers"	5920	"Statistical Assistants"	5940	"Office and Administrative Support Workers, All Other"	6005	"First-Line Supervisors of Farming, Fishing, and Forestry Workers"	6010	"Agricultural Inspectors"	6020	"Animal Breeders"	6040	"Graders and Sorters, Agricultural Products"	6050	"Miscellaneous Agricultural Workers"	6115	"Fishing and Hunting Workers"	6120	"Forest and Conservation Workers"	6130	"Logging Workers"	6200	"First-Line Supervisors of Construction Trades and Extraction Workers"	6210	"Boilermakers"	6220	"Brickmasons, Blockmasons, and Stonemasons"	6230	"Carpenters"	6240	"Carpet, Floor, and Tile Installers and Finishers"	6250	"Cement Masons, Concrete Finishers, and Terrazzo Workers"	6260	"Construction Laborers"	6305	"Construction Equipment Operators"	6330	"Drywall Installers, Ceiling Tile Installers, and Tapers"	6355	"Electricians"	6360	"Glaziers"	6400	"Insulation Workers"	6410	"Painters and Paperhangers"	6441	"Pipelayers"	6442	"Plumbers, Pipefitters, and Steamfitters"	6460	"Plasterers and Stucco Masons"	6500	"Reinforcing Iron and Rebar Workers"	6515	"Roofers"	6520	"Sheet Metal Workers"	6530	"Structural Iron and Steel Workers"	6540	"Solar Photovoltaic Installers"	6600	"Helpers, Construction Trades"	6660	"Construction and Building Inspectors"	6700	"Elevator and Escalator Installers and Repairers"	6710	"Fence Erectors"	6720	"Hazardous Materials Removal Workers"	6730	"Highway Maintenance Workers"	6740	"Rail-Track Laying and Maintenance Equipment Operators"	6750	"Septic Tank Servicers and Sewer Pipe Cleaners"	6765	"Miscellaneous Construction and Related Workers"	6800	"Derrick, Rotary Drill, and Service Unit Operators, Oil and Gas  "	6821	"Excavating and Loading Machine and Dragline Operators, Surface Mining"	6825	"Earth Drillers, Except Oil and Gas"	6835	"Explosives Workers, Ordnance Handling Experts, and Blasters"	6850	"Underground Mining Machine Operators"	6920	"Roustabouts, Oil and Gas"	6950	"Other Extraction Workers"	7000	"First-Line Supervisors of Mechanics, Installers, and Repairers"	7010	"Computer, Automated Teller, and Office Machine Repairers"	7020	"Radio and Telecommunications Equipment Installers and Repairers"	7030	"Avionics Technicians"	7040	"Electric Motor, Power Tool, and Related Repairers"	7050	"Electrical and Electronics Installers and Repairers, Transportation Equipment"	7100	"Electrical and Electronics Repairers, Industrial and Utility "	7110	"Electronic Equipment Installers and Repairers, Motor Vehicles"	7120	"Audiovisual Equipment Installers and Repairers"	7130	"Security and Fire Alarm Systems Installers"	7140	"Aircraft Mechanics and Service Technicians"	7150	"Automotive Body and Related Repairers"	7160	"Automotive Glass Installers and Repairers"	7200	"Automotive Service Technicians and Mechanics"	7210	"Bus and Truck Mechanics and Diesel Engine Specialists"	7220	"Heavy Vehicle and Mobile Equipment Service Technicians and Mechanics"	7240	"Small Engine Mechanics"	7260	"Miscellaneous Vehicle and Mobile Equipment Mechanics, Installers, and Repairers"	7300	"Control and Valve Installers and Repairers"	7315	"Heating, Air Conditioning, and Refrigeration Mechanics and Installers"	7320	"Home Appliance Repairers"	7330	"Industrial and Refractory Machinery Mechanics"	7340	"Maintenance and Repair Workers, General"	7350	"Maintenance Workers, Machinery"	7360	"Millwrights"	7410	"Electrical Power-Line Installers and Repairers"	7420	"Telecommunications Line Installers and Repairers"	7430	"Precision Instrument and Equipment Repairers"	7440	"Wind Turbine Service Technicians"	7510	"Coin, Vending, and Amusement Machine Servicers and Repairers"	7520	"Commercial Divers"	7540	"Locksmiths and Safe Repairers"	7550	"Manufactured Building and Mobile Home Installers"	7560	"Riggers"	7610	"Helpers--Installation, Maintenance, and Repair Workers"	7640	"Other Installation, Maintenance, and Repair Workers"	7700	"First-Line Supervisors of Production and Operating Workers"	7710	"Aircraft Structure, Surfaces, Rigging, and Systems Assemblers"	7720	"Electrical, Electronics, and Electromechanical Assemblers"	7730	"Engine and Other Machine Assemblers"	7740	"Structural Metal Fabricators and Fitters"	7750	"Other Assemblers and Fabricators"	7800	"Bakers"	7810	"Butchers and Other Meat, Poultry, and Fish Processing Workers"	7830	"Food and Tobacco Roasting, Baking, and Drying Machine Operators and Tenders"	7840	"Food Batchmakers"	7850	"Food Cooking Machine Operators and Tenders"	7855	"Food Processing Workers, All Other"	7905	"Computer numerically controlled tool operators and programmers"	7925	"Forming Machine Setters, Operators, and Tenders, Metal and Plastic"	7950	"Cutting, Punching, and Press Machine Setters, Operators, and Tenders, Metal and Plastic"	8000	"Grinding, Lapping, Polishing, and Buffing Machine Tool Setters, Operators, and Tenders, Metal and Plastic"	8025	"Other Machine Tool Setters, Operators, and Tenders, Metal and Plastic"	8030	"Machinists"	8040	"Metal Furnace Operators, Tenders, Pourers, and Casters"	8060	"Model Makers and Patternmakers, Metal and Plastic"	8100	"Molders and Molding Machine Setters, Operators, and Tenders, Metal and Plastic"	8130	"Tool and Die Makers"	8140	"Welding, Soldering, and Brazing Workers"	8225	"Other Metal Workers and Plastic Workers"	8250	"Prepress Technicians and Workers"	8255	"Printing Press Operators"	8256	"Print Binding and Finishing Workers"	8300	"Laundry and Dry-Cleaning Workers"	8310	"Pressers, Textile, Garment, and Related Materials"	8320	"Sewing Machine Operators"	8335	"Shoe and Leather Workers"	8350	"Tailors, Dressmakers, and Sewers"	8365	"Textile Machine Setters, Operators, and Tenders"	8450	"Upholsterers"	8465	"Other Textile, Apparel, and Furnishings Workers"	8500	"Cabinetmakers and Bench Carpenters"	8510	"Furniture Finishers"	8530	"Sawing Machine Setters, Operators, and Tenders, Wood"	8540	"Woodworking Machine Setters, Operators, and Tenders, Except Sawing"	8555	"Other Woodworkers"	8600	"Power Plant Operators, Distributors, and Dispatchers"	8610	"Stationary Engineers and Boiler Operators"	8620	"Water and Wastewater Treatment Plant and System Operators"	8630	"Miscellaneous Plant and System Operators"	8640	"Chemical Processing Machine Setters, Operators, and Tenders"	8650	"Crushing, Grinding, Polishing, Mixing, and Blending Workers"	8710	"Cutting Workers"	8720	"Extruding, Forming, Pressing, and Compacting Machine Setters, Operators, and Tenders"	8730	"Furnace, Kiln, Oven, Drier, and Kettle Operators and Tenders"	8740	"Inspectors, Testers, Sorters, Samplers, and Weighers"	8750	"Jewelers and Precious Stone and Metal Workers"	8760	"Dental and Ophthalmic Laboratory Technicians and Medical Appliance Technicians"	8800	"Packaging and Filling Machine Operators and Tenders"	8810	"Painting Workers"	8830	"Photographic Process Workers and Processing Machine Operators"	8850	"Adhesive Bonding Machine Operators and Tenders"	8910	"Etchers and Engravers"	8920	"Molders, Shapers, and Casters, Except Metal and Plastic"	8930	"Paper Goods Machine Setters, Operators, and Tenders"	8940	"Tire Builders"	8950	"Helpers--Production Workers"	8865	"Other Production Equipment Operators and Tenders"	8990	"Other Production Workers"	9005	"Supervisors of Transportation and Material Moving Workers"	9030	"Aircraft Pilots and Flight Engineers"	9040	"Air Traffic Controllers and Airfield Operations Specialists"	9050	"Flight Attendants"	9110	"Ambulance Drivers and Attendants, Except Emergency Medical Technicians"	9121	"Bus Drivers, School"	9122	"Bus Drivers, Transit and Intercity"	9130	"Driver/Sales Workers and Truck Drivers"	9141	"Shuttle Drivers and Chauffeurs"	9142	"Taxi Drivers"	9150	"Motor Vehicle Operators, All Other"	9210	"Locomotive Engineers and Operators"	9240	"Railroad Conductors and Yardmasters"	9265	"Other Rail Transportation Workers"	9300	"Sailors and Marine Oilers"	9330	"Ship Engineers "	9310	"Ship and Boat Captains and Operators"	9350	"Parking Attendants"	9365	"Transportation Service Attendants"	9410	"Transportation Inspectors"	9415	"Passenger Attendants"	9430	"Other Transportation Workers"	9510	"Crane and Tower Operators"	9570	"Conveyor, Dredge, and Hoist and Winch Operators"	9600	"Industrial Truck and Tractor Operators"	9610	"Cleaners of Vehicles and Equipment"	9620	"Laborers and Freight, Stock, and Material Movers, Hand"	9630	"Machine Feeders and Offbearers"	9640	"Packers and Packagers, Hand"	9645	"Stockers and Order Fillers"	9650	"Pumping Station Operators"	9720	"Refuse and Recyclable Material Collectors"	9760	"Other Material Moving Workers"	9800	"Military Officer Special and Tactical Operations Leaders"	9810	"First-Line Enlisted Military Supervisors"	9825	"Military Enlisted Tactical Operations and Air/Weapons Specialists and Crew Members"	9830	"Military, Rank Not Specified"	9920	"Unemployed, with no work experience in the last 5 years or earlier or never worked"	50	"Marketing and sales managers"	100	"Administrative services managers"	330	"Gaming managers"	430	"Managers, all other"	740	"Business operations specialists, all other"	840	"Financial analysts"	950	"Financial specialists, all other"	1020	"Software developers, applications and systems software"	1030	"Web developers"	1060	"Database administrators"	1107	"Computer occupations, all other"	1300	"Architects, except naval"	1540	"Drafters"	1550	"Engineering technicians, except drafters"	1740	"Environmental scientists and geoscientists"	1820	"Psychologists"	1930	"Geological and petroleum technicians"	1965	"Miscellaneous life, physical, and social science technicians"	2000	"Counselors"	2010	"Social workers"	2160	"Miscellaneous legal support workers"	2200	"Postsecondary teachers"	2340	"Other teachers and instructors"	2430	"Librarians"	2540	"Teacher assistants"	2550	"Other education, training, and library workers"	2630	"Designers"	2720	"Athletes, coaches, umpires, and related workers"	2750	"Musicians, singers, and related workers"	2760	"Entertainers and performers, sports and related workers, all other"	2800	"Announcers"	2860	"Miscellaneous media and communication workers"	2900	"Broadcast and sound engineering technicians and radio operators"	2960	"Media and communication equipment workers, all other"	3060	"Physicians and surgeons"	3260	"Health diagnosing and treating practitioners, all other"	3320	"Diagnostic related technologists and technicians"	3400	"Emergency medical technicians and paramedics"	3420	"Health practitioner support technologists and technicians"	3510	"Medical records and health information technicians"	3535	"Miscellaneous health technologists and technicians"	3540	"Other healthcare practitioners and technical occupations"	3600	"Nursing, psychiatric, and home health aides"	3730	"First-line supervisors of protective service workers, all other"	3800	"Bailiffs, correctional officers, and jailers"	3850	"Police and sheriff's patrol officers"	3860	"Transit and railroad police"	3955	"Lifeguards and other recreational, and all other protective service workers"	4050	"Combined food preparation and serving workers, including fast food"	4060	"Counter attendants, cafeteria, food concession, and coffee shop"	4250	"Grounds maintenance workers"	4300	"First-line supervisors of gaming workers"	4320	"First-line supervisors of personal service workers"	4410	"Motion picture projectionists"	4430	"Miscellaneous entertainment attendants and related workers"	4460	"Embalmers and funeral attendants"	4520	"Miscellaneous personal appearance workers"	4610	"Personal care aides"	4620	"Recreation and fitness workers"	4650	"Personal care and service workers, all other "	5030	"Communications equipment operators, all other"	5520	"Dispatchers"	5620	"Stock clerks and order fillers"	5700	"Secretaries and administrative assistants"	5800	"Computer operators"	6100	"Fishers and related fishing workers"	6110	"Hunters and trappers"	6300	"Paving, surfacing, and tamping equipment operators"	6310	"Pile-driver operators"	6320	"Operating engineers and other construction equipment operators"	6420	"Painters, construction and maintenance"	6430	"Paperhangers"	6440	"Pipelayers, plumbers, pipefitters, and steamfitters"	6820	"Earth drillers, except oil and gas"	6830	"Explosives workers, ordnance handling experts, and blasters"	6840	"Mining machine operators"	6910	"Roof bolters, mining"	6930	"Helpers--extraction workers"	6940	"Other extraction workers"	7600	"Signal and track switch repairers"	7630	"Other installation, maintenance, and repair workers"	7900	"Computer control programmers and operators"	7920	"Extruding and drawing machine setters, operators, and tenders, metal and plastic"	7930	"Forging machine setters, operators, and tenders, metal and plastic"	7940	"Rolling machine setters, operators, and tenders, metal and plastic"	7960	"Drilling and boring machine tool setters, operators, and tenders, metal and plastic "	8010	"Lathe and turning machine tool setters, operators, and tenders, metal and plastic"	8020	"Milling and planing machine setters, operators, and tenders, metal and plastic"	8120	"Multiple machine tool setters, operators, and tenders, metal and plastic "	8150	"Heat treating equipment setters, operators, and tenders, metal and plastic"	8160	"Layout workers, metal and plastic"	8200	"Plating and coating machine setters, operators, and tenders, metal and plastic"	8210	"Tool grinders, filers, and sharpeners"	8220	"Metal workers and plastic workers, all other"	8330	"Shoe and leather workers and repairers"	8340	"Shoe machine operators and tenders"	8360	"Textile bleaching and dyeing machine operators and tenders"	8400	"Textile cutting machine setters, operators, and tenders"	8410	"Textile knitting and weaving machine setters, operators, and tenders"	8420	"Textile winding, twisting, and drawing out machine setters, operators, and tenders"	8430	"Extruding and forming machine setters, operators, and tenders, synthetic and glass fibers"	8440	"Fabric and apparel patternmakers"	8460	"Textile, apparel, and furnishings workers, all other"	8520	"Model makers and patternmakers, wood"	8550	"Woodworkers, all other"	8840	"Semiconductor processors"	8860	"Cleaning, washing, and metal pickling equipment operators and tenders"	8900	"Cooling and freezing equipment operators and tenders"	8965	"Production workers, all other"	9000	"Supervisors of transportation and material moving workers"	9120	"Bus drivers"	9140	"Taxi drivers and chauffeurs"	9200	"Locomotive engineers and operators"	9230	"Railroad brake, signal, and switch operators"	9260	"Subway, streetcar, and other rail transportation workers"	9340	"Bridge and lock tenders"	9360	"Automotive and watercraft service attendants   "	9420	"Other transportation workers "	9500	"Conveyor operators and tenders"	9520	"Dredge, excavating, and loading machine operators"	9560	"Hoist and winch operators"	9730	"Mine shuttle car operators"	9740	"Tank car, truck, and ship loaders"	9750	"Material moving workers, all other"	9820	"Military enlisted tactical operations and air/weapons specialists and crew members"	130	"Human resources managers"	200	"Farm, ranch, and other agricultural managers"	210	"Farmers and ranchers"	320	"Funeral directors"	560	"Compliance officers, except agriculture, construction, health and safety, and transportation"	620	"Human resources, training, and labor relations specialists"	720	"Meeting and convention planners"	730	"Other business operations specialists"	1000	"Computer scientists and systems analysts"	1040	"Computer support specialists"	1100	"Network and computer systems administrators"	1110	"Network systems and data communications analysts"	1810	"Market and survey researchers"	1960	"Other life, physical, and social science technicians"	2020	"Miscellaneous community and social service specialists"	2140	"Paralegals and legal assistants"	2150	"Miscellaneous legal support workers"	2820	"Public relations specialists"	3130	"Registered nurses"	3240	"Therapists, all other"	3410	"Health diagnosing and treating practitioner support technicians"	3530	"Miscellaneous health technologists and technicians"	3650	"Medical assistants and other healthcare support occupations"	3920	"Security guards and gaming surveillance officers"	3950	"Lifeguards and other protective service workers"	4550	"Transportation attendants"	4960	"Sales and related workers, all other"	5930	"Office and administrative support workers, all other"	6000	"First-line supervisors/managers of farming, fishing, and forestry workers"	6350	"Electricians"	6510	"Roofers"	6760	"Miscellaneous construction and related workers"	7310	"Heating, air conditioning, and refrigeration mechanics and installers"	7620	"Other installation, maintenance, and repair workers"	8230	"Bookbinders and bindery workers"	8240	"Job printers"	8260	"Printing machine operators"	8960	"Production workers, all other"

label values occ occ_label


************2002 to 2010 occ crosswalk******
replace occ=136 if occ==130
replace occ=205 if occ==200 | occ==210
replace occ=4465 if occ==320
replace occ=565 if occ==560
replace occ=630 if occ==620
replace occ=725 if occ==720
replace occ=740 if occ==730
replace occ=1005 if occ==1000
replace occ=1050 if occ==1040
replace occ=1105 if occ==1100
replace occ=1007 if occ==1110
replace occ=735 if occ==1810
replace occ=1965 if occ==1960
replace occ=2025 if occ==2020
replace occ=2145 if occ==2140
replace occ=2825 if occ==2820
replace occ=3255 if occ==3130
replace occ=3245 if occ==3240
replace occ=3420 if occ==3410
replace occ=3535 if occ==3530
replace occ=3645 if occ==3650
replace occ=3930 if occ==3920
replace occ=9415 if occ==4960
replace occ=4965 if occ==4960
replace occ=5940 if occ==5930
replace occ=6005 if occ==6000
replace occ=6355 if occ==6350
replace occ=6515 if occ==6510
replace occ=7315 if occ==7310
replace occ=7630 if occ==7620
replace occ=8256 if occ==8230
replace occ=8255 if occ==8240 | occ==8260
replace occ=8965 if occ==8960
************2018 to 2010 occ crosswalk******
replace occ=	0050	if occ==	0051
replace occ=	0050	if occ==	0052
replace occ=	0100	if occ==	0101
replace occ=	0100	if occ==	0102
replace occ=	0330	if occ==	0335
replace occ=	0430	if occ==	0335
replace occ=	0430	if occ==	0426
replace occ=	0430	if occ==	0440
replace occ=	0430	if occ==	0705
replace occ=	0740	if occ==	0705
replace occ=	0740	if occ==	0750
replace occ=	0840	if occ==	0845
replace occ=	0840	if occ==	0960
replace occ=	0950	if occ==	0960
replace occ=	1107	if occ==	0705
replace occ=	1107	if occ==	1108
replace occ=	1107	if occ==	1065
replace occ=	1107	if occ==	1022
replace occ=	1107	if occ==	1032
replace occ=	1020	if occ==	1021
replace occ=	1020	if occ==	1022
replace occ=	1030	if occ==	1031
replace occ=	1030	if occ==	1032
replace occ=	1060	if occ==	1065
replace occ=	1300	if occ==	1305
replace occ=	1300	if occ==	1306
replace occ=	1540	if occ==	1541
replace occ=	1540	if occ==	1545
replace occ=	1550	if occ==	1551
replace occ=	1550	if occ==	1555
replace occ=	1740	if occ==	1745
replace occ=	1740	if occ==	1750
replace occ=	1820	if occ==	1821
replace occ=	1820	if occ==	1822
replace occ=	1820	if occ==	1825
replace occ=	1930	if occ==	1935
replace occ=	1965	if occ==	1935
replace occ=	1965	if occ==	1970
replace occ=	2000	if occ==	2001
replace occ=	2000	if occ==	2002
replace occ=	2000	if occ==	2003
replace occ=	2000	if occ==	2004
replace occ=	2000	if occ==	2005
replace occ=	2000	if occ==	2006
replace occ=	2010	if occ==	2011
replace occ=	2010	if occ==	2012
replace occ=	2010	if occ==	2013
replace occ=	2010	if occ==	2014
replace occ=	2160	if occ==	2170
replace occ=	2160	if occ==	2180
replace occ=	2160	if occ==	2862
replace occ=	2200	if occ==	2205
replace occ=	2200	if occ==	2545
replace occ=	2340	if occ==	2350
replace occ=	2340	if occ==	2360
replace occ=	2430	if occ==	2435
replace occ=	2540	if occ==	2545
replace occ=	2550	if occ==	2435
replace occ=	2550	if occ==	2555
replace occ=	2630	if occ==	2631
replace occ=	2630	if occ==	2632
replace occ=	2630	if occ==	2633
replace occ=	2630	if occ==	2634
replace occ=	2630	if occ==	2635
replace occ=	2630	if occ==	2636
replace occ=	2630	if occ==	2640
replace occ=	2720	if occ==	2721
replace occ=	2720	if occ==	2722
replace occ=	2720	if occ==	2723
replace occ=	2750	if occ==	2751
replace occ=	2750	if occ==	2752
replace occ=	2760	if occ==	2755
replace occ=	2760	if occ==	2770
replace occ=	2800	if occ==	2805
replace occ=	2800	if occ==	2865
replace occ=	2860	if occ==	2861
replace occ=	2860	if occ==	2865
replace occ=	2900	if occ==	2905
replace occ=	2900	if occ==	5040
replace occ=	2960	if occ==	2905
replace occ=	2960	if occ==	2970
replace occ=	3060	if occ==	3065
replace occ=	3060	if occ==	3070
replace occ=	3060	if occ==	3090
replace occ=	3060	if occ==	3100
replace occ=	3260	if occ==	3270
replace occ=	3260	if occ==	3261
replace occ=	3320	if occ==	3321
replace occ=	3320	if occ==	3322
replace occ=	3320	if occ==	3323
replace occ=	3320	if occ==	3324
replace occ=	3320	if occ==	3330
replace occ=	3400	if occ==	3401
replace occ=	3400	if occ==	3402
replace occ=	3420	if occ==	3421
replace occ=	3420	if occ==	3422
replace occ=	3420	if occ==	3423
replace occ=	3420	if occ==	3424
replace occ=	3420	if occ==	3430
replace occ=	3420	if occ==	3545
replace occ=	3510	if occ==	3515
replace occ=	3510	if occ==	3550
replace occ=	3535	if occ==	3545
replace occ=	3540	if occ==	1980
replace occ=	3540	if occ==	3550
replace occ=	3600	if occ==	3601
replace occ=	3600	if occ==	3603
replace occ=	3600	if occ==	3605
replace occ=	3730	if occ==	3725
replace occ=	3730	if occ==	3735
replace occ=	3800	if occ==	3801
replace occ=	3800	if occ==	3802
replace occ=	3850	if occ==	3870
replace occ=	3860	if occ==	3870
replace occ=	3955	if occ==	3946
replace occ=	3955	if occ==	3960
replace occ=	4050	if occ==	4055
replace occ=	4060	if occ==	4055
replace occ=	4250	if occ==	4251
replace occ=	4250	if occ==	4252
replace occ=	4250	if occ==	4255
replace occ=	4320	if occ==	4330
replace occ=	4320	if occ==	9005
replace occ=	4300	if occ==	4330
replace occ=	4410	if occ==	4435
replace occ=	4430	if occ==	4435
replace occ=	4460	if occ==	4461
replace occ=	4520	if occ==	4521
replace occ=	4520	if occ==	4522
replace occ=	4520	if occ==	4525
replace occ=	4610	if occ==	3602
replace occ=	4620	if occ==	4621
replace occ=	4620	if occ==	4622
replace occ=	4650	if occ==	4461
replace occ=	4650	if occ==	4655
replace occ=	5030	if occ==	5040
replace occ=	5520	if occ==	5521
replace occ=	5520	if occ==	5522
replace occ=	5620	if occ==	9645
replace occ=	5700	if occ==	5710
replace occ=	5700	if occ==	5720
replace occ=	5700	if occ==	5730
replace occ=	5700	if occ==	5740
replace occ=	5800	if occ==	1108
replace occ=	6100	if occ==	6115
replace occ=	6110	if occ==	6115
replace occ=	6300	if occ==	6305
replace occ=	6310	if occ==	6305
replace occ=	6320	if occ==	6305
replace occ=	6420	if occ==	6410
replace occ=	6430	if occ==	6410
replace occ=	6440	if occ==	6441
replace occ=	6440	if occ==	6442
replace occ=	6820	if occ==	6825
replace occ=	6820	if occ==	6835
replace occ=	6830	if occ==	6835
replace occ=	6840	if occ==	6850
replace occ=	6840	if occ==	6950
replace occ=	6910	if occ==	6850
replace occ=	6930	if occ==	6950
replace occ=	6940	if occ==	6950
replace occ=	7600	if occ==	7640
replace occ=	7630	if occ==	7640
replace occ=	7900	if occ==	7905
replace occ=	7920	if occ==	7925
replace occ=	7930	if occ==	7925
replace occ=	7940	if occ==	7925
replace occ=	7960	if occ==	8025
replace occ=	8010	if occ==	8025
replace occ=	8020	if occ==	8025
replace occ=	8120	if occ==	8225
replace occ=	8150	if occ==	8225
replace occ=	8160	if occ==	8225
replace occ=	8200	if occ==	8225
replace occ=	8210	if occ==	8225
replace occ=	8220	if occ==	8225
replace occ=	8330	if occ==	8335
replace occ=	8340	if occ==	8335
replace occ=	8360	if occ==	8365
replace occ=	8400	if occ==	8365
replace occ=	8410	if occ==	8365
replace occ=	8420	if occ==	8365
replace occ=	8430	if occ==	8465
replace occ=	8440	if occ==	8465
replace occ=	8460	if occ==	8465
replace occ=	8520	if occ==	8555
replace occ=	8550	if occ==	8555
replace occ=	8860	if occ==	8865
replace occ=	8900	if occ==	8865
replace occ=	8840	if occ==	8990
replace occ=	8965	if occ==	7905
replace occ=	8965	if occ==	8990
replace occ=	9000	if occ==	9005
replace occ=	9120	if occ==	9121
replace occ=	9120	if occ==	9122
replace occ=	9120	if occ==	9141
replace occ=	9140	if occ==	9141
replace occ=	9140	if occ==	9142
replace occ=	9200	if occ==	9210
replace occ=	9200	if occ==	9265
replace occ=	9230	if occ==	9265
replace occ=	9260	if occ==	9265
replace occ=	9340	if occ==	9430
replace occ=	9360	if occ==	9365
replace occ=	9420	if occ==	9365
replace occ=	9420	if occ==	9430
replace occ=	9500	if occ==	9570
replace occ=	9520	if occ==	9570
replace occ=	9520	if occ==	9760
replace occ=	9520	if occ==	6850
replace occ=	9520	if occ==	6821
replace occ=	9560	if occ==	9570
replace occ=	9730	if occ==	6850
replace occ=	9740	if occ==	9760
replace occ=	9750	if occ==	9760
replace occ=	9820	if occ==	1555
replace occ=	9820	if occ==	9825



***Occupational category****
gen occ_category = 1 if occ >= 10 & occ<= 960
replace occ_category = 2 if occ >= 1000 & occ<= 1980
replace occ_category = 3 if occ >= 2000 & occ<= 2920
replace occ_category = 4 if occ >= 3000 & occ<= 3550
replace occ_category = 5 if occ >= 3600 & occ<= 4655
replace occ_category = 6 if occ >= 4700 & occ<= 4965
replace occ_category = 7 if occ >= 5000 & occ<= 5940
replace occ_category = 8 if occ >= 6000 & occ<= 6130
replace occ_category = 9 if occ >= 6200 & occ<= 6950
replace occ_category = 10 if occ >= 7000 & occ<= 7640
replace occ_category = 11 if occ >= 7700 & occ<= 8990
replace occ_category = 12 if occ >= 9000 & occ<= 9920


label define occ_category_label 1 "Management, Business, and Financial Occupations" 2 "Computer, Engineering, and Science Occupations" 3 "Education, Legal, Community Service, Arts, and Media Occupations" 4 "Healthcare Practitioners and Technical Occupations" 5 "Service Occupations" 6 "Sales and Related Occupations" 7 "Office and Administrative Support Occupations" 8 "Farming, Fishing, and Forestry Occupations" 9 "Construction and Extraction Occupations" 10 "Installation, Maintenance, and Repair Occupations" 11 "Production Occupations" 12 "Transportation and Material Moving Occupations"
label values occ_category occ_category_label 


gen stem_deg= degfieldd==1100 |	degfieldd==1103 |	degfieldd==1104 |	degfieldd==1105 |	degfieldd==1106 |	degfieldd==1199 |	degfieldd==1300 |	degfieldd==1301 |	degfieldd==1401 |	degfieldd==2001 |	degfieldd==2100 |	degfieldd==2101 |	degfieldd==2102 |	degfieldd==2105 |	degfieldd==2106 |	degfieldd==2107 |	degfieldd==2400 |	degfieldd==2401 |	degfieldd==2402 |	degfieldd==2403 |	degfieldd==2404 |	degfieldd==2405 |	degfieldd==2406 |	degfieldd==2407 |	degfieldd==2408 |	degfieldd==2409 |	degfieldd==2410 |	degfieldd==2411 |	degfieldd==2412 |	degfieldd==2413 |	degfieldd==2414 |	degfieldd==2415 |	degfieldd==2416 |	degfieldd==2417 |	degfieldd==2418 |	degfieldd==2419 |	degfieldd==2499 |	degfieldd==2500 |	degfieldd==2502 |	degfieldd==2503 |	degfieldd==2504 |	degfieldd==2599 |	degfieldd==3600 |	degfieldd==3601 |	degfieldd==3602 |	degfieldd==3603 |	degfieldd==3604 |	degfieldd==3605 |	degfieldd==3606 |	degfieldd==3607 |	degfieldd==3608 |	degfieldd==3609 |	degfieldd==3611 |	degfieldd==3699 |	degfieldd==3700 |	degfieldd==3701 |	degfieldd==3702 |	degfieldd==4002 |	degfieldd==4003 |	degfieldd==4005 |	degfieldd==4006 |	degfieldd==5000 |	degfieldd==5001 |	degfieldd==5002 |	degfieldd==5003 |	degfieldd==5004 |	degfieldd==5005 |	degfieldd==5006 |	degfieldd==5007 |	degfieldd==5008 |	degfieldd==5098 |	degfieldd==5102 |	degfieldd==5202 |	degfieldd==5701 |	degfieldd==5901 |	degfieldd==6100 |	degfieldd==6102 |	degfieldd==6103 |	degfieldd==6104 |	degfieldd==6105 |	degfieldd==6106 |	degfieldd==6107 |	degfieldd==6108 |	degfieldd==6109 |	degfieldd==6110 |	degfieldd==6199

* Stata code to classify degree fields based on PUMS codes
* This handles both 2009 and 2010+ coding systems

* First, create a variable to indicate which system to use
* You should modify this based on your data - either set directly or use a condition
gen byte coding_system = .
label var coding_system "Degree field coding system"
label define coding_lbl 1 "2009 System" 2 "2010+ System"
label values coding_system coding_lbl

* Uncomment and modify one of these approaches:
*Option 1: Set coding system based on survey year (if available in your data)
 replace coding_system = 1 if year == 2009
 replace coding_system = 2 if year >= 2010

* Option 2: Or manually set which coding system to use
* replace coding_system = 1 // Use 2009 system
* replace coding_system = 2 // Use 2010+ system

* Create variables for degree field groups
gen degfield_group = .
label var degfield_group "Degree Field Classification"

gen degfield_broader = .
label var degfield_broader "Broader Degree Field Classification"

* ===== 2009 CODING SYSTEM =====
if 1 {
    * Group 1: Computers, Mathematics and Statistics (2009)
    replace degfield_group = 1 if inlist(degfieldd, 2100, 2102, 2105, 2106, 2107, 3700, 3701, 3702) & coding_system == 1

    * Group 2: Biological, Agricultural, and Environmental Sciences (2009)
    replace degfield_group = 2 if inlist(degfieldd, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1199, ///
                                         1301, 1302, 1303, 3600, 3601, 3602, 3603, 3604, 3605, ///
                                         3606, 3607, 3608, 3609, 3699) & coding_system == 1

    * Group 3: Physical and Related Science (2009)
    replace degfield_group = 3 if inlist(degfieldd, 5000, 5001, 5002, 5003, 5004, 5005, 5006, 5007) ///
                                & coding_system == 1

    * Group 4: Psychology (2009)
    replace degfield_group = 4 if inlist(degfieldd, 5200, 5201, 5202, 5203, 5205, 5206, 5299) ///
                                & coding_system == 1

    * Group 5: Social Science (2009)
    replace degfield_group = 5 if inlist(degfieldd, 1501, 5500, 5501, 5502, 5503, 5504, 5505, 5506, 5507, 5599) ///
                                & coding_system == 1

    * Group 6: Engineering (2009)
    replace degfield_group = 6 if inlist(degfieldd, 2400, 2401, 2402, 2403, 2404, 2405, 2406, 2407, 2408, 2409, ///
                                         2410, 2411, 2412, 2413, 2414, 2415, 2416, 2417, 2418, 2419, 2499) ///
                                & coding_system == 1

    * Group 7: Multidisciplinary Studies (2009)
    replace degfield_group = 7 if inlist(degfieldd, 4001, 4002, 4003, 4005, 4006, 4007, 4008) ///
                                & coding_system == 1

    * Group 8: Science and Engineering Related Fields (2009)
    replace degfield_group = 8 if inlist(degfieldd, 1401, 2101, 2305, 2308, 2500, 2501, 2502, 2503, 2504, 2599, ///
                                         5102, 6100, 6102, 6103, 6104, 6105, 6106, 6107, 6108, 6109, 6110, 6199) ///
                                & coding_system == 1

    * Group 9: Business (2009)
    replace degfield_group = 9 if inlist(degfieldd, 3201, 6200, 6201, 6202, 6203, 6204, 6205, 6206, 6207, 6209, ///
                                         6210, 6211, 6212, 6299) ///
                                & coding_system == 1

    * Group 10: Education (2009)
    replace degfield_group = 10 if inlist(degfieldd, 2300, 2301, 2303, 2304, 2306, 2307, 2309, 2310, 2311, 2312, ///
                                          2313, 2314, 2399) ///
                                & coding_system == 1

    * Group 11: Literature and Languages (2009)
    replace degfield_group = 11 if inlist(degfieldd, 2601, 2602, 2603, 3301, 3302) ///
                                 & coding_system == 1

    * Group 12: Liberal Arts and History (2009)
    replace degfield_group = 12 if inlist(degfieldd, 3401, 3402, 4801, 4901, 6402, 6403) ///
                                 & coding_system == 1

    * Group 13: Visual and Performing Arts (2009)
    replace degfield_group = 13 if inlist(degfieldd, 6000, 6001, 6002, 6003, 6004, 6005, 6006, 6007, 6099) ///
                                 & coding_system == 1

    * Group 14: Communications (2009)
    replace degfield_group = 14 if inlist(degfieldd, 1901, 1902, 1903, 1904, 2001) ///
                                 & coding_system == 1

    * Group 15: Other (2009)
    replace degfield_group = 15 if inlist(degfieldd, 2201, 2901, 3202, 3501, 3801, 4101, 5301, 5401, 5402, 5403, ///
                                          5404, 5601, 5701, 5901) ///
                                 & coding_system == 1
}

* ===== 2010+ CODING SYSTEM =====
if 2 {
    * Group 1: Computers, Mathematics and Statistics (2010+)
    replace degfield_group = 1 if inlist(degfieldd, 2100, 2102, 2105, 2106, 2107, 3700, 3701, 3702) ///
                                & coding_system == 2

    * Group 2: Biological, Agricultural, and Environmental Sciences (2010+)
    replace degfield_group = 2 if inlist(degfieldd, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1199, ///
                                         1301, 1302, 1303, 3600, 3601, 3602, 3603, 3604, 3605, ///
                                         3606, 3607, 3608, 3609, 3611, 3699) ///
                                & coding_system == 2

    * Group 3: Physical and Related Science (2010+)
    replace degfield_group = 3 if inlist(degfieldd, 5000, 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5098) ///
                                & coding_system == 2

    * Group 4: Psychology (2010+)
    replace degfield_group = 4 if inlist(degfieldd, 5200, 5201, 5202, 5203, 5205, 5206, 5299) ///
                                & coding_system == 2

    * Group 5: Social Science (2010+)
    replace degfield_group = 5 if inlist(degfieldd, 1501, 5500, 5501, 5502, 5503, 5504, 5505, 5506, 5507, 5599) ///
                                & coding_system == 2

    * Group 6: Engineering (2010+)
    replace degfield_group = 6 if inlist(degfieldd, 2400, 2401, 2402, 2403, 2404, 2405, 2406, 2407, 2408, 2409, ///
                                         2410, 2411, 2412, 2413, 2414, 2415, 2416, 2417, 2418, 2419, 2499) ///
                                & coding_system == 2

    * Group 7: Multidisciplinary Studies (2010+)
    replace degfield_group = 7 if inlist(degfieldd, 4000, 4001, 4002, 4005, 4006, 4007) ///
                                & coding_system == 2

    * Group 8: Science and Engineering Related Fields (2010+)
    replace degfield_group = 8 if inlist(degfieldd, 1401, 2101, 2305, 2308, 2500, 2501, 2502, 2503, 2504, 2599, ///
                                         5102, 6100, 6102, 6103, 6104, 6105, 6106, 6107, 6108, 6109, 6110, 6199) ///
                                & coding_system == 2

    * Group 9: Business (2010+)
    replace degfield_group = 9 if inlist(degfieldd, 3201, 6200, 6201, 6202, 6203, 6204, 6205, 6206, 6207, 6209, ///
                                         6210, 6211, 6212, 6299) ///
                                & coding_system == 2

    * Group 10: Education (2010+)
    replace degfield_group = 10 if inlist(degfieldd, 2300, 2301, 2303, 2304, 2306, 2307, 2309, 2310, 2311, 2312, ///
                                          2313, 2314, 2399) ///
                                 & coding_system == 2

    * Group 11: Literature and Languages (2010+)
    replace degfield_group = 11 if inlist(degfieldd, 2601, 2602, 2603, 3301, 3302) ///
                                 & coding_system == 2

    * Group 12: Liberal Arts and History (2010+)
    replace degfield_group = 12 if inlist(degfieldd, 3401, 3402, 4801, 4901, 6402, 6403) ///
                                 & coding_system == 2

    * Group 13: Visual and Performing Arts (2010+)
    replace degfield_group = 13 if inlist(degfieldd, 6000, 6001, 6002, 6003, 6004, 6005, 6006, 6007, 6099) ///
                                 & coding_system == 2

    * Group 14: Communications (2010+)
    replace degfield_group = 14 if inlist(degfieldd, 1901, 1902, 1903, 1904, 2001) ///
                                 & coding_system == 2

    * Group 15: Other (2010+)
    replace degfield_group = 15 if inlist(degfieldd, 2201, 2901, 3202, 3501, 3801, 4101, 5301, 5401, 5402, 5403, ///
                                          5404, 5601, 5701, 5901) ///
                                 & coding_system == 2
}

* Add value labels
label define degfield_group_lbl 1 "Computers, Mathematics and Statistics" ///
                             2 "Biological, Agricultural, and Environmental Sciences" ///
                             3 "Physical and Related Science" ///
                             4 "Psychology" ///
                             5 "Social Science" ///
                             6 "Engineering" ///
                             7 "Multidisciplinary Studies" ///
                             8 "Science and Engineering Related Fields" ///
                             9 "Business" ///
                             10 "Education" ///
                             11 "Literature and Languages" ///
                             12 "Liberal Arts and History" ///
                             13 "Visual and Performing Arts" ///
                             14 "Communications" ///
                             15 "Other"

label values degfield_group degfield_group_lbl

* Create a broader classification
replace degfield_broader = 1 if inrange(degfield_group, 1, 7) /* Science and Engineering Group */
replace degfield_broader = 2 if degfield_group == 8 /* Science and Engineering Related Fields */
replace degfield_broader = 3 if degfield_group == 9 /* Business */
replace degfield_broader = 4 if degfield_group == 10 /* Education */
replace degfield_broader = 5 if inrange(degfield_group, 11, 15) /* Arts, Humanities, and Other */

label define degfield_broader_lbl 1 "Science and Engineering Group" ///
                                2 "Science and Engineering Related Fields" ///
                                3 "Business" ///
                                4 "Education" ///
                                5 "Arts, Humanities, and Other"

label values degfield_broader degfield_broader_lbl

* ===== Check for differences between 2009 and 2010+ systems =====
di as text _newline "Key differences between 2009 and 2010+ coding systems:"
di as text "1. Group 2 (Bio/Ag/Env Sciences): 2010+ adds code 3611 (Neuroscience)"
di as text "2. Group 3 (Physical Sciences): 2010+ adds codes 5008 (Materials Science) and 5098 (Multi-Disciplinary Science)"
di as text "3. Group 7 (Multidisciplinary): 2010+ adds code 4000 (Multi-Disciplinary Studies)"
di as text "4. Group 7 (Multidisciplinary): 2010+ removes code 4008 (Multi-Disciplinary Science) - moved to Group 3"
di as text "5. Group 7 (Multidisciplinary): 2010+ removes code 4003 (Neuroscience) - moved to Group 2"

* Create tables to check results
tab degfield_group coding_system, missing
tab degfield_broader coding_system, missing

* For a detailed check, you can list specific cases
* list degfieldd degfield_group degfield_broader coding_system if missing(degfield_group)


gen twentytwo_by_2012 = 1 if (2012 - birthyr)>=22
replace twentytwo_by_2012 = 0 if (2012-birthyr)<22



drop educd grad*

export delimited using "G:\Shared drives\Undocu Research\Data\ACS_foreign_noncit_age.csv"

