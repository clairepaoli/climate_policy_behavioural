function tot_tax_inputed = marginal_tax(taxable_income)

annual_taxable = taxable_income*52;

cat(annual_taxable<=11500)=1;
cat(annual_taxable>11500 & annual_taxable<=45000)=2;
cat(annual_taxable>45000 & annual_taxable<=150000)=3;
cat(annual_taxable>150000)=4;

tot_tax_inputed(cat==1) = 0;
tot_tax_inputed(cat==2) = 0.20*(annual_taxable(cat==2)-11500);
tot_tax_inputed(cat==3) = 0.20*(45000-11501) + 0.4*(annual_taxable(cat==3)-45001); 
tot_tax_inputed(cat==4) =  0.20*(45000-11501) + 0.4*(150000-45001) + 0.45*(annual_taxable(cat==4)-150001); 
tot_tax_inputed = tot_tax_inputed./52;
tot_tax_inputed = tot_tax_inputed';
tot_tax_inputed(isnan(tot_tax_inputed)) = 0;

end
