function [g,l,a] = gini(pop,val,makeplot)
    % check arguments
    assert(nargin >= 2, 'gini expects at least two arguments.')
    if nargin < 3
        makeplot = false;
    end
    assert(numel(pop) == numel(val), ...
        'gini expects two equally long vectors (%d ~= %d).', ...
        size(pop,1),size(val,1))
    pop = [0;pop(:)]; val = [0;val(:)];     % pre-append a zero
    isok = all(~isnan([pop,val]'))';        % filter out NaNs
    if sum(isok) < 2
        warning('gini:lacking_data','not enough data');
        g = NaN; l = NaN(1,4);
        return;
    end
    pop = pop(isok); val = val(isok);
    
    assert(all(pop>=0) && all(val>=0), ...
        'gini expects nonnegative vectors (neg elements in pop = %d, in val = %d).', ...
        sum(pop<0),sum(val<0))
    
    % process input
    z = val .* pop;
    [~,ord] = sort(val);
    pop    = pop(ord);     z    = z(ord);
    pop    = cumsum(pop);  z    = cumsum(z);
    relpop = pop/pop(end); relz = z/z(end);
    
    % Gini coefficient
    % We compute the area below the Lorentz curve. We do this by
    % computing the average of the left and right Riemann-like sums.
    % (I say Riemann-'like' because we evaluate not on a uniform grid, but
    % on the points given by the pop data).
    %
    % These are the two Rieman-like sums:
    %    leftsum  = sum(relz(1:end-1) .* diff(relpop));
    %    rightsum = sum(relz(2:end)   .* diff(relpop));
    % The Gini coefficient is one minus twice the average of leftsum and
    % rightsum. We can put all of this into one line.
    g = 1 - sum((relz(1:end-1)+relz(2:end)) .* diff(relpop));
    
    % Lorentz curve
    l = [relpop,relz];
    a = [pop,z];
    if makeplot   % ... plot it?
        area(relpop,relz,'FaceColor',[0.5,0.5,1.0]);    % the Lorentz curve
        hold on
        plot([0,1],[0,1],'--k');                        % 45 degree line
        axis tight      % ranges of abscissa and ordinate are by definition exactly [0,1]
        axis square     % both axes should be equally long
        set(gca,'XTick',get(gca,'YTick'))   % ensure equal ticking
        set(gca,'Layer','top');             % grid above the shaded area
        grid on;
        title(['\bfGini coefficient = ',num2str(g)]);
        xlabel('share of population');
        ylabel('share of value');
    end
    
end