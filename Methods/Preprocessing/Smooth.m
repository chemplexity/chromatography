% ------------------------------------------------------------------------
% Method      : Smooth
% Description : Asymmetric least squares smoothing function
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   y = Smooth(y)
%   y = Smooth( __ , Name, Value)
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
%   'smoothness' -- smoothing parameter (1E-1 to 1E4)
%       0.5 (default) | number
%
%   'asymmetry' -- asymmetry parameter (0 to 1)
%       0.5 (default) | number
%
%   'iterations' -- maximum number of smoothing iterations
%       5 (default) | number
%       
%   'gradient' -- minimum change required for continued iterations
%       1E-4 (default) | number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Smooth(y)
%   y = Smooth(y, 'asymmetry', 0.4)
%   y = Smooth(y, 'smoothness', 500, 'iterations', 20)
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
default.smoothness = 0.5;
default.asymmetry  = 0.5;
default.iterations = 5;
default.gradient   = 1E-4;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'smoothness',...
    default.smoothness,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));

addParameter(p, 'asymmetry',...
    default.asymmetry,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

addParameter(p, 'iterations',...
    default.iterations,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));

addParameter(p, 'gradient',...
    default.gradient,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

parse(p, varargin{:});

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
if ~isa(y, 'double')
    y = double(y);
    isSingle = 1;
else
    isSingle = 0;
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
            break
        end
        
        % Calculate signal
        z = W \ (W' \ (w(:,1) .* y(:,i)));
        
        % Calculate weights
        w(:,2) = w(:,1);
        w(:,1) = a * (y(:,i) > z) + (1 - a) * (y(:,i) < z);
        
        % Check gradient
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
    
    % Reset weights
    w(:,1) = 1;
    W = spdiags(w(:,1), 0, m, m);
    
    % Update signal
    y(:,i) = z;
    
end

if isSingle
    y = single(y);
end

end