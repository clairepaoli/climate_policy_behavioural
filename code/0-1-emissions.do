*******************************************************************************;
* 0. Clean emissions data
* Author: Claire Paoli
* Date: March 2021
* Objective: clean raw data on emissions, saving outputs as two datasets "emissions"
* and "emissions_2017"
*******************************************************************************;

clear all
capture log close
set type double
set more off

global path "/Volumes/My Passport for Mac/Research/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/raw"
global temp "$path/temp"
global clean "$path/clean"

cd "$path"

* Two ways of calculating GHG emissions:
	* 1) (Aggregate) Compute total hh expenditures by COICOP category from survey; divide total GHG emissions by this number for average intensity by COICOP group
	* 2) (Specific products) Conversion factors by disaggregated products, provided by UK Govt
	
* Create aggregate tables with:
** By year and COICOP group:
**** Exp. (£ million), GHG (Ktonnes CO2e), GHG Intensity, CPI
	
* Create disaggregated tables for Housing and Transport:
** By year and COICOP subgroup within Housing and Trasport:
**** Exp. (£ million), GHG (Ktonnes CO2e), GHG Intensity, CPI

* Take 2017 intensity factors for 

* End goal: carbon intensity metric by aggregate COICOP groups and disaggregated for two groups

*******************************************************************************;
* GHGs by aggregate COICOP group 1998-2017;
*******************************************************************************;

*********** Emissions;
import excel "$raw/0-carbon-emissions/carbon_emissions.xlsx", sheet("GHG - Ktonnes CO2e") cellrange(A2:AI30) firstrow clear

g c01 = c011 + c012
g c02 = c021 + c022
g c03 = c031 + c032
egen c04 = rowtotal(c041-c045)
egen c05 = rowtotal(c051-c056)
egen c06 = rowtotal(c061-c063)
egen c07 = rowtotal(c071-c073)
egen c08 = rowtotal(c081-c083)
egen c09 = rowtotal(c091-c095)

foreach x of var c* { 
	rename `x' `x'_emissions 
}
rename total total_emissions
save "$raw/0-carbon-emissions/carbon_emissions.dta", replace

************ HH Spending;

* Aggregate spending by UK hhs;
import excel "$raw/1-household-spending/uk-total/uk_spending.xlsx", sheet("tot") cellrange(A4:P27) firstrow clear
save "$raw/1-household-spending/uk-total/temp.dta", replace

* Disaggregate spending on housing;
import excel "$raw/1-household-spending/uk-total/uk_spending.xlsx", sheet("4") cellrange(A3:V26) firstrow clear
save "$raw/1-household-spending/uk-total/temp_4.dta", replace

import excel "$raw/1-household-spending/uk-total/uk_spending.xlsx", sheet("7") cellrange(A3:Q26) firstrow clear
save "$raw/1-household-spending/uk-total/temp_7.dta", replace

use "$raw/1-household-spending/uk-total/temp.dta", clear
merge 1:1 year using "$raw/1-household-spending/uk-total/temp_7.dta"
drop _merge
merge 1:1 year using "$raw/1-household-spending/uk-total/temp_4.dta"
drop _merge

foreach x of var c* { 
	rename `x' `x'_exp 
}

save "$raw/1-household-spending/uk-total/tot_spending.dta", replace

*********** Emissions + Spending;
use "$raw/0-carbon-emissions/carbon_emissions.dta", clear
merge 1:1 year using "$raw/1-household-spending/uk-total/tot_spending.dta"
drop _merge
save "$raw/1-household-spending/uk-total/temp_spending.dta", replace

*********** Emissions + Spending + CPI;
use "$raw/1-household-spending/uk-total/temp_spending.dta", clear
merge 1:1 year using "$raw/2-prices/prices_yearly.dta"
drop if _merge==2
drop _merge

********** Totals;
keep year c10_emissions-c09_emissions tot_exp-c12_exp CPI_6-CPI_7 c041_emissions-c045_emissions c41_exp c42_exp c43_exp c44_exp c45_exp c451_exp c452_exp c453_exp c454_exp c455_exp CPI_41 CPI_43 CPI_44 CPI_45 CPI_454 CPI_453 CPI_452 CPI_451 CPI_441
drop if year<1998
drop if year>2017

order tot_uk_exp total_emissions, after(year)
order c01_exp c01_emissions CPI_1, after(total_emissions)
order c02_exp c02_emissions CPI_2, after(CPI_1)
order c03_exp c03_emissions CPI_3, after(CPI_2)
order c04_exp c04_emissions CPI_4, after(CPI_3)
order c05_exp c05_emissions CPI_5, after(CPI_4)
order c06_exp c06_emissions CPI_6, after(CPI_5)
order c07_exp c07_emissions CPI_7, after(CPI_6)
order c08_exp c08_emissions CPI_8, after(CPI_7)
order c09_exp c09_emissions CPI_9, after(CPI_8)
order c10_exp c10_emissions CPI_10, after(CPI_9)
order c11_exp c11_emissions CPI_11, after(CPI_10)
order c12_exp c12_emissions CPI_12, after(CPI_11)

order c41_exp c041_emissions CPI_41, after(CPI_12)
order c42_exp c042_emissions, after(CPI_41)
order c43_exp c043_emissions CPI_43, after(c042_emissions)
order c44_exp c044_emissions CPI_44, after(CPI_43)
order c45_exp c045_emissions CPI_45, after(CPI_44)

order c451_exp CPI_451, after(CPI_45)
order c452_exp CPI_452, after(CPI_451)
order c453_exp CPI_453, after(CPI_452)
order c454_exp CPI_454, after(CPI_453)

********** Create intensity coefficient;
* Recall Ktonnes GHG and million £ -- convert to kg and £
local vars "1 2 3 4 5 6 7 8 9" 
local vars2 "10 11 12"
local vars3 "41 43 44 45"

	foreach j in `vars'{
	g c0`j'_intensity = (c0`j'_emissions*1000000)/(c0`j'_exp*1000000)
	}
	
	foreach j in `vars2'{
	g c`j'_intensity = (c`j'_emissions*1000000)/(c`j'_exp*1000000)
	}

	foreach j in `vars3'{
	g c0`j'_intensity = (c0`j'_emissions*1000000)/(c`j'_exp*1000000)
	}
	
	
********** Impute values;
* Note: we essentially will assume coefficients corresponding to the year 2017
* for our simulations. As we will use the sample of households interviewed in
* LCF round 2017-2018, some households will be interviewed in 2018. To avoid dropping 
* these households, we impute 2017 values in 2018 and 2019 (for completeness).
 
expand 2 in l
expand 2 in l
replace year = 2018 in 21
replace year = 2019 in 22
 
save "$clean/emissions.dta", replace

*******************************************************************************;
* GHGs by specific COICOP group, 2017;
*******************************************************************************;
* These are taken from the UK National Statistics tables as could not find total 
* emissions for these subcategories.

import excel "$raw/0-carbon-emissions/carbon_emissions.xlsx", sheet("2017_coicop_clean") firstrow clear
drop cNonprofit-cChanges

rename * *_co2

save "$clean/emissions_2017.dta", replace









