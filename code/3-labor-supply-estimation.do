********************************************************************************
* 3. Labour Supply
* Author: Claire Paoli
* Date: March 2021
* Objective: estimate labour supply elasticities
********************************************************************************

clear all
set more off
scalar drop _all
macro drop _all
estimates drop _all
capture log close
set type double


global path "/Volumes/My Passport for Mac/Research/Projects/Carbon Pricing/2-analysis"
global raw "$path/01-data/raw"
global temp "$path/01-data/temp"
global clean "$path/01-data/clean"

global estimates "$path/03-output/estimates"

use "$clean/data-labor-supply.dta", clear

global nprice "7"

***************************************;
* Labour supply;
**************************************;

** Keep only singles and couples (no hhs with more than 2 adults)
** Drop retirees and students
drop if retiree==1 | student==1
* 31,611 hhs

* some cleaning;
drop if inc_wk_salary_tot > 0 & hours_tot==0 
* 512
g labor_income_temp = inc_wk_salary_tot + inc_wk_self
drop if labor_income_temp>0 & hours_tot==0
* 16
drop if hours_tot>0 & labor_income_temp==0
* 67

* HH Chars
g spouse = (a015_spouse!=.)
gen d_married = (spouse==1)
replace sexhrp = 0 if sexhrp==2

* Create 3 groups: single-f, single-m, married
g group = 1 if d_married==0&sexhrp==0
replace group = 2 if d_married==0&sexhrp==1
replace group = 3 if d_married==1

g single = (d_married==0)

* Working;
gen d_children = (het_household==5|het_household>6)
gen d_working = (hours_tot>0)

* Non-labor income = total weekly income - labor income;
g non_labor_income = income_wk_tot - inc_wk_salary_tot - inc_wk_self
* Log of total income;
g ltotincome = ln(income_wk_tot)
* Taxable income = total income;
g ltaxableinc = ln(income_taxable)
replace ltaxableinc=0 if ltaxableinc==.

* use equivalized income variables
* kdensity inc_wk_salary_tot, legend(label(1 "Gross Labor HH Income"))

* Gross hourly wage;
// gen wage = inc_wk_salary_tot/hours_tot 
// gen wage_real = wage/dxy
// * Net hourly wage;
// gen net_wage = (inc_wk_salary_tot - income_paye_tax_net)/hours_tot // this leads to negative wages, when taxes > salaried income;
// gen wage_dxy_1 = net_wage/dxy 
// replace wage_dxy_1 = 0 if wage_dxy_1==. 
// gen lwage_dxy_1 = log(wage_dxy_1) // 4,801 missing values generated from taking logs
// replace lwage_dxy_1 = 0 if lwage_dxy_1==.

// gen wage_tax =  wage_notax - hourly_tax
// gen wage_tax2 =  wage_notax*(1-mar_tax)

* These variables include self-employment income and hours as part of the wage!
gen wage_dxy_1 = wage_tax/(dxy/100)
* use wage_dx_2 in estimation! Recall that: wage_tax2 =  wage_notax*(1-mar_tax)
gen wage_dxy_2 = wage_tax2/dxy
gen lwage_dxy_1 = log(wage_dxy_1)
gen lwage_dxy_2 = log(wage_dxy_2)
replace lwage_dxy_1 = 0 if lwage_dxy_1==.
replace lwage_dxy_2 = 0 if lwage_dxy_2==.

* These variables do not include self-employment income and hours as part of the wage!
gen hours_tot_noself = wk_hours_worked_spouse + wk_hours_worked_hrp
gen wage_notax_noself = (inc_wk_salary_tot)/hours_tot_noself
replace wage_notax_noself = 0 if wage_notax_noself==.
gen wage_tax_noself =  wage_notax_noself*(1-mar_tax)/dxy
gen lwage_tax_noself = log(wage_tax_noself)
replace lwage_tax_noself = 0 if lwage_tax_noself==.

* Total hours and weekly wage;
gen log_hours = log(hours_tot) 
replace log_hours = 0 if log_hours==.
gen log_hours_noself = log(hours_tot_noself)

* Plot;
hist wage_notax
hist wage_tax2
hist hours_tot


*drop if lwage_dxy_1 <0 //173 observations deleted


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

** Correct for selectivity bias (Heckman 1979) to obtain estimated selectivity-corrected net wages

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


* Create instruments for pre-tax wages: follow West and Williams (2007) and use occupation-, state-, gender-specific mean: for variables with self-employment!
bysort group occupation region: egen mean_wages_ins = mean(wage_dxy_1)
bysort group occupation region: egen groups = count(hh_id)
g log_ins_wage = log(mean_wages_ins)
replace log_ins_wage = 0 if log_ins_wage==.

bysort group occupation region: egen mean_wages_ins2 = mean(wage_dxy_2)
bysort group occupation region: egen groups3 = count(hh_id)
g log_ins_wage2 = log(mean_wages_ins2)
replace log_ins_wage2 = 0 if log_ins_wage2==.

* Create instruments for pre-tax wages: follow West and Williams (2007) and use occupation-, state-, gender-specific mean: for variables without self-employment!
bysort group occupation region: egen wage_tax_noself_ins = mean(wage_tax_noself) if hours_tot_noself>0
g lwage_tax_noself_ins = log(wage_tax_noself_ins)
replace lwage_tax_noself_ins = 0 if wage_tax_noself_ins==.

bysort group occupation region: egen mean_x = mean(lxtot)

g y_inst_2 = mean_x
forvalues num=1(1)$nprice {
	replace y_inst_2 = y_inst_2 - mean_s`num'*p`num'
}

gen london = (region==7)

label variable lwage_dxy_2 "log(w*(1-t))/PM"
label variable y "log(y)"

global controls "i.region i.month i.year"

* Interactions using variables with self-employment
gen lwage_dxy_2_male = lwage_dxy_2*sexhrp
gen log_ins_wage_male = log_ins_wage2*sexhrp

gen lwage_dxy_2_married = lwage_dxy_2*d_married
gen log_ins_wage_married = log_ins_wage2*d_married

g group2 = (group==2)
g group3 = (group==3)
gen lwage_dxy_2_group2 = lwage_dxy_2*group2
gen log_ins_wage_group2 = log_ins_wage2*group2

gen lwage_dxy_2_group3 = lwage_dxy_2*group3
gen log_ins_wage_group3 = log_ins_wage2*group3



// * Total sample
// eststo clear
// eststo mo1: reg log_hours log_wage_dxy_1 [aw=weighta]
// eststo mo2: reg log_hours log_wage_dxy_1 heck london sexhrp d_children single $controls [aw=weighta]
// eststo mo3: ivregress gmm log_hours heck london sexhrp d_children single (log_wage_dxy_1 = log_ins_wage i.group)  $controls [aw=weighta]
// eststo mo4: ivregress gmm log_hours heck london sexhrp d_children single (log_wage_dxy_1 = log_ins_wage i.group)  $controls , vce(bootstrap)
// eststo mo5: ivregress gmm log_hours heck london sexhrp d_children single (log_wage_dxy_1 log_wage_dxy_1_male = log_ins_wage log_ins_wage_male i.group) $controls , vce(bootstrap)
// eststo mo6: ivregress gmm ltaxableinc heck london sexhrp d_children single (log_wage_dxy_1 = log_ins_wage i.group)   $controls , vce(bootstrap)
// esttab mo1 mo2 mo3 mo4 mo5 mo6 using "$estimates/labor-supply.tex", keep(log_wage_dxy_1 heck london sexhrp d_children single log_wage_dxy_1_male _cons) cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(N r2, label(N R-Sqr)) title(Labour Supply: UK Households, Total) replace

keep if d_working==1 & occupation!=.

* Total sample
eststo clear
eststo mo1: reg log_hours lwage_dxy_2 [aw=weight_adjusted]
eststo mo2: reg log_hours lwage_dxy_2 heck_agg london sexhrp d_children single $controls [aw=weight_adjusted]
eststo mo3: ivregress gmm log_hours heck_agg london sexhrp d_children single (lwage_dxy_2 = log_ins_wage2)  $controls [aw=weight_adjusted]
eststo mo4: ivregress gmm log_hours heck_agg london sexhrp d_children single (lwage_dxy_2 = log_ins_wage2)  $controls , vce(bootstrap)
eststo mo5: ivregress gmm log_hours heck_agg london sexhrp d_children single (lwage_dxy_2 c.lwage_dxy_2#sexhrp = log_ins_wage2 c.log_ins_wage2#sexhrp) $controls , vce(bootstrap)
esttab mo1 mo2 mo3 mo4 mo5 using "$estimates/labor-supply_wself.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(N r2, label(N R-Sqr)) title(Labour Supply: UK Households, Total) replace

* Couples
preserve
keep if single==0

eststo mo7: reg log_hours lwage_dxy_2 [aw=new_weight]
eststo mo8: reg log_hours lwage_dxy_2 heck_agg london sexhrp d_children spouse_working $controls [aw=weight_adjusted]
eststo mo9: ivregress gmm log_hours heck_agg london sexhrp d_children spouse_working (lwage_dxy_2 = log_ins_wage2)  $controls [aw=weight_adjusted]
eststo mo10: ivregress gmm log_hours heck_agg london sexhrp d_children spouse_working (lwage_dxy_2 = log_ins_wage2)  $controls , vce(bootstrap)
eststo m011: ivregress gmm log_hours heck_agg london sexhrp d_children spouse_working (lwage_dxy_2 c.lwage_dxy_2#sexhrp = log_ins_wage2 c.log_ins_wage2#sexhrp) $controls , vce(bootstrap)
esttab mo7 mo8 mo9 mo10 m011 using "$estimates/labor-supply-couples.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(N r2, label(N R-Sqr)) title(Labour Supply: UK Households, Couples) replace

restore

* Singles
preserve
keep if single==1
eststo mo20: reg log_hours lwage_dxy_2 [aw=new_weight]
eststo mo21: reg log_hours lwage_dxy_2 heck_agg london sexhrp d_children $controls [aw=weight_adjusted]
eststo mo22: ivregress gmm log_hours heck_agg london sexhrp d_children (lwage_dxy_2 = log_ins_wage2)  $controls [aw=weight_adjusted]
eststo mo23: ivregress gmm log_hours heck_agg london sexhrp d_children (lwage_dxy_2 = log_ins_wage2)  $controls , vce(bootstrap)
eststo mo24: ivregress gmm log_hours heck_agg london sexhrp d_children (lwage_dxy_2 c.lwage_dxy_2#sexhrp = log_ins_wage2 c.log_ins_wage2#sexhrp) $controls , vce(bootstrap)
esttab mo20 mo21 mo22 mo23 mo24 using "$estimates/labor-supply-singles.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(N r2, label(N R-Sqr)) title(Labour Supply: UK Households, Singles) replace
restore

* Pick model to use for calibration;
ivregress gmm log_hours heck_agg london sexhrp d_children single (lwage_dxy_2 = log_ins_wage2)  $controls , vce(bootstrap)



estimates store LABOR
estwrite  using "$estimates/labor-supply", replace
estimates restore LABOR

