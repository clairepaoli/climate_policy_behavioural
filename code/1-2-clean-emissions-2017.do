********************************************************************************
* 1.2 2017 emissions
* Author: Claire Paoli
* Date: March 2021
* Objective: clean emissions data for 2017 that will then be merged with simulation dataset
* in "5-prepare-simulation-data"
********************************************************************************

clear all
capture log close
set type double
set more off

global path "/Volumes/My Passport for Mac/Research/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/raw"
global temp "$path/temp"
global clean "$path/clean"

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
use "$clean/clean.dta", clear

** Reaggregated Commodities (7 Groups);
** Food: food + alcohol
** Heating: gas + solid fuels + liquid fuels + electricity
** Housing: water + rent + maint
** Transport: 72 air rail road sea transport_other
** Services: comm + educ + health
** Durables: furnishing + clothing
** Other: Other + Recreation + Restaurants

merge m:1 year using "$clean/emissions.dta"
drop if _merge==2
drop _merge

append using "$clean/emissions_2017.dta"

foreach var of varlist c1111_co2-c12535_co2{
replace `var'=`var'[_N]
}

drop if hh_id==.

** Aggregate expenditure variables
g xfood = xfood_only + xalc
g xtransport_tot = xtransport
replace xtransport = xt72 + xair + xrail + xroad + xsea + xtransport_other
g xheating = xgas + xcoal + xfuels + xelec
g xhousing = xhouse - xheating
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
g elec_emi = xelec * c441_co2 
g furn_emi = xfurn * c05_intensity
g cloth_emi = xcloth * c03_intensity
g gas_emi = xgas * c442_co2
g coal_emi = xcoal * c4431_co2
g fuels_emi = xfuels * c4432_co2
g t71_emi = (c71112t+c71122t+c71212t) * c7111_co2 + (c71311t+c71411t)*c7131_co2
g t72_emi = (c71311t+c71411t+c72111t+c72112t+c72113t+c72114t+c72115t)* c7211_co2 + c72211t*c7221_co2 + (c72212t+c72213t)*c7222_co2 + (c72313t+c72314t+c72411t+c72412t)*c7241_co2 + (c72413t+c72114t)*c7244_co2
g t73_emi = xair*c7341_co2 + xrail*c7311_co2 + xroad*c7321_co2 + xsea*c7348_co2 + (c73512t*c7331_co2 + c73513t*c7343_co2 + c73611t*c7345_co2)

* Product carbon intensity;
g food_only_intensity = c01_intensity
g alc_intensity = c02_intensity
g gas_intensity = c442_co2
g coal_intensity = c4431_co2
g fuels_intensity = c4432_co2
g elec_intensity = c441_co2
g air_intensity = c7341_co2
g rail_intensity = c7311_co2
g road_intensity = c7321_co2
g sea_intensity = c7348_co2
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
g transport_other_intensity = (c73512t*c7331_co2 + c73513t*c7343_co2 + c73611t*c7345_co2)/xtransport_other

foreach var of varlist t71_intensity t72_intensity transport_other_intensity {
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

xtile inc_quint = income_wk_tot [pw=new_weight], nq(5)

set scheme s2color
graph bar (mean) food_emi heating_emi transport_emi housing_emi serv_emi dur_emi other_emi if year==2017, over(inc_quint) ytitle("kgCO2e") stack

set scheme s2color
graph bar (mean) food_int_c heating_int_c transport_int_c housing_int_c serv_int_c dur_int_c other_int_c if year==2017, by(inc_quint) ytitle("kgCO2e per £") 

graph bar (mean) food_int_c heating_int_c transport_int_c housing_int_c serv_int_c dur_int_c other_int_c if year==2017, over(inc_quint) ytitle("kgCO2e per £") stack

graph bar bsxgas bsxcoal bsxfuels bsxelec, over(inc_quint) stack ytitle("Heating Share")

keep LCF_round year hh_id food_emi elec_emi heating_emi transport_emi housing_emi serv_emi dur_emi other_emi tot_hh_footprint food_int_c-other_int_c food_only_intensity-transport_other_intensity

sort LCF_round year hh_id

save "$clean/data_emissions.dta", replace

