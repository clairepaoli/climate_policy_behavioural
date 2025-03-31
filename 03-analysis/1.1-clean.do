*******************************************************************************;
* 1. Clean "merged" data
* Author: Claire Paoli
* Date: March 2021
	* Updated March 2025
* Objective: cleaning "merged" data and output "clean" data
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

*******************************************************************************;
** Clean;
*******************************************************************************;

use "$clean/2025.02.26_merged_wprices.dta", clear

** Disaggregate data in "Total Housing, Water, Electricity"
** p604t = sum of codes B010 + B020 + B050 + B053u + B056u + B060 + B102 
** + B104 + B107 +B108 + B159 + (B175 - B178) + B222 + (B170 - B173) + B221 
** + B018 + B017 + C41211t + C43111t + C43112t + C43212c + C44112u + C44211t 
** + C45112t + C45114t + C45212t + C45214t + C45222t + C45312t + C45411t 
** + C45412t + C45511t 

local vars "b010 b020 b050 b053p b056p b060 b102 b104 b107 b108 b159 (b175) b222 c45222t b2231 b226 b1701 (b170) b221 b018 b017 b1751 b1701 b2241 b226 b227 b231 b232 b233 b174 c41211 c43111 c43112 c44211 c45112  c45114  c45212 c45214 c45222 c45312 c45411 c45412  c45511"

foreach var in `vars' {
replace `var' = 0 if `var'==.
}

rename a049 hh_size

* Check weights;
g new_weight = 1000*weighta*hh_size
g tot_sample = .
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(new_weight) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample)

// . tab LCF_round, su(tot_sample)

//              |        Summary of tot_sample
//    LCF_round |        Mean   Std. Dev.       Freq.
// -------------+------------------------------------
// LCF_2001-2.. |    59137751           0       7,473
// LCF_2002-2.. |    57990258           0       6,927
// LCF_2003-2.. |    58149254           0       7,048
// LCF_2004-2.. |    58312500           0       6,798
// LCF_2005-2.. |    58473006           0       6,785
//     LCF_2006 |    58603253           0       6,645
//     LCF_2007 |    59420590   7.451e-09       6,136
//     LCF_2008 |    60365926           0       5,843
//     LCF_2009 |    60596180           0       5,822
//     LCF_2010 |    61372644   7.451e-09       5,263
//     LCF_2011 |    61396239           0       5,691
//     LCF_2012 |    61724678   7.451e-09       5,593
//     LCF_2013 |    63290722           0       5,144
//     LCF_2014 |    63696021           0       5,133
//     LCF_2015 |    63951625           0       4,912
//     LCF_2016 |    64399918           0       5,041
//     LCF_2017 |    64904648   7.451e-09       5,407
//     LCF_2018 |    65106163   7.451e-09       5,473
//     LCF_2019 |    65653789           0       5,438
//     LCF_2020 |    66125956           0       5,400
//     LCF_2021 |    49833974           0       4,182
// -------------+------------------------------------
//        Total |    60946457   3410126.4     122,154


* Calculate tot housing, heating and electricity WITHOUT rebates
// # delimit ;
// g xhouse_calculated = b010 + b020 + b050 + b053p + b056p + b060 + b102 
//  + b104 + b107 +b108 + b159 + (b175 - b178) + b222 + (b170 - b173) + b221 
//  + b018 + b017 + c41211t + c43111t + c43112t + c43212c + c44211t 
//  + c45112t + c45114t + c45212t + c45214t + c45222t + c45312t + c45411t 
//  + c45412t + c45511t;
//  # delimit cr

* 1ST LEVEL OF HH DROPS
* Drop households with positive electricity and gas rebates
	* We are interested in elasticities wrt to carbon intensive goods, so rebates complicate
	* things unncessarily;
drop if b178 > 0 // "Rebate for separate Electricity amount"
* 3885  households dropped
drop if b173 > 0 // "Rebate for separate Gas amount"
* 618 households dropped
drop if b174 > 0 // "Rebate for combined gas and electricity" - only available 2013-2022
* 1,162 observations deleted

* Drop households with only aggregate gas and electricity bill information and no separate amounts (only 252)
* (Note: need to drop because no way to assign price)
* drop if (b231>0 |b232>0 |b233>0 ) & (b226==0 & b227==0)
* Update: no need to drop, as we have the gas and electricity component

* Cap (net) rent payments at 0
replace b010 = 0 if b010<0 // "rent rates - last net payment"
replace b020 = 0 if b020<0 // "Net rent - service charge deducted"

// * Generate housing variables from disaggregated parts
// g xhouse = 0
// * Years 2013-2018
// # delimit ;
// replace xhouse = b010 + b020 + b050 + b053p + b056p + b060 + b102 
//  + b104 + b107 + b108 + b159 + (b175) + b222 + (b170) + b221 + b224 +
//  + b018 + b017 + b1751 + b1701 + b231 +b232 + b233 + c41211 + c43111 + c43112 + c44211 
//  + c45112 + c45114 + c45212 + c45214 + c45222 + c45312 + c45411 
//  + c45412 if year>2012;
 
// replace xhouse = b010 + b020 + b102 + b104 + 
// 	b107 + b108 + b050 + b060 + b159 + 
// 	(b175 - b178) + b224 + (b170 - b173) + 
// 	b223 + b018 + b017 + b053u + b056u + 
// 	b1751 + b1701 + ((b231 + b232 + b233) - (b174)) + 
// 	c41211 + c43111 + c43112 + c44211 + c45112 + c45212 + 
// 	c45222 + c45312 + c45411 + c45412 + c45511 + c44112u
// # delimit cr
// * c44112p missing, water supply in second dwelling

// * Years 2006-2012
// # delimit ;
// replace xhouse = b010 + b020 + b050 + b053p + b056p + b060 + b102 
//  + b104 + b107 + b108 + b159 + (b175) + b222 + (b170) + b221 
//  + b018 + b017 + c41211 + c43111 + c43112 + c44211 
//  + c45112 + c45114 + c45212 + c45214 + c45222 + c45312 + c45411
//  + c45412 if year<2013;
// # delimit cr
 
// drop if xhouse<0
// * 0 dropped

** Energy 
foreach var in b175 p250t b1751 b178 b222 b224 c45114t c45112t b227 b2241 ///
 b017 c45312t c45411t c45412t b018 b170 b173 b1701 b221 b223 b2231 c45212t c45222t p249t b2231 b226 ///
 b010 b020 c41211t b102 b104 b107 b108 c43111t c43112t ///
 b050 b053p b056p c44112u b060 c44211t c45511t b1591 c43212c{
    replace `var' = 0 if missing(`var')
}

gen p6041t = b175 + p250t + b1751 + b178 + b222 + b224 + c45114t + c45112t + (b227 + b2241)
label variable p6041t "efs: total electricity"
order p6041t, after(p604t)
* Excluded combined elec and gas bill, included elec component of combined utilities bill

gen p6042t = b017 + c45312t
label variable p6042t "efs: total liquid fuels: oil, paraffin, water and steam"
order p6042t, after(p604t)
* Oil and paraffin

gen p6043t = c45411t + c45412t
label variable p6043t "efs: total solid fuels: coal and coke, wood and peat"
order p6043t, after(p604t)
* Coal and coke

gen p6044t = b018 + b170 - b173 + b1701 + b221 + b223 + b2231 + c45212t + c45222t + p249t + (b2231 + b226)
label variable p6044t "efs: total gas"
order p6044t, after(p604t)
* Excluded combined elec and gas bill, included gas component of combined utilities bill

gen p6045t = b010 + b020 + c41211t
label variable p6045t "efs: total rents for housing"
order p6045t, after(p604t)

gen p6046t = b102 + b104 + b107 + b108 + c43111t + c43112t + c43212c
label variable p6046t "efs: regular maintenance and repair of dwelling"
order p6046t, after(p604t)

gen p6047t = b050 + b053p + b056p + c44112u + b060 + c44211t + c45511t + b159
label variable p6047t "efs: water supply and services for dwelling"
order p6047t, after(p604t)

g xhouse = p6041t + p6042t + p6043t + p6044t + p6045t + p6046t + p6047t

// drop xhouse
// rename xhouse2 xhouse

* Compare with p604t (Total Housing, Water, Electricity)
g check_xhouse = xhouse/p604t-1
* 2-3% diff between 2001-2012, 0% after

foreach var in p6041t p6042t p6043t p6044t p6045t p6046t p6047t {
    count if `var' == 0
}

// * Rounding issue
// replace p6043t=0 if p6043t<0

* out of 116,489 hh...
* hh with 0 electricity: 6,621
* hh with 0 liquid fuels: 109,135
* hh with 0 solid fuels: 113,283
* hh with 0 gas: 89,537
* hh with 0 on all: 358 

*******************************;
* Transport;
*******************************;

su b244 b245 b247 b249 b250 b252 b248 b218 b217 b219 b216

* Drop households with no expenditure on gas and electricity
* drop if (p6041t==0&p6042t==0&p6043t==0&p6044t==0)
*(3,094 observations deleted)

foreach var in b244 b245 b247 c71111c c71112t c71121c c71122t c71211c c71212t c71311t c71411t ///
 b249 b250 b252 c72111t c72112t c72113t c72114t c72115t ///
 c72211t c72212t c72213t c72311c c72312c c72313t c72314t c72411t c72412t c72413t ///
 b248 b216 b217 b218 b219 c73112t c73212t c73213t c73214t c73311t ///
 c73312t c73411t c73512t c73513t c73611t c72414t b487 b488 {
    replace `var' = 0 if missing(`var')
}
 
* Purchase of vehicles
g p6071t = b244 + b245 + b247 + c71111c + c71112t + c71121c + c71122t + c71211c + c71212t + c71311t + c71411t
* Operation of personal transport
g p6072t = b249 + b250 + b252 + c72111t + c72112t + c72113t + c72114t + c72115t+ c72211t + c72212t + c72213t + c72311c + c72312c + c72313t + c72314t + c72411t + c72412t + c72413t
* Transport services
g p6073t = b248 + b216 + b217 + b218 + b219 + c73112t + c73212t + c73213t + ///
	c73214t + c73311t + c73312t + c73411t + c73512t + c73513t + c73611t + c72414t + ///
	b487 + b488
order p6071t, after(p607t)
order p6072t, after(p6071t)
order p6073t, after(p6072t) 

* p6073t is disaggregated
g xrail = b218 + c73112t
* CPI_731 - passenger transport by rail
g xroad = b217 + c73212t + c73213t + c73214t + c73512t + b216 + c72414t + b248 
* CPI_732 - passenger transport by road and other services
g xair = c73311t + c73312t + b487 + b488
* CPI_733 - passenger transport by air
g xsea = c73411t + b219
* CPI_734 - passenger transport by water/sear
g xtransport_other = c73513t + c73611t

* Check total transport costs
g xtransport_calculated = p6071t + p6072t + p6073t
g check_xtransport = xtransport_calculated/p607t-1
* All years expect 2014 and 2016  are ok

// * 2ND LEVEL OF HH DROPS
// * Drop if trasport costs are negative
// drop if p6071t<0 | p6072t<0 | p6073t<0
// * 31 obs deleted

* Drop vars not needed
// drop c11111-cc1316l
// drop c11121w-cc3211w
// drop fs11-fs1455
// drop p600-p620cp

foreach var in p601t p602t p603t p605t p606t p607t p608t p609t p610t p611t p612t {
    replace `var' = 0 if missing(`var')
}

* Rename expenditure vars
rename p601t xfood_only
rename p602t xalc
rename p603t xcloth

rename p6047t xwater
rename p6046t xmaint
rename p6045t xrents
rename p6044t xgas
rename p6043t xcoal
rename p6042t xfuels
rename p6041t xelec

rename p605t xfurn
rename p606t xhealth

rename p607t xtransport_orig
rename p6071t xt71
rename p6072t xt72
rename p6073t xt73
g xtransport_calc = xt71 + xt72 + xt73

rename p608t xcomm
rename p609t xrecr
rename p610t xeduc
rename p611t xrest
rename p612t xother

* Generate total expenditure
g xtot = xfood_only + xalc + xcloth + xhouse + xfurn + xhealth + xtransport_calc + xcomm + xrecr + xeduc + xrest + xother
g xheating = xgas + xcoal + xfuels + xelec

* Rename price vars
rename CPI_6 phealth
order phealth, after(xhealth)

rename CPI_1 pfood_only
order pfood, after(xfood)

rename CPI_2 palc
order palc, after(xalc)

rename CPI_3 pcloth
order pcloth, after(xcloth)

rename CPI_4 phouse
order phouse, after(xhouse)

rename CPI_451 pelec
order pelec, after(xelec) 

rename CPI_452 pgas
order pgas, after(xgas)

rename CPI_453 pfuels
order pfuels, after(xfuels)

rename CPI_454 pcoal
order pcoal , after(xcoal)

rename CPI_41 prents
order prents, after(xrents)

rename CPI_43 pmaint
order pmaint, after(xmaint)

rename  CPI_44 pwater
order pwater, after(xwater)

rename CPI_5 pfurn
order pfurn, after(xfurn)

rename CPI_7 ptransport
order ptransport, after(xtransport_calc)

rename CPI_71 pt71
order pt71, after(xt71)

rename CPI_72 pt72
order pt72, after(xt72)

rename CPI_73 pt73
order pt73, after(xt73)

rename CPI_731 prail
rename CPI_732 proad
rename CPI_733 pair
rename CPI_734 psea
rename CPI_735 ptransport_other

rename CPI_8 pcomm
order pcomm, after(xcomm)

rename CPI_9 precr
order precr, after(xrecr)

rename CPI_10 peduc
order peduc, after(xeduc)

rename CPI_11 prest
order prest, after(xrest)

rename CPI_12 pother
order pother, after(xother)

*******************************************************************************;
** Main HH char
*******************************************************************************;

* Region
** 01 = north east, 02 = north west and merseyside, 03 = yorkshire and the humber, 
** 04 = east midlands, 05 = west midlands, 06 = eastern, 07 = london, 08 = south east, 09 = south west,
** 10 = wales, 11 = scotland, 12 = northern ireland
rename gorx region // "Government Office Region modified"
foreach num of numlist 1/12 {
gen region_`num'=(region==`num')
} 

* Household size and composition
rename a062 hh_comp

rename g019 n_children
rename g018 n_adults

* Tenure type (rent, owned etc)
rename a122 tenure_type

* Number of cars used or owned by hh
rename a160 n_cars
g n_cars2 = (n_cars==0)
replace n_cars2 = 1 if n_cars==1
replace n_cars2 = 2 if n_cars==2
replace n_cars2 = 3 if n_cars>2
label define n_cars2 0 "0 cars or vans" 1 "1 car or van" 2 "2 cars or vans" 3 "3+ cars or vans"
label values n_cars2 n_cars2

rename a114p n_rooms

* Number of people economically active
rename a056 n_econ

* Income range of HRP
rename a060 income_pw

* Age group and sex
* sexhrp
egen  agehrp = cut(a005p), at(0,15,24,34,49, 64, 74, 100)
g m_65 = (a005p>64)
tab sexhrp agehrp, row

* Dwelling type
rename a116 dwelling_type
gen Whole_House =(inlist(dwelling_type,1,2,3))
gen Flat = (inlist(dwelling_type,4,5))
gen Other_dwelling = (dwelling_type==6)

gen Rented = (inlist(tenure_type,1,2,3,4))
gen Owned = (inlist(tenure_type,5,6,7))


* Ethnicity
gen ethnicityhrp = a012p
replace ethnicityhrp = 3 if ethnicityhrp==6
replace ethnicityhrp = 4 if ethnicityhrp==10
label define ethnicityhrp 0 "not applicable" 1 "white" 2 "mixed race" 3 "asian" 4 "black" 5 "other"
label values ethnicityhrp ethnicityhrp


* Type of central heating
g central_heating = (a150==1 | a151==1 | a152==1 | a153==1 | a154==1 | a155==1| a156==1)

rename a150 eletric_heating
rename a151 gas_heating
rename a152 oil_heating
rename a153 solidfuel_heating
gen other_heating =( a155==1 | a156==1)

* Gas electric supplied to accomodation
rename a103 electricity_supplied

* No dwelling age

*******************************************************************************;
** HH level income variables
*******************************************************************************;

* Number of persons economically active
tab n_econ

* Check composition of hh where at least 3 economically active persons
tab hh_comp if n_econ > 2

* Generally at least three adults, or children

//   Number of |
//     persons |
// economicall |
//    y active |      Freq.     Percent        Cum.
// ------------+-----------------------------------
//           0 |     38,498       33.05       33.05
//           1 |     33,107       28.42       61.47
//           2 |     36,612       31.43       92.90
//           3 |      6,310        5.42       98.32
//           4 |      1,685        1.45       99.76
//           5 |        240        0.21       99.97
//           6 |         33        0.03      100.00
//           7 |          2        0.00      100.00
//           9 |          2        0.00      100.00
// ------------+-----------------------------------
//       Total |    116,489      100.00



* Economic position of HRP 
rename a093 economic_position
gen unemployed = (economic_position==4)
gen employed = (inlist(economic_position, 1,2,3,5))
gen inactive = (inlist(economic_position, 6,7))
tab economic_position
** 01 = self-employed, 02 = full time employee, 03 = pt employee, 04 = unemployed,
** 05 = work related training, 06 = retiree over min retirement age, 07 = retiree under min retirement age 

** Whether HRP is students and retiree
gen student = (inactive==1 & a015==3)
gen retiree = (inactive==1 & a015==2) 
* this includes those that checked "Retired / unoccupied & minimum NI age", ages 49+

* Economic position of spouse
gen employed_spouse = (a015_spouse==1)
tab economic_position	  
tab employed_spouse

* HHs with both HRP and spouse working
g hh_two_incomes = (employed_spouse==1&employed==1)
* 30 % of hh each year

* HHs with only HRP working
g hh_one_income = (employed_spouse==0&employed==1)
tab hh_one_income
* 26 % of hh each year

** HH weekly salary
g income_wk_salary = p356 // "normal gr wage\salary(all ),hhld-13wk rl - top-coded"
replace income_wk_salary = p356p if income_wk_salary == .

g income_wk_self = p320 // "income from self-employment - hhld" (2001-2006), "income from self-employment - hhld - top-coded"
replace income_wk_self = p320p if income_wk_self == .

g income_wk_invest  = p324 // "income from investments - household"
replace income_wk_invest = p324p if income_wk_invest ==.

g income_wk_ss = p348 // "social security benefits - household"

g income_wk_pension = p328 // "Income from annuities, pensions - household"
replace income_wk_pension = p328p if income_wk_pension == .

g income_wk_other = p340 // "Income from other sources - household"
replace income_wk_other = p340p if income_wk_other ==.

g income_wk_tot = p344 // "gross normal weekly household income - top-coded"
 replace income_wk_tot = p344p if income_wk_tot == .  

g income_wk_disposable = p389 // "Normal weekly disposable hhld income - top-coded"
replace income_wk_disposable = p389p if income_wk_disposable == .

local vars "income_wk_salary income_wk_self income_wk_invest income_wk_ss income_wk_pension income_wk_other income_wk_tot income_wk_disposable"
foreach var in `vars'{
replace `var'=0 if `var'==.
}

* Check that total weekly gross income from data matches calculated gross income
g income_wk_tot_calculated = income_wk_salary + income_wk_self + income_wk_invest + income_wk_ss + income_wk_pension + income_wk_other
g check_income = income_wk_tot_calculated/income_wk_tot - 1
* exactly the same for 2001-2005, for 2006 to 2021, income_wk_tot_calculated 
* is 5-6% lower than income_wk_tot

g social_sec_share = income_wk_ss/income_wk_tot_calculated
* social security payments are on average 30% of total weekly income - seems high

* Main source of income
rename p425 income_source
* 0 = not recorded, 1 = wage salaries, 2 = self-employment, 3 = investment income
* 4 = annuities pensions, 5 = social security benefits, 6 = income-other sources

** Income taxes;
g income_paye_tax = p390
replace income_paye_tax = p390p if income_paye_tax == .

g income_paye_tax_net_reductions = p392 
replace income_paye_tax_net_reductions = p392p if income_paye_tax_net_reductions == .

g income_tax_annual = income_paye_tax*52

* g income_paye_tax_refund = p391
* g income_paye_tax_net = p392p 

g ni_contribution = p388  
replace ni_contribution = p388p if ni_contribution == .

local vars "income_paye_tax income_paye_tax_net_reductions ni_contribution"
foreach var in `vars'{
replace `var'=0 if `var'==.
}

// local vars "p392p p388p"
// foreach var in `vars'{
// replace `var'=0 if `var'==.
// }

g deductions = income_paye_tax_net_reductions + ni_contribution

* gen income_taxable = income_wk_tot - ss_only
gen income_taxable_wk = income_wk_salary + income_wk_self + income_wk_pension
su income_taxable_wk

* Annual taxable income (before tax deductions and trasfers):
gen income_taxable_annual = (income_taxable_wk) * 52
gen income_annual_tot_calculated = (income_wk_tot_calculated) * 52
su income_taxable_annual income_annual_tot_calculated

* Average income tax rate = reported weekly income tax * 52 / annual taxable income
gen avg_income_tax = income_tax_annual/income_taxable_annual
replace avg_income_tax = 0 if avg_income_tax==.
* average income tax is 6%, which is very low

* Average income tax rate = reported weekly income tax net of reductions * 52 / annual taxable income
gen avg_income_tax_net =  income_paye_tax_net_reductions*52/income_taxable_annual
replace avg_income_tax_net = 0 if avg_income_tax_net==.
* The mean is 21%, seems more reasonable

* Average income tax rate = reported weekly income tax net of reductions * 52 / annual salary income
* gen avg_income_tax_net2 =  income_paye_tax_net_reductions*52/(income_wk_salary*52)
* replace avg_income_tax_net2 = 0 if avg_income_tax_net2==.
* income_wk_salary is 0 for 46,803 hhs, 

* drop if income_tax>1
* 5 hhs dropped

*******************************************************************************;
** HRP level income variables;
*******************************************************************************;
local vars "p007 p007p p006 p006p p047p p047 p037p p037 p048 p048p p049 p049p p051 p051p a220 a244 a221"
foreach var in `vars' {
replace `var' = 0 if `var'==.
}

g income_hrp_labor_gross = p007
replace income_hrp_labor_gross = p007p if income_hrp_labor_gross == .
label variable income_hrp_labor_gross "Normal gross wage/salary of HRP, weekly"

g income_hrp_labor_net = p006
replace income_hrp_labor_net = p006p if income_hrp_labor_net == .
label variable income_hrp_labor_gross "Normal take home pay of HRP, weekly"

g income_hrp_self = p047p + p037p

g income_hrp_capital = p048
replace income_hrp_capital = p048p if income_hrp_capital == .
label variable income_hrp_capital "Total income from investments, weekly"

g income_hrp_pension = p049
replace income_hrp_pension = p049p if income_hrp_pension == .
label variable income_hrp_pension "Total income from pensions, weekly"

g income_hrp_other = p050
label variable income_hrp_other "Total income from other sources, weekly"

g income_hrp_wk_tot = p051
replace income_hrp_wk_tot = p051p if income_hrp_wk_tot == .
label variable income_hrp_wk_tot "Total personal gross income, weekly"

// g income_hrp_labor = p199p

* Weekly hours worked as employee
gen wk_hours_worked_hrp = a220 + a244
** a220 = usual weekly hours (excluding breaks and overtime)
** a244 = Hours paid overtime usually worked
** 2444 = Hours unpaid overtime usually worked (did not include)

* Weekly hours worked as self-employed
gen wk_hours_worked_hrp_self = a221
** a221 = self employed: usual weekly hours worked

* Total weekly hours worked (employee or self-employed)
gen wk_hours_worked_hrp_tot = wk_hours_worked_hrp + wk_hours_worked_hrp_self
replace wk_hours_worked_hrp_tot = 0 if wk_hours_worked_hrp_tot==.
replace wk_hours_worked_hrp_tot = 100 if wk_hours_worked_hrp_tot>100

* Drop households in which HRP is working in some way but no reported hours
su hh_id if (economic_position==1|economic_position==2|economic_position==3) & wk_hours_worked_hrp_tot==0
drop if (economic_position==1|economic_position==2|economic_position==3) & wk_hours_worked_hrp_tot==0
* 16 housholds, all self-employed. Drop them.

*******************************************************************************;
** Spouse income variables;
*******************************************************************************;
local hours "a220_spouse a244_spouse a2444_spouse a221_spouse"
foreach var in `hours' {
replace `var' = 0 if `var'==. & a015_spouse!=.
}

* Weekly hours worked as employee:
gen wk_hours_worked_spouse = a220_spouse + a244_spouse

* Weekly hours worked as self-employed
gen wk_hours_worked_spouse_self = a221_spouse

* Total weekly hours worked (employee or self-employed)
gen wk_hours_worked_spouse_tot = wk_hours_worked_spouse + wk_hours_worked_spouse_self
replace wk_hours_worked_spouse_tot = 0 if wk_hours_worked_spouse_tot==.
replace wk_hours_worked_spouse_tot = 100 if wk_hours_worked_spouse_tot>100

g income_spouse_labor_gross = p007p_spouse
label variable income_spouse_labor_gross "Normal gross wage/salary of HRP, weekly"

g income_spouse_self = p047p_spouse + p037p_spouse
g income_spouse_capital = p049_spouse

g income_spouse_wk_tot = p051p_spouse
label variable income_spouse_wk_tot "Total personal gross income (normal) - top-coded"

*******************************************************************************;
* Income Tax Rate - Modeling UK Tax System; FIX;
*******************************************************************************;

* Income tax is implemented at hh level in the model;
* UK Income Tax Rates and Bands
* up to 12,500, 0%
* 12,501 - 50,000, 20%
* 50,001 - 150,000 40%
* over 150,000 45%
* Taxpayer's income is assessed for tax according to a prescribed order, 
* with income from employment using up the personal allowance and being taxed first, 
* followed by savings income (from interest or otherwise unearned) and then dividends.

*******************;
* HH level;
*******************;

* Tax brackets;
gen cat_1 = 0
replace cat_1 = 1 if (income_taxable_annual<=11500)
replace cat_1 = 2 if (income_taxable_annual>11500 & income_taxable_annual<=45000)
replace cat_1 = 3 if (income_taxable_annual>45000 & income_taxable_annual<=150000)
replace cat_1 = 4 if (income_taxable_annual>150000)

* Compute marginal mechanically;
* Marginal taxes;
gen mar_tax = 0
replace mar_tax = 0 if (cat_1==1)
replace mar_tax = 0.20 if (cat_1==2)
replace mar_tax = 0.40 if (cat_1==3)
replace mar_tax = 0.45 if (cat_1==4)

* Gen total tax paid (calculated on hh taxable ncome);
gen tax_annual_calculated = 0
replace tax_annual_calculated = 0 if cat_1==1
replace tax_annual_calculated = 0.20*(income_taxable_annual-11500) if cat_1==2
replace tax_annual_calculated = 0.20*(45000-11501) + 0.4*(income_taxable_annual-45001) if cat_1==3
replace tax_annual_calculated = 0.20*(45000-12501) + 0.4*(150000-45001) + 0.45*(income_taxable_annual-150001) if cat_1==4
* tax_annual_calculated (calculated) is much higher than income_tax_annual (from data)

* Total hours (hrp + spouse)
gen hh_hours_wk_tot = wk_hours_worked_spouse_tot + wk_hours_worked_hrp_tot

* Average annual tax;
gen avg_tax_calculated = tax_annual_calculated/income_taxable_annual
replace avg_tax_calculated=0 if avg_tax_calculated==.

* Pre-tax wage;
gen wage_notax = (income_wk_self + income_wk_salary)/hh_hours_wk_tot
replace wage_notax = 0 if wage_notax==.

*g hourly_tax = income_paye_tax_net/hours_tot
*replace hourly_tax=0 if hourly_tax==.
*gen wage_tax =  wage_notax - hourly_tax

gen wage_tax2 =  wage_notax*(1-mar_tax)

gen exp_share = xtot/income_wk_tot_calculated

* adjust deductions so that they are calculated from the derived tax
replace deductions = tax_annual_calculated/52 + ni_contribution

* Total savings;
gen savings_wk = income_wk_tot_calculated - deductions - xtot 
* Assume that income > expenditure = savings
// replace income_wk_tot = income_wk_tot_calculated + abs(savings_wk) if savings_wk<0
su savings_wk

* deductibles
gen income_tax_refunds = p391
gen check_refunds_share = income_tax_refunds/income_paye_tax
gen deductibles = income_paye_tax - income_paye_tax_net_reductions

*******************************************************************************;
** Household Types;
*******************************************************************************;

*****household types (8 types)
* 01 Other
g het_household=1
* 02 Retirees
replace het_household=2   if (retiree==1)
* 03 Students
replace het_household=3   if (student==1)
* 04 Working: single with no children
replace het_household=4   if employed==1 & (hh_comp==1|hh_comp==2)
* 05 Working: single with children
replace het_household=5   if employed==1 & inlist(hh_comp,3,4,5,6)
* 06 Working: couple with no children
replace het_household=6   if employed==1 & inlist(hh_comp,7,8)
* 07 Working: couple with up to 2 children
replace het_household=7   if employed==1 & inlist(hh_comp,9,10,11,12)
* 08 Working: couple with >2 children
replace het_household=8   if employed==1 & inlist(hh_comp,13,14,15,16,17)

* Note that "other" includes households of (unemployed) and (inactive hhs which are not retirees or students)

* Dummies for dwelling characteristics:
	* central heating, no central heating, (urban vs rural), male HRP, female HRP
	* flat vs. whole house
	
	
* Check weights again:
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(new_weight) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample)
* Still representative;


// #delimit ;
//  order LCF_round new_weight mscale oecdsc hh_size hh_comp n_children n_adults tenure_type n_cars n_cars2 n_econ 
//  income_pw agehrp m_65 sexhrp n_rooms dwelling_type Whole_House Flat Other_dwelling 
//  Rented Owned ethnicityhrp student retiree central_heating eletric_heating 
//  gas_heating oil_heating solidfuel_heating other_heating economic_position 
//  unemployed employed inactive het_household, after(weighta);
 
// #delimit cr


save "$clean/2025.03.29_clean.dta", replace

*******************************************************************************;

// #delimit ;
// su xhouse xtot xfood xalc xcloth xhouse xgas xcoal xfuels xrents 
// xwater xmaint xelec xfurn xhealth xtransport xcomm xrecr 
// xeduc xrest xother [aw=weighta];

// su phouse pfood palc pcloth phouse pgas pcoal pfuels prents pwater pmaint pelec 
// pfurn phealth ptransport pcomm precr peduc prest pother [aw=weighta];
// #delimit cr





