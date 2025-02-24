
%% Import EASI demand;

clear; close all; clc
easi = readtable('EASI_output_7.xls');

% Settings;
neq = 6;
netq = 7;
n_types = 7;


% EASI data;
% A_0 matrix; 6 (categorie) x 8 
A0m = easi(12:17,2:7);       % A0 matrix of coefficients for p;
A0m = table2array(A0m);
new = 0 - sum(A0m,2);
A_0 = [A0m new];
new = [new' 0];
A_0 = [A_0;new];
A_0 = A_0(:,1:6);
new = 0 - sum(A_0,2);
A = [A_0 new];

% Br matrix; 6 (categories) x 4 (polynomials)
br = easi(1:4,2:7);          % The b vector of coefficients for y to the power r;
br = table2array(br);
br = br';
temp = 0 - sum(br);
B =  [br;temp];

% Z matrix; 8 (categories) x 7 (household types)
Zm = easi(5:11,2:7);         % The D matrix of coefficients for z and y;                    
Zm = table2array(Zm);
Z = Zm';
temp = 0 - sum(Z);
D =  [Z;temp];

clear temp Zm br new Z A0m A_0

