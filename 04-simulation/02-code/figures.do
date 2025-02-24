***************************;
** Results
***************************;

clear all
set more off
scalar drop _all
macro drop _all
estimates drop _all


#delimit cr
set more 1

set scheme s2color

cd "/Volumes/My Passport for Mac/School/Oxford/Year 2/Thesis/0. Carbon Pricing/2-analysis/simulation"
********************************************************************************
import excel "output_data.xlsx", sheet("Sheet1") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)

hist(EV_R), ytitle("Density") xtitle("Weekly Expenditure (£)") width(5)


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

g pre_tax_burden = ni_contribution + tax_tot
g post_tax_burden = ni_contribution + tax_tot + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden

set scheme s2color
graph bar  (mean)  offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar (mean)  offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


set scheme s2color
grstyle init
grstyle color background white
grstyle color major_grid dimgray
grstyle linewidth major_grid thin
grstyle yesno draw_major_hgrid yes
grstyle yesno grid_draw_min yes
grstyle yesno grid_draw_max yes
grstyle anglestyle vertical_tick horizontal
graph set window fontface "Gourmand"

graph box EV_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar
*hist(EV_R), ytitle("Density") xtitle("EV Weekly Expenditure (£)") width(5) color(navy)

graph bar MPS, over(inc_decile) graphregion(color(white)) ///
title("Marginal propensity to save") ///
ytitle("Percent") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


eststo clear
eststo m1: reg EV_R rural i.region dummy_male dummy_child dummy_single i.ethnicityhrp 
eststo m2: reg EV_frac rural i.region dummy_male dummy_child dummy_single i.ethnicityhrp
eststo m3: reg EV_R   rural i.region dummy_male dummy_child dummy_single exp_poverty share_maint Whole_House Owned n_rooms i.ethnicityhrp central_heating eletric_heating gas_heating oil_heating d_cars share_motor share_public
eststo m4: reg EV_frac rural i.region dummy_male dummy_child dummy_single exp_poverty share_maint Whole_House Owned n_rooms i.ethnicityhrp central_heating eletric_heating gas_heating oil_heating d_cars share_motor share_public
esttab m1 m2 m3 m4 using "results/R/heterog.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(N r2, label(N R-Sqr)) title(No Recycling: Determinants of Welfare Effect) replace

tab inc_decile, su(MPS)
tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

********************************************************************************
import excel "output_data.xlsx", sheet("Sheet2") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)


replace EV_s_frac = EV_s/income
g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

set scheme s2color
graph bar offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


g pre_tax_burden = ni_contribution + tot_tax_inputed
g post_tax_burden = ni_contribution + tot_tax_inputed + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

set scheme s2color
graph set window fontface "Gourmand"

graph box EV_s_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_s_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar legend(size(small))

* what percent of households have positive EVs within each group?
g EV_positive = (EV_s >= 0) 

tab inc_decile, su(EV_positive)
tab z_cat EV_positive, row

tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

********************************************************************************
import excel "output_data.xlsx", sheet("Sheet3") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)


replace EV_s2_frac = EV_s2/income
g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

set scheme s2color
graph bar offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


g pre_tax_burden = ni_contribution + tot_tax_inputed
g post_tax_burden = ni_contribution + tot_tax_inputed + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

set scheme s2color
graph set window fontface "Gourmand"

graph box EV_s2_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_s2_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar legend(size(small))

* what percent of households have positive EVs within each group?
g EV_positive = (EV_s2 >= 0) 

tab z_cat EV_positive, row
tab inc_decile, su(EV_positive)

tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

********************************************************************************
import excel "output_data.xlsx", sheet("Sheet4") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)


replace EV_ss_frac = EV_ss/income
g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

set scheme s2color
graph bar offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill

graph bar MPS, over(inc_decile) graphregion(color(white)) ///
title("Propensity to save") ///
ytitle("Percent") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill

g pre_tax_burden = ni_contribution + tax_tot
g post_tax_burden = ni_contribution + tax_tot + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

graph box EV_ss_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_ss_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar legend(size(small))

* what percent of households have positive EVs within each group?
g EV_positive = (EV_ss >= 0) 

tab inc_decile, su(EV_positive)
tab z_cat EV_positive, row

tab inc_decile, su(change_burden)
tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

********************************************************************************
* HE Transfers;

import excel "output_data.xlsx", sheet("Sheet6") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)


replace EV_s3_frac = EV_s3/income
g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

set scheme s2color
graph bar offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


g pre_tax_burden = ni_contribution + tax_tot
g post_tax_burden = ni_contribution + tax_tot + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

graph box EV_s3_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_s3_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar legend(size(small))

* what percent of households have positive EVs within each group?
g EV_positive = (EV_s3 >= 0) 

tab inc_decile, su(EV_s3_frac)

g dummy_famale = (dummy_male==0)
g single_females = dummy_famale*dummy_single

tab inc_decile, su(EV_positive)
tab z_cat EV_positive, row

tab inc_decile, su(change_burden)
tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

********************************************************************************
* Income tax

import excel "output_data.xlsx", sheet("Sheet5") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)


replace EV_l_frac = EV_l/income
g carbon_tax = piE_individual
g offer_1 = carbon_tax/c
g offer_2 = carbon_tax/disp_income_1

set scheme s2color
graph bar offer_1, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of total expenditures") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


graph bar offer_2, over(inc_decile) graphregion(color(white)) ///
title("Carbon taxes as share of disposable income") ///
ytitle("Share (%)") ylabel(, angle(horizontal)) ///
b1title("Income Deciles") nofill


g pre_tax_burden = ni_contribution + tax_tot
g post_tax_burden = ni_contribution + tax_tot + carbon_tax
g change_burden = post_tax_burden/pre_tax_burden


label define z_catl 1 "Other" 2 "Retirees" 3 "Students" 4 "Working: Single, no Child." 5 "Working: Single, Child." 6 "Working: Couple, no Child." 7 "Working: Couple, < 3 Child." 8 "Working: Couple, >2 Child.", replace
label values z_cat z_catl 

graph box EV_l_frac, over(inc_decile) nooutsides ytitle("EV / Income") b1title("Income Deciles")
graph box EV_l_frac, over(z_cat) nooutsides ytitle("EV / Income", height(10)) b1title("Household Type") asyvar legend(size(small))

* what percent of households have positive EVs within each group?
g EV_positive = (EV_l >= 0) 

tab inc_decile, su(EV_l_frac)

g dummy_famale = (dummy_male==0)
g single_females = dummy_famale*dummy_single

tab inc_decile, su(EV_positive)
tab z_cat EV_positive, row

tab inc_decile, su(change_burden)
tab inc_decile, su(carbon_tax)
tab inc_decile, su(offer_1)
tab inc_decile, su(offer_2)
tab inc_decile, su(c)
tab inc_decile, su(c_0)

probit EV_positive 

********************************************************************************
* Combined
import excel "output_data.xlsx", sheet("Sheet7") firstrow clear
rename id hh_id
rename LCF LCF_round
sort LCF_round hh_id
merge LCF_round hh_id using "determinants.dta"
drop if _merge==2
g share_public = public_transport/c_0
g share_motor = motor_fuel/c_0
g rural = (urban==0)

g type = 1 if rural==1
replace type = 2 if dummy_single==1
replace type = 3 if employed==0
replace type = 4 if dummy_child==1
replace type = 5 if dummy_male==1

g EV_positive = (EV_comb >= 0) 


tab inc_quantile, su(EV_positive)
tab type, su(EV_positive)















