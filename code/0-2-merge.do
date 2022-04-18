*******************************************************************************;
* 0. Merge household data with CPI and emissions data
* Author: Claire Paoli
* Date: March 2021
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

global path "/Volumes/My Passport for Mac/Research/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/raw"
global temp "$path/temp"
global clean "$path/clean"

*******************************************************************************;
* Merge hh level and person level datasets;
*******************************************************************************;

local years "2006 2007 2008 2009 2010 2011 2012 2013 2014 2018"

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



*******************************************************************************;
* Append merged datasets into complete series;
*******************************************************************************;

cd "$temp/temp2"

* Use macro to append files
local i: dir . file *
tokenize `"`i'"'
use `1', clear
local j=2
while `"``j''"'~="" {
append using  ``j'', force
 local j = `j'+1
  }
  
rename case hh_id

* Time
order year, after(hh_id)
order a099, after(year)
rename a099 quarter
order a055, after(quarter)
rename a055 month

save "$clean/merged.dta", replace


*******************************************************************************;
** Merge CPI prices;
*******************************************************************************;

use "$clean/merged.dta", clear
merge m:1 year month using "$temp/temp1/prices_monthly.dta"

drop if _merge !=3
drop _merge
drop month2

*******************************************************************************;
** Merge emissions data; NO -- DO LATER;
*******************************************************************************;
* merge m:1 year using "$clean/emissions.dta"
* tab year if _merge == 1
* Note that hhs not merged correspond to those in the LCF 2017 and 2018 rounds who
* were interviewed in 2018 and 2019.

* drop if _merge!=3
* drop _merge

save "$clean/merged.dta", replace

