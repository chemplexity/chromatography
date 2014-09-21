% Method: WhittakerSmoother
% Description: Asymmetric least squares baseline correction
%
% Syntax:
%   baseline = WhittakerSmoother(y, 'OptionName', optionvalue...)
%
%   Options:
%       Smoothness : 10^3 to 10^9
%       Asymmetry  : 10^1 to 10^-5
%
% Examples:
%   baseline = WhittakerSmoother(y)
%   baseline = WhittakerSmoother(y, 'Asymmetry', 10^-2)
%   baseline = WhittakerSmoother(y, 'Smoothness', 10^5)
%   baseline = WhittakerSmoother(y, 'Smoothness', 10^7, 'Asymmetry', 10^-3)
%
% References:
%   -P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function baseline = WhittakerSmoother(y, varargin)

% Check input
if nargin == 1
    smoothness = 10^5;
    asymmetry = 10^-3;
    
% Check options
elseif nargin > 2
    
    % Check for input values
    smoothness_index = find(strcmp(varargin, 'Smoothness'));
    asymmetry_index = find(strcmp(varargin, 'Asymmetry'));
        
    % Check for empty values
    if isempty(smoothness_index)
        smoothness = 10^5;
    else
        smoothness = varargin{smoothness_index + 1};
    end
    
    if isempty(asymmetry_index)
        asymmetry = 10^-3;
    else
        asymmetry = varargin{asymmetry_index + 1};
    end
    
    % Check for valid values
    if asymmetry >= 1
        asymmetry = 0.99;
    end
    
else
    return
end

% Ensure y is double precision
y = double(y);
    
% Perform baseline calculation on each vector
for i = 1:length(y(1,:))
    
    % Get length of y vector
    length_y = length(y(:,i));

    % Initialize variables needed for calculation
    diff_matrix = diff(speye(length_y), 2);
    weights = ones(length_y, 1);

    % Pre-allocate memory for baseline
    baseline(:,i) = zeros(length_y, 1);

    % Make sure data is positive values
    if min(y(:,i)) >= 0 && max(y(:,i)) > 0

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
    end
end
end