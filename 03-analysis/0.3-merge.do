*******************************************************************************;
* 0. Merge household data with CPI and emissions data
* Author: Claire Paoli
* Date: March 2021 
	* Updated Feb 2025
* Objective: merge household level data with CPI and emissions, outputting a 
* dataset "merged"
*******************************************************************************;

* Living Costs and Food Survey 
* Household Questionnaire:
*** Household characteristics, ethnicity, employment details, ownership of 
*** household durables. Includes regular payments made by all households and durables.
* Income Questionnaire: Key person-level variables used in the survey. Includes 
*** income from employmet, benefits and assets. 
* Part 1 Expenditure Codes gives an indication of the types of items to be found 
*** under each expenditure code and provides a look-up table between the 
*** EFS codes (e-codes) and the COICOP-plus c-codes.

clear all
capture log close
set type double
set more off

global path "/Volumes/Untitled/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/01-raw"
global temp "$path/02-temp"
global clean "$path/03-clean"

*******************************************************************************;
* Merge hh level and person level datasets;
*******************************************************************************;

local years "2001-2002 2002-2003 2003-2004 2004-2005 2006 2007"

foreach year in `years' {
* Per level, HRP
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/`year'_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
* Note that this is = 1 if "spouse cohabitee"
keep if a002 == 1
keep case a015 a220 a221 a244 a2444 p007 p037 p047 p049 p051 p053 p188 p199 wkgross b312
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007) (a244_spouse a2444_spouse p007p_spouse)
rename (p037 p047 p051 p053 p188 wkgross b312 p049 p199) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/`year'_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/`year'tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvhh_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/`year'tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_`year'"

save "$temp/temp2/`year'_clean.dta", replace
}

local years "2005-2006"

foreach year in `years' {
* Per level, HRP
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/`year'_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
* Note that this is = 1 if "spouse cohabitee"
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007 p037 p047 p049 p051 p053 p188 p199 wkgross b312
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007) (a244_spouse a2444_spouse p007p_spouse)
rename (p037 p047 p051 p053 p188 wkgross b312 p049 p199) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/`year'_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/`year'tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-efs/`year'/`year'_dvhh_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/`year'tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_`year'"

save "$temp/temp2/`year'_clean.dta", replace
}

local years "2008 2009 2010 2011 2012 2013 2014"

foreach year in `years' {
* Per level, HRP
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/`year'_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/`year'_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/`year'tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvhh_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/`year'tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_`year'"

save "$temp/temp2/`year'_clean.dta", replace
}

* Note that, since the 2014 survey covers Jan-Dec 2014 and the 2015-2016 survey covers April 2015 to
* March 2016, we are missing three months of 2015 data.

local years "2015 2016 2017"

foreach year in `years' {
* Per level, HRP
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/`year'_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvper_ukanon.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/`year'_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/`year'_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/`year'tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/`year'/`year'_dvhh_urbanrural_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/`year'tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_`year'"

save "$temp/temp2/`year'_clean.dta", replace
}


*2018

* Per level, HRP
use "$raw/1-household-spending/uk-lsc/2018/2018_dvper_ukanon201819.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/2018_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/2018/2018_dvper_ukanon201819.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/2018_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/2018_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/2018_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/2018tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/2018/2018_dvhh_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/2018tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_2018"

save "$temp/temp2/2018_clean.dta", replace


*2019-2020

* Per level, HRP
use "$raw/1-household-spending/uk-lsc/2019-2020/lcfs_2019_dvper_ukanon201920.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/2019_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/2019-2020/lcfs_2019_dvper_ukanon201920.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/2019_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/2019_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/2019_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/2019tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/2019-2020/lcfs_2019_dvhh_urbanrural_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/2019tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_2019"

save "$temp/temp2/2019_clean.dta", replace

*2020-2021

* Per level, HRP
use "$raw/1-household-spending/uk-lsc/2020-2021/lcfs_2020_dvper_ukanon202021.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/2020_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/2020-2021/lcfs_2020_dvper_ukanon202021.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/2020_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/2020_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/2020_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/2020tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/2020-2021/lcfs_2020_dvhh_urbanrural_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/2020tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_2020"

save "$temp/temp2/2020_clean.dta", replace

*2021-2022

* Per level, HRP
use "$raw/1-household-spending/uk-lsc/2021-2022/lcfs_2021_dvper_ukanon202122.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/2021_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/2021-2022/lcfs_2021_dvper_ukanon202122.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/2021_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/2021_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/2021_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/2021tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/2021-2022/lcfs_2021_dvhh_urbanrural_ukanon.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/2021tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_2021"

save "$temp/temp2/2021_clean.dta", replace

*2022-2023

* Per level, HRP
use "$raw/1-household-spending/uk-lsc/2022-2023/dvper_ukanon_2022-23.dta", clear
rename *, lower
keep if a003 == 1
save "$temp/temp1/2022_dvper_ukanon_clean.dta", replace

* Per level, spouse
use "$raw/1-household-spending/uk-lsc/2022-2023/dvper_ukanon_2022-23.dta", clear
rename *, lower
keep if a0031 == 1
keep case a015 a220 a221 a244 a2444 p007p p037p p047p p049 p051p p053p p188p p199p wkgrossp b312p
rename a015 a015_spouse
rename a220 a220_spouse
rename a221 a221_spouse
rename (a244 a2444 p007p) (a244_spouse a2444_spouse p007p_spouse)
rename (p037p p047p p051p p053p p188p wkgrossp b312p p049 p199p) (p037p_spouse p047p_spouse p051p_spouse p053p_spouse p188p_spouse wkgrossp_spouse b312p_spouse p049_spouse p199p_spouse)
save "$temp/temp1/2022_dvper_spouse_ukanon_clean.dta", replace

** Merge individual level
use "$temp/temp1/2022_dvper_ukanon_clean.dta", clear
merge 1:1 case using "$temp/temp1/2022_dvper_spouse_ukanon_clean.dta"
drop _merge
save "$temp/temp1/2022tot.dta", replace

* HH level
use "$raw/1-household-spending/uk-lsc/2022-2023/dvhh_urbanrural_ukanon_2022.dta", clear
rename *, lower

* merge both *
merge 1:1 case using "$temp/temp1/2022tot.dta"
* all matched *
drop _merge
g LCF_round = "LCF_2022"

save "$temp/temp2/2022_clean.dta", replace

*******************************************************************************;
* Append merged datasets into complete series;
*******************************************************************************;

cd "$temp/temp2"
append using `: dir . files "*.dta"', force  
rename case hh_id

* Time
order year, after(hh_id)
order a099, after(year)
rename a099 quarter
order a055, after(quarter)
rename a055 month

save "$clean/merged.dta", replace

* check years;
tab LCF_round
tab year

* Note that in 2006, the EFS was moved from financial to calendar year.
* Therefore, the 2005-06 dataset covers April 2005 to March 2006, and the
* 2006 dataset covers Jan to Dec 2006. See https://sp.ukdataservice.ac.uk/doc/5986/mrdoc/pdf/5986_volume_a_introduction_2006.pdf.
* We keep both in the data. In LCF 2015, it seems that it was moved back to financial year. 

*******************************************************************************;
** Merge CPI prices;
*******************************************************************************;

use "$clean/merged.dta", clear

* Note LCF cases can either be processed as ‘main stage’ cases, in which case they are assigned 
* the month they appear in the interview quota and are assigned values from 1 to 12 (January to December, as you might expect).
* If the interview cannot be completed in the original quota, the case may be reissued. 
* If the reissue is successful, the month variable is then assigned a value based on the month of reissue, 
* between 21 and 32 (again, January to December). 

g month_orig = month
replace month = cond(inlist(month, 21,22,23,24,25,26,27,27,29,28,30,31,32), month - 20, month)

merge m:1 year month using "$raw/2-prices/2_clean/2025.02.22_prices_monthly.dta"
* merge m:1 year month using "$clean/2025.02.22_prices_monthly.dta"

keep if inrange(year, 2001, 2021)
* Missing three months in 2015 in LCF data.

destring CPI_*, replace

drop if _merge !=3
drop _merge

*******************************************************************************;
** Merge emissions data; NO -- DO LATER;
*******************************************************************************;
* merge m:1 year using "$clean/emissions.dta"
* tab year if _merge == 1
* Note that hhs not merged correspond to those in the LCF 2017 and 2018 rounds who
* were interviewed in 2018 and 2019.

* drop if _merge!=3
* drop _merge

save "$clean/2025.02.26_merged_wprices.dta", replace

