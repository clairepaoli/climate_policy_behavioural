
function EV = EV(c_0, c, w_0, w, p_0, q, A, J)
    x = double(A,q,p_0);
    EV = exp((log(c) + sum(w_0.*p_0 - w.*q) + 0.5.* x)) - c_0;
    EV = real(EV);
    
function x = double(A,q,p) 
   m = 0 ;n = 0; 
   x = 0; 
   for i = 1:J
        for j = 1:J
        x = x + A(m+i,n+j)*q(i)*q(j) - A(m+i,n+j)*p(i)*p(j); 
      end
   end  
 end
    
    
end