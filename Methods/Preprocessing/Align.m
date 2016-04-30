% ------------------------------------------------------------------------
% Method      : Align
% Description : Parametric time warping chromatogram alignment
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   index = Align(y0, y)
%   index = Align(y0, y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y0 (required)
%       Description : calibration signal
%       Type        : array
%
%   y (required)
%       Description : intensity values
%       Type        : array, matrix, cell array
%
%   'iterations' (optional)
%       Description : number of iterations for warping optimization 
%       Type        : number
%       Default     : 50
%       Range       : >0
%
%   'convergence' (optional)
%       Description : stopping criteria
%       Type        : number
%       Default     : 1E-4
%       Range       : >0
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

addRequired(p, 'y0',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'iterations',...
    default.iterations,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

addParameter(p, 'convergence',...
    default.convergence,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y0          = p.Results.y0;
y           = p.Results.y;
iterations  = p.Results.iterations;
convergence = p.Results.convergence;

% ---------------------------------------
% Validate
% ---------------------------------------
if iterations <= 0
    iterations = 1;
end

if convergence <= 0
    convergence = 0;
end

% ---------------------------------------
% Variables
% ---------------------------------------
m = max([length(y0(:,1)), length(y(:,1))]);
n = length(y(1,:));

% ---------------------------------------
% Alignment
% ---------------------------------------
for i = 1:n

    B = [ones(m,1), (1:m)', ((1:m)'/m).^2];

    coeff = [0;1;0];
    rmse = [0,0,0,0];

    for j = 1:iterations
    
        w = B * coeff;
        index = find(1 < w & w < length(y0(:,1)));
        yi = floor(w(index));
        dy = y0(yi+1,1) - y0(yi,1);
        yy = y0(yi,1) + (w(index) - yi) .* dy;
        
        % Calculate residuals
        residuals = y(index,i) - yy;
    
        % Determine RMSE
        rmse(1) = sqrt(residuals' * residuals / m);
        rmse(3) = abs((rmse(1) - rmse(2)) / (rmse(1) + 1E-10));
        
        % Check convergence
        if rmse(3) < convergence
            break
        end
        
        % Save previous values
        rmse(2) = rmse(1);
 
        % Update coefficients
        coeff = coeff + (repmat(dy, 1, 3) .* B(index,:)) \ residuals;
        
    end
    
    % ---------------------------------------
    % Output
    % ---------------------------------------
    varargout{1}{i} = yi;
    varargout{2}{i} = index;
    
end
end