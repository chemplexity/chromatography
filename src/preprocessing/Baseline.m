function b = Baseline(varargin)
% ------------------------------------------------------------------------
% Method      : Baseline
% Description : Asymmetric least squares baseline calculation
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   b = Baseline(y)
%   b = Baseline( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   y -- intensity values
%       array | matrix
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'smoothness' -- smoothing parameter (1E3 to 1E9)
%       1E6 (default) | number
%
%   'asymmetry' -- asymmetry parameter (1E-6 to 1E-1)
%       1E-4 (default) | number
%
%   'iterations' -- maximum number of baseline iterations
%       10 (default) | number
%       
%   'gradient' -- minimum change required for continued iterations
%       1E-4 (default) | number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   b = Baseline(y)
%   b = Baseline(y, 'asymmetry', 1E-6)
%   b = Baseline(y, 'smoothness', 1E5, 'iterations', 50)
%   b = Baseline(y, 'smoothness', 1E7, 'asymmetry', 1E-2)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

% ---------------------------------------
% Defaults
% ---------------------------------------
default.smoothness = 1E6;
default.asymmetry  = 1E-4;
default.iterations = 10;
default.gradient   = 1E-4;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

p.addRequired('y', @ismatrix);

p.addParameter('smoothness', default.smoothness, @isscalar);
p.addParameter('asymmetry',  default.asymmetry,  @isscalar);
p.addParameter('iterations', default.iterations, @isscalar);
p.addParameter('gradient',   default.gradient,   @isscalar);

p.parse(varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y          = p.Results.y;
s          = p.Results.smoothness;
a          = p.Results.asymmetry;
iterations = p.Results.iterations;
gradient   = p.Results.gradient;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: y
type = class(y);

if ~strcmpi(type, 'double')
    y = double(y);
end

% Parameter: 'asymmetry'
if a <= 0
    a = 1E-9;
elseif a >= 1
    a = 1 - 1E-9;
end

% Parameter: 'smoothness'
if s <= 0
    s = 0;
elseif s > 1E15
    s = 1E15;
end

% Parameter: 'iterations'
if iterations <= 0
    iterations = 1;
end

% Parameter: 'gradient'
if gradient < 0
    gradient = 0;
end

% ---------------------------------------
% Variables
% ---------------------------------------
[m,n] = size(y);

% Signal
yavg = mean(y);
ystd = std(y);

% Baseline
z = 0;
b = zeros(m,n);

% Weights
w = ones(m, 2);

% Diagonal matrix
W = spdiags(w(:,1), 0, m, m);

% Difference matrix
D = diff(speye(m), 2);
D = s * (D' * D);

if m <= 1
    return
end

% ---------------------------------------
% Baseline
% ---------------------------------------
for i = 1:n
    
    % Check y-values
    if ~any(y(:,i)~=0)
        continue
    end
    
    % Filter signal
    y(abs(y(:,i)) > yavg(i) + ystd(i),i) = yavg(i);
    
    for j = 1:iterations
        
        % Cholesky factorization
        [W, error] = chol(W + D);
        
        % Check errors
        if error
            break
        end

        % Calculate signal
        z = W \ (W' \ (w(:,1) .* y(:,i)));
        
        % Calculate weights
        w(:,2) = w(:,1);
        w(:,1) = a * (y(:,i) > z) + (1 - a) * (y(:,i) < z);
        
        % Check convergence
        if mean(abs(diff(w,[],2))) <= gradient
            break
        end
        
        % Check iterations
        if j == iterations
            break
        end
        
        % Update diagonal matrix
        W = sparse(1:m, 1:m, w(:,1));
        
    end
    
    % Update baseline
    b(:,i) = z;
    
    % Reset weights
    if i < n
        w(:,1) = 1;
        W = spdiags(w(:,1), 0, m, m);
    end
    
end

if ~strcmpi(type, 'double')
    b = cast(b, type);
end

end