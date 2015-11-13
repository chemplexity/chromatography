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
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Smooth(y)
%   y = Smooth(y, 'asymmetry', 0.4)
%   y = Smooth(y, 'smoothness', 500)
%   y = Smooth(y, 'smoothness', 10, 'asymmetry', 0.25)
%

function varargout = Smooth(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments.');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''.');
end

% Default options
asymmetry = 0.5;
smoothness = 0.5;

% Check options
if nargin > 1
    
    % Check user input
    input = @(x) find(strcmpi(varargin, x),1);
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        asymmetry = varargin{input('asymmetry')+1};
        
        % Check user input
        if ~isnumeric(asymmetry)
            asymmetry = 0.5;
        elseif asymmetry <= 0
            asymmetry = 1E-9;
        elseif asymmetry >= 1
            asymmetry = 1 - 1E-6;
        end
    end
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        smoothness = varargin{input('smoothness')+1};
        
        % Check user input
        if ~isnumeric(smoothness)
            smoothness = 0.5;
        elseif smoothness <= 0
            smoothness = 1E-9;
        end
    end
end

% Check precision
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
smoothed = zeros(size(y));
weights = ones(rows, 1);
w = spdiags(weights, 0, rows, rows);

% Variables
d = diff(speye(rows), 2);
d = smoothness * (d' * d);

% Calculate smoothed data
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
    s = zeros(rows,1);
    
    % Number of iterations
    for j = 1:10
        
        % Cholesky factorization
        w = chol(w + d);
        
        % Left matrix divide, multiply matrices
        s = w \ (w' \ (weights .* y(:,i)));
        
        % Determine weights
        weights = asymmetry * (y(:,i) > s) + (1 - asymmetry) * (y(:,i) < s);
        
        % Reset sparse matrix
        w = sparse(index, index, weights);
    end
    
    % Remove negative values
    s(s<0) = 0;
    
    % Check offset
    if offset(i) ~= 0
        smoothed(:,i) = s - offset(i);
        
    elseif offset(i) == 0
        smoothed(:,i) = s;
    end
    
    % Reset variables
    weights = ones(rows, 1);
end

% Set output
varargout{1} = smoothed;
end