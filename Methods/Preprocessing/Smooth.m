% ------------------------------------------------------------------------
% Method      : Smooth
% Description : Asymmetric least squares smoothing function
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   y = Smooth(y)
%   y = Smooth(y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   'smoothness' (optional)
%       Description : smoothness parameter used for smoothing calculation
%       Type        : number
%       Default     : 0.5
%       Range       : 0 to 10000
%
%   'asymmetry' (optional)
%       Description : asymmetry parameter used for smoothing calculation
%       Type        : number
%       Default     : 0.5
%       Range       : 0.0 to 1.0
%
%   'iterations' (optional)
%       Description : total iterations used for smoothing calculation
%       Type        : number
%       Default     : 5
%       Range       : >0
%
%   'convergence' (optional)
%       Description : stopping criteria
%       Type        : number
%       Default     : 1E-4
%       Range       : >0
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Smooth(y)
%   y = Smooth(y, 'asymmetry', 0.4)
%   y = Smooth(y, 'smoothness', 500, 'iterations', 2)
%   y = Smooth(y, 'smoothness', 10, 'asymmetry', 0.45)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function y = Smooth(varargin)

% ---------------------------------------
% Default
% ---------------------------------------
default.smoothness  = 0.5;
default.asymmetry   = 0.5;
default.iterations  = 5;
default.convergence = 1E-4;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'smoothness',...
    default.smoothness,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

addParameter(p, 'asymmetry',...
    default.asymmetry,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

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
y           = p.Results.y;
s           = p.Results.smoothness;
a           = p.Results.asymmetry;
iterations  = p.Results.iterations;
convergence = p.Results.convergence;

% ---------------------------------------
% Validate
% ---------------------------------------
if ~isa(y, 'double')
    y = double(y);
end

if s <= 0
    s = 1E-9;
end

if a <= 0
    a = 1E-9;
elseif a >= 1
    a = 1 - 1E-9;
end

% ---------------------------------------
% Variables
% ---------------------------------------
[m,n] = size(y);

% Weights
w = ones(m, 2);

% Diagonal matrix
W = spdiags(w(:,1), 0, m, m);

% Difference matrix
D = diff(speye(m), 2);
D = s * (D' * D);

% ---------------------------------------
% Smooth
% ---------------------------------------
for i = 1:n
    
    % Check y-values
    if ~nnz(y(:,i))
        continue
    end
    
    for j = 1:iterations
        
        % Cholesky factorization
        [W, error] = chol(W + D);
        
        % Check errors
        if error
            disp(j);
            break
        end
        
        % Calculate signal
        z = W \ (W' \ (w(:,1) .* y(:,i)));
        
        % Calculate weights
        w(:,2) = w(:,1);
        w(:,1) = a * (y(:,i) > z) + (1 - a) * (y(:,i) < z);
        
        % Check convergence
        if mean(abs(diff(w,[],2))) <= convergence
            break
        end
        
        % Check iterations
        if j == iterations
            break
        end
        
        % Update diagonal matrix
        W = sparse(1:m, 1:m, w(:,1));
        
    end
    
    % Reset weights
    w(:,1) = 1;
    W = spdiags(w(:,1), 0, m, m);
    
    % Update signal
    y(:,i) = z;
    
end

end