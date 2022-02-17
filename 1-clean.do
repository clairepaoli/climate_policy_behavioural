*******************************************************************************;
* 1. Clean "merged" data
* Author: Claire Paoli
* Date: March 2021
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

global path "/Volumes/My Passport for Mac/Research/Projects/Carbon Pricing/2-analysis/01-data"
global raw "$path/raw"
global temp "$path/temp"
global clean "$path/clean"

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

use "$clean/merged.dta", clear

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
local varlist "LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018"
foreach year in `varlist'{
sum(new_weight) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample)

// . tab LCF_round, su(tot_sample)

//             |        Summary of tot_sample
//   LCF_round |        Mean   Std. Dev.       Freq.
// ------------+------------------------------------
//    LCF_2006 |    58603253           0       6,645
//    LCF_2007 |    59420590   7.451e-09       6,136
//    LCF_2008 |    60365926           0       5,843
//    LCF_2009 |    60596180           0       5,822
//    LCF_2010 |    61372644   7.451e-09       5,263
//    LCF_2011 |    59827931           0       5,551
//    LCF_2012 |    60372326           0       5,473
//    LCF_2013 |    62907171   7.451e-09       5,116
//    LCF_2014 |    62614867   7.451e-09       5,055
//    LCF_2015 |    63178465           0       4,862
//    LCF_2016 |    63902243   7.451e-09       5,007
//    LCF_2017 |    64482446           0       5,371
//    LCF_2018 |    64482160           0       5,431
// ------------+------------------------------------
//       Total |    61572903   1948800.1      71,575


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
drop if b178 > 0
* 1769  households dropped
drop if b173 > 0
* 502 households dropped
drop if b174 > 0
* 478 observations deleted

* Drop households with only aggregate gas and electricity bill information and no separate amounts (only 104)
* (Note: need to drop because no way to assign price)
drop if (b231>0 |b232>0 |b233>0 ) & (b226==0 & b227==0)

* Cap (net) rent payments at 0
replace b010 = 0 if b010<0
replace b020 = 0 if b020<0

* Generate housing variables from disaggregated parts
g xhouse = 0
* Years 2013-2018
# delimit ;
replace xhouse = b010 + b020 + b050 + b053p + b056p + b060 + b102 
 + b104 + b107 + b108 + b159 + (b175) + b222 + (b170) + b221
 + b018 + b017 + b1751 + b1701 + b231 +b232 + b233 + c41211 + c43111 + c43112 + c44211 
 + c45112 + c45114 + c45212 + c45214 + c45222 + c45312 + c45411 
 + c45412 if year>2012;
# delimit cr
* c44112p missing, water supply in second dwelling

* Years 2006-2012
# delimit ;
replace xhouse = b010 + b020 + b050 + b053p + b056p + b060 + b102 
 + b104 + b107 + b108 + b159 + (b175) + b222 + (b170) + b221 
 + b018 + b017 + c41211 + c43111 + c43112 + c44211 
 + c45112 + c45114 + c45212 + c45214 + c45222 + c45312 + c45411
 + c45412 if year<2013;
# delimit cr
 
drop if xhouse<0
* 0 dropped

** Energy 
gen p6041t = b175 + b222 + c45114 + c45112 + b1751 + b1751 + b227 + b2241
label variable p6041t "efs: total electricity"
order p6041t, after(p604t)
gen p6042t = b017 + c45312
label variable p6042t "efs: total liquid fuels"
order p6042t, after(p604t)
gen p6043t = c45411 + c45411 + c45412
label variable p6043t "efs: total solid fuels"
order p6043t, after(p604t)
gen p6044t = b018 + b170 + b221 + c45212 + c45214 + c45222 + b2231 + b226 + b1701
label variable p6044t "efs: total gas"
order p6044t, after(p604t)
gen p6045t = b010 + b020 + c41211
label variable p6045t "efs: total rents for housing"
order p6045t, after(p604t)
gen p6046t = b102 + b104 + b107 + b108 + b159 + c43111 + c43112 
label variable p6046t "efs: regular maintenance and repair of dwelling"
order p6046t, after(p604t)
gen p6047t = b050 + b053p + b056p + b060 + c44211
label variable p6047t "efs: water supply and services for dwelling"
order p6047t, after(p604t)
g xhouse2 = p6041t+p6042t+p6043t+p6044t+p6045t+p6046t+p6047t

drop xhouse
rename xhouse2 xhouse

* Rounding issue
replace p6043t=0 if p6043t<0

* out of 61,837 hh...
* hh with 0 electricity: 3,857
* hh with 0 oil: 58,047
* hh with 0 coal: 60,307
* hh with 0 gas: 14,098
* hh with 0 on all: 2,810 

*******************************;
* Transport;
*******************************;

su b244 b245 b247 b249 b250 b252 b248 b218 b217 b219 b216

* Drop households with no expenditure on gas and electricity
* drop if (p6041t==0&p6042t==0&p6043t==0&p6044t==0)
*(3,094 observations deleted)
 
/*
preserve
keep b244 b245 b247 b249 b250 b252 b248 b218 b217 b219 b216 c71111c c71112t c71121c c71122t c71211c c71212t c71311t c71411t c72111t c72112t c72113t c72114t c72115t c72211t c72212t c72213t c72311c c72312c c72313t c72314t c72411t c72412t c72413t c72414t c73112t c73212t c73213t c73214t c73311t c73312t c73411t c73512t c73513t c73611t
replace */


g p6071t = b244 + b245 + b247 + c71111c + c71112t + c71121c + c71122t + c71211c + c71212t + c71311t + c71411t
g p6072t = b248 + b249 + b250 + b252 + c72111t + c72112t + c72113t + c72114t + c72115t+ c72211t + c72212t + c72213t + c72311c + c72312c + c72313t + c72314t + c72411t + c72412t + c72413t + c72414t
g p6073t = b216 + b217 + b218 + b219 + c73112t + c73212t + c73213t + c73214t + c73311t + c73312t + c73411t + c73512t + c73513t + c73611t
order p6071t, after(p607t)
order p6072t, after(p6071t)
order p6073t, after(p6072t) 

* 2ND LEVEL OF HH DROPS
* Drop if trasport costs are negative
drop if p6071t<0 | p6072t<0 | p6073t<0

* Drop vars not needed
// drop c11111-cc1316l
// drop c11121w-cc3211w
// drop fs11-fs1455
// drop p600-p620cp

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
rename p607t xtransport
rename p6071t xt71
rename p6072t xt72
rename p6073t xt73
rename p608t xcomm
rename p609t xrecr
rename p610t xeduc
rename p611t xrest
rename p612t xother

g xair = c73311t + c73312t
g xrail = c73112t
g xroad = c73212t + c73213t + c73214t
g xsea = c73411t
g xtransport_other = c73512t + c73513t + c73611t

* Generate total expenditure
g xtot = xfood_only+xalc+xcloth+xhouse+xfurn+xhealth+xtransport+xcomm+xrecr+xeduc+xrest+xother

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
order pwater , after(xwater)

rename CPI_5 pfurn
order pfurn, after(xfurn)

rename CPI_7 ptransport
order ptransport, after(xtransport)

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
rename gorx region
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

* Whether HRP is employed
rename a093 economic_position
gen unemployed = (economic_position==4)
gen employed = (inlist(economic_position, 1,2,3,5))
gen inactive = (inlist(economic_position, 6,7))
tab economic_position
** 01 = self-employed, 02 = full time employee, 03 = pt employee, 04 = unemployed,
** 05 = work related training, 06 = retiree over min retirement age, 07 = retiree under min retirement age 

** Students and retirees
gen student = (inactive==1 & a015==3)
gen retiree = (inactive==1 & a015==2) 
* this includes those that checked "Retired / unoccupied & minimum NI age", ages 49+


* Whether spouse is employed
gen employed_spouse = (a015_spouse==1)
tab economic_position	  
tab employed_spouse


* HHs with both HRP and spouse working
g hh_two_incomes = (employed_spouse==1&employed==1)
* 30 % of hh each year

* HHs with only HRP working
g hh_one_income = (employed_spouse==0&employed==1)
* 30 % of hh each year

** HH weekly salary
g inc_wk_salary_tot = p356
g inc_wk_self = p320
g inc_wk_invest  = p324
replace inc_wk_invest = p324p if inc_wk_invest ==.
g income_wk_ss = p348
g income_wk_pension = p328
replace income_wk_pension = p328p if income_wk_pension ==.
g income_wk_other = p340 
replace income_wk_other = p340p if income_wk_other ==.
g income_wk_tot = p344

g income_wk_disposable = p389

local vars "inc_wk_salary_tot inc_wk_self inc_wk_invest income_wk_ss income_wk_pension income_wk_other income_wk_tot income_wk_disposable"
foreach var in `vars'{
replace `var'=0 if `var'==.
}

g social_sec_share = income_wk_ss/income_wk_tot


* Main source of income
rename p425 income_source
* 01 = not recorded, 02 = wage salaries, 03 = self-employment, 04 = investment income
* 05 = annuities pensions, 06 = social security benefits, 07 = income-other sources

** Income taxes;
g income_paye_tax = p390p 
replace income_paye_tax = 0 if income_paye_tax==.

g income_tax_annual = income_paye_tax*52
g income_paye_tax_refund = p391
g income_paye_tax_net = p392p 
g ni_contribution = p388p 
g income_transfers = p203 

local vars "income_paye_tax_refund income_paye_tax_net ni_contribution income_transfers"
foreach var in `vars'{
replace `var'=0 if `var'==.
}

local vars "p392p p388p"
foreach var in `vars'{
replace `var'=0 if `var'==.
}

g deductions = p392p + p388p

* gen income_taxable = income_wk_tot - ss_only
gen income_taxable = inc_wk_salary_tot + inc_wk_self + income_wk_pension
su income_taxable

* Total savings;
gen savings = income_wk_tot - xtot
replace income_wk_tot = income_wk_tot + abs(savings) if savings<0
su savings

* Annual taxable income (before tax deductions and trasfers):
gen taxable_income_annual = (income_taxable) * 52
gen income_annual = (income_wk_tot) * 52
su taxable_income_annual income_annual

gen income_tax = income_tax_annual/taxable_income_annual
replace income_tax = 0 if income_tax==.

gen income_tax_net =  income_paye_tax_net/income_taxable
replace income_tax_net = 0 if income_tax_net==.

gen income_tax_net2 =  income_paye_tax_net/inc_wk_salary_tot
replace income_tax_net2 = 0 if income_tax_net2==.

drop if income_tax>1

*******************************************************************************;
** HRP level income variables;
*******************************************************************************;

g income_hrp_labor_gross = p007p 
label variable income_hrp_labor_gross "Normal gross wage/salary of HRP, weekly"
g income_hrp_labor_net = p006p 
g income_hrp_self = p047p + p037p
g income_hrp_capital = p049
replace income_hrp_capital = p049p if income_hrp_capital == .
g income_hrp_tot = p051p
label variable income_hrp_tot "Total personal gross income, weekly"
g income_hrp_labor = p199p

* Weekly hours worked as employee
gen wk_hours_worked_hrp = a220 + a244 + a2444
** a220 = weekly hours (excluding breaks and overtime)
** a221 = self employed: usual weekly hours worked (did not inclue)
** a244 = Hours paid overtime usually worked
** 2444 = Hours unpaid overtime usually worked

* Weekly hours worked as self-employed
gen wk_hours_worked_hrp_self = a221

* Total weekly hours worked (employee or self-employed)
gen wk_hours_worked_hrp_tot = wk_hours_worked_hrp + wk_hours_worked_hrp_self
replace wk_hours_worked_hrp_tot = 0 if wk_hours_worked_hrp_tot==.
replace wk_hours_worked_hrp_tot = 100 if wk_hours_worked_hrp_tot>100

* Drop households in which HRP is working in some way but no reported hours
su hh_id if (economic_position==1|economic_position==2|economic_position==3) & wk_hours_worked_hrp_tot==0
drop if (economic_position==1|economic_position==2|economic_position==3) & wk_hours_worked_hrp_tot==0
* 10 housholds, all self-employed. Drop them. 

*******************************************************************************;
** Spouse income variables;
*******************************************************************************;
local hours "a220_spouse a244_spouse a2444_spouse a221_spouse"
foreach var in `hours' {
replace `var' = 0 if `var'==. & a015_spouse!=.
}

* Weekly hours worked as employee:
gen wk_hours_worked_spouse = a220_spouse + a244_spouse + a2444_spouse

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
g income_spouse_tot = p051p_spouse
label variable income_spouse_tot "Total personal gross income, weekly"
g income_spouse_labor = p199p_spouse

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

* In data

* income_paye_tax
* ni_contribution

*******************;
* HH level;
*******************;

* gen income_tot = income_labor + income_capital_2 + income_capital_3 + income_transfers_public+ income_transfers_nopublic


* Tax brackets;
gen cat_1 = 0
replace cat_1 = 1 if (taxable_income_annual<=11500)
replace cat_1 = 2 if (taxable_income_annual>11500 & taxable_income_annual<=45000)
replace cat_1 = 3 if (taxable_income_annual>45000 & taxable_income_annual<=150000)
replace cat_1 = 4 if (taxable_income_annual>150000)

* Compute marginal mechanically;
* Marginal taxes;
gen mar_tax = 0
replace mar_tax = 0 if (cat_1==1)
replace mar_tax = 0.20 if (cat_1==2)
replace mar_tax = 0.40 if (cat_1==3)
replace mar_tax = 0.45 if (cat_1==4)

* Gen total tax paid (calculated on hh taxable ncome);
gen tax = 0
replace tax = 0 if cat_1==1
replace tax = 0.20*(taxable_income_annual-11500) if cat_1==2
replace tax = 0.20*(45000-11501) + 0.4*(taxable_income_annual-45001) if cat_1==3
replace tax = 0.20*(45000-12501) + 0.4*(150000-45001) + 0.45*(taxable_income_annual-150001) if cat_1==4

* Total hours (hrp + spouse)
gen hours_tot = wk_hours_worked_spouse_tot + wk_hours_worked_hrp_tot

* Average annual tax;
gen aver_tax = tax/taxable_income_annual
replace aver_tax=0 if aver_tax==.

* Pre-tax wage;
gen wage_notax = (inc_wk_self + inc_wk_salary_tot)/hours_tot
replace wage_notax = 0 if wage_notax==.

*g hourly_tax = income_paye_tax_net/hours_tot
*replace hourly_tax=0 if hourly_tax==.
*gen wage_tax =  wage_notax - hourly_tax

gen wage_tax2 =  wage_notax*(1-mar_tax)

gen exp_share = xtot/income_wk_tot


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
replace het_household=6   if employed==1 & inlist(hh_comp,6,8)
* 07 Working: couple with up to 2 children
replace het_household=7   if employed==1 & inlist(hh_comp,9,10,11,12)
* 08 Working: couple with >2 children
replace het_household=8   if employed==1 & inlist(hh_comp,13,14,15,16,17)

* Note that "other" includes households of (unemployed) and (inactive hhs which are not retirees or students)

* Dummies for dwelling characteristics:
	* central heating, no central heating, (urban vs rural), male HRP, female HRP
	* flat vs. whole house
	
	
* Check weights again:
local varlist "LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018"
foreach year in `varlist'{
sum(new_weight) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample)
* Still representative;


#delimit ;
 order LCF_round new_weight mscale oecdsc hh_size hh_comp n_children n_adults tenure_type n_cars n_cars2 n_econ 
 income_pw agehrp m_65 sexhrp n_rooms dwelling_type Whole_House Flat Other_dwelling 
 Rented Owned ethnicityhrp student retiree central_heating eletric_heating 
 gas_heating oil_heating solidfuel_heating other_heating economic_position 
 unemployed employed inactive het_household, after(weighta);
 
#delimit cr


save "$clean/clean.dta", replace

*******************************************************************************;

#delimit ;
su xhouse xtot xfood xalc xcloth xhouse xgas xcoal xfuels xrents 
xwater xmaint xelec xfurn xhealth xtransport xcomm xrecr 
xeduc xrest xother [aw=weighta];

su phouse pfood palc pcloth phouse pgas pcoal pfuels prents pwater pmaint pelec 
pfurn phealth ptransport pcomm precr peduc prest pother [aw=weighta];
#delimit cr





