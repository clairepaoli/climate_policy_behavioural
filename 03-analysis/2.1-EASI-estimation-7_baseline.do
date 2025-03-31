********************************************************************************
* 1. EASI Demand System with 7 Groups (baseline analysis) 
* Author: Claire Paoli
* Date: March 2021
	* Updated: March 2025 
* Objective: produce EASI estimates and elasticities
********************************************************************************

clear all
capture log close
set type double
set more off

global path "/Volumes/Untitled/Projects/Carbon Pricing/2-analysis"
global raw "$path/01-data/01-raw"
global temp "$path/01-data/02-temp"
global clean "$path/01-data/03-clean"

global estimates "$path/03-output/estimates"
global figures "$path/03-output/figures"
global simulation "$path/04-simulation"

global var "d_* region*  month*"
********************************************************************************
use "$clean/2025.03.29_clean.dta", clear

** 12 Commodities;
** Food
** Alcohol
** Clothing
** Housing, Water, Electricity
** Furnishing, HH Equipment, Carpets
** Health
** Transport
** Communication
** Recreation
** Education
** Restaurants and Hotels
** Others

** Disaggregate Housing, Water, Electricity;
	** Gas
	** Electricity
	** Oil (Solid and Liquid)
	** Other housing

** Reaggregated Commodities (7 Groups);
** Food: food + alcohol
** Heating: gas + solid fuels + liquid fuels + electricity
** Housing: water + rent + maint
** Transport: vehicle_maint + rail = air + road + sea + transport_other
** Services: comm + educ + health
** Durables: furnishing + clothing + vehicle
** Other: Other + Recreation + Restaurants

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


** Aggregate expenditure variables
g xfood = xfood_only + xalc
* g xtransport_tot = xtransport_calculated
g xtransport = xt72 + xair + xrail + xroad + xsea + xtransport_other
* g xheating = xgas + xcoal + xfuels + xelec (already calculated)
g xhousing = xwater + xrent + xmaint
g xserv = xcomm + xeduc + xhealth
g xdur = xfurn + xcloth + xt71
g xother2 = xother + xrecr + xrest

// su xfood xalc xcloth xhouse xdur xhealth xtransport xcomm xrecr xeduc xrest xother xserv xdur xother2
// su p537t p538t p539t p540t p541t p542t p543t p544t p545t p546t p547t p548t p549t p551cp

* G total consumption for total goods and non-durable goods
replace xtot = xfood + xheating + xtransport + xhousing + xserv + xdur + xother2
* g xtot_ndur = xfood + xheating + xtransport + xhousing + xserv + xother2

**************************************************************;
* Generate hh char variables;
**************************************************************;

gen North_East = (region==1)
gen North_West = (region==2)
gen Yorkshire  = (region==3)
gen East_Midlands = (region==4)
gen West_Midlands = (region==5)
gen Eastern = (region==6)
gen London = (region==7)
gen South_East= (region==8)
gen South_West= (region==9)
gen Wales = (region==10)
gen Scotland = (region==11)
gen Northern_Ireland= (region==12)

gen Female_HRP =(sexhrp==2)
gen Male_HRP = (sexhrp==1)

gen White = (ethnicityhrp==1)
gen Black = (ethnicityhrp==4)
gen Asian = (ethnicityhrp==3)
gen Mixed = (ethnicityhrp==2)
gen Other_ethnicity =(ethnicityhrp==0 | ethnicityhrp==5)

** Durables
g dishwasher = (a169==1)
g washing_machine = (a108==1)
g dryer = (a167==1)

** Type of central heating
* eletric_heating
* gas_heating
* oil_heating
* solidfuel_heating
* other_heating

** Number of cars owned
gen No_cars =(n_cars==0)
gen Cars =(n_cars!=0)

** 8 Household Types
gen One_Man = (hh_comp==1)
gen One_Woman = (hh_comp==2)
gen One_Woman_Children = (hh_comp==4|hh_comp==6)
gen One_Man_Children = (hh_comp==3|hh_comp==5)
gen Two_Adults =(inlist(hh_comp,7,8))
gen Two_Adults_2Children =(inlist(hh_comp,9,10,11,12))
gen Two_Adults_2plus_Children =(inlist(hh_comp,13,14,15,16,17))
gen Other_hhcomp = (hh_comp>17)

* Main income source
gen Wage_Salaries=(income_source==2)
gen Self_Empl=(income_source==3)
gen Invest=(income_source==4|income_source==5)
gen SS = (income_source==6)


g hh_freq_0 = 0
foreach year in 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 {
sum(weighta) if year == `year'
scalar tot_sample_0 = r(sum)
replace hh_freq_0 = weighta/tot_sample_0 if year == `year'
}

**************************************************************;
* Generate Subset;
**************************************************************;

* "All categories are screened for durable goods such as car purchases, renovation works, or other forms of physical investments"

* Drop hhs in Scotland and Norther Ireland
g set1 = (Scotland ==1|Northern_Ireland==1)

* Drop students and retirees
g set2 = (student==1|retiree==1)

* Set of people who own whole house and have central heating
*g set3 = (Whole_House==1 & Owned==1 & central_heating==1)

* drop if set1==1
* drop if set2==1
* keep if set3==1
su hh_id
* 116,473

**************************************************************;
* create budget shares and stone price index;
**************************************************************;
* Budget shares considering all goods 
local group1 "xfood xalc xcloth xhouse xgas xcoal xfuels xelec xwater xmaint xserv xrents xheating xhousing xhealth xtransport xcomm xrecr xeduc xrest xother xfurn xdur xother2"
foreach var in `group1'{
 gen bs`var'=`var'/xtot
}
su bsxfood-bsxother2

// * Budget shares excuding durable goods
// local group2 "xfood xalc xhouse xgas xcoal xfuels xelec xwater xmaint xrents xserv xheating xhousing xhealth xtransport xcomm xrecr xeduc xrest xother xother2"
// foreach var in `group2'{
//  gen bs`var'_ndur =`var'/xtot_ndur
// }
// su bsxfood_ndur-bsxother2_ndur

* weird that there are households where the entire weekly budget is only one consumption aggregate

***************************************************************;
* Using budget shares for all goods, keep only obs with positive > 0 budget shares
***************************************************************;
g todrop = 0
foreach good in $goodall{
replace todrop = 1 if bsx`good'<=0
}

kdensity weighta if todrop == 1, plot(kdensity weighta if todrop == 0) ///
	legend(label(1 "To Drop") label(2 "Not Drop") rows(1))
ksmirnov weighta, by(todrop)
	
drop if todrop==1
** 22% of hhs dropped (25,995 hhs);

********************************; 
* Banks Blundell Lewbel: out of 3 st. deviations from mean of log(tot.expend.) or budget share
* other possibility: cut off <0.5 percentile and >99.5 percentile of tot-expend.
********************************;

* Outliers in expenditure groups;
gen outliers=0
foreach v in $goodall {
quietly: centile  bsx`v', centile(1 99)
replace outliers=1 if  bsx`v'<r(c_1) | bsx`v'>r(c_2)
}
count if outliers==1
keep if outliers==0
drop outliers
** 10,840 hh dropped

***************************************************************;
* Robustness checks: impute values to avoid drop 25% of hhs; 
***************************************************************;
* Replace expenditures
// su xfood xheating xtransport xhousing xserv xdur xother2
// foreach good in $goodall{
// quietly: centile  x`good' if x`good'>0, centile(10)
// replace x`good' = r(c_1) if x`good'<=0
// }

// * New budget shares:
// foreach good in $goodall{
// replace bsx`good'=x`good'/xtot
// }
// su bsxfood-bsxother2

************ Price index based on Lewbel (1989)

foreach good in $goodall {
g index_k_`good' = 1
g index_good_`good' = 1
g index_stone_`good' = 0
}

* Create sub-budget shares
foreach good in $goodall {
foreach goodb in $`good' {
 g  wg`good'_`goodb' = x`goodb'/x`good'
 su wg`good'_`goodb'
}
}

foreach good in $goodall {
foreach goodb in $`good' {
 su p`goodb'
}
}

* Reference household
foreach good in $goodall {
foreach goodb in $`good' {
	ameans  wg`good'_`goodb'
replace index_k_`good'=(index_k_`good')*r(mean)^-r(mean) if r(mean)>0
}
} 
 

*** Index I
foreach good in  $goodall{
foreach goodb in $`good' {
replace index_good_`good' = index_good_`good'*(p`goodb'/wg`good'_`goodb')^wg`good'_`goodb' if wg`good'_`goodb'!=0 &wg`good'_`goodb'!=. & p`goodb'!=.
	}
}

**** index II
foreach good in $goodall{
replace index_good_`good' = index_good_`good'/index_k_`good'
}

* Use this as prices
foreach good in $goodall{
gen lindex_good_`good'= log(index_good_`good') 
}

su lindex_good_*

**************************************************************;
* Create logs;
**************************************************************;
* generate lxtot_ndur =ln(xtot_ndur)
generate lxtot =ln(xtot)

* Create logs of all variables
foreach var in $goodall {
	gen lx`var' = ln(x`var')
}

* Replace missing values with 0
foreach var of varlist lx* {
replace `var'=0 if `var'==.
}

replace oecdsc = 1 if oecdsc==0

* Income quintile by hh income: (divide hh into 5 income groups each year)
g equiv_income = income_wk_tot_calculated/oecdsc
egen inc_quantile = xtile(equiv_income), by(year) p(20(20)80)
egen inc_decile = xtile(equiv_income), by(year) p(10(10)90)

* Quartile by non-durable consumption:
// g equiv_xtot_ndur = xtot_ndur/oecdsc
// egen exp_quantile = xtile(equiv_xtot_ndur), by(year) p(20(20)80)
// egen exp_decile = xtile(equiv_xtot_ndur), by(year) p(10(10)90)
// egen exp_quantile2 = xtile(xtot), by(year) p(20(20)80)

**************************************************************;
* Descriptive stats: budget shares and prices;
**************************************************************;
* New weights;
g tot_sample_new = .
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(new_weight) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample_new = tot_sample_0 if LCF_round == "`year'"
}

// tab LCF_round, su(tot_sample_new)

//              |      Summary of tot_sample_new
//    LCF_round |        Mean   Std. Dev.       Freq.
// -------------+------------------------------------
// LCF_2001-2.. |    41347349           0       4,784
// LCF_2002-2.. |    41015429           0       4,436
// LCF_2003-2.. |    41448314           0       4,585
// LCF_2004-2.. |    41210890           0       4,351
// LCF_2005-2.. |    41248795           0       4,346
//     LCF_2006 |    41403183           0       4,261
//     LCF_2007 |    41395764           0       3,869
//     LCF_2008 |    42108146           0       3,686
//     LCF_2009 |    42433773           0       3,642
//     LCF_2010 |    42185559           0       3,322
//     LCF_2011 |    42664783           0       3,701
//     LCF_2012 |    43214978           0       3,657
//     LCF_2013 |    46461117           0       3,487
//     LCF_2014 |    46101317           0       3,483
//     LCF_2015 |    45626682   7.452e-09       3,313
//     LCF_2016 |    48187495   7.452e-09       3,483
//     LCF_2017 |    47570772           0       3,671
//     LCF_2018 |    47909530           0       3,681
//     LCF_2019 |    48494391           0       3,703
//     LCF_2020 |    43624879           0       3,397
//     LCF_2021 |    34645802           0       2,780
// -------------+------------------------------------
//        Total |    43288759   3077650.3      79,638


* Adjust weights;
g weight_adjusted = .
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
replace weight_adjusted = new_weight*(tot_sample/tot_sample_new) if LCF_round == "`year'"
}

* Check totals;
g tot_sample_new_adjusted =.
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(weight_adjusted) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample_new_adjusted = tot_sample_0 if LCF_round == "`year'"
}

* tab LCF_round, su(tot_sample_new_adjusted)
* ok!

su lindex_good_food lindex_good_heating lindex_good_transport lindex_good_housing lindex_good_serv lindex_good_dur lindex_good_other2
su bsxfood bsxheating bsxtransport bsxhousing bsxserv bsxdur bsxother2 bsxgas bsxcoal bsxfuels bsxelec
su xtot savings income_paye_tax income_wk_salary income_wk_tot_calculated wage_notax hh_hours_wk_tot

replace wage_notax = 0 if wage_notax==.
g inc_wk_nonsalary_tot = income_wk_tot_calculated - income_wk_salary
replace deductions= 0 if deductions==.
replace income_wk_disposable = income_wk_tot_calculated - deductions

* Income! This matches other plots in literature;
g equiv_disp_income = income_wk_disposable/oecdsc
egen disp_income_decile = xtile(equiv_disp_income), by(year) p(10(10)90)
bysort year: egen agg_disp_income = total(equiv_disp_income)
bysort year disp_income_decile: egen agg_disp_decile = total(equiv_disp_income)
bysort year disp_income_decile: g agg_disp_share = agg_disp_decile/agg_disp_income
tab disp_income_decile, su(agg_disp_share)

* Consumption! Lorenz curve;
g equiv_consumption = xtot/oecdsc
egen x_decile = xtile(equiv_consumption), by(year) p(10(10)90)
bysort year: egen agg_x = total(equiv_consumption)
bysort year x_decile: egen agg_x_decile = total(equiv_consumption)
bysort year x_decile: g agg_x_share = agg_x_decile/agg_x

tab x_decile, su(xtot)
tab x_decile, su(income_wk_disposable)

bysort year: egen median_exp = median(equiv_consumption)
g  exp_poverty = (equiv_consumption< 0.6*median_exp)

// g  exp_poverty_impossible = (equiv_consumption < 0.5*0.6*median_exp)
// replace equiv_consumption = 0.5*0.6*median_exp if exp_poverty_impossible==1

* Household type
tab het_household

bysort year: egen agg_income = total(equiv_income)
bysort year x_decile: egen agg_income_quintile = total(equiv_income)
bysort year x_decile: g agg_income_share = agg_income_quintile/agg_income


* Table 1
tab x_decile, su(agg_income_share)
tab x_decile, su(agg_x_share)
tab x_decile, su(equiv_disp_income)
tab x_decile, su(equiv_consumption)

tab x_decile if year==2021, su(agg_income_share)
tab x_decile if year==2021, su(agg_x_share)
tab x_decile if year==2021, su(equiv_disp_income)
tab x_decile if year==2021, su(equiv_consumption)

// tab exp_quantile, su(xtot)
// tab exp_quantile, su(xtot_ndur)
// tab exp_quantile, su(income_wk_disposable)
// tab exp_quantile, su(agg_income_share)
// tab exp_quantile, su(agg_consumption_share)

// tab inc_quantile, su(agg_income_share)
// tab inc_quantile, su(agg_consumption_share)

*Urban rural only for 2015-2021
g urban = 1 if (urgridewp==1 & region!=11)
replace urban = 1 if (urgridscp==1 & region==11)
replace urban = 0 if (urgridewp==2 & region!=11)
replace urban = 0 if (urgridscp==2 & region==11)

* HH Economic variables:
eststo clear
eststo sum1: quietly estpost tabstat ///
    unemployed employed student retiree income_wk_salary inc_wk_nonsalary_tot xtot ///
	income_wk_tot_calculated income_wk_disposable wage_notax exp_share wk_hours_worked_hrp_tot wk_hours_worked_spouse_tot income_paye_tax ///
	hh_size n_children n_adults Female_HRP White Black Asian Mixed Other_ethnicity ///
	Cars n_cars dishwasher washing_machine dryer ///
	Whole_House Flat ///
	Rented Owned central_heating eletric_heating gas_heating oil_heating solidfuel_heating other_heating ///
	North_East North_West Yorkshire East_Midlands West_Midlands Eastern London South_East South_West Wales Scotland Northern_Ireland [aw=weight_adjusted], statistics(mean sd min p99) columns(statistics)
esttab sum1 using "$estimates/2025.03.29_sum1.tex", cells("mean(fmt(2)) sd(fmt(2)) min p99") label nodepvar title(Summary Statistics) replace

eststo sum2: quietly estpost tab ///
    het_household
esttab sum2 using "$estimates/2025.03.29_sum2.tex", title(Household Types) label nodepvar replace

eststo sum3: quietly estpost summarize ///
    bsxfood bsxheating  bsxtransport bsxhousing bsxserv bsxdur bsxother2 ///
	bsxgas bsxcoal bsxfuels bsxelec ///
	lindex_good_food lindex_good_heating lindex_good_transport lindex_good_housing lindex_good_serv lindex_good_dur lindex_good_other2 [aw=weight_adjusted]
esttab sum3 using "$estimates/2025.03.29_sum3.tex", cells("mean(fmt(2)) sd(fmt(2)) min p99") label nodepvar title(Budget Shares and Prices) replace

********************************************************************************
* EASI Demand System I
* Tricks with Hicks: The EASI demand system
* Arthur Lewbel and Krishna Pendakur
* 2008, American Economic Review

*data labeling conventions:
* data weights: weighta (replace with 1 if unweighted estimation is desired)
* budget shares: sneq
* prices: nprice
* log total expenditures: lxtot
* implicit utility: y, or related names
* demographic characteristics: z1 to zndem

* Rename prices and budget sets
gen s1 = bsxfood
gen s2 = bsxheating
gen s3 = bsxtransport
gen s4 = bsxhousing
gen s5 = bsxserv
gen s6 = bsxdur
gen s7 = bsxother2

gen p1 = lindex_good_food
gen p2 = lindex_good_heating
gen p3 = lindex_good_transport
gen p4 = lindex_good_housing
gen p5 = lindex_good_serv
gen p6 = lindex_good_dur
gen p7 = lindex_good_other2


// * Check if shares add to 1
// gen sum_bs=0
// foreach k of varlist ws_*{
// replace sum_ws= `k'+sum_ws
// }

// qui sum sum_ws
// if r(max)  >1 display "OH, PROBLEMS!"

* Controls for car ownership, region and month
* gen d_cars = (Cars==1)
gen d_rent = (Rented==1)
gen d_flat = (Flat==1)
* Gen proxy for dwelling size;


* Note: don't use the d_urban dummy in this sample.  
gen d_urban = urban
gen d_eletric_heating = eletric_heating
gen d_gas_heating = gas_heating

forvalues j=1(1)12 {
	gen month_`j'= (month==`j')
}

forvalues j=1(1)12 {
	gen reg_`j'= (region==`j')
}

* Note: not urban!
global var "d_eletric_heating d_gas_heating d_rent d_flat reg_* month_* i.year"

***************************************;
* Settings;
***************************************;

* J-1 = 6, J = 7
global neq "6"
global neqt "7"
global quantiles "1 2 3 4 5"
* Z = 8, but omit z1 since picked up by br1 
global n_types= "7"
global text=1

global estimation=1

global nprice "$neqt"
global ndem "$n_types"
global npowers "4"

* set a convergence criterion and choose whether or not to base it on parameters
global conv_crit "0.001"
scalar conv_param=1
scalar conv_y=0

* set the matrix size big enough to do constant,y,y*z,p + controls
global matsize_value = 100+$neq*(1+$npowers+$ndem+$ndem)+300
set matsize $matsize_value

***************************************;
* Gen dummies and vars;
***************************************;
* 8 types of hhs 
* Baseline = type_8: working single with no children;
g type_1 = het_household==3 // 
g type_2 = het_household==5 //
g type_3 = het_household==6 //
g type_4 = het_household==7 //
g type_5 = het_household==8 //
g type_6 = het_household==1 //
g type_7 = het_household==2 //
g type_8 = het_household==4 //

* normalised prices are what enter the demand system
* generate normalised prices, backup prices (they get deleted), and pAp, pBp

global nplist ""
forvalues j=1(1)$neq {
	g np`j'= p`j' - p$nprice	
	global nplist "$nplist np`j'"
}

forvalues j=1(1)$neq {
	g np`j'_backup=np`j'
	g Ap`j'=0
	g Bp`j'=0
}
g pAp=0
g pBp=0

* List demographic characteristics (i.e the hh types): fill them in, and add them to zlist below
forvalues k=1(1)$n_types {
g z`k' = type_`k'
}
global zlist "z1-z$ndem"

* No p interactions
// global npzlist ""
// forvalues j=1(1)$neq {
// 	forvalues k=1(1)$ndem {
// 		g np`j'z`k'=np`j'*z`k'	
// 		global npzlist "$npzlist np`j'z`k'"
// 	}
// }

* Make y_stone = x-p'w, and gross instrument, y_tilda = x-p'w^bar
g y_stone=lxtot
g y_tilda=lxtot
g P_stone=0
* Compute each mean budget shar, which we use in instrument 
forvalues num=1(1)$nprice {
	egen mean_s`num' = mean(s`num')
	replace y_tilda = y_tilda - mean_s`num'*p`num'
	replace y_stone = y_stone - s`num'*p`num'
	replace P_stone = P_stone + s`num'*p`num'
}

* Note that P_stone = sum across j: s`num' * p`num'
* y_stone = lxtot - P_stone
* y_tilda = lxtot - P_stone (with average budget shares)

***************************************;
* Make list of functions;
***************************************;

* make list of functions of (implicit) utility, y: fill them in, and add them to ylist below
* alternatively, fill ylist and yinstlist with the appropriate variables and instruments
g y = y_stone
g y_inst = y_tilda

global ylist ""
global yinstlist ""
global yzlist ""
global yzinstlist ""
global ynplist ""
global ynpinstlist ""

* List of powers of utility
forvalues j=1(1)$npowers {
	g y`j'=y^`j'
	g y`j'_inst=y_inst^`j'
	global ylist "$ylist y`j'"
	global yinstlist "$yinstlist y`j'_inst"
}

* Interactions y - demographics
forvalues k=1(1)$ndem {
	g yz`k' = y * z`k'
	g yz`k'_inst = y_inst * z`k'
	global yzlist "$yzlist yz`k'"
	global yzinstlist "$yzinstlist yz`k'_inst"
}

* Interactions y - prices
forvalues k=1(1)$neq {
	g ynp`k' = y*np`k'
	g ynp`k'_inst = y_inst * np`k'
	global ynplist "$ynplist ynp`k'"
	global ynpinstlist "$ynpinstlist ynp`k'_inst"
}

* Set up the equation to estimate and put them in a list to create system of equations
* w = y z p controls
global eqlist ""
forvalues num=1(1)$neq {
	*global eq`num' "(s`num' $ylist $zlist $yzlist $nplist $ynplist $npzlist)"
	global eq`num' "(s`num' $ylist $yzlist $nplist $var)"
	macro list eq`num'
	global eqlist "$eqlist \$eq`num'"
}

* Create linear constraints and put them in a list, called conlist
* Symmetry of Slutsky matrix (cross prices)
global conlist ""
forvalues j=1(1)$neq {
	local jplus1=`j'+1
	forvalues k = `jplus1'(1)$neq {
		constraint `j'`k' [s`j']np`k'=[s`k']np`j'	
		global conlist "$conlist `j'`k'"
	}
}

save "$clean/2025.03.29_data_easi.dta", replace

**************************************;
* Exact model implemented by iterative linear methods;
**************************************;

* Exact model requires two steps:  
	* step 1) get a pre-estimate to construct the intrument;
		* Run three stage least squares, and then iterate to convergence,
		* constructing y = (y_stone + 0.5 * p'A(z)p)/(1-0.5*p'Bp) at each iteration
	* step 2) use the instrument to estimate the model
* first get a pre-estimate to create the instrument:

* Note that the difference in predicted values for y = 1 between p and p = 0 is A(z)p, and
* that the difference in difference in predicted values for y=1 vs y=0 between p and p=0 is Bp

* Note that in a demand system with J goods, can estimate J-1 and recover the parameters
* Of the last group from constraints that budget shares must add up to 1

* Prices are normalized so that the price vector in Jan 2001 = (1,..,1), such that the log is p = 0

* Create boostrapped program to estimate standard errors;
capture program drop myboot
program myboot
preserve

bsample

* Generate vars
replace y = y_stone
g y_backup = y_stone
g y_old = y_stone
g y_change = 0
scalar crit_test = 1
scalar iter = 0


// reg3 $eqlist [aweight=weighta], constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist) noconst
// reg3 $eqlist [aweight=weighta], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist) noconst
// sureg $eqlist, constr($conlist)
// sureg $eqlist

* As long as the criterion test is larger than the convergence criterion, iterate:
while crit_test>$conv_crit {

	scalar iter=iter+1
	*quietly reg3 $eqlist ,  constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist)
	quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist)
	
	if (iter>1) {		
		matrix params_old=params
	}
	matrix params=e(b)
	quietly replace pAp=0
	quietly replace pBp=0
	quietly replace y_old=y
	quietly replace y_backup=y

	*predict with y=1
	*generate rhs vars,interactions with y=1
	forvalues j=1(1)$npowers {
		quietly replace y`j'=1
	} 
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=np`j'
	} 
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=z`j'
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1_p0, equation(s`j')		
	}
	
	*refresh p,pz
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	}
	
	*generate rhs vars,interactions with y=0
	foreach yvar in $ylist $yzlist {
		quietly replace `yvar'=0
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0_p0, equation(s`j')		
	}

	*refresh p only
	forvalues j=1(1)$neq {
		quietly replace np`j'= np`j'_backup
	}
	
	*fill in pAp and pBp
	forvalues j=1(1)$neq {
		quietly replace Ap`j'=s`j'hat_y0-s`j'hat_y0_p0
		quietly replace pAp=pAp+np`j'*Ap`j'	
		quietly replace Bp`j'=(s`j'hat_y1-s`j'hat_y1_p0)-(s`j'hat_y0-s`j'hat_y0_p0)
		quietly replace pBp=pBp+np`j'*Bp`j'	
		quietly drop s`j'hat_y0 s`j'hat_y0_p0 s`j'hat_y1 s`j'hat_y1_p0
	}

	*round pAp and pBp to the nearest millionth, for easier checking
	quietly replace pAp=int(1000000*pAp+0.5)/1000000
	quietly replace pBp=int(1000000*pBp+0.5)/1000000

	*recalculate y,yz,py,pz
	
	quietly replace y=(y_stone+0.5*pAp)/(1-0.5*pBp)
	
	forvalues j=1(1)$npowers {
		quietly replace y`j'=y^`j'
	}
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=y*z`j'
	} 
	*refresh py,pz
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=y*np`j'_backup

	}

	if (iter>1 & conv_param==1) {		
		matrix params_change=(params-params_old)
		matrix crit_test_mat=(params_change*(params_change'))
		svmat crit_test_mat, names(temp)
		scalar crit_test=temp
		drop temp
	}
	quietly replace y_change=abs(y-y_old)
	quietly summ y_change
	if(conv_y==1) {
		scalar crit_test=r(max)
	}
	display "iteration " iter 
	scalar list crit_test 
	summ y_change y_stone y y_old pAp pBp
}

* Create the instrument, and its interactions yz
* Eq. on pg. 15 of Tricks with Hicks
* Recall that we had already created these vars before, just replacing the y with y_inst;
* Previously, y_inst = y_tilda = lxtot. We effectively calculated a measure of indirect utility.
* quietly replace y_inst = (y_tilda + 0.5*pAp)/(1-0.5*pBp)

*with nice instrument in hand, run three stage least squares on the model, and then iterate to convergence
replace y_old=y
replace y_change=0
scalar iter=0
scalar crit_test=1
while crit_test>$conv_crit {
	scalar iter=iter+1
	
	*quietly reg3 $eqlist ,  constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist)
	quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist)
	
	if (iter>1) {		
		matrix params_old=params
	}
	matrix params=e(b)
	quietly replace pAp=0
	quietly replace pBp=0
	quietly replace y_old=y
	quietly replace y_backup=y

	*predict with y=1
	*generate rhs vars,interactions with y=1
	forvalues j=1(1)$npowers {
		quietly replace y`j'=1
	} 
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=np`j'
	} 
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=z`j'
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1_p0, equation(s`j')		
	}
	
	*refresh p,pz
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	
	}
	
	*generate rhs vars,interactions with y=0
	foreach yvar in $ylist $yzlist {
		quietly replace `yvar'=0
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist $npzlist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0_p0, equation(s`j')		
	}

	*refresh p only
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	}
	
	*fill in pAp and pBp
	forvalues j=1(1)$neq {
		quietly replace Ap`j'=s`j'hat_y0-s`j'hat_y0_p0
		quietly replace pAp=pAp+np`j'*Ap`j'	
		quietly replace Bp`j'=(s`j'hat_y1-s`j'hat_y1_p0)-(s`j'hat_y0-s`j'hat_y0_p0)
		quietly replace pBp=pBp+np`j'*Bp`j'	
		quietly drop s`j'hat_y0 s`j'hat_y0_p0 s`j'hat_y1 s`j'hat_y1_p0
	}

	*round pAp and pBp to the nearest millionth, for easier checking
	quietly replace pAp=int(1000000*pAp+0.5)/1000000
	quietly replace pBp=int(1000000*pBp+0.5)/1000000

	*recalculate y,yz,py,pz
	quietly replace y=(y_stone+0.5*pAp)/(1-0.5*pBp)
	
	forvalues j=1(1)$npowers {
		quietly replace y`j'= y^`j'
	}
	forvalues j=1(1)$ndem {
		quietly replace yz`j'= y*z`j'
	} 
	*refresh py,pz
	forvalues j=1(1)$neq {
		quietly replace ynp`j'= y*np`j'_backup

	}

	if (iter>1 & conv_param==1) {		
		matrix params_change=(params-params_old)
		matrix crit_test_mat=(params_change*(params_change'))
		svmat crit_test_mat, names(temp)
		scalar crit_test=temp
		drop temp
	}
	quietly replace y_change=abs(y-y_old)
	quietly summ y_change
	if(conv_y==1) {
		scalar crit_test=r(max)
	}
	display "iteration " iter 
	scalar list crit_test 
	summ y_change y_stone y y_old pAp pBp
}

eststo clear
eststo: quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist) 
restore 
end

***************** ONLY RUN THIS ONCE: BOOTSTRAPPED *******************************************
preserve
* Estimate bootstrapped standard errors by iterating 50 times;
* simulate, reps(50) seed(1): myboot
use "$estimates/2025.03.29_easi7.dta"

**************************************;
* Create tables of EASI coefficients with bootstrapped se;
**************************************;
qui de
scalar N = r(k)
scalar n = N/$neq

global matsize_value = n*12
set matsize $matsize_value

matrix COEF = J(n*12, 1, 0)

scalar t = 1
foreach var of varlist s1_b_y1-s6_b_cons{ 
	qui su `var'
	mat COEF[t,1]=r(mean)
	mat COEF[t+1,1]=r(sd)
	scalar t = t+2
}

mat temp1 = COEF[1..112,1...]
mat temp2 = COEF[113..224,1...]
mat temp3 = COEF[225..336,1...]
mat temp4 = COEF[337..448,1...]
mat temp5 = COEF[449..560,1...]
mat temp6 = COEF[561..672,1...]

mat COEF2 = temp1,temp2,temp3,temp4,temp5,temp6
mat COEF = COEF2
outtable using "$estimates/2025.03.29_EASI7_boot", mat(COEF) longtable nobox center f(%9.3f) replace

mat colnames COEF = food energy transport housing services durables
* Note that here, every other row is the standard errors
qui xml_tab COEF,  save($estimates/2025.03.29_EASI_ouput_7_boot.xml) replace  title("Coefficients EASI: 7 Groups") sheet("Coefficients")
restore

***************** END BOOTSTRAPPED **********************************************************

* Run point estimates without bootstrap

capture program drop EASIestimation
program EASIestimation
preserve

* Generate vars
replace y = y_stone
g y_backup = y_stone
g y_old = y_stone
g y_change = 0
scalar crit_test = 1
scalar iter = 0


// reg3 $eqlist [aweight=weighta], constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist) noconst
// reg3 $eqlist [aweight=weighta], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist) noconst
// sureg $eqlist, constr($conlist)
// sureg $eqlist

* As long as the criterion test is larger than the convergence criterion, iterate:
while crit_test>$conv_crit {

	scalar iter=iter+1
	*quietly reg3 $eqlist ,  constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist)
	quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist)
	
	if (iter>1) {		
		matrix params_old=params
	}
	matrix params=e(b)
	quietly replace pAp=0
	quietly replace pBp=0
	quietly replace y_old=y
	quietly replace y_backup=y

	*predict with y=1
	*generate rhs vars,interactions with y=1
	forvalues j=1(1)$npowers {
		quietly replace y`j'=1
	} 
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=np`j'
	} 
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=z`j'
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1_p0, equation(s`j')		
	}
	
	*refresh p,pz
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	}
	
	*generate rhs vars,interactions with y=0
	foreach yvar in $ylist $yzlist {
		quietly replace `yvar'=0
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0_p0, equation(s`j')		
	}

	*refresh p only
	forvalues j=1(1)$neq {
		quietly replace np`j'= np`j'_backup
	}
	
	*fill in pAp and pBp
	forvalues j=1(1)$neq {
		quietly replace Ap`j'=s`j'hat_y0-s`j'hat_y0_p0
		quietly replace pAp=pAp+np`j'*Ap`j'	
		quietly replace Bp`j'=(s`j'hat_y1-s`j'hat_y1_p0)-(s`j'hat_y0-s`j'hat_y0_p0)
		quietly replace pBp=pBp+np`j'*Bp`j'	
		quietly drop s`j'hat_y0 s`j'hat_y0_p0 s`j'hat_y1 s`j'hat_y1_p0
	}

	*round pAp and pBp to the nearest millionth, for easier checking
	quietly replace pAp=int(1000000*pAp+0.5)/1000000
	quietly replace pBp=int(1000000*pBp+0.5)/1000000

	*recalculate y,yz,py,pz
	
	quietly replace y=(y_stone+0.5*pAp)/(1-0.5*pBp)
	
	forvalues j=1(1)$npowers {
		quietly replace y`j'=y^`j'
	}
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=y*z`j'
	} 
	*refresh py,pz
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=y*np`j'_backup

	}

	if (iter>1 & conv_param==1) {		
		matrix params_change=(params-params_old)
		matrix crit_test_mat=(params_change*(params_change'))
		svmat crit_test_mat, names(temp)
		scalar crit_test=temp
		drop temp
	}
	quietly replace y_change=abs(y-y_old)
	quietly summ y_change
	if(conv_y==1) {
		scalar crit_test=r(max)
	}
	display "iteration " iter 
	scalar list crit_test 
	summ y_change y_stone y y_old pAp pBp
}

* Create the instrument, and its interactions yz
* Eq. on pg. 15 of Tricks with Hicks
* Recall that we had already created these vars before, just replacing the y with y_inst;
* Previously, y_inst = y_tilda = lxtot. We effectively calculated a measure of indirect utility.
* quietly replace y_inst = (y_tilda + 0.5*pAp)/(1-0.5*pBp)

*with nice instrument in hand, run three stage least squares on the model, and then iterate to convergence
replace y_old=y
replace y_change=0
scalar iter=0
scalar crit_test=1
while crit_test>$conv_crit {
	scalar iter=iter+1
	
	*quietly reg3 $eqlist ,  constr($conlist) endog($ylist $ynplist $yzlist) exog($yinstlist $ynpinstlist $yzinstlist)
	quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist)
	
	if (iter>1) {		
		matrix params_old=params
	}
	matrix params=e(b)
	quietly replace pAp=0
	quietly replace pBp=0
	quietly replace y_old=y
	quietly replace y_backup=y

	*predict with y=1
	*generate rhs vars,interactions with y=1
	forvalues j=1(1)$npowers {
		quietly replace y`j'=1
	} 
	forvalues j=1(1)$neq {
		quietly replace ynp`j'=np`j'
	} 
	forvalues j=1(1)$ndem {
		quietly replace yz`j'=z`j'
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y1_p0, equation(s`j')		
	}
	
	*refresh p,pz
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	
	}
	
	*generate rhs vars,interactions with y=0
	foreach yvar in $ylist $yzlist {
		quietly replace `yvar'=0
	} 
	*generate predicted values
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0, equation(s`j')		
	}
	*set all p, pz, py to zero
	foreach yvar in $nplist $npzlist {
		quietly replace `yvar'=0
	} 
	forvalues j=1(1)$neq {
		quietly predict s`j'hat_y0_p0, equation(s`j')		
	}

	*refresh p only
	forvalues j=1(1)$neq {
		quietly replace np`j'=np`j'_backup
	}
	
	*fill in pAp and pBp
	forvalues j=1(1)$neq {
		quietly replace Ap`j'=s`j'hat_y0-s`j'hat_y0_p0
		quietly replace pAp=pAp+np`j'*Ap`j'	
		quietly replace Bp`j'=(s`j'hat_y1-s`j'hat_y1_p0)-(s`j'hat_y0-s`j'hat_y0_p0)
		quietly replace pBp=pBp+np`j'*Bp`j'	
		quietly drop s`j'hat_y0 s`j'hat_y0_p0 s`j'hat_y1 s`j'hat_y1_p0
	}

	*round pAp and pBp to the nearest millionth, for easier checking
	quietly replace pAp=int(1000000*pAp+0.5)/1000000
	quietly replace pBp=int(1000000*pBp+0.5)/1000000

	*recalculate y,yz,py,pz
	quietly replace y=(y_stone+0.5*pAp)/(1-0.5*pBp)
	
	forvalues j=1(1)$npowers {
		quietly replace y`j'= y^`j'
	}
	forvalues j=1(1)$ndem {
		quietly replace yz`j'= y*z`j'
	} 
	*refresh py,pz
	forvalues j=1(1)$neq {
		quietly replace ynp`j'= y*np`j'_backup

	}

	if (iter>1 & conv_param==1) {		
		matrix params_change=(params-params_old)
		matrix crit_test_mat=(params_change*(params_change'))
		svmat crit_test_mat, names(temp)
		scalar crit_test=temp
		drop temp
	}
	quietly replace y_change=abs(y-y_old)
	quietly summ y_change
	if(conv_y==1) {
		scalar crit_test=r(max)
	}
	display "iteration " iter 
	scalar list crit_test 
	summ y_change y_stone y y_old pAp pBp
}

eststo clear
eststo: quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist) 
estimates store EASI

esttab using "$estimates/2025.03.29_EASI_output_7.csv", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(r2 df_r bic, fmt(3 0 1) label(R-sqr)) replace
estwrite  using "$estimates/2025.03.29_EASI_output_7", replace

restore 
end


// eststo clear
// eststo: quietly reg3 $eqlist [aw = weight_adjusted], constr($conlist) endog($ylist  $yzlist) exog($yinstlist  $yzinstlist) 
// esttab using "$estimates/EASI_output_7.csv", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(r2 df_r bic, fmt(3 0 1) label(R-sqr)) replace

// estimates store EASI
// estwrite  using "$estimates/EASI_output_7", replace

EASIestimation
estimates restore EASI

predict bs1, equation(s1)
quietly twoway (qfitci bsxfood lxtot) (qfitci bs1 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure") legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Food")
graph export "$figures/2025_03_29_bs1.png", replace

predict bs2, equation(s2)
quietly twoway (qfitci bsxheating lxtot) (qfitci bs2 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure")  legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Energy")
graph export "$figures/2025_03_29_bs2.png", replace

predict bs3, equation(s3)
quietly twoway (qfitci bsxtransport lxtot) (qfitci bs3 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure")  legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Transport")
graph export "$figures/2025_03_29_bs3.png", replace

predict bs4, equation(s4)
quietly twoway (qfitci bsxhousing lxtot) (qfitci bs4 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure")  legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Housing")
graph export "$figures/2025_03_29_bs4.png", replace

predict bs5, equation(s5)
quietly twoway (qfitci bsxserv lxtot) (qfitci bs5 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure")  legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Services")
graph export "$figures/2025_03_29_bs5.png", replace

predict bs6, equation(s6)
quietly twoway (qfitci bsxdur lxtot) (qfitci bs6 lxtot), ytitle("Budget Share") xtitle("Log Tot Expenditure")  legend(label(2 "Quadratic Fit - Data") label(3 "Quadratic Fit - 3SLS")) title("Durables")
graph export "$figures/2025_03_29_bs6.png", replace


foreach good in $goodall{
lpoly x`good' lxtot, noscatter ci title(`good') legend(off) ytitle("Expenditure") xtitle("Log Tot Expenditure") graphregion(fcolor(white)) note("") degree(4) 
display "bwidth="r(bwidth) ", Kernel=" r(kernel) ", degree=" r(degree)
graph export "$figures/2025_03_29_engel_`good'.png", replace
}

**************************************;
* Store matrix of coefficients in Excel;
**************************************;
* Matrix of coefficients
mat COEF = e(b)

* Total number of paramters
scalar parametres=e(k)/$neq

local j0 = 1
local j1 = parametres

* For each equation, generate a matrix of coefficients
forvalues num=1(1)$neq {
	matrix COEF_`num' = COEF[1,`j0'..`j1']
	local j0 =`j0' + parametres
	local j1 =`j1' + parametres
}

mat M_COEF = COEF_1
forvalues num = 2(1)$neq {
          mat M_COEF = M_COEF\COEF_`num'
	}
mat M_COEF = M_COEF'

mat colnames M_COEF = food energy transport housing services durables
qui xml_tab M_COEF,  save($estimates/2025.03.29_EASI_ouput_7.xml) replace  title("Coefficients EASI: 7 Groups") sheet("Coefficients")
qui xml_tab M_COEF,  save($simulation/01-input/2025.03.29_EASI_ouput_7.xls) replace  title("Coefficients EASI: 7 Groups") sheet("Coefficients")

**************************************;
* Elasticites;
**************************************;

* Retrieve final commodity group parameters by summing across;
local start_a = $npowers + $ndem
* Coefficients on prices
matrix A_0 = M_COEF[`start_a'+1..`start_a'+$neq, 1..6]
matrix new = J(1 ,$neq ,0) 
mat A_0 = A_0\new	
matrix new = J(1 ,$neq+1 ,0)
mat A_0 = A_0,new'
mat list A_0

mata: A_0 = st_matrix("A_0")

mata {
neqn=$neq+1 
for(i=1; i<=neqn-1; ++i) {
		A_0[i, neqn] = - sum(A_0[i,1..(neqn-1)])
		A_0[neqn, i] = A_0[i, neqn]
	}
	A_0[neqn, neqn] = - sum(A_0[neqn, 1..(neqn-1)])
}
mata: A_0
* symmetric

* Polynomial
matrix Br = M_COEF[1..$npowers , 1..$neq]'
mata: Br = st_matrix("Br")	
mata: Br = Br \-colsum(Br,1)
mata: Br

* Z
local start_a = $npowers+1
matrix Z = M_COEF[`start_a'..`start_a'+$ndem-1 , 1..$neq]'
mata: Z = st_matrix("Z")	
mata:  Z = Z \-colsum(Z,1)	
mata: Z
count
scalar pop =r(N)
drop y 

mata  {
		w = st_data(., tokens("s1 s2 s3 s4 s5 s6 s7"))		
		p = st_data(., tokens("p1 p2 p3 p4 p5 p6 p7"))		
		lx = st_data(., "lxtot")			
		zs = st_data(., tokens("z1 z2 z3 z4 z5 z6 z7"))
		num = st_numscalar("pop")

	 
	pAp = J(num,1,0)
	for(t=1; t<=num; ++t) {
		for(i=1; i<=neqn; ++i) {
		pAp[t]=p[t,1..neqn]*A_0*p[t,1..neqn]'
			}
		}
 
	sp = J(num, 1, 0)
	for(t=1; t<=num; ++t) {
	sp[t]= w[t,1..neqn] * p[t,1..neqn]'
	}
		
	y = (lx - sp + 0.5*pAp)
	st_addvar("double","y")
	st_store(.,"y", y)
	
	k2 = J(num, neqn, 0)	
	for(t=1; t<=num; ++t) {	
		for(i=1; i<=neqn; ++i) {
			k2[t,i] = Br[i,1] + Br[i,2] * 2 * y[t] + Br[i,3] * 3 * y[t] * y[t] + Br[i,4] * 4 * y[t] * y[t] * y[t] + Z[i,1]'* zs[t,1]+ Z[i,2]'* zs[t,2]+ Z[i,3]'* zs[t,3]+ Z[i,4]'* zs[t,4]+ Z[i,5]'* zs[t,5]+ Z[i,6]'* zs[t,6]+ Z[i,7]'* zs[t,7]
		}	
	}
	

	sumpk = J(num,1,0)
	for(t=1; t<=num; ++t) {	
	sumpk[t,1]=p[t,1..neqn]*(k2[t,1..neqn])'	
	}

	X = exp(lx)

	dxy = J(num, 1, 0)
	for(t=1; t<=num; ++t) {		
		dxy[t,1] = X[t,1]/exp(y[t,1]):*((1 + sumpk[t,1]))
	}
	st_addvar("double","dxy")
	st_store(.,"dxy",dxy)

	}

	

save "$clean/2025.03.29_data-labor-supply.dta", replace

* Check weights:
g tot_sample_temp = .
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(weight_adjusted) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample_temp = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample_temp)
* ok!

** PEij = ( dwi/dlog(pj) ) 1/wi - 1

** EEi = ( dwi/wlog(x)) 1/wi + 1
 
preserve

* Note: equiv_income is only available post 2002, so we remove years before
drop if inc_quantile == .
collapse s1 s2 s3 s4 s5 s6 s7 p1 p2 p3 p4 p5 p6 p7 np1 np2 np3 np4 np5 np6 z1-z7 lxtot, by (inc_quantile)

mata { 
	w = st_data(., tokens("s1 s2 s3 s4 s5 s6 s7"))		
	p = st_data(., tokens("p1 p2 p3 p4 p5 p6 p7"))		
	x = st_data(., "lxtot")			
	zs= st_data(., tokens("z1 z2 z3 z4 z5 z6 z7"))
			
	num = 5
	neqn = 7
	quintile = 5
	
	
	pAp = J(quintile,1,0)
	for(t=1; t<=quintile; ++t) {
		for(i=1; i<=neqn; ++i) {
		pAp[t]=p[t,1..neqn]*A_0*p[t,1..neqn]'
		}
	}
 
	
	wp = J(quintile, 1, 0)
	for(t=1; t<=quintile; ++t) {
	wp[t]=w[t,1..neqn]*p[t,1..neqn]'
	}
	
	
	y=(x - wp+0.5*pAp)

	
	k2 = J(num, neqn, 0)	
	for(t=1; t<=num; ++t) {	
		for(i=1; i<=neqn; ++i) {
			k2[t,i] = Br[i,1] + Br[i,2] * 2 * y[t] + Br[i,3] * 3 * y[t] * y[t] + Br[i,4] * 4 * y[t] * y[t] * y[t] + Z[i,1]'* zs[t,1]+ Z[i,2]'* zs[t,2]+ Z[i,3]'* zs[t,3]+ Z[i,4]'* zs[t,4] + Z[i,5]'* zs[t,5]+ Z[i,6]'* zs[t,6] + Z[i,7]'* zs[t,7]
		}	
	}		

	
	sumpk = J(num,1,0)
	for(t=1; t<=num; ++t) {	
	sumpk[t,1]=p[t,1..neqn]*(k2[t,1..neqn])'	
	}

	
	mu = J(quintile, neqn, 0)
	for(t=1; t<=quintile; ++t) {		
		for(i=1; i<=neqn; ++i) {
			mu[t,i] = k2[t,i]/(1+sumpk[t,1])
		}
	}

	
	xela_income = J(quintile, neqn, 0)
	for(t=1; t<=quintile; ++t) {		
	for(i=1; i<=neqn; ++i) {
		xela_income[t,i] = 1 + k2[t,i]/w[t,i]
	}
	}
		xela_income
		

	y 
	/// Hicksian elasticities
	all_H = J(quintile * neqn, neqn, 0)
	eta_H = J(neqn,neqn,0) 
		for (t=1; t<=quintile; ++t) {	
		for (i=1; i<=neqn; ++i) {
		for (j=1; j<=neqn; ++j) {
			eta_H[i,j] = -1*(i==j) + A_0[i,j]*1/w[t,i]
		}
		}
			all_H[((t-1)*neqn+1)..neqn*t,1..neqn] = eta_H[1..neqn,1..neqn]	
		}	
	all_H

		
	/// Marshallian elasticities
	all_M = J(quintile * neqn,neqn,0)
	eta_M = J(neqn,neqn,0)
	
	for(t=1; t<=quintile; ++t) {	
	for(i=1; i<=neqn; ++i) {
	for(j=1; j<=neqn; ++j) {
		eta_M[i,j] = (-1*(i==j) + A_0[i,j]*1/w[t,i]) - xela_income[t,i] * w[t,i]
		}
		}
   
	all_M[((t-1)*neqn+1)..neqn*t,1..neqn] = eta_M[1..neqn,1..neqn]	 
		}
	all_M
	
   
   	st_rclear()
	st_eclear()
	
	for(t=1; t<=quintile; ++t) {	
		for(i=1; i<=neqn; ++i) {
			rmac = sprintf("r(xela_income_%f_%f)", t,i)
			st_numscalar(rmac, xela_income[t,i])
			
			for(j=1; j<=neqn; ++j) {
				rmac = sprintf("r(all_H_%f_%f_%f)",j, i,t)
				st_numscalar(rmac, all_H[((t-1) * neqn + i),j])
				rmac = sprintf("r(all_M_%f_%f_%f)",j, i,t)
				st_numscalar(rmac, all_M[((t-1) * neqn + i),j])
			
				}
			}			
		}


	for(i=1; i<=neqn; ++i) {
   	for(j=1; j<=neqn; ++j) {
			rmac = sprintf("r(A_0_%f_%f)", i, j)
			st_numscalar(rmac, A_0[i,j])			
}
}					
}

restore	

*************************************************
// use "$estimates/2025.03.29_easi7.dta", clear
 
// eststo clear
// eststo income: quietly estpost summarize ///
   
// esttab sum1 using "$estimates/2025.03.29_income_elas.tex", cells("mean(fmt(3)) sd(fmt(3))") label nodepvar title(Income Elasticities) replace

// eststo income: quietly estpost summarize ///
   
// esttab sum1 using "$estimates/2025.03.29_H_elast.tex", cells("mean(fmt(3)) sd(fmt(3))") label nodepvar title(Hicksian Elasticities) replace

// eststo income: quietly estpost summarize ///
   
// esttab sum1 using "$estimates/2025.03.29_M_elas.tex", cells("mean(fmt(3)) sd(fmt(3))") label nodepvar title(Marshallian Elasticities) replace
		
			


