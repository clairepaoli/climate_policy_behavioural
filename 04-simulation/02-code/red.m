 
i=11
MPS = MPS(i,:)
 mu
 l = l(i,:)
 l_0 = l_0(i,:)
 w = w(i,:)
 z = z(i,:)
 v=v(i,:)
 v_0=v_0(i,:)
 p=p_0(i,:)
 np=np_0(i,:)
c=c(i,:)
c_0=c_0(i,:)
wage=wage(i,:)
alpha_easi=alpha_easi(i,:)
residuals_easi=residuals_easi(i,:)
tax_tot=tax_tot(i,:)
labor_income=labor_income(i,:)
phi=phi(i,:)
savings=savings(i,:)
lu=lu(i,:)
xbar=xbar(i,:)
taxable_income=taxable_income(i,:)
s=s(i,:)
post_tax_wage=post_tax_wage(i,:)
ni_contribution=ni_contribution(i,:)
social_sec=social_sec(i,:)
EASIdxdy=EASIdxdy(i,:)
iter=iter(i,:)
converg=converg(i,:)


[v_blu(i,:), w_blu(i,:), l_blu(i,:), u_blu(i,:), dxdy_blu(i,:), c_blu(i,:), post_tax_wage_blu(i,:), tot_tax_inputed_blu(i,:), iter_blu(i,:),converg_blu(i,:),savings_blu(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_0(i,:), np_0(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    
 
    