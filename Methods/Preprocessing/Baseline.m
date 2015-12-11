% ------------------------------------------------------------------------
% Method      : Baseline
% Description : Asymmetric least squares baseline calculation
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   baseline = Baseline(y)
%   baseline = Baseline(y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   'smoothness' (optional)
%       Description : smoothness parameter used for baseline calculation
%       Type        : number
%       Default     : 1E6
%       Range       : 1E3 to 1E9
%
%   'asymmetry' (optional)
%       Description : asymmetry parameter used for baseline calculation
%       Type        : number
%       Default     : 1E-4
%       Range       : 1E-3 to 1E-9
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   baseline = Baseline(y)
%   baseline = Baseline(y, 'asymmetry', 1E-2)
%   baseline = Baseline(y, 'smoothness', 1E5)
%   baseline = Baseline(y, 'smoothness', 1E7, 'asymmetry', 1E-3)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631
%

function varargout = Baseline(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''.');
end

% Default options
smoothness = 1E6;
asymmetry = 1E-4;

% Check user input
if nargin > 1
    
    input = @(x) find(strcmpi(varargin,x),1);
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        
        asymmetry = varargin{input('asymmetry')+1};
        
        % Check for valid input
        if ~isnumeric(asymmetry)
            asymmetry = 1E-4;
            
        elseif asymmetry <= 0
            asymmetry = 1E-9;
            
        elseif asymmetry >= 1
            asymmetry = 1 - 1E-6;
        end
        
    end
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        
        smoothness = varargin{input('smoothness')+1};
        
        % Check for valid input
        if ~isnumeric(smoothness) || smoothness > 10^15
            smoothness = 1E6;
            
        elseif smoothness <= 0
            smoothness = 1E6;
        end
        
    end
end

% Check data precision
if ~isa(y, 'double')
    y = double(y);
end

% Check data length
if all(size(y) <= 3)
    error('Insufficient number of points.');
end

% Check for negative values
if any(min(y) < 0)
    
    % Determine offset
    offset = min(y);
    offset(offset > 0) = 0;
    offset(offset < 0) = abs(offset(offset < 0));
    
else
    offset = zeros(1, length(y(1,:)));
end

% Variables
rows = length(y(:,1));
index = 1:rows;

% Pre-allocate memory
baseline = zeros(size(y));
weights = ones(rows, 1);

w = spdiags(weights, 0, rows, rows);

% Variables
d = diff(speye(rows), 2);
d = smoothness * (d' * d);

% Calculate baseline
for i = 1:length(y(1,:))
    
    % Check offset
    if offset(i) ~= 0
        y(:,i) = y(:,i) + offset(i);
    end
    
    % Check values
    if nnz(y(:,i)) == 0
        continue
    end
    
    % Pre-allocate memory
    b = zeros(rows,1);
    
    % Number of iterations
    for j = 1:10
        
        % Cholesky factorization
        w = chol(w + d);
        
        % Left matrix divide, multiply matrices
        b = w \ (w' \ (weights .* y(:,i)));
        
        % Determine weights
        weights = asymmetry * (y(:,i) > b) + (1 - asymmetry) * (y(:,i) < b);
        
        % Reset sparse matrix
        w = sparse(index, index, weights);
    end
    
    % Remove negative values
    b(b<0) = 0;
    
    % Remove offset
    if offset(i) ~= 0
        baseline(:,i) = b - offset(i);
        
    elseif offset(i) == 0
        baseline(:,i) = b;
    end
    
    % Reset variables
    weights = ones(rows, 1);
end

% Set output
varargout{1} = baseline;

end