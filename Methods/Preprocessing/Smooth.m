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
%   'smoothness' : value (~100 to 10000)
%   'asymmetry'  : value (~0.01 to 0.99)
%
% Description
%   y            : intensity values
%   'smoothness' : smoothing factor (default = 500)
%   'asymmetry'  : asymmetry factor (default = 0.5)
%
% Examples
%   smoothed = Smooth(y)
%   smoothed = Smooth(y, 'asymmetry', 0.4)
%   smoothed = Smooth(y, 'smoothness', 5000)
%   smoothed = Smooth(y, 'smoothness', 2500, 'asymmetry', 0.25)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function [smoothed, weights] = Smooth(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
end

% Check user input
if nargin == 1
    
    % Default pararmeters
    smoothness = 500;
    asymmetry = 0.5;
    
% Check options
elseif nargin > 1
    
    % Check user input
    input = @(x) find(strcmpi(varargin, x),1);

    % Check smoothness options
    if ~isempty(input('smoothness'));
        smoothness = varargin{input('smoothness')+1};

        % Check user input
        if ~isnumeric(smoothness)
            smoothness = 500;
        elseif smoothness <= 0
            smoothness = 500;
        end 
    else
        smoothness = 500;
    end
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        asymmetry = varargin{input('asymmetry')+1};

        % Check user input
        if ~isnumeric(asymmetry)
            asymmetry = 0.5;
        elseif asymmetry <= 0
            asymmetry = 10^-6;
        elseif asymmetry >= 1
            asymmetry = 0.99999;
        end
    else
        asymmetry = 0.5;
    end
end

% Check precision
if ~isa(y, 'double')
    y = double(y);
end

% Perform smoothing calculation on each vector
for i = 1:length(y(1,:))
    
    % Correct negative y-values
    if min(y(:,i)) < 0
        correction = abs(min(y(:,i)));
        y(:,i) = y(:,i) + correction;
        
    % Correct non-positive definite y-values
    elseif max(y(:,i)) == 0
        continue
    else 
        correction = 0;
    end
    
    % Get length of y vector
    length_y = length(y(:,i));

    % Initialize variables needed for calculation
    diff_matrix = diff(speye(length_y), 2);
    weights = ones(length_y, 1);

    % Pre-allocate memory for smoothed data
    smoothed(:,i) = zeros(length_y, 1);

    % Number of iterations
    for j = 1:10
            
        % Sparse diagonal matrix
        weights_diagonal = spdiags(weights, 0, length_y, length_y);
        
        % Cholesky factorization
        cholesky_factor = chol(weights_diagonal + smoothness * diff_matrix' * diff_matrix);
        
        % Left matrix divide, multiply matrices
        smoothed(:,i) = cholesky_factor \ (cholesky_factor' \ (weights .* y(:,i)));
        
        % Reassign weights
        weights = asymmetry * (y(:,i) > smoothed(:,i)) + (1 - asymmetry) * (y(:,i) < smoothed(:,i));
    end
    
    % Correct for negative y-values
    y(:,i) = y(:,i) - correction;
end
end