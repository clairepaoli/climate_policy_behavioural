
syms xo2 xo xar
eq1 = xo2 +xo +xar - 1;
eq2 = 2*xo2 +xo -4*xar;
eq3 = 2.063E-4*xo2 - xo^2;
sol = solve(eq1,eq2,eq3); 
double(sol.xo)

syms x y z
eq1=exp(x)+sqrt(y)-z.^3-2;
eq2=x.^2-y-z-5;
eq3=x+exp(y-1)+z-7;
eqs = [eq1, eq2, eq3];
[x,y,z]=vpasolve(eqs,[x,y,z]);

% try;
i = 3451;
c_0 = c_0(i,:);
c = c_0;
v_0 = v_0(i,:);
v = v_0;
l_0 = l_0(i,:);
l = l_0;
w_0 = w_0(i,:);
w = w_0;
z =  z(i,:);
p = p_0(i,:);
p_0 = p_0(i,:);
p_1 = p_1(i,:);
A
B
D
wage = wage(i,:);
alpha_easi = alpha_easi(i,:);
residuals_easi = residuals_easi(i,:);
tax_tot = tax_tot(i,:);
labor_income = labor_income(i,:);
phi = phi(i,:);
elasticity = 0.05;
savings = savings(i,:);
e = e(i,:);
lu = lu(i,:);
xbar = xbar(i,:);
s = 0;
lambda = 1;
%residuals_2 = w_0 - w;

% Build algorithm that converges to true values;

backup_v = 0;
converg = 1;
iter = 1;
while converg > 0.0001
        if iter == 1
        c = c_0;
        v = v_0;
        l = l_0;
        else
        end
    
    backup_v = v;
    for j=1:J
        w(j) = shares( ...
        z, p, v, A(j,:), B(j,:), D(j,:), alpha_easi(j), residuals_easi(j));
    end
    v = indirect_u(c, w, p, A, J);
    dxdy = c./exp(v) * (1 + p*( B(:,1) + B(:,2).*2*v.^1 + B(:,3).*3*v.^2 + B(:,4).*4.*v.^3 + sum(D.*z,2) ));
    dxdy = dxdy/100;
    post_tax_wage = (labor_income - lambda.*tax_tot)./(dxdy.*(l.*lu));
    post_tax_wage(isnan(post_tax_wage)) = 0;
    l = real((post_tax_wage).^elasticity)*lu;
    c = wage.*l - tax_tot + xbar + s - savings; 
    iter = iter + 1;
    iter;
    if iter == 1
    converg = 1;     
    else
    converg = abs(v - backup_v);
    end
  
end

u = real(exp(v) - phi.*((l)./(1+1/elasticity))^(1+1/elasticity));
co2 = sum((w.*c).*e,2);
pi = (100/1000);
carbon_tax = co2*(100/1000);

EV_R = EV_2(v, v_0, w, w_0, p_0, A, J);
EV_s = EV_2(v, v_0, w, w_0, p_0, A, J);
EV_l = EV_2(v, v_0, w, w_0, p_0, A, J);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
syms w1 w2 w3 w4 w5 w6 w7 v dxdy post_tax_wage l c u
eq1 = B(1,1).* v.^1 + B(1,2).*v.^2 + B(1,3).*v.^3 + B(1,4).*v.^4 ...
        + sum(A(1,:).*p) + sum(D(1,:).*z.*v) + alpha_easi(1) + residuals_easi(1) - w1;
eq2 = B(2,1).* v.^1 + B(2,2).*v.^2 + B(2,3).*v.^3 + B(2,4).*v.^4 ...
        + sum(A(2,:).*p) + sum(D(2,:).*z.*v) + alpha_easi(2) + residuals_easi(2) - w2;
eq3 = B(3,1).* v.^1 + B(3,2).*v.^2 + B(3,3).*v.^3 + B(3,4).*v.^4 ...
        + sum(A(3,:).*p) + sum(D(3,:).*z.*v) + alpha_easi(3) + residuals_easi(3) - w3;
eq4 = B(4,1).* v.^1 + B(4,2).*v.^2 + B(4,3).*v.^3 + B(4,4).*v.^4 ...
        + sum(A(4,:).*p) + sum(D(4,:).*z.*v) + alpha_easi(4) + residuals_easi(4) - w4;
eq5 = B(5,1).* v.^1 + B(5,2).*v.^2 + B(5,3).*v.^3 + B(5,4).*v.^4 ...
        + sum(A(4,:).*p) + sum(D(4,:).*z.*v) + alpha_easi(5) + residuals_easi(5) - w5;
eq6 = B(6,1).* v.^1 + B(6,2).*v.^2 + B(6,3).*v.^3 + B(6,4).*v.^4 ...
        + sum(A(4,:).*p) + sum(D(4,:).*z.*v) + alpha_easi(6) + residuals_easi(6) - w6;
eq7 = B(7,1).* v.^1 + B(7,2).*v.^2 + B(7,3).*v.^3 + B(7,4).*v.^4 ...
        + sum(A(4,:).*p) + sum(D(4,:).*z.*v) + alpha_easi(7) + residuals_easi(7) - w7;
eq8 = indirect_u2(c, w1, w2, w3, w4, w5, w6, w7, p, A) - v;
eq9 = c/exp(v) * (1 + p*(B(:,1) + B(:,2)*2*v^1 + B(:,3)*3*v^2 + B(:,4)*4*v^3 + sum(D.*z,2) )) - dxdy;
eq10 = (labor_income - lambda.*tax_tot)./(dxdy.*(l.*lu)) - post_tax_wage;
eq11 = real((post_tax_wage).^elasticity).*lu - l;
eq12 = wage.*l.*lu - tax_tot + xbar + s - savings - c;
eq13 = real(exp(v) - phi.*((l.*lu)./(1+1/elasticity))^(1+1/elasticity)) - u;
eqs = [eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8, eq9, eq10, eq11, eq12, eq13];
[w1, w2, w3, w4, w5, w6, w7, v, dxdy, post_tax_wage, l, c, u]=solve(eqs,[w1, w2, w3, w4, w5, w6, w7, v, dxdy, post_tax_wage, l, c, u]);
 
syms w1 w2 w3 w4 w5 w6 w7 v dxdy post_tax_wage l c u
eq1 = shares(z, p, v, A(1,:), B(1,:), D(1,:), alpha_easi(1), residuals_easi(1)) - w1;
eq2 = shares(z, p, v, A(2,:), B(2,:), D(2,:), alpha_easi(2), residuals_easi(2)) - w2;
eq3 = shares(z, p, v, A(3,:), B(3,:), D(3,:), alpha_easi(3), residuals_easi(3)) - w3;
eq4 = shares(z, p, v, A(4,:), B(4,:), D(4,:), alpha_easi(4), residuals_easi(4)) - w4;
eq5 = shares(z, p, v, A(5,:), B(5,:), D(5,:), alpha_easi(5), residuals_easi(5)) - w5;
eq6 = shares(z, p, v, A(6,:), B(6,:), D(6,:), alpha_easi(6), residuals_easi(6)) - w6;
eq7 = shares(z, p, v, A(7,:), B(7,:), D(7,:), alpha_easi(7), residuals_easi(7)) - w7;
eq8 = indirect_u2(c, w1, w2, w3, w4, w5, w6, w7, p, A) - v;
eq9 = c/exp(v) * (1 + p*(B(:,1) + B(:,2)*2*v^1 + B(:,3)*3*v^2 + B(:,4)*4*v^3 + sum(D.*z,2) )) - dxdy;
eq10 = (labor_income - lambda.*tax_tot)./(dxdy.*(l.*lu)) - post_tax_wage;
eq11 = real((post_tax_wage).^elasticity).*lu - l;
eq12 = wage.*l.*lu - tax_tot + xbar + s - savings - c;
eq13 = real(exp(v) - phi.*((l.*lu)./(1+1/elasticity))^(1+1/elasticity)) - u;
eqs = [eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8, eq9, eq10, eq11, eq12, eq13];
[w1, w2, w3, w4, w5, w6, w7, v, dxdy, post_tax_wage, l, c, u]=solve(eqs,[w1, w2, w3, w4, w5, w6, w7, v, dxdy, post_tax_wage, l, c, u], 'IgnoreAnalyticConstraints',1);

