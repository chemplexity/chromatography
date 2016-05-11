% ------------------------------------------------------------------------
% Method      : Align
% Description : Batch signal alignment with parametric time warping
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   index = Align(y, yref)
%   index = Align( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   y -- intensity values
%       array | matrix
%
%   yref -- reference signal for alignment
%       array
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'iterations' -- number of iterations to perform warping optimization 
%       50 (default) | number
%
%   'convergence' -- stopping criteria
%       1E-4 (default) | number
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%    P.H.C. Eilers, Analytical Chemistry, 76 (2004) 404

function varargout = Align(varargin)

% ---------------------------------------
% Default
% ---------------------------------------
default.iterations  = 50;
default.convergence = 1E-4;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addRequired(p, 'yref',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'iterations',...
    default.iterations,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));

addParameter(p, 'convergence',...
    default.convergence,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y           = p.Results.y;
yref        = p.Results.yref;
iterations  = p.Results.iterations;
convergence = p.Results.convergence;

% ---------------------------------------
% Variables
% ---------------------------------------
m = max([length(yref(:,1)), length(y(:,1))]);
n = length(y(1,:));

% ---------------------------------------
% Alignment
% ---------------------------------------
for i = 1:n

    B = [ones(m,1), (1:m)', ((1:m)'/m).^2];

    coeff = [0; 1; 0];
    rmse  = [0, 0, 0, 0];

    for j = 1:iterations
    
        w = B * coeff;
        
        index = find(1 < w & w < length(yref(:,1)));
        
        yi = floor(w(index));
        
        dy = yref(yi+1,1) - yref(yi,1);
        
        yy = yref(yi,1) + (w(index) - yi) .* dy;
        
        % Calculate residuals
        residuals = y(index,i) - yy;
    
        % Determine RMSE
        rmse(1) = sqrt(residuals' * residuals / m);
        rmse(3) = abs((rmse(1) - rmse(2)) / (rmse(1) + 1E-10));
        rmse(2) = rmse(1);
        
        % Check convergence
        if rmse(3) < convergence
            break
        end

        % Update coefficients
        coeff = coeff + (repmat(dy, 1, 3) .* B(index,:)) \ residuals;
        
    end
    
    varargout{1}{i} = yi;
    varargout{2}{i} = index;
    
end

end