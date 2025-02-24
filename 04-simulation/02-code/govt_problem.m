
function [obj1, obj2, obj3] = govt_problem(lambda,mu, H, hhsize, hhfreq, eta, income, MPS, e, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s,  J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg)

    
% lambda = lambda0;
% mu = mu0;

pi = 100/1000;

for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
end

for i=1:H
    income(i,:) = wage(i,:).*l(i,:) - lambda*tot_tax_inputed(i,:) + mu*social_sec(i,:) + xbar(i,:) + s(i,:);
    EV(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
end

tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV>=0))/tot2_H;

zh = income.^(-eta);
w0 = 1/mean(zh);
wh = w0.*zh;
hhpareto_tot = sum(w0.*income.^(-eta).*hhfreq);
hhpareto = wh./hhpareto_tot;


co2 = sum(w.*c.*(e./(1+pi*e)),2);
E = sum(co2.*hhfreq);

u = real(exp(v) - phi.*((l)./(1+1/elasticity)).^(1+1/elasticity)); 

H_tot = sum(hhfreq);
ce = c - EV;
G = gini(hhfreq,income,false); 

%obj = (1/H_tot)*sum(ce./sqrt(hhsize))*(1-G);
%x=ce./sqrt(hhsize);

obj1 = sum(hhfreq.*hhpareto.*c);
obj2 = - (1/tot2_H)*pi*E;
obj3 = obj1 + obj2;
return

