********************************************************************************
* 1.2 2019 emissions
* Author: Claire Paoli
* Date: May 2023
	* Updated in March 2025
* Objective: clean emissions data for 2019 that will then be merged with simulation dataset
* in "5-prepare-simulation-data"
********************************************************************************

clear all
capture log close
set type double
set more off

global path "/Volumes/Untitled/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/01-raw"
global temp "$path/02-temp"
global clean "$path/03-clean"

global var "d_* region*  month*"

global goodall "food heating transport housing serv dur other2"
global goodall_non_other "food heating transport housing serv dur"

global food "food_only alc"
global heating "gas coal fuels elec"
global transport "t72 air rail road sea transport_other"
global housing "water rent maint"
global serv "comm educ health"
global dur "furn cloth t71"
global other2 "other recr rest"
global heating2 "gas coal fuels"


********************************************************************************

use "$clean/2025.03.29_clean.dta", clear

** Reaggregated Commodities (7 Groups);
** Food: food + alcohol
** Heating: gas + solid fuels + liquid fuels + electricity
** Housing: water + rent + maint
** Transport: 72 air rail road sea transport_other
** Services: comm + educ + health
** Durables: furnishing + clothing
** Other: Other + Recreation + Restaurants

merge m:1 year using "$clean/2025.02.22_emissions.dta", force
drop if _merge==2
drop _merge

merge m:1 year using "$clean/2025.02.26_carbon_intensity_2001_2021.dta"
drop _merge

** Aggregate expenditure variables
g xfood = xfood_only + xalc
* g xtransport_tot = xtransport_calculated
g xtransport = xt72 + xair + xrail + xroad + xsea + xtransport_other
* g xheating = xgas + xcoal + xfuels + xelec (already calculated)
g xhousing = xwater + xrent + xmaint
g xserv = xcomm + xeduc + xhealth
g xdur = xfurn + xcloth + xt71
g xother2 = xother + xrecr + xrest

replace xtot = xfood + xheating + xtransport + xhousing + xserv + xdur + xother2
g xtot_ndur = xfood + xheating + xtransport + xhousing + xserv + xother2

foreach var in $heating{
g bsx`var' = x`var'/xheating
}

* HH-level emissions:
g food_only_emi = xfood_only * c01_intensity
g alc_emi = xalc * c02_intensity
g elec_emi = xelec * ghg_per_gbp_c451 
g furn_emi = xfurn * c05_intensity
g cloth_emi = xcloth * c03_intensity
g gas_emi = xgas * ghg_per_gbp_c452 
g coal_emi = xcoal * ghg_per_gbp_c454
g fuels_emi = xfuels * ghg_per_gbp_c453

* Purchase of vehicles
g t71_emi = (c71112t + c71122t + b244 + c71111c + c71121c) * ghg_per_gbp_c711 + ///
			(c71212t + b245 + c71211c) * ghg_per_gbp_c712 + ///
			(c71311t + b247) * ghg_per_gbp_c713 + ///
			c71411t * ghg_per_gbp_c714

* Operation of transport
g t72_emi = (c72111t + c72112t + c72113t + c72114t + c72115t) * ghg_per_gbp_c721 + ///
			(c72211t+c72212t+c72213t) * ghg_per_gbp_c722 + /// Keep diesel, petrol and other fuels aggregated as disaggregated values are not available
			(c72311c+c72312c+c72313t+c72314t+b249+b250+b252) * ghg_per_gbp_c723 + ///
			(c72411t+c72412t+c72413t) * ghg_per_gbp_c724

* Other transport services
g t73_emi = xair * ghg_per_gbp_c733 + ///
			xrail * ghg_per_gbp_c731_2 + ///
			xroad * ghg_per_gbp_c731_2 + ///
			xsea * ghg_per_gbp_c734 + /// Set values for "other transport services" for all below, as disaggregaged values are not available, but note that these values are quite high (42 to 25 kgGHG per gbp)
			xtransport_other * ghg_per_gbp_c734 

* Product carbon intensity;
g food_only_intensity = c01_intensity
g alc_intensity = c02_intensity
g gas_intensity = ghg_per_gbp_c452
g coal_intensity = ghg_per_gbp_c454
g fuels_intensity = ghg_per_gbp_c453
g elec_intensity = ghg_per_gbp_c451
g air_intensity = ghg_per_gbp_c733
g rail_intensity = ghg_per_gbp_c731_2
g road_intensity = ghg_per_gbp_c731_2
g sea_intensity = ghg_per_gbp_c734
g transport_other_intensity = ghg_per_gbp_c734
g water_intensity = c044_intensity
g rent_intensity = c041_intensity
g maint_intensity = c043_intensity
g comm_intensity = c08_intensity
g educ_intensity = c10_intensity
g health_intensity = c06_intensity
g furn_intensity = c05_intensity
g cloth_intensity = c03_intensity
g other_intensity = c12_intensity
g recr_intensity = c09_intensity
g rest_intensity = c11_intensity


* No aggregate intensity coeff for these categories, so create one;
g t71_intensity = t71_emi/xt71
g t72_intensity = t72_emi/xt72

foreach var of varlist t71_intensity t72_intensity {
su `var'
replace `var'= r(mean)
}

* Product Carbon Intensity: Aggregates;
* Food
g food_emi = food_only_emi + alc_emi
* Heating
g heating_emi = xgas * gas_intensity + xcoal * coal_intensity + xfuels * fuels_intensity + xelec * elec_intensity
* Electricity already defined
* Transport
g transport_emi = t72_emi + t73_emi
* Housing
g housing_emi = xwater*water_intensity + xmaint*maint_intensity + xrents*rent_intensity
* Services
g serv_emi = xcomm*comm_intensity + xeduc*educ_intensity + xhealth*health_intensity
* Durables
g dur_emi = t71_emi + xfurn*furn_intensity + xcloth*cloth_intensity
* Other 
g other_emi = xother*other_intensity + xrecr*recr_intensity + xrest*rest_intensity
* Total
g tot_hh_footprint = food_emi + heating_emi + transport_emi + housing_emi + serv_emi + dur_emi + other_emi

* HH-level emission intensity:
g food_int_c = food_emi/xfood
* Heating (including elec)
g heating_int_c = heating_emi/xheating 
* Transport
g transport_int_c = transport_emi/xtransport
* Housing
g housing_int_c = housing_emi/xhousing
* Electricity
* g elec_int = elec_emi/xelec
* Services
g serv_int_c = serv_emi/xserv
* Durables
g dur_int_c = dur_emi/xdur
* Other 
g other_int_c = other_emi/xother2

g tot_int_c = tot_hh_footprint/xtot
* recall xtot = xfood+xalc+xcloth+xhouse+xfurn+xhealth+xtransport+xcomm+xrecr+xeduc+xrest+xother

foreach var of varlist food_int_c heating_int_c transport_int_c housing_int_c serv_int_c dur_int_c other_int_c {
replace `var' = 0 if `var' ==.
}

xtile inc_quint = income_wk_tot_calculated [pw=new_weight], nq(5)

set scheme s2color
graph bar (mean) food_emi heating_emi transport_emi housing_emi serv_emi dur_emi other_emi if year==2019, over(inc_quint) ytitle("kgCO2e") stack

set scheme s2color
graph bar (mean) food_int_c heating_int_c transport_int_c housing_int_c serv_int_c dur_int_c other_int_c if year==2019, by(inc_quint) ytitle("kgCO2e per £") 

graph bar (mean) food_int_c heating_int_c transport_int_c housing_int_c serv_int_c dur_int_c other_int_c if year==2019, over(inc_quint) ytitle("kgCO2e per £") stack

graph bar bsxgas bsxcoal bsxfuels bsxelec, over(inc_quint) stack ytitle("Households' Energy Purchases")
graph bar bsxgas bsxcoal bsxfuels bsxelec, over(year) stack ytitle("Households' Energy Purchases")

keep LCF_round year hh_id ///
	 food_emi elec_emi heating_emi transport_emi housing_emi serv_emi dur_emi other_emi ///
	 tot_hh_footprint food_int_c-other_int_c ///
	 food_only_intensity-t72_intensity

sort LCF_round year hh_id

save "$clean/2025.03.29_data_wemissions.dta", replace

