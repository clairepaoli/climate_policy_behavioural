*******************************************************************************;
* 0. Clean emissions data
* Author: Claire Paoli
* Date: March 2023 
	* Updated Feb 2025
* Objective: clean raw data on emissions, saving outputs as two datasets "emissions"
* and "emissions_2019"
*******************************************************************************;

clear all
capture log close
set type double
set more off

global path "/Volumes/Untitled/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/01-raw"
global temp "$path/02-temp"
global clean "$path/03-clean"

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

* Take 2019 intensity factors

* End goal: carbon intensity metric by aggregate COICOP groups and disaggregated for two groups

*******************************************************************************;
* GHGs by aggregate COICOP group 1998-2019;
*******************************************************************************;

*********** Total annual emissions by COICOP group;
// import excel "$raw/0-carbon-emissions/carbon_emissions.xlsx", sheet("GHG - Ktonnes CO2e") cellrange(A2:AI30) firstrow clear

* Updated to include data for 2020 - 2021; most recent emissions estimated for 2021;

import excel "$raw/0-carbon-emissions/1_raw/UK_full_dataset_1990_to_2021__including_conversion_factors_by_SIC_code.xlsx", sheet("Summary_product_90-21") cellrange(B2:AK35) firstrow clear
rename B year
rename *, lower
drop if year == .

// rename food                              c011
// rename nonalcoholicbeverages            c012
// rename alcoholicbeverages               c021
// rename tobacco                          c022
// rename clothing                         c031
// rename footwear                         c032
// rename actualrentalsforhouseholds       c041
// rename imputedrentalsforhouseholds      c042
// rename maintenanceandrepairofthedw      c043
// rename watersupplyandmiscellaneousd     c044
// rename electricitygasandotherfuels      c045
// rename furniturefurnishingscarpets      c051
// rename householdtextiles                c052
// rename householdappliances              c053
// rename glasswaretablewareandhouseho     c054
// rename toolsandequipmentforhousean      c055
// rename goodsandservicesforhousehold     c056
// rename medicalproductsappliancesand     c061
// rename outpatientservices               c062
// rename hospitalservices                 c063
// rename purchaseofvehicles               c071
// rename operationofpersonaltransport     c072
// rename transportservices                c073
// rename postalservices                   c081
// rename telephoneandtelefaxequipment     c082
// rename telephoneandtelefaxservices      c083
// rename audiovisualphotoandinfopro       c091
// rename othermajordurablesforrecreat     c092
// rename otherrecreationalequipmentetc    c093
// rename recreationalandculturalservic    c094
// rename newspapersbooksandstationery     c095
// rename education                        c10
// rename restaurantsandhotels             c11
// rename miscellaneousgoodsandservices    c12

destring *, replace

// g c01 = c011 + c012
// g c02 = c021 + c022
// g c03 = c031 + c032
// egen c04 = rowtotal(c041-c045)
// egen c05 = rowtotal(c051-c056)
// egen c06 = rowtotal(c061-c063)
// egen c07 = rowtotal(c071-c073)
// egen c08 = rowtotal(c081-c083)
// egen c09 = rowtotal(c091-c095)

save "$raw/0-carbon-emissions/2_clean/2025.02.21_carbon_emissions.dta", replace

************ HH Spending, Blue Book 2024;
* Source: https://www.ons.gov.uk/economy/nationalaccounts/satelliteaccounts/bulletins/consumertrends/julytoseptember2024
* Units: £ 

* Aggregate spending by UK hhs; 1997-2023;
import excel "$raw/1-household-spending/uk-total/_raw/cvmnsa.xlsx", sheet("0KN") cellrange(A9:P35) clear
rename (A B C D E F G H I J K L M N O P) ///
       (year  tot_exp net_tour tot_uk_exp c01  c02 c03 c04 c05  c06  c07  c08  c09  c10  c11  c12)

save "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp.dta", replace

* Disaggregate spending on housing;
import excel "$raw/1-household-spending/uk-total/_raw/cvmnsa.xlsx", sheet("04KN") cellrange(A9:U35) clear
rename (A B C D E F G H I J K L M N O P Q R S T U) ///
       (year c04 c41 c411 c412 c42 c421	c422 c43 c431 c432 c44 c441	c442 c443 c444 c45 c451	c452 c453 c454)
drop c444
save "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp_4.dta", replace

* Disaggregate spending on transport;
import excel "$raw/1-household-spending/uk-total/_raw/cvmnsa.xlsx", sheet("07KN") cellrange(A9:Q35) clear
rename (A B C D E F G H I J K L M N O P Q) ///
       (year c07 c71 c711 c712 c713	c72	c721 c722 c723 c724	c73	c731 c732 c733 c734	c736)

save "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp_7.dta", replace

use "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp.dta", clear
merge 1:1 year using "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp_7.dta"
drop _merge
merge 1:1 year using "$raw/1-household-spending/uk-total/_temp/2025.02.22_temp_4.dta"
drop _merge

foreach x of var c* { 
	rename `x' `x'_exp 
}

save "$raw/1-household-spending/uk-total/_clean/2025.02.22_tot_spending.dta", replace

*********** Emissions + Spending;
use "$raw/0-carbon-emissions/2_clean/2025.02.21_carbon_emissions.dta", clear
merge 1:1 year using "$raw/1-household-spending/uk-total/_clean/2025.02.22_tot_spending.dta"
drop _merge
keep if inrange(year, 1997, 2021)

save "$raw/1-household-spending/uk-total/_clean/2025.02.22_spending_emissions.dta", replace

*********** Emissions + Spending + CPI;
use "$raw/1-household-spending/uk-total/_clean/2025.02.22_spending_emissions.dta", clear
merge 1:1 year using "$raw/2-prices/2_clean/2025.02.22_prices_yearly.dta"
drop if _merge==2
drop _merge

********** Totals;
drop if year<1998

rename food c011_emissions
rename nonalcoholicbeverages c012_emissions
egen c01_emissions = rowtotal(c011_emissions c012_emissions)

rename alcoholicbeverages c021_emissions
rename tobacco c022_emissions
egen c02_emissions = rowtotal(c021_emissions c022_emissions)

rename clothing c031_emissions
rename footwear c032_emissions
egen c03_emissions = rowtotal(c031_emissions c032_emissions)

rename actualrentalsforhouseholds c041_emissions
rename imputedrentalsforhouseholds c042_emissions
rename maintenanceandrepairofthedw c043_emissions
rename watersupplyandmiscellaneousd c044_emissions
rename electricitygasandotherfuels c045_emissions
egen c04_emissions = rowtotal(c041_emissions c042_emissions c043_emissions c044_emissions c045_emissions)

rename furniturefurnishingscarpets c051_emissions
rename householdtextiles c052_emissions
rename householdappliances c053_emissions
rename glasswaretablewareandhouseho c054_emissions
rename toolsandequipmentforhousean c055_emissions
rename goodsandservicesforhousehold c056_emissions
egen c05_emissions = rowtotal(c051_emissions c052_emissions c053_emissions c054_emissions c055_emissions c056_emissions)

rename medicalproductsappliancesand c061_emissions
rename outpatientservices c062_emissions
rename hospitalservices c063_emissions
egen c06_emissions = rowtotal(c061_emissions c062_emissions c063_emissions)

rename purchaseofvehicles c071_emissions
rename operationofpersonaltransport c072_emissions
rename transportservices c073_emissions
egen c07_emissions = rowtotal(c071_emissions c072_emissions c073_emissions)

rename postalservices c081_emissions
rename telephoneandtelefaxequipment c082_emissions
rename telephoneandtelefaxservices c083_emissions
egen c08_emissions = rowtotal(c081_emissions c082_emissions c083_emissions)

rename audiovisualphotoandinfopro c091_emissions
rename othermajordurablesforrecreat c092_emissions
rename otherrecreationalequipmentetc c093_emissions
rename recreationalandculturalservic c094_emissions
rename newspapersbooksandstationery c095_emissions
egen c09_emissions = rowtotal(c091_emissions-c095_emissions)

rename education c10_emissions
rename restaurantsandhotels c11_emissions
rename miscellaneousgoodsandservices c12_emissions
rename total total_emissions

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
	
save "$clean/2025.02.22_emissions.dta", replace	
	
// ********** Impute values;
// * Note: we essentially will assume coefficients corresponding to the year 2021
// * for our simulations. As we will use the sample of households interviewed in
// * LCF round 2018-2019, some households will be interviewed in 2018. To avoid dropping 
// * these households, we impute 2019 values in 2018 and 2020 (for completeness).
 
// expand 2 in l
// expand 2 in l
// replace year = 2018 in 21
// replace year = 2020 in 22
 
// save "$clean/emissions.dta", replace

*******************************************************************************;
* GHGs by disaggregated COICOP group, 2001-2021;
*******************************************************************************;
* These are taken from the UK National Statistics tables as could not find total 
* emissions for these subcategories.

// import excel "$raw/0-carbon-emissions/1_raw/2019_Defra_results_UK.xlsx", sheet("COICOP_multipliers_2019") cellrange(B2:D112) firstrow clear
// rename B COICP_cat

// save "$temp/emissions_2019.dta", replace

import excel "$raw/0-carbon-emissions/1_raw/UK_full_dataset_1990_to_2021__including_conversion_factors_by_SIC_code.xlsx", sheet("ghg_coicop_mult") clear
rename (A B C D E F G H I J K L M N O P Q R S T U V) ///
	   (COICP_cat ghg_gbp_2001 ghg_gbp_2002 ghg_gbp_2003 ghg_gbp_2004 ghg_gbp_2005 ///
	   ghg_gbp_2006 ghg_gbp_2007 ghg_gbp_2008 ghg_gbp_2009 ghg_gbp_2010 ghg_gbp_2011 ///
	   ghg_gbp_2012 ghg_gbp_2013 ghg_gbp_2014 ghg_gbp_2015 ghg_gbp_2016 ghg_gbp_2017 ///
	   ghg_gbp_2018 ghg_gbp_2019 ghg_gbp_2020 ghg_gbp_2021)
	   
drop if COICP_cat == ""

rename ghg_gbp_* ghg_*
reshape long ghg_, i(COICP_cat) j(year) string
destring year, replace
rename ghg_ ghg_per_gbp

* Pull out everything before the first space
gen str20 cat_num = word(COICP_cat, 1)
* cat_num should be things like "7.1.1", "7.1.2", etc.

* Replace periods "." with underscores "_"
replace cat_num = subinstr(cat_num, ".", "", .)

* Build a short code: c711_ghg_per_gbp
gen str30 cat_code = "_c" + cat_num
encode cat_code, gen(catnum)

drop COICP_cat catnum cat_num
reshape wide ghg_per_gbp, i(year) j(cat_code) string

save "$clean/2025.02.26_carbon_intensity_2001_2021.dta", replace








