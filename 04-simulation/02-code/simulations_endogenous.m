
%% Models with endogenous intensities;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 1: Funding general budget - essentially uncompensated
% elasticities matter

% Model mechanism: 
        % increase carbon tax, adjust government budget constraint (increse
        % revenue), consumer prices increase based on co2 intensity of each commodity group, incidence on hh depends on
        % composition of consumption bundle, hhs adjust budget shares
        % (substitution effect since uncompensated price change), y changes, dxdy changes, compute
        % EV based on price change + change in y for each hh to observe heterogeneity across income groups and
        % hh types.
pi = 100/1000;
lambda = 1;
mu = 1;
s = zeros(H,1);
R = 0;
EV_R = zeros(H,1);
v = zeros(H,1);
s = zeros(H,1);
dxdy = zeros(H,1);
mar_tax = zeros(H,1);
savings = zeros(H,1);
taxable_income = zeros(H,1);
tot_tax_inputed = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
u = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;

% HH problem;
test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 0.0001
    backup_lambda = lambda;

    for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

lambda = R_0/sum(tot_tax_inputed.*hhfreq);
test = abs(lambda - backup_lambda);

end

x_1 = w.*c;
co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
 
sum(isnan(l)) 
sum(isnan(v))

for i=1:H
    EV_R(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
    EV_frac = EV_R(i,:)./income;
end

% Aggregates;
hrs = sum(l.*hhfreq*52); 
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy)); 
GDP_noadj = sum(c.*hhfreq*52); 

price_change = (exp(p_1) - exp(p_0))./exp(p_0);
dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy); 
mean(dxdy_change) %0.0280
l_change = (hrs - hrs_0)/hrs_0; %-0.0269
E_change = (E - E_0)/E_0; %-0.4268
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0576
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %-0.0252
 
disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
social_sec_share = social_sec./income;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_0,false) %
gini(hhfreq,disp_income_1,false) %0.2721
gini(hhfreq,c_0,false) %
gini(hhfreq,c,false) %0.2959 

% Calculate initial guesses;
R_0 = sum(tot_tax_inputed_0.*hhfreq);
E = sum(co2.*hhfreq); %total weekly emissions;
piE = pi*E;
piE_individual = pi*co2;
lambda_guess = (R_0 - piE)./(R_0); %0.8647
R_guess = piE;

% Per capita transfers, adjusted for family size; 
s_guess = zeros(H,1);
hh_size2 = zeros(H,3);
temp = hh_size2(:,1);
temp(hhsize==1) = 1;
temp2 = hh_size2(:,2);
temp2(hhsize==2) = 1; 
temp3 = hh_size2(:,3);
temp3(hhsize>2) = hhsize(hhsize>2)-2;
hh_size2 = [temp temp2 temp3];
hh_size2 = 1*hh_size2(:,1) + 0.5*hh_size2(:,2) + 0.25*hh_size2(:,3);

tot_H = sum(sum(hh_size2.*hhfreq),2);
s_guess(:) = (hh_size2/tot_H).*piE; %32.8766 (mean)


% Per capita transfers, targeted to bottom 40% of equivalized income distribution;
s_guess2 = inc_quantile;

tot_IC = sum(sum(hh_size2(s_guess2 < 3).*hhfreq(s_guess2 < 3)),2);
s_guess2(s_guess2 < 3) = (hh_size2(s_guess2 < 3)/tot_IC).*piE; %33.7194
s_guess2(s_guess2 == 3) = 0;
s_guess2(s_guess2 == 4) = 0;
s_guess2(s_guess2 == 5) = 0; 

% Per capita transfers, increase in social security benefits;
ss_tot = sum(social_sec.*hhfreq);
mu_guess = (piE/ss_tot) + 1; %35% increse in social security benefits;

% Per capita transfers, targeted to rural households and adjusted for regions; 
temp1 = zeros(H,1);
temp1(urban==1) = 1;
temp1(urban==0) = 1.1;
temp2 = ones(H,1);
temp2(region==11) = 1.5;
temp2(region==12) = 1.5;
temp2(region==1) = 1.5;
temp2(region==2) = 1.5;
hh_size3 = temp1.*temp2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 2a: Recycled as homogenous transfers;

% Model mechanism: 
        % increase carbon tax, adjust government budget constraint (increse
        % transfers), consumer prices increase based on co2 intensity of each commodity group, incidence on hh depends on
        % composition of consumption bundle, hhs reoptimize budget shares
        % (compensated price change, nondistortionary income rebates), compute
        % EV for each hh to observe heterogeneity across income groups and
        % hh types.
        
pi = 100/1000;
lambda = 1;
mu = 1;
s = s_guess;
R = 0;
v = zeros(H,1);
s = zeros(H,1);
dxdy = zeros(H,1);
mar_tax = zeros(H,1);
tot_tax_inputed = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
u = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;

test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 1
    if iter2>1
        tot_H = sum(sum(hh_size2.*hhfreq),2);
        s(:) = (hh_size2/tot_H).*piE;
    end
    
%    for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%    end
    
   for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = sum(s.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end

co2 = sum((w.*c.*e_end./(1+pi*e_end)),2);

for i=1:H
     EV_s(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s_frac = EV_s(i,:)./income;
end

%lambda = 1.0459;
% mean(s) = 21.1744
tot2_H = sum(hhfreq);
hist(EV_s(~isnan(v))) 
positive_share = sum(hhfreq(EV_s>=0))/tot2_H; %0.1793

% Aggregates;
piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 

dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0264
l_change = (hrs - hrs_0)/hrs_0; %-0.0266
E_change = (E - E_0)/E_0; %-0.4141
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0290
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0032

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2624
gini(hhfreq,c,false) %0.2872

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 2b: Recycled as targeted transfers (all transfers to bottom 2 quintiles);

pi = 100/1000;
lambda = 1;
mu = 1;
s = s_guess2;
R = 0;
EV_s2 = zeros(H,1);
v = zeros(H,1);
s = zeros(H,1);
dxdy = zeros(H,1);
mar_tax = zeros(H,1);
tot_tax_inputed = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
u = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;

test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 1
    if iter2>1
    
    s = inc_quantile;
    tot_IC = sum(sum(hh_size2(s < 3).*hhfreq(s < 3)),2);
    s(s < 3) = (hh_size2(s < 3)/tot_IC).*piE; %13.2460
    s(s == 3) = 0;
    s(s == 4) = 0;
    s(s == 5) = 0; 
    end
    
%    for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%    end
    
   for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = sum(s(~isnan(v)).*hhfreq(~isnan(v))) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end
   
co2 = sum((w.*c.*e_end./(1+pi*e_end)),2);

for i=1:H
     EV_s2(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s2_frac = EV_s2(i,:)./income;
end

tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_s2>0))/tot2_H; %0.2925

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));

dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0255
l_change = (hrs - hrs_0)/hrs_0; %-0.0266
E_change = (E - E_0)/E_0; %-0.4118
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0259
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0059


disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2497
gini(hhfreq,c,false) %0.2761

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 2c: Recycled as targeted transfers (increase social security benefits);

pi = 100/1000;
lambda = 1;
s = zeros(H,1);
EV_ss = zeros(H,1);
v = zeros(H,1);
dxdy = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
u = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
mu = mu_guess;
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;

test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 1
    if iter2>1
    
    ss_tot = sum(social_sec.*hhfreq);
    mu = (piE/ss_tot) + 1;
    
    end
    
%     for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%     end
    
    for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;

   
    test = (mu-1)*sum(social_sec.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end
%lambda = 1.0461
% mu = 1.2248
co2 = sum((w.*c.*e_end./(1+pi*e_end)),2);

for i=1:H
     EV_ss(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_ss_frac = EV_ss(i,:)./income;
end


tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_ss>0))/tot2_H; %0.3359

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0144


dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0258
l_change = (hrs - hrs_0)/hrs_0; %-0.0267
E_change = (E - E_0)/E_0; %-0.4075
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0179

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2721
gini(hhfreq,c,false) %0.2796

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 2d: Recycled as targeted transfers (targeting rural households and adjusted for regions);

pi = 100/1000;
lambda = 1;
mu = 1;
s = s_guess;
R = 0;
v = zeros(H,1);
s = zeros(H,1);
dxdy = zeros(H,1);
mar_tax = zeros(H,1);
tot_tax_inputed = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
u = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;


test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 1
    if iter2>1
        tot_H = sum(sum(hh_size3.*hh_size2.*hhfreq),2);
        s(:) = (hh_size2.*hh_size3/tot_H).*piE;
    end
    
%    for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%    end
    
   for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
   
    co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = sum(s.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end
 
co2 = sum((w.*c.*e_end./(1+pi*e_end)),2);

for i=1:H
     EV_s3(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s3_frac = EV_s3(i,:)./income;
end

tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_s3>0))/tot2_H; %0.1846

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0033

dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0264
l_change = (hrs - hrs_0)/hrs_0; %-0.0266
E_change = (E - E_0)/E_0; %-0.4140
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0290

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2621
gini(hhfreq,c,false) %0.2869

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 3: Decrease income tax;

% Model mechanism: 
% increase carbon tax, adjust government budget constraint (decrease lambda), 
        % consumer prices increase based on co2 intensity of each commodity group, incidence on hh depends on
        % composition of consumption bundle, hhs adjust budget shares, marginal tax changes so 
        % hhs adjust labor supply, compute
        % EV for each hh to observe heterogeneity across income groups and
        % hh types.
pi = 100/1000;
lambda = lambda_guess;
mu = 1;
s = zeros(H,1);
EV_l = zeros(H,1);
v = zeros(H,1);
dxdy = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
mar_tax = zeros(H,1);
u = zeros(H,1);
c = zeros(H,1);
co2 = zeros(H,1);
post_tax_wage = zeros(H,1);
R_0 = sum(tot_tax_inputed(~isnan(l)).*hhfreq(~isnan(l)));
mar_tax = zeros(H,1);
tot_tax_inputed = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
beta = 500/1000;
pe = 0.625;
rho = (pi/beta)^pe;
e_end = (1-rho)*e;

test = 1000;
iter2 = 1;

% HH problem;
while abs(test) > 1
    if iter2 > 1
    sum_tax = sum(tot_tax_inputed.*hhfreq);
    lambda = (R_0 - piE)./(sum_tax);
    end

%      for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%      end
    
      for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_2(i,:), np_2(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e_end./(1+pi*e_end),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = R_0 - sum((lambda).*tot_tax_inputed.*hhfreq) - piE;
 
    iter2 = iter2 + 1;
    
end

co2 = sum((w.*c.*e_end./(1+pi*e_end)),2);
    
for i=1:H
     EV_l(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_l_frac = EV_l(i,:)./income;
end

% lambda = 0.8861;
tot2_H = sum(hhfreq);
tot_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_l>=0 & ~isnan(l)))/tot2_H; % 0.1077

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
E_0 = sum(co2_0.*hhfreq*52);
dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0275
l_change = (hrs - hrs_0)/hrs_0; %-0.0145
E_change = (E - E_0)/E_0; %-0.4092
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0067
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0267


disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2857
gini(hhfreq,c,false) %0.3065


figure
hold on
hist(EV_s(~isnan(v)))
set(gca, 'FontSize', 12)
xlabel('EV')
ylabel('Distribution')
xtickformat('gbp')


figure
hold on
gscatter(inc_quantile, EV_frac)
xlabel('Income Quintiles')
ylabel('EV (% of income)')
xticks([1 2 3 4 5])
set(gca, 'FontSize', 14)

figure
hold on
gscatter(z_cat, EV_frac)
xlabel('Household Composition')
ylabel('EV (% of income)')
xticks([1 2 3 4 5 6 7 8])
xticklabels({'Students','Working: Single with Children', ...
    'Working: Couple with No Children',...
    'Working: Couple with Up to 2 Children',...
    'Working: Couple with>2 Children','Other','Retirees', 'Working: Single with No Children'})
set(gca, 'FontSize', 14)

T = table(hhfreq, tax_tot, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_l, disp_income, income, income_1, disp_income_1, income, EV_l_frac, dxdy, EASIdxdy, inc_quantile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single);        
writetable(T,filename,'Sheet',5)