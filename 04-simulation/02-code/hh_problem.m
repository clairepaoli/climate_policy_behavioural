
function [v, w, l, u, dxdy, c, post_tax_wage, tot_tax_inputed, iter,converg,savings] = hh_problem(MPS, mu, l, l_0, w, z, v, v_0, p, np, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution,social_sec,EASIdxdy,iter,converg)

converg = 1;
iter = 1;

c = c_0;
v = v_0;
l = l_0;
dxdy = EASIdxdy;
        
while converg > 0.0001
        
    if iter > 1000
        l = NaN;     
        break           
    end
    
    backup_v = v;
    backup_l = l;
    backup_dxdy = dxdy;
    for j=1:J
     w(j) = shares( ...
     z, np, v, A(j,:), B(j,:), D(j,:), alpha_easi(j), residuals_easi(j));
    end
    w(7) = 1 - sum(w(1:6),2);
    v = indirect_u(c, w, p, A, J);
    dxdy = c./exp(v) * (1 + p*( B(:,1) + B(:,2).*2*v.^1 + B(:,3).*3*v.^2 + B(:,4).*4.*v.^3 + sum(D.*z,2) ));
    dxdy = dxdy/100;
    taxable_income = wage.*l;
    tot_tax_inputed = marginal_tax(taxable_income);
    post_tax_wage = ((labor_income - lambda*tot_tax_inputed)./l_0);
    post_tax_wage = post_tax_wage./dxdy;
    post_tax_wage(isnan(post_tax_wage)) = 0;
    l = (post_tax_wage.^elasticity).*lu;
    disp_income = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
    savings = disp_income.*MPS;
    c = max(1, wage.*l + xbar + mu*social_sec + s - lambda*tot_tax_inputed - savings - ni_contribution);
    if iter == 1
        converg = 1;     
    else
        converg = abs(v - backup_v) + abs(l - backup_l) + abs(dxdy - backup_dxdy);
    end
    iter = iter + 1;
  
end

if(isnan(l))
u = nan;
else
u = real(exp(v) - phi.*((l)./(1+1/elasticity))^(1+1/elasticity));
end

end