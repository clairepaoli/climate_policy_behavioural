
%% Model for simulating the effects of carbon taxation for UK HH with estimated EASI demand 
% (1) Calibrate parameters;
% (2) Specify variables from data;
% (3) Calibrate variables from estimation so that they match the data;
% (4) Solve nonlinear system to get values for y and ws;
% (5) Calculate results:
    % EV
    % hours (household)
    % hours (aggregate)
    % expenditure (aggregate) (GDP)
% (6) Optimize to get optimal values for lambda, s and R;


clear; close all; clc
data = readtable('simulation_data_100.xls');

filename = 'output_data.xlsx';

%% 1. Parameter Values

     % Indices
     H = 3367;              % Households
     K = 7;                 % Household characteristics
     R = 4;                 % Exponents in polynomial Engel curves R=4
     IC = 10;               % Income categories
     J = 7;                 % Commodity groups (aggregated demand categories)
     
     
    %set scalar parameter values (calibrated based on previous estimation)
     EASI_elasticity = 0.28;            % EASI labour elasticity        
     EASI_heta = 0;                     % EASI elasticity of substitution
     
     elasticity = EASI_elasticity;      % Frischian wage elasticity of labour supply;
     heta = EASI_heta;                  % Elasticity of substitution - this is zero in our model;
     weight_co2 = 0;                    % Weight of CO2 in agg. utility
     penalty_scalar = 10000;            % Scalar on penalty. pi target; set to a really high number;
     pi_target = 0;                     % Target carbon tax
     CO2_target = 0;                    % Target CO2 emissions
     eta = 2;                           % Inequality aversion;                         
     m = 1;                             % Misperception parameters vector;

     %load estimated paramaters
     
     A                       % price effects
     B                       % b matrix
     D
     
     % Household data;
     id = table2array(data(:,"hh_id"));
     id2 = [1:H]';
     LCF = table2array(data(:,"LCF_round"));
     exp_poverty = table2array(data(:,"exp_poverty"));
     urban = table2array(data(:,"urban"));
     urban(isnan(urban))=0;
     n_children = table2array(data(:,"n_children"));
     n_adults = table2array(data(:,"n_adults"));
     region = table2array(data(:,"region"));
     oecd = table2array(data(:,"oecdsc"));
     x_0 = table2array(data(:,["xfood", "xheating", "xtransport", "xhousing", "xserv", "xdur", "xother2"]));                        
     w_0 = table2array(data(:,["s1", "s2", "s3", "s4", "s5", "s6", "s7"]));                                                              
     e = table2array(data(:,["food_int", "heating_int", "transport_int", "housing_int", "serv_int", "dur_int", "other_int"]));     
     c_0 = table2array(data(:,"xtot"));
     equiv_c_0 = table2array(data(:,"equiv_consumption"));
     z = table2array(data(:,["z1", "z2", "z3", "z4", "z5", "z6", "z7"])); 
     alpha_easi = table2array(data(:,["alphas_easi_1", "alphas_easi_2", "alphas_easi_3", "alphas_easi_4", "alphas_easi_5", "alphas_easi_6"]));
     alpha_easi = [alpha_easi zeros(H,1)];
     alpha_l = table2array(data(:,"alphas_l"));
     residuals_easi = table2array(data(:,["res_easi_1", "res_easi_2", "res_easi_3", "res_easi_4", "res_easi_5", "res_easi_6"]));
     residuals_easi = [residuals_easi zeros(H,1)];
     p_0 = table2array(data(:,["p1", "p2", "p3", "p4", "p5", "p6", "p7"]));    % 1000 x 8: Commodity prices (before carbon tax)  
     p_1 = table2array(data(:,["p1_new", "p2_new", "p3_new", "p4_new", "p5_new", "p6_new", "p7_new"])); 
     p_2 = table2array(data(:,["p1_2new", "p2_2new", "p3_2new", "p4_2new", "p5_2new", "p6_2new", "p7_2new"])); 
     np_0 = table2array(data(:,["np1", "np2", "np3", "np4", "np5", "np6"]));
     np_0 = [np_0 zeros(H,1)];
     np_1 = table2array(data(:,["np1_new", "np2_new", "np3_new", "np4_new", "np5_new", "np6_new"]));
     np_1 = [np_1 zeros(H,1)];
     np_2 = table2array(data(:,["np1_2new", "np2_2new", "np3_2new", "np4_2new", "np5_2new", "np6_2new"]));
     np_2 = [np_2 zeros(H,1)];
     income = table2array(data(:,"income_wk_tot")); 
     equiv_income = table2array(data(:,"equiv_income"));
     income_disp = table2array(data(:,"income_wk_disposable")); 
     equiv_income_disp = table2array(data(:,"equiv_disp_income"));
     social_sec = table2array(data(:,"ss_only")); 
     social_sec(isnan(social_sec))=0;
     salary_income = table2array(data(:,"inc_wk_salary_tot"));
     self_income = table2array(data(:,"inc_wk_self"));
     labor_income = salary_income + self_income;
     EASIdxdy = table2array(data(:,"dxy"));                                  % EASI baseline d x wrt y
     lres = table2array(data(:,"lres"));                           % EASI residuals in labor supply;
     l_0 = table2array(data(:,"hours_tot"));                     % 1000 x 1: weekly hours worked;
     lu = exp(alpha_l + lres);
     exp_quantile = table2array(data(:,"exp_quantile"));
     exp_decile = table2array(data(:,"exp_decile"));
     inc_decile = table2array(data(:,"inc_decile"));
     inc_quantile = table2array(data(:,"inc_quantile"));
     x_decile = table2array(data(:,"x_decile"));
     disp_income_decile = table2array(data(:,"disp_income_decile"));
     wage = labor_income./l_0;
     wage(isnan(wage))=0;
     wage(isinf(wage))=0;
     cons_shares = table2array(data(:,"exp_share"));              % 1000 x 1: consumption share of income;
     %savings = table2array(data(:,"savings"));                  % 1000 x 1: Level of savings;
     hhsize = table2array(data(:,"hh_size"));                   % 1000 x 1: persons per household,
     hhweight = table2array(data(:,"new_weight"));              % 1000 x 1: weight of household in aggregate,
     v_0 = table2array(data(:,"y"));
    
     xbar =  income - labor_income - social_sec;
     taxable_income = labor_income + xbar;
 
     
     hhtotal = sum(hhweight);             % total sum of households in UK;
     hhfreq =  hhweight;            % relative frequency of household in aggregate,
     hhpareto = ones(H,1);                % Pareto weight of household in aggregate utility,

    tax_tot = table2array(data(:,"income_paye_tax"));  
    ni_contribution = table2array(data(:,"ni_contribution")); 
    tax_avg_0 = tax_tot./taxable_income; 
    tax_avg_0(isnan(tax_avg_0))=0;
    tax_avg_0(isinf(tax_avg_0))=0;
    disp_income_0 = income - tax_tot;
    savings_0 = income - tax_tot - ni_contribution - c_0;
    MPS = savings_0./income;
    
    bla = tax_tot./labor_income; 
    bla(isnan(bla))=0;
    bla(isinf(bla))=0;
    mean(bla) %0.0652
    
    dummy_london = table2array(data(:,"london"));              % dummy = 1 if London
    dummy_male = table2array(data(:,"sexhrp"));                % dummy = 1 if male
    dummy_single = table2array(data(:,"single"));              % dummy = 1 if single
    dummy_child = table2array(data(:,"d_children"));           % dummy = 1 if with children
    
    % Hh types;
    z_cat = zeros(H,1);
    z_cat(z(:,1)==1) = 3;
    z_cat(z(:,2)==1) = 5;
    z_cat(z(:,3)==1) = 6;
    z_cat(z(:,4)==1) = 7;
    z_cat(z(:,5)==1) = 8;
    z_cat(z(:,6)==1) = 1;
    z_cat(z(:,7)==1) = 2;
    z_cat(z_cat==0) = 4;

    
    
    %phi2 = exp(EASI_phi0 + dummy_london * EASI_phi_london + dummy_male * EASI_phi_male + dummy_single * EASI_phi_single + dummy_child * EASI_phi_child);
    
     phi = 1./(exp(alpha_l./elasticity));
    %todrop = zeros(H,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% Descriptives:

hist(w_0)
hist(p_0)
hist(p_1)
hist(c_0)
hist(income)
tabulate(inc_quantile)
tabulate(inc_decile)

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%% Model;
% each household: u = v + phi*(1/1+1/e)*l^(1+1/e) - psi*E
% v_est = exp( log(xtot) - sumj wj log(pj) + sumj sumi aji log(pj) log(pi) )
% l = w(1-t_new)/(phi * P)
% for j =i...J wj_est = sumr b1 log(v) + b2 log(v)^2 + b3 log(v)^3 + b4 + log(v)^4 + sum(j=2-T)*Z*zj*log(v) + ajk log(pk) + ej
% hh budget constraint: (w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8)*xtot + savings = w*l - tax + exogenous income + s
% E = sumh (w1*e1 + w2*e2 + w3*e3 + w4*e4 + w5*e5 + w6*e6 + w7*e7 + w8*e8)*xtot
% t_new = lambda*t_old

% government:
% sum Nh 
% sumh Nh s = pi * E, where s = 1/H (pi * E)
% R = pi * E
% (1-lambda) sumh Nh tax = pi * E

% Results:
% E_log: v_est + sumj wj log(pj) - sumj wj_est log(pj) + 0.5 sumj sumi log(qj)
% log(qi) - 0.5 sumj aij sumi log(pj) log(pi)
% E = exp(E_log)
% EV = E - v_0
% hours_h = labor_est * EASIlres
% hours_tot = sum(hours_h .* hhweight * 4 * 12,2);                
% x_agg = sum(x_h .* hhweight * 4 * 12,2);


%% Computations
% Solve system of nonlinear equations:
    % 1. Problem of one household; solve for budget shares, y and l and c, compute
    % total household emissions;
    % 2. Solve this problem for all households in a loop;
    % 3. Compute aggregate emissions E, total carbon tax revenue pi * E
    % First solve steps 1-3 for original prices (no carbon tax) to get baseline
    % w, c and v.
    % 4. For each scenario, rerun problem:
        % For no recycling, solve problem with new prices only
        % For lump sum recycling: solve problem with s = 1/H * pi * E and
        % new prices: use convergence algorithm that finds values that make
        % government budget constraint hold. 
        % For lowering carbon tax: solve problem with new marginal tax and new prices;
    % 5. After each scenario, make sure that govt budget constraint holds up to small parameter. 
    % 6. If doesn't hold, repeat step 4 with new pi * E
    % 7. Repeat steps 4-6 until govt budget constraint holds;
    % 8. For each scenario, compute EV for each household, aggregate hours worked, aggregate consumption, aggregate emissions.
        % EV depends on baseline prices, w and c and new prices, new w and new c. 
    % 9. Export to Excel, compute average EVs for each income group and
        % household type. 

% Optimization: find optimal way of recycling revenues: 
    % 1. Compute social welfare function: add up household utilities weighted by
    % Pareto weights and net of aggregate emissions cost. 
    % 2. Maximize this objective function wrt transfers, lambda and R such that the government budget constraint holds. Find optimal way of recycling revenues.
    % 3. Apply this optimal way and repeat steps  in solver to derive household EV.

% Optimization with mispercetions: find optimal way of recycling revenues: 
    % Apply misperception parameter: draw misperception parameters from
    % pre-defined distribution (normal) and pre-specified bounds. Households
    % randomly subject to misperceptio parameter so underperceive and
    % overperceive prices. 
% 1. Compute social welfare function: add up household utilities weighted by
% Pareto weights and net of aggregate emissions cost. 
% 2. Maximize this objective function wrt transfers, lambda and R such that the government budget constraint holds. Find optimal way of recycling revenues.
% 3. Apply this optimal way and repeat steps  in solver to derive household EV.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Warm start: test functions and estimate baseline (no carbon tax)
s = zeros(H,1);
s_guess = zeros(H,1);
lambda = 1;
mu = 1;
v = zeros(H,1);
dxdy = zeros(H,1);
w = zeros(H,J);
l = zeros(H,1);
savings = zeros(H,1);
v_blu = zeros(H,1);
taxable_income = zeros(H,1);
u = zeros(H,1);
c = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);
co2 = zeros(H,1);
R = 0;
post_tax_wage = zeros(H,1);

% Tax incidence;
% co2 = sum((w_0.*c_0).*e,2);
% carbon_tax = co2*(100/1000); %weekly carbon tax paid;
% offer_1 = carbon_tax./c_0;
% offer_2 = carbon_tax./disp_income;
% 
% % practice round;
% % Estimate w given v;
% for j=1:J 
% w(:,j) = B(j,1).* v_0.^1 + B(j,2).*v_0.^2 + B(j,3).*v_0.^3 + B(j,4).*v_0.^4 ...
%         + sum(A(j,:).*np_0,2) + sum(D(j,:).*z.*v_0,2) + alpha_easi(:,j) + residuals_easi(:,j);
% end
% w(:,7) = 1 - sum(w(:,1:6),2);
% hist(w)
% res = w - w_0;
% hist(res)
% 
% 
% %Estimate v, given original shares:
% for i=1:H
% v(i,:) = indirect_u(c_0(i,:), w(i,:), p_0(i,:), A, J);
% end
% check = v_0 - v;
% hist(check); %ok
% hist(v)
% 
% for i=1:H
% dxdy(i,:) = c_0(i,:)/exp(v(i,:)) * (1 + p_0(i,:)*(B(:,1) + B(:,2)*2*v(i,:)^1 + B(:,3)*3*v(i,:)^2 + B(:,4)*4*v(i,:)^3 + sum(D.*z(i,:),2) )); 
% end
% 
% dxdy = dxdy/100;
% check = dxdy - EASIdxdy; %very small;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
% Baseline: estimate the original values;
% HH problem;

% for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_0(i,:), np_0(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
% end

for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_0(i,:), np_0(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
end

co2 = sum(w.*c.*e,2);

% Households which didn't converge;
sum(isnan(l)) %0 households;
[l l_0]
[v v_0]
[c c_0]

post_tax_wage_0 = post_tax_wage;
l_0 = l;
c_0 = c;
v_0 = v;
w_0 = w;
u_0 = u;
co2_0 = co2;
post_tax_wage_0 = post_tax_wage;
savings_0 = savings;
income_0 =  wage.*l_0 + social_sec + xbar + s;
disp_income_0 = wage.*l_0 - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
tot_tax_inputed_0 = tot_tax_inputed;

hrs_0 = sum(l_0.*hhfreq*52); 
E_0 = sum(co2_0.*hhfreq*52); 
GDP_0 = sum(c_0.*hhfreq*52);

R_0 = sum(tot_tax_inputed_0.*hhfreq);

 
%% Equivalent variations (policy scenarios 1-3)
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

% HH problem;
% for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
% end

test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 0.0001
    backup_lambda = lambda;

for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
end

lambda = R_0/sum(tot_tax_inputed.*hhfreq);
test = abs(lambda - backup_lambda);

end

x_1 = w.*c;
co2 = sum(w.*c.*e./(1+pi*e),2);
 
sum(isnan(l)) 
sum(isnan(v))

for i=1:H
    EV_R(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
    EV_frac = EV_R(i,:)./income;
end


sum(EV_R>0) % 0
sum(isnan(v))


figure
hold on
gscatter(x_decile, EV_frac)
xlabel('Consumption Deciles')
ylabel('EV (% of income)')
xticks([1 2 3 4 5 6 7 8 9 10])
set(gca, 'FontSize', 14)

figure
hold on
gscatter(z_cat, EV_frac)
xlabel('Household Composition')
ylabel('EV (% of income)')
xticks([1 2 3 4 5 6 7 8])
xticklabels({'Other','Retirees', ...
    'Students',...
    'Working: Single with no children',...
    'Working: Single with children',...
    'Working: Couple with no children',...
    'Working: Couple with < 3 children',...
    ' Working: Couple with >2 children'})
set(gca, 'FontSize', 14)


l_change = ( l - l_0)./l_0;
wage_change = (post_tax_wage - post_tax_wage_0)./post_tax_wage_0;
nanmean(l_change(inc_decile==1))
nankeen(l_change(inc_decile==10))
nanmean(wage_change(inc_decile==1))
nanmean(wage_change(inc_decile==10))

% Aggregates;
hrs = sum(l.*hhfreq*52); 
hrs_0 = sum(l_0.*hhfreq*52);
E = sum(co2.*hhfreq*52);
E_0 = sum(co2_0.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy)); 
GDP_0 = sum(c_0.*hhfreq*52);

price_change = (exp(p_1) - exp(p_0))./exp(p_0);
mean(price_change)
dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy); 
mean(dxdy_change) %the mean price increase is 0.0440
l_change = (hrs - hrs_0)/hrs_0; %-0.0328
E_change = (E - E_0)/E_0; %-0.1397
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0798
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %-0.0307
 
%disp_income_1 = wage.*l - lambda*tax_tot + social_sec + xbar + s - ni_contribution;
disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
social_sec_share = social_sec./income;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_0,false) %0.2764
gini(hhfreq,disp_income_1,false) %0.2714
gini(hhfreq,c_0,false) %0.2990
gini(hhfreq,c,false) %0.2954

% Calculate initial guesses;
R_0 = sum(tot_tax_inputed_0.*hhfreq);
%R_0 = sum(tot_tax.*hhfreq);
E = sum(co2.*hhfreq); %total weekly emissions;
piE = pi*E;
piE_individual = pi*co2;
lambda_guess = (R_0 - piE)./(R_0); %0.6074
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


T = table(id, MPS, LCF, hhfreq, tax_tot, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_R, disp_income_0, income_0, income_1, disp_income_1, income, EV_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',1)

% Effect of transfers with no behavioural response (ROBUSTNESS CHECKS);
tot2_H = sum(hhfreq);
weird = EV_R + s_guess;
sum(weird>0);
positive_share = sum(hhfreq(weird>0))/tot2_H; %0.3709%

figure
hold on
gscatter(inc_quantile, weird)
xlabel('Income Quintiles')
ylabel('Net Welfare')
xticks([1 2 3 4 5])
set(gca, 'FontSize', 14)

figure
hold on
gscatter(z_cat, weird)
xlabel('Household Composition')
ylabel('EV')
xticks([1 2 3 4 5 6 7 8])
xticklabels({'Students','Working: Single with Children', ...
    'Working: Couple with No Children',...
    'Working: Couple with Up to 2 Children',...
    'Working: Couple with>2 Children','Other','Retirees', 'Working: Single with No Children'})
set(gca, 'FontSize', 14)

weird2 = EV_R + s_guess2;
sum(weird2>0)
positive_share = sum(hhfreq(weird2>0))/tot2_H; %0.3596

figure
hold on
gscatter(x_decile, weird2)
xlabel('Income Quintiles')
ylabel('Net Welfare')
xticks([1 2 3 4 5 6 7 8 9 10])
set(gca, 'FontSize', 14)

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


test = 1000;
iter2 = 1;
% HH problem;
while abs(test) > 1
    if iter2>1
        tot_H = sum(sum(hh_size2.*hhfreq),2);
        s(:) = (hh_size2/tot_H).*piE;
    end
    backup_lambda = lambda;
    
%    for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%    end
    
   for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test2 = sum(s.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    test3 = abs(lambda - backup_lambda);
    test = test2 + test3;

    iter2 = iter2 + 1;
    
end

%lamdba = 1.0559
co2 = sum((w.*c.*e./(1+pi*e)),2);

for i=1:H
     EV_s(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s_frac = EV_s(i,:)./income;
end


tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_s>=0))/tot2_H; %0.1875

figure
hold on
hist(EV_s(~isnan(l)))
set(gca, 'FontSize', 12)
xlabel('EV')
ylabel('Distribution')
xtickformat('gbp')


figure
hold on
gscatter(inc_quantile, EV_s_frac)
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

% Aggregates;
piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 

dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0412
l_change = (hrs - hrs_0)/hrs_0; % -0.0324
E_change = (E - E_0)/E_0; %-0.1103
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0369
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; % 0.0125

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2569
gini(hhfreq,c,false) %0.2825

T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_s, disp_income_0, income_0, income_1, disp_income_1, income, EV_s_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scenario 2b: Recycled as targeted transfers (all transfers to bottom 2 quintiles);

pi = 100/1000;
lambda = 1;
mu = 1;
s = s_guess2;
R = 0;
EV_R = zeros(H,1);
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
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = sum(s(~isnan(v)).*hhfreq(~isnan(v))) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end

%lamdba = 1.0562
co2 = sum((w.*c.*e./(1+pi*e)),2);

for i=1:H
     EV_s2(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s2_frac = EV_s2(i,:)./income;
end


tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_s2>0))/tot2_H; %0.2991

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));

dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0399
l_change = (hrs - hrs_0)/hrs_0; %-0.0324
E_change = (E - E_0)/E_0; %-0.1054
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0321
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0167

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2382
gini(hhfreq,c,false) %0.2669

T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_s2, disp_income_0, income_0, income_1, disp_income_1, income, EV_s2_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',3)

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
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;

   
    test = (mu-1)*sum(social_sec.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end
%lambda = 1.0562
% mu = 1.3432
co2 = sum((w.*c.*e./(1+pi*e)),2);

for i=1:H
     EV_ss(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_ss_frac = EV_ss(i,:)./income;
end


tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_ss>0))/tot2_H; %0.3447

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0299


dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0402
l_change = (hrs - hrs_0)/hrs_0; %-0.0326
E_change = (E - E_0)/E_0; %-0.0952
GDP_change = (GDP - GDP_0)/GDP_0; % -0.0200

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2714
gini(hhfreq,c,false) %0.2724

T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_ss, disp_income_0, income_0, income_1, disp_income_1, income, EV_ss_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',4)

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
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
   
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = sum(s.*hhfreq) - piE;
    lambda = R_0/sum(tot_tax_inputed.*hhfreq);
    iter2 = iter2 + 1;
    
end
 
%lambda = 1.0559
co2 = sum((w.*c.*e./(1+pi*e)),2);

for i=1:H
     EV_s3(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_s3_frac = EV_s3(i,:)./income;
end


tot2_H = sum(hhfreq);
positive_share = sum(hhfreq(EV_s3>0))/tot2_H; %0.1927

piE_individual = pi*co2;
hrs = sum(l.*hhfreq*52);
E = sum(co2.*hhfreq*52);
GDP = sum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = sum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; %0.0126


dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
mean(dxdy_change) %0.0412
l_change = (hrs - hrs_0)/hrs_0; %-0.0323
E_change = (E - E_0)/E_0; %-0.1102
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0368
disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2565
gini(hhfreq,c,false) %0.2822

T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_s3, disp_income_0, income_0, income_1, disp_income_1, income, EV_s3_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',6)


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
R_0 = sum(tot_tax_inputed_0.*hhfreq);
mar_tax = zeros(H,1);
tot_tax_inputed = zeros(H,1);
iter = zeros(H,1);
converg = zeros(H,1);

% The problem is that taxes are small part of labor income so the change in
% the wage is very small;
% post_tax_wage = ((labor_income - lambda*tax_tot)./l_0)
% ghjhg = ((labor_income - tax_tot)./l_0);
% change = post_tax_wage./ghjhg
% change(isnan(change)) = 0;

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
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    test = R_0 - sum((lambda).*tot_tax_inputed.*hhfreq) - piE;
 
    iter2 = iter2 + 1;
    
end

%lambda = 0.8188
co2 = sum(w.*c.*e./(1+pi*e),2);
    
for i=1:H
     EV_l(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_l_frac = EV_l(i,:)./income;
end


tot2_H = sum(hhfreq(~isnan(l)));
positive_share = sum(hhfreq(EV_l>=0 & ~isnan(l)))/tot2_H; %0.1081 


piE_individual = pi*co2;
hrs = nansum(l.*hhfreq*52);
E = nansum(co2.*hhfreq*52);
GDP = nansum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = nansum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; % 0.0281


dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
nanmean(dxdy_change) % 0.0432
l_change = (hrs - hrs_0)/hrs_0; %-0.0160
E_change = (E - E_0)/E_0; %--0.1027
GDP_change = (GDP - GDP_0)/GDP_0; %-0.0230

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;

gini(hhfreq,disp_income_1,false) %0.2868
gini(hhfreq,c,false) %0.3074


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

T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_l, disp_income_0, income_0, income_1, disp_income_1, income, EV_l_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',5)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combined policy; combine income tax and transfers;

% Set income tax from 1 to 0.80, and let social security payments adjust:

pi = 100/1000;
mu = mu_guess;
s = zeros(H,1);
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
R_0 = sum(tot_tax_inputed_0.*hhfreq);


test = 1000;
iter2 = 1;

lambda = 1;
lambda = 0.95;
lambda = 0.90;
lambda = 0.85;
lambda = 0.80;

% HH problem;
while abs(test) > 1
    if iter2 > 1
    ss_tot = sum(social_sec.*hhfreq);
    mu = (revenues/ss_tot);
    end

%      for i=1:H
%     [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem2( ...
%         MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
%         tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
%     end

    for i=1:H
    [v(i,:), w(i,:), l(i,:), u(i,:), dxdy(i,:), c(i,:), post_tax_wage(i,:), tot_tax_inputed(i,:), iter(i,:),converg(i,:),savings(i,:)] = hh_problem( ...
        MPS(i,:), mu, l(i,:), l_0(i,:), w(i,:), z(i,:), v(i,:), v_0(i,:), p_1(i,:), np_1(i,:), A, B, D, c(i,:), c_0(i,:), wage(i,:), alpha_easi(i,:), residuals_easi(i,:), ...
        tax_tot(i,:), labor_income(i,:), phi(i,:), elasticity, savings(i,:), lu(i,:), xbar(i,:), taxable_income(i,:), s(i,:), lambda, J, post_tax_wage(i,:), ni_contribution(i,:), social_sec(i,:), EASIdxdy(i,:),iter(i,:),converg(i,:));
    end

    sum(isnan(l))
    
    co2 = sum(w.*c.*e./(1+pi*e),2);
    E = sum(co2.*hhfreq);
    piE = pi.*E;
    
   
    % test govt;
    revenues = piE - R_0 + sum(hhfreq.*social_sec) + lambda*sum(tot_tax_inputed.*hhfreq);
    test = piE - R_0 + sum(hhfreq.*social_sec) + lambda*sum(tot_tax_inputed.*hhfreq) - mu*sum(social_sec.*hhfreq);
    
    
    iter2 = iter2 + 1;
    
end

co2 = sum(w.*c.*e./(1+pi*e),2);
    
for i=1:H
     EV_comb(i,:) = EV_2(v(i,:), v_0(i,:), w(i,:), w_0(i,:), p_0(i,:), A, J);
     EV_comb_frac = EV_comb(i,:)./income;
end


tot2_H = sum(hhfreq(~isnan(l)));
positive_share = sum(hhfreq(EV_comb>=0 & ~isnan(l)))/tot2_H; %0.2974 


piE_individual = pi*co2;
hrs = nansum(l.*hhfreq*52);
E = nansum(co2.*hhfreq*52);
GDP = nansum(c.*hhfreq*52.*(EASIdxdy./dxdy));
GDP_noadj = nansum(c.*hhfreq*52); 
GDP_noadj_change = (GDP_noadj - GDP_0)/GDP_0; 


dxdy_change = (exp(dxdy) - exp(EASIdxdy))./exp(EASIdxdy);
nanmean(dxdy_change) 
l_change = (hrs - hrs_0)/hrs_0; 
E_change = (E - E_0)/E_0; 
GDP_change = (GDP - GDP_0)/GDP_0; 

disp_income_1 = wage.*l - lambda*tot_tax_inputed + social_sec + xbar + s - ni_contribution;
income_1 =  wage.*l + social_sec + xbar + s;


T = table(id, LCF, hhfreq, tot_tax_inputed, ni_contribution, social_sec, w_0, w, c, c_0, post_tax_wage, EV_comb, disp_income_0, income_0, income_1, disp_income_1, income, EV_comb_frac, dxdy, EASIdxdy, inc_quantile, inc_decile, x_decile, z_cat, co2, co2_0, dxdy_change, piE_individual, urban, exp_poverty, urban, region, dummy_male, dummy_london, dummy_child, dummy_single, p_1);
writetable(T,filename,'Sheet',7)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal policy; govt optimizes to max social welfare function;
pi = 100/1000;
s = zeros(H,1);
R = 0;
v = zeros(H,1);
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
tot_tax_inputed = zeros(H,1);
R_0 = sum(tot_tax_inputed_0.*hhfreq);

% set bounds;
lb = [0,1];
ub = [1,Inf];
% theta_guess = [1,30.9556];
% theta_guess2 = [0.8,100];
% theta_guess3 = [0.5,1000];

lambda0 = [1;0.8;0;0.5;0.2];
mu0 = [1.3;1.14;1;2;6];

% Pre-specify the output variables from our optimiser:
parest = nan(2,length(lambda0)); % This will save our two pararmater estimates
parest2 = nan(2,length(lambda0));
parest3 = nan(2,length(lambda0));
parest4 = nan(2,length(lambda0));
func = nan(length(lambda0),1); % This will save the value of the log likelihood at our parameter estimates
func2 = nan(length(lambda0),1);
func3 = nan(length(lambda0),1);
func4 = nan(length(lambda0),1);
exitflag = nan(length(lambda0),1); % This will tell us why the optimiser stopped

P = [- sum(tot_tax_inputed.*hhfreq), sum(social_sec.*hhfreq)];
b = [piE - R_0 + sum(social_sec.*hhfreq)];

% eta = 0
% for ii = 1:length(lambda0)
%     [parest(:,ii),func(ii,1),output,grad] =...
%     fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, ...
%         MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, ...
%         c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, ...
%         elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ...
%         ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0(ii,1);mu0(ii,1)],[],[],P,b,lb,ub,[]);
% end

%Test!
obj = govt_problem(theta_guess, H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg);
obj2 = govt_problem(theta_guess2, H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg);
obj3 = govt_problem(theta_guess3, H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg);

lambda0 = 0.9;
mu0 = 1;

eta = 0;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);

for ii = 1:length(lambda0)
    [parest(:,ii),func(ii,1),output,grad] =...
    fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, ...
        MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, ...
        c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, ...
        elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ...
        ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0(ii,1);mu0(ii,1)],P,b,[],[],lb,ub,[]);
end


eta = 0.2;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);


eta = 0.4;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);

eta = 0.6;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);
lambda = 0.9994
mu = 1.3047

eta = 0.8;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);


eta = 1;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);


eta = 1.2;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);
eta = 1.4;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);
eta = 1.6;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);
eta = 1.8;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);
eta = 2;
[theta_hat, fval,grad,hessian] = fmincon(@(t) govt_problem(t(1,1),t(2,1), H, hhsize, hhfreq, eta, income, MPS, mu, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, lambda, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg),[lambda0; mu0],P,b,[],[],lb,ub,[]);



% Test: for given eta, plot social welfare function at different
% combinations of lambda and mu;
eta = 0;
eta = 0.2;
eta = 0.4;
eta = 0.6;
eta = 0.8;
eta = 1;
eta = 2;

[obj1, obj2, obj3] = govt_problem(lambda, mu, H, hhsize, hhfreq, eta, income, MPS, e, l, l_0, w, w_0, z, v, v_0, p_0, p_1, np_1, A, B, D, c, c_0, wage, alpha_easi, residuals_easi, tax_tot, labor_income, phi, elasticity, savings, lu, xbar, taxable_income, s, J, post_tax_wage, ni_contribution, social_sec, EASIdxdy,iter,converg);
                    

lambda = 1
mu = 1.33

lambda = 0.95
mu = 1.19

lambda = 0.9
mu = 1.12

lambda = 0.85
mu = 1.05

lambda = 0.83
mu = 1











 