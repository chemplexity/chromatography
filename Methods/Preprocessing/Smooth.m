% Method: Smooth
%  -Asymmetric least squares smoothing filter
%
% Syntax
%   smoothed = Smooth(y)
%   smoothed = Smooth(y, 'OptionName', optionvalue...)
%
% Input
%   y            : array or matrix
%
% Options
%   'asymmetry'  : value (~0.01 to 0.99)
%   'smoothness' : value (~0.01 to 10000)
%
% Description
%   y            : intensity values
%   'asymmetry'  : asymmetry factor (default = 0.5)
%   'smoothness' : smoothing factor (default = 0.1)
%
% Examples
%   smoothed = Smooth(y)
%   smoothed = Smooth(y, 'asymmetry', 0.4)
%   smoothed = Smooth(y, 'smoothness', 500)
%   smoothed = Smooth(y, 'smoothness', 10, 'asymmetry', 0.25)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function varargout = Smooth(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
end

% Default options
asymmetry = 0.5;
smoothness = 0.1;
    
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
            asymmetry = 10^-9;
        elseif asymmetry >= 1
            asymmetry = 1 - 10^-6;
        end
    end
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        smoothness = varargin{input('smoothness')+1};

        % Check user input
        if ~isnumeric(smoothness)
            smoothness = asymmetry / 50;
        elseif smoothness <= 0
            smoothness = 10^-9;
        end
    end
end

% Check precision
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

% Pre-allocate memory
smoothed = zeros(size(y));

% Variables
rows = length(y(:,1));
index = 1:rows;

% Pre-allocate memory
weights = ones(rows, 1);

% Variables
d = diff(speye(rows), 2);
d = smoothness * (d' * d);

w = spdiags(weights, 0, rows, rows);

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
    
    % Check offset
    if offset(i) ~= 0
        smoothed(:,i) = s - offset(i);
    else
        smoothed(:,i) = s;
    end
    
    % Reset variables
    weights = ones(rows, 1);
end

% Set output
varargout{1} = smoothed;
end