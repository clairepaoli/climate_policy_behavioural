********************************************************************************
* 5. Prepare data for simulation
* Author: Claire Paoli
* Date: March 2021
* Objective: prepare data for input into MATLAB
********************************************************************************

clear all
set more off
scalar drop _all
macro drop _all
estimates drop _all

#delimit cr

global path "/Volumes/Untitled/Projects/Carbon Pricing/2-analysis"
global raw "$path/01-data/01-raw"
global temp "$path/01-data/02-temp"
global clean "$path/01-data/03-clean"

global estimates "$path/03-output/estimates"
global figures "$path/03-output/figures"
global simulation "$path/04-simulation"

********************************************************************************

use "$clean/2025.03.29_data-labor-supply.dta", clear

keep if LCF_round == "LCF_2017"
* 3556 obs

* Merge with emissions data
sort LCF_round year hh_id
merge LCF_round year hh_id using "$clean/2025.03.29_data_wemissions.dta"
keep if _merge == 3
drop if year==.
drop _merge

global neq "6"
global neqt "7"
global quantiles "1 2 3 4 5"
global n_types= "7"
global text=1

global estimation = 1
global nprice "$neqt"
global ndem "$n_types"
global npowers "4"
global conv_crit "0.001"
scalar conv_param=1
scalar conv_y=0

global matsize_value=100+$neq*(1+$npowers+$ndem+$neq*(1+$ndem+1)+$ndem)+100
set matsize $matsize_value

********************************************************************************

* Aggregate goods
global goodall "food heating transport housing serv dur other2"
global goodall_non_other "food heating transport housing serv dur"


* Individual goods
global food "food_only alc"
global heating "gas coal fuels elec"
global transport "t72 air rail road sea transport_other"
global housing "water rent maint"
global serv "comm educ health"
global dur "furn cloth t71"
global other2 "other recr rest"

global nplist "np1 np2 np3 np4 np5 np6"
global ylist "y1 y2 y3 y4"
global yzlist "yz1 yz2 yz3 yz4 yz5 yz6 yz7"


* HH footprint and intensity per quantity of good (NOT EXPENDITURE)
* Note that conversion from expenditure to quantity: q = exp * 100 / price index
// foreach good in $goodall {
// gen `good'_int = 0
// gen `good'_CO2_q = 0
// } 

// foreach good in  $goodall {
// foreach goodb in $`good' {
// qui replace `good'_CO2_q = `goodb'_intensity * x`goodb'* 100/p`goodb' + `good'_CO2_q
// }

// qui replace `good'_int = `good'_CO2_q/(x`good' * 100/index_good_`good')

// }

********************************************************************************
* EASI Estimation

estread using "$estimates/2025.03.29_EASI_output_7"
estimates restore EASI

* A matrix
mat COEF=e(b)

scalar parametres=e(k)/$neq

local j0=1
local j1=parametres

forvalues num=1(1)$neq {
matrix COEF_`num'=COEF[1,`j0'..`j1']
local j0=`j0'+parametres
local j1=`j1'+parametres
}

mat M_COEF = COEF_1
forvalues num=2(1)$neq {
          mat M_COEF = M_COEF\COEF_`num'
	}
mat M_COEF = M_COEF'

* A_0 matrix
local start_a=$npowers+$ndem
matrix A_0=M_COEF[`start_a'+1..`start_a'+$neq, 1..6]
matrix new = J(1 ,$neq ,0)
mat A_0 = A_0\new	
matrix new = J(1 ,$neq+1 ,0)
mat A_0 = A_0,new'

mata: A_0 = st_matrix("A_0")

mata{
neqn=$neq+1 
for(i=1; i<=neqn-1; ++i) {
		A_0[i, neqn] = -sum(A_0[i,1..(neqn-1)])
		A_0[neqn, i] = A_0[i, neqn]
	}
	A_0[neqn, neqn] = -sum(A_0[neqn, 1..(neqn-1)])
}

* Polynomial (B Matrix)
matrix Br = M_COEF[1..$npowers , 1..$neq]'
mata: Br = st_matrix("Br")	
mata: Br = Br \-colsum(Br,1)	


* Yz
local start_a=$npowers+1
matrix Zy = M_COEF[`start_a'..`start_a'+$ndem-1 , 1..$neq]'
mata: Zy = st_matrix("Zy")	
mata:  Zy = Zy \-colsum(Zy,1)

count
scalar pop =r(N)
drop y 

mata {
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
	
		
}

gen y_back = y	
forvalues j=1(1)$neq {
	replace np`j'_backup = np`j'
}

* Residuals
forvalues j=1(1)$neq {
  quietly predict res_easi_`j', equation(s`j')  residuals 
  label variable res_easi_`j'  "res_easi_`j'" 
  }
 
g temp = res_easi_1 + res_easi_2 + res_easi_3 + res_easi_4 + res_easi_5 + res_easi_6 
g res_easi_7 = 0 - temp
drop temp

* Alphas: predicted budget shares when y = 0 and p = 0 - i.e. the constant
* Replace variables of real expedniture with zeros
foreach yvar in $ylist $yzlist $nplist {
    quietly replace `yvar'= 0
} 	
    
forvalues j=1(1)$neq {
   quietly predict alphas_easi_`j', equation(s`j')
   label  variable alphas_easi_`j' "alphas_easi_`j'"
  }
  
replace y = y_back

g temp = alphas_easi_1 + alphas_easi_2 + alphas_easi_3 + alphas_easi_4 + alphas_easi_5 + alphas_easi_6 
g alphas_easi_7 = 1 - temp
drop temp

forvalues j=1(1)$npowers {
	replace y`j'=y^`j'
}

forvalues k=1(1)$ndem {
	replace yz`k'=y*z`k'
}

forvalues j=1(1)$neq {
	replace np`j'=np`j'_backup
}

********************************************************************************
* New prices;
* Carbon tx = 100 pounds / tonnes of CO2e;

foreach good in $goodall {
foreach goodb in $`good' {
g change_p`goodb' = .
}
}

scalar pi = 100/1000

replace change_pfood_only = pi*food_only_intensity
replace change_palc = pi*alc_intensity

replace change_pelec = pi*elec_intensity
replace change_pgas = pi*gas_intensity
replace change_pfuels = pi*fuels_intensity
replace change_pcoal = pi*coal_intensity

replace change_pt72 = pi*t72_intensity
replace change_pair = pi*air_intensity
replace change_prail = pi*rail_intensity
replace change_proad = pi*road_intensity
replace change_psea = pi*sea_intensity
replace change_ptransport_other = pi*transport_other_intensity

replace change_pwater = pi*water_intensity
replace change_pmaint = pi*maint_intensity
replace change_prent = pi*rent_intensity

replace change_pcomm = pi*comm_intensity
replace change_peduc = pi*educ_intensity
replace change_phealth = pi*health_intensity

replace change_pfurn = pi*furn_intensity
replace change_pt71 = pi*t71_intensity
replace change_pcloth = pi*cloth_intensity

replace change_prest = pi*rest_intensity
replace change_pother = pi*other_intensity
replace change_precr = pi*recr_intensity

su change_pfood_only-change_prest
*graph bar change_pfood_only-change_prest 

foreach good in $goodall {
foreach goodb in $`good' {
g p_new`goodb' = p`goodb'
replace p_new`goodb' = p`goodb'*(1+change_p`goodb') if change_p`goodb'!=.
}
}

foreach good in $goodall {
replace index_k_`good' = 1
replace index_good_`good' = 1
g index2_good_`good' = 1
replace index_stone_`good' = 0
}

 
foreach good in $goodall {
foreach goodb in $`good' {
	ameans  wg`good'_`goodb'
replace index_k_`good'=(index_k_`good')*r(mean)^-r(mean) if r(mean)>0
}
} 

*** Index I
foreach good in  $goodall{
foreach goodb in $`good' {
replace index_good_`good' = index_good_`good'*(p_new`goodb'/wg`good'_`goodb')^wg`good'_`goodb' if wg`good'_`goodb'!=0 &wg`good'_`goodb'!=. & p_new`goodb'!=.
	}
}

**** index II
foreach good in $goodall{
replace index2_good_`good' = index_good_`good'/index_k_`good'
}

* Use this as prices
foreach good in $goodall{
replace lindex_good_`good'= log(index2_good_`good') 
}

su lindex_good_*

g p1_new = lindex_good_food
g p2_new = lindex_good_heating
g p3_new = lindex_good_transport
g p4_new = lindex_good_housing
g p5_new = lindex_good_serv
g p6_new = lindex_good_dur
g p7_new = lindex_good_other2


g p1_change = (exp(p1_new) - exp(p1))/exp(p1)
g p2_change = (exp(p2_new) - exp(p2))/exp(p2)
g p3_change = (exp(p3_new) - exp(p3))/exp(p3)
g p4_change = (exp(p4_new) - exp(p4))/exp(p4)
g p5_change = (exp(p5_new) - exp(p5))/exp(p5)
g p6_change = (exp(p6_new) - exp(p6))/exp(p6)
g p7_change = (exp(p7_new) - exp(p7))/exp(p7)


graph box p1_change-p7_change, nooutsides ytitle("Percentage change in prices",  height(5))
su p1_change-p7_change

forvalues j=1(1)$neq {
	g np`j'_new = p`j'_new - p7_new
}

********************************************************************************
* New prices with endogenous intensities;
* Carbon tax = 100 pounds / tonnes of CO2e

scalar pi = 100/1000
scalar beta = 500/1000
scalar pe = 0.625
scalar rho = (pi/beta)^pe

replace change_pfood_only = pi*(1-rho)*food_only_intensity
replace change_palc = pi*(1-rho)*alc_intensity

replace change_pelec = pi*(1-rho)*elec_intensity
replace change_pgas = pi*(1-rho)*gas_intensity
replace change_pfuels = pi*(1-rho)*fuels_intensity
replace change_pcoal = pi*(1-rho)*coal_intensity

replace change_pt72 = pi*(1-rho)*t72_intensity
replace change_pair = pi*(1-rho)*air_intensity
replace change_prail = pi*(1-rho)*rail_intensity
replace change_proad = pi*(1-rho)*road_intensity
replace change_psea = pi*(1-rho)*sea_intensity
replace change_ptransport_other = pi*(1-rho)*transport_other_intensity

replace change_pwater = pi*(1-rho)*water_intensity
replace change_pmaint = pi*(1-rho)*maint_intensity
replace change_prent = pi*(1-rho)*rent_intensity

replace change_pcomm = pi*(1-rho)*comm_intensity
replace change_peduc = pi*(1-rho)*educ_intensity
replace change_phealth = pi*(1-rho)*health_intensity

replace change_pfurn = pi*(1-rho)*furn_intensity
replace change_pt71 = pi*(1-rho)*t71_intensity
replace change_pcloth = pi*(1-rho)*cloth_intensity

replace change_prest = pi*(1-rho)*rest_intensity
replace change_pother = pi*(1-rho)*other_intensity
replace change_precr = pi*(1-rho)*recr_intensity

su change_pfood_only-change_prest
*graph bar change_pfood_only-change_prest 

foreach good in $goodall {
foreach goodb in $`good' {
g p_2new`goodb' = p`goodb'
replace p_2new`goodb' = p`goodb'*(1+change_p`goodb') if change_p`goodb'!=.
}
}

foreach good in $goodall {
replace index_k_`good' = 1
replace index_good_`good' = 1
g index3_good_`good' = 1
replace index_stone_`good' = 0
}

 
foreach good in $goodall {
foreach goodb in $`good' {
	ameans  wg`good'_`goodb'
replace index_k_`good'=(index_k_`good')*r(mean)^-r(mean) if r(mean)>0
}
} 

*** Index I
foreach good in  $goodall{
foreach goodb in $`good' {
replace index_good_`good' = index_good_`good'*(p_2new`goodb'/wg`good'_`goodb')^wg`good'_`goodb' if wg`good'_`goodb'!=0 &wg`good'_`goodb'!=. & p_2new`goodb'!=.
	}
}

**** index II
foreach good in $goodall{
replace index3_good_`good' = index_good_`good'/index_k_`good'
}

* Use this as prices
foreach good in $goodall{
replace lindex_good_`good'= log(index3_good_`good') 
}

su lindex_good_*

g p1_2new = lindex_good_food
g p2_2new = lindex_good_heating
g p3_2new = lindex_good_transport
g p4_2new = lindex_good_housing
g p5_2new = lindex_good_serv
g p6_2new = lindex_good_dur
g p7_2new = lindex_good_other2

forvalues j=1(1)$neq {
	g np`j'_2new = p`j'_2new - p7_2new
}

********************************************************************************
* Footprints;

// foreach good in $goodall {
// * HH Footprint
// gen `good'_CO2 = 0
// * Carbon intensity
// gen `good'_intensity2 = 0
// }

// * Total footprint per good yearly and tons
// foreach good in  $goodall {
// 	foreach goodb in $`good' {
// 	* Yearly footprint of each subcategory
// 	replace  `good'_CO2 = x`goodb' *`goodb'_intensity + `good'_CO2
// 	}
// 	* Yearly 
// 	replace  `good'_intensity2 = `good'_CO2/x`good'
// }


// * nonparametric regression: budget shares on log total expenditure
// foreach good in $goodall{
// lpoly bsx`good' lxtot, noscatter ci title(`good') legend(off) ytitle("Budget share")  graphregion(fcolor(white)) note("") degree(4)
// display "bwidth="r(bwidth) ", Kernel=" r(kernel) ", degree=" r(degree)
// }

// * nonparametric regression: good expenditures on log total expenditure
// foreach good in $goodall{
// lpoly x`good' lxtot, noscatter ci title(`good') legend(off) ytitle("Budget share")  graphregion(fcolor(white)) note("")
// display "bwidth="r(bwidth) ", Kernel=" r(kernel) ", degree=" r(degree)
// }

********************************************************************************
* Labour;

* Check if I need to drop this!
// drop if inc_wk_salary_tot > 0 & hours_tot==0 
// g labor_income_temp = inc_wk_salary_tot + inc_wk_self
// drop if labor_income_temp>0 & hours_tot==0
// drop if hours_tot>0 & labor_income_temp==0

* HH Chars
g spouse = (a015_spouse!=.)
gen d_married = (spouse==1)
replace sexhrp = 0 if sexhrp==2

* Create 3 groups: single-f, single-m, married
g group = 1 if d_married==0&sexhrp==0
replace group = 2 if d_married==0&sexhrp==1
replace group = 3 if d_married==1
* remove students and retirees, since we do so in the estimation
replace group = . if retiree==1 | student==1

g single = (d_married==0)

* Working;
gen d_children = (het_household==5|het_household>6)
gen d_working = (hh_hours_wk_tot>0)

* Non-labor income = total weekly income - labor income;
g non_labor_income = income_wk_tot_calculated - income_wk_salary - income_wk_self
* Log of total income;
g ltotincome = ln(income_wk_tot_calculated)

* Remove retirees and students with positive hours worked
drop if group == . & hh_hours_wk_tot > 0
* 52 hh dropped

* These variables include self-employment income and hours as part of the wage!
gen wage_dxy_2 = wage_tax2/dxy
gen lwage_dxy_2 = log(wage_dxy_2)
replace lwage_dxy_2 = 0 if lwage_dxy_2==.

* Total hours and weekly wage;
gen log_hours = log(hh_hours_wk_tot) 

* a094 = type of profession;
g occupation = a094 if inlist(a094, 1,2,3,4,5,6,7,8)
* Marital status
g marital_status = a006p

tab income_source
* gen hig_transfer_tot=income_transfers_public>r(mean)
* Dummy for whether major source of income are ss benefis or annuities/pensions
g d_transfers = (incom e_source==4|income_source==5)
* Spouse working;
g spouse_working = (a015_spouse==1)

* Correct for selectivity bias (Heckman 1979) to obtain estimated selectivity-corrected net wages
g agehrp2 = agehrp^2
g edu = a010
g lpgas = ln(pgas)

probit d_working agehrp sexhrp agehrp2 ethnicityhrp edu d_children d_transfers lpgas i.region i.year if group==1
predict prob_1, index
gen small_phi_1 = normalden(prob_1)
gen big_phi_1 = normal(prob_1)
gen heck = small_phi_1/big_phi_1
replace heck = 0 if heck==.

probit d_working agehrp sexhrp agehrp2 ethnicityhrp edu d_children d_transfers lpgas i.region i.year if group==2
predict prob_2, index
gen small_phi_2 = normalden(prob_2)
gen big_phi_2 = normal(prob_2)
gen heck2 = small_phi_2/big_phi_2
replace heck2 = 0 if heck2==.

probit d_working agehrp sexhrp agehrp2 ethnicityhrp edu d_children d_transfers spouse_working lpgas i.region i.year if group==3
predict prob_3, index
gen small_phi_3 = normalden(prob_3)
gen big_phi_3 = normal(prob_3)
gen heck3 = small_phi_3/big_phi_3
replace heck3 = 0 if heck3==.

g heck_agg = heck if group==1
replace heck_agg = heck2 if group==2
replace heck_agg = heck3 if group==3

* Create instruments for pre-tax wages: follow West and Williams (2007) and use occupation-, state-, gender-specific mean
bysort group occupation region: egen mean_wages_ins2 = mean(wage_dxy_2)
bysort group occupation region: egen groups3 = count(hh_id)
g log_ins_wage2 = log(mean_wages_ins2)
replace log_ins_wage2 = 0 if log_ins_wage2==.

* Gender and occupation specific only (national net wage)
// bysort group occupation: egen mean_wages_ins_national = mean(wage_dxy_2)
// bysort occupation region: egen groups2 = count(hh_id)
// g log_ins_wage_national = log(mean_wages_ins_national)
// replace log_ins_wage_national = 0 if log_ins_wage_national ==.

bysort group occupation region: egen mean_x = mean(lxtot)

g y_inst_2 = mean_x
forvalues num=1(1)$nprice {
	replace y_inst_2 = y_inst_2 - mean_s`num'*p`num'
}

gen london = (region==7)

label variable lwage_dxy_2 "log(w*(1-t))/PM"
label variable y "log(y)"

global controls "i.region i.month i.year"

estread using "$estimates/2025.03.29_labor-supply"
estimates restore LABOR

mat COEF=e(b)
mat COEF2 = COEF'
mat colnames COEF2 = IV 
qui xml_tab COEF2,  save($estimates/2025.03.29_labour_fn.xls) replace  title("Labour Supply")

predict lres, residuals
replace lres=0 if lres==.

g backup = lwage_dxy_2
g backup1 = log_ins_wage2

replace lwage_dxy_2 = 0
replace log_ins_wage2 = 0

predict alphas_l
label  variable alphas_l "alphas_l"

replace lwage_dxy_2 = backup
replace log_ins_wage2 = backup1

// ********************************************************************************
* check weights;

g tot_sample_final = .
g weight_adjusted_final = .
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(weight_adjusted) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample_final = tot_sample_0 if LCF_round == "`year'"
}

local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
replace weight_adjusted_final = weight_adjusted*(tot_sample/tot_sample_final) if LCF_round == "`year'"
}

* check
g tot_sample_final_adjusted =.
local varlist "LCF_2001-2002 LCF_2002-2003 LCF_2003-2004 LCF_2004-2005 LCF_2005-2006 LCF_2006 LCF_2007 LCF_2008 LCF_2009 LCF_2010 LCF_2011 LCF_2012 LCF_2013 LCF_2014 LCF_2015 LCF_2016 LCF_2017 LCF_2018 LCF_2019 LCF_2020 LCF_2021"
foreach year in `varlist'{
sum(weight_adjusted_final) if LCF_round == "`year'"
scalar tot_sample_0 = r(sum)
replace tot_sample_final_adjusted = tot_sample_0 if LCF_round == "`year'"
}

tab LCF_round, su(tot_sample_final_adjusted)
* ok!

* kdensity p1, plot(kdensity p1_new) legend(label(1 "Pre-tax") label(2 "Post-tax") rows(1))

tab month, generate(dummy_month)
tab year, generate(dummy_year)
tab region, generate(dummy_region)

* Variables needed
preserve

#delimit ;
keep 

hh_id 
LCF_round 
weight_adjusted_final
hh_size 
exp_poverty 
urban 
n_children 
n_adults 
region

income_wk_salary
income_wk_self 
income_wk_invest 
income_wk_ss 
income_wk_pension
income_wk_other
income_wk_tot_calculated
income_wk_disposable 
income_taxable_wk 
savings_wk

ni_contribution 
deductions
dxy
exp_share 

oecdsc 
equiv_income 
equiv_disp_income 
equiv_consumption 

hh_hours_wk_tot

wage_notax
wage_tax2
wage_dxy_2 

mar_tax 
avg_tax_calculated 

het_household

heck_agg 
sexhrp 
london 
d_children 
group 
single

xtot 
xfood 
xheating 
xtransport 
xhousing 
xserv 
xdur 
xother2	

s1	s2	s3	s4	s5	s6	s7	
p1	p2	p3	p4	p5	p6	p7	
p1_new	p2_new	p3_new	p4_new	p5_new	p6_new	p7_new 
z1	z2	z3	z4	z5	z6	z7	 

np1 np2 np3 np4 np5 np6 
np1_new np2_new np3_new np4_new np5_new np6_new 
np1_2new np2_2new np3_2new np4_2new np5_2new np6_2new 
p1_2new	p2_2new	p3_2new	p4_2new	p5_2new	p6_2new	p7_2new

lres y alphas_l
 
res_easi_1	res_easi_2	res_easi_3	res_easi_4	res_easi_5	res_easi_6 res_easi_7

alphas_easi_1	alphas_easi_2	alphas_easi_3	alphas_easi_4	alphas_easi_5	alphas_easi_6 alphas_easi_7

inc_decile
inc_quantile
disp_income_decile
x_decile

food_emi 
heating_emi 
transport_emi 
housing_emi 
serv_emi 
dur_emi 
other_emi 
tot_hh_footprint

food_int_c 
heating_int_c 
transport_int_c 
housing_int_c 
serv_int_c 
dur_int_c 
other_int_c

d_urban
d_eletric_heating
d_gas_heating
dummy_month*
dummy_year*
dummy_region* ;

replace hh_id = _n

#delimit ;

order 

hh_id 
LCF_round 
weight_adjusted_final
hh_size 
het_household
exp_poverty 
urban 
n_children 
n_adults 
region
oecdsc

income_wk_salary
income_wk_self 
income_wk_invest 
income_wk_ss 
income_wk_pension
income_wk_other
income_wk_tot_calculated
income_wk_disposable 
income_taxable_wk 
savings_wk

ni_contribution 
deductions
dxy
exp_share

hh_hours_wk_tot

wage_notax
wage_tax2

mar_tax 
avg_tax_calculated 

xfood
xtransport
xheating
xhousing
xserv
xdur
xother2
xtot

equiv_income 
equiv_disp_income 
equiv_consumption 
inc_decile
inc_quantile
disp_income_decile
x_decile

exp_poverty
urban
s1
s2
s3
s4
s5
s6
s7
p1
p2
p3
p4
p5
p6
p7
np1
np2
np3
np4
np5
np6
z1
z2
z3
z4
z5
z6
z7
dxy
y
res_easi_1
res_easi_2
res_easi_3
res_easi_4
res_easi_5
res_easi_6
res_easi_7
alphas_easi_1
alphas_easi_2
alphas_easi_3
alphas_easi_4
alphas_easi_5
alphas_easi_6
alphas_easi_7
p1_new
p2_new
p3_new
p4_new
p5_new
p6_new
p7_new
np1_new
np2_new
np3_new
np4_new
np5_new
np6_new
p1_2new
p2_2new
p3_2new
p4_2new
p5_2new
p6_2new
p7_2new
np1_2new
np2_2new
np3_2new
np4_2new
np5_2new
np6_2new

group
single
d_children
wage_dxy_2
heck_agg
london
lres
alphas_l 
dummy_month*
dummy_year*
dummy_region*

food_emi
heating_emi
transport_emi
housing_emi
serv_emi
dur_emi
other_emi
tot_hh_footprint

food_int_c 
heating_int_c 
transport_int_c 
housing_int_c 
serv_int_c 
dur_int_c 
other_int_c 
tot_hh_footprint;

export excel using "$simulation/01-input/2025.03.29_simulation_data.xls", firstrow(variables) nolabel replace	
restore


*** Create dataset with determinants;

// use "$clean/data-labor-supply.dta", clear
// keep if year==2017

// gen d_cars = (n_cars>0)
// g public_transport = b216 + c73112
// g motor_fuel = c72211 + c72212 + c72213
// g share_maint = xmaint/xhousing

// preserve 
// keep hh_id LCF_round unemployed employed n_cars n_rooms Whole_House Flat Other_dwelling Rented Owned ethnicityhrp student retiree central_heating eletric_heating gas_heating oil_heating solidfuel_heating other_heating electricity_supplied share_maint motor_fuel public_transport d_cars
// save "$simulation/01-input/determinants.dta", replace
// restore












