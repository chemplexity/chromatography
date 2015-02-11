% Method: Baseline
%  -Asymmetric least squares baseline correction
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
%   'asymmetry'  : value (~10^-1 to 10^-6)
%
% Description
%   y            : intensity values
%   'smoothness' : smoothing factor (default = 10^6)
%   'asymmetry'  : asymmetry factor (default = 10^-4)
%
% Examples
%   baseline = Baseline(y)
%   baseline = Baseline(y, 'asymmetry', 10^-2)
%   baseline = Baseline(y, 'smoothness', 10^5)
%   baseline = Baseline(y, 'smoothness', 10^7, 'asymmetry', 10^-3)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function [baseline, weights] = Baseline(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
end

% Check user input
if nargin == 1
    
    % Default pararmeters
    smoothness = 10^6;
    asymmetry = 10^-4;
    
% Check options
elseif nargin > 1
    
    % Check user input
    input = @(x) find(strcmpi(varargin, x),1);

    % Check smoothness options
    if ~isempty(input('smoothness'));
        smoothness = varargin{input('smoothness')+1};

        % Check user input
        if ~isnumeric(smoothness)
            smoothness = 10^6;
        elseif smoothness <= 0
            smoothness = 10^-6;
        end 
    else
        smoothness = 10^6;
    end
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        asymmetry = varargin{input('asymmetry')+1};

        % Check user input
        if ~isnumeric(asymmetry)
            asymmetry = 10^-4;
        elseif asymmetry <= 0
            asymmetry = 10^-6;
        elseif asymmetry >= 1
            asymmetry = 0.99999;
        end
    else
        asymmetry = 10^-4;
    end
end

% Check precision
if ~isa(y, 'double')
    y = double(y);
end

% Perform baseline calculation on each vector
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

    % Pre-allocate memory for baseline
    baseline(:,i) = zeros(length_y, 1);

    % Number of iterations
    for j = 1:10
            
        % Sparse diagonal matrix
        weights_diagonal = spdiags(weights, 0, length_y, length_y);
        
        % Cholesky factorization
        cholesky_factor = chol(weights_diagonal + smoothness * diff_matrix' * diff_matrix);
        
        % Left matrix divide, multiply matrices
        baseline(:,i) = cholesky_factor \ (cholesky_factor' \ (weights .* y(:,i)));
        
        % Reassign weights
        weights = asymmetry * (y(:,i) > baseline(:,i)) + (1 - asymmetry) * (y(:,i) < baseline(:,i));
    end
    
    % Correct for negative y-values
    y(:,i) = y(:,i) - correction;
end
end