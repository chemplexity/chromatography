% Method: Baseline
%  -Asymmetric least squares baseline calculation
%
% Syntax
%   baseline = Baseline(y)
%   baseline = Baseline(y, 'OptionName', optionvalue...)
%
% Input
%   y            : array or matrix
%
% Options
%   'smoothness' : value (~10^3 to 10^9)
%   'asymmetry'  : value (~10^-6 to 10^-1)
%
% Description
%   y            : intensity values
%   'smoothness' : smoothing parameter (default = 10^6)
%   'asymmetry'  : asymmetry parameter (default = 10^-4)
%
% Examples
%   baseline = Baseline(y)
%   baseline = Baseline(y, 'asymmetry', 10^-2)
%   baseline = Baseline(y, 'smoothness', 10^5)
%   baseline = Baseline(y, 'smoothness', 10^7, 'asymmetry', 10^-3)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function varargout = Baseline(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
end

% Default options
asymmetry = 10^-4;
smoothness = 10^6;

% Check user input
if nargin > 1
    
    input = @(x) find(strcmpi(varargin,x),1);
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        asymmetry = varargin{input('asymmetry')+1};
        
        % Check for valid input
        if ~isnumeric(asymmetry)
            asymmetry = 10^-4;
        elseif asymmetry <= 0
            asymmetry = 10^-9;
        elseif asymmetry >= 1
            asymmetry = 1 - 10^-6;
        end
    end
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        smoothness = varargin{input('smoothness')+1};
        
        % Check for valid input
        if ~isnumeric(smoothness) || smoothness > 10^15
            smoothness = 10^6;
        elseif smoothness <= 0
            smoothness = 10^6;
        end
    end
end

% Check data precision
if ~isa(y, 'double')
    y = double(y);
end

% Check data length
if all(size(y) <= 3)
    error('Insufficient number of points');
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
    if ~any(y(:,i) ~= 0)
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
    
    % Check offset
    if offset(i) ~= 0
        
        % Preserve negative values from input
        baseline(:,i) = b - offset(i);
        
    elseif offset(i) == 0
        
        % Correct negative values from smoothing
        b(b < 0) = 0;
        baseline(:,i) = b;
    end
    
    % Reset variables
    weights = ones(rows, 1);
end

% Set output
varargout{1} = baseline;
end