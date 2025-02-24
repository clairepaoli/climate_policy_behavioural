
function v = indirect_u(c, w, p, A, J)
    double_sum = sum2(A,p);
    v = log(c) - sum(w.*p,2) + 0.5*double_sum;
    
 function double_sum = sum2(A,p) 
   m = 0 ;n = 0; 
   double_sum = 0 ; 
   for i = 1:J
        for j = 1:J
        double_sum = double_sum + A(m+i,n+j)*p(i)*p(j); 
        end
   end  
   end  
    
end