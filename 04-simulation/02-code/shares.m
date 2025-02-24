
function w = shares(z,p,v, A, B, D, alpha_easi, residuals_easi)
    w = B(1).* v.^1 + B(2).*v.^2 + B(3).*v.^3 + B(4).*v.^4 ...
        + sum(A.*p,2) + sum(D.*z.*v,2) + alpha_easi + residuals_easi;
    % Replace w = 0 if predictions are negative;
    w = real(w);
    %w = max(w,0);
end