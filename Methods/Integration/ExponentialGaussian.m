% Method: ExponentialGaussian
%  -Curve fitting with the exponentially modified gaussian equation
%
% Syntax
%   ExponentialGaussian(x, y)
%   ExponentialGaussian(x, y, 'OptionName', optionvalue...)
%
% Options
%   'center' : value
%   'width'  : value
%
% Description
%   x        : array
%   y        : array or matrix
%   'center' : search for peak at center value -- (default: x at max(y))
%   'width'  : search for peak at center +/- width/2 -- (default: 2)
%
% Examples
%   peaks = ExponentialGaussian(x, y)
%   peaks = ExponentialGaussian(x, y, 'center', 22.10)
%   peaks = ExponentialGaussian(x, y, 'center', 12.44, 'width', 0.24)
%   
% References
%   Y. Kalambet, et.al, Journal of Chemometrics, 25 (2011) 352

function peaks = ExponentialGaussian(x, y, varargin)

% Check input type, length, precision
if ~isnumeric(x) || ~isnumeric(y)
    error('Undefined input arguments of type ''xy''');
elseif length(x(:,1)) ~= length(y(:,1))
    error('Index of input arguments unequal');
else
    x = double(x);
    y = double(y);
end
    
% Check window center options
if ~isempty(find(strcmp(varargin, 'center'),1))
    window_center = varargin{find(strcmp(varargin, 'center'),1) + 1};
    
    % Check user input
    if isempty(window_center)
        window_center = [];
    elseif ~isnumeric(window_center)
        error('Undefined input arguments of type ''center''');
    elseif window_center > max(x) || window_center < min(x)
        window_center = [];
    end
else
    % Default window center
    window_center = [];
end
    
% Check window size options
if ~isempty(find(strcmp(varargin, 'width'),1))
    window_size = varargin{find(strcmp(varargin, 'width'),1) + 1};
    
    % Check user input
    if isempty(window_size)
        window_size = [];
    elseif ~isnumeric(window_size)
        error('Undefined input arguments of type ''width''');
    elseif window_size > max(x) || window_size < min(x)
        window_size = [];
    end
else
    % Default window size
    window_size = [];
end

% Create output data structure 
peak_fields = {...
    'peak_time',...
    'peak_width',...
    'peak_height',...
    'peak_area',...
    'peak_fit',...
    'peak_fit_residuals',...
    'peak_fit_error',...
    'peak_fit_options'...
    };

values{length(peak_fields)} = [];
peaks = cell2struct(values, peak_fields, 2);
    
% Anonymous function for exponential gaussian model
exponential_gaussian = @(x,c,h,w,e) h * exp(-((c-x).^2) ./ (2*(w^2))) .* (w/e) .* ((pi/2)^0.5) .* erfcx((1/(2^0.5)) .* (((c-x) ./ w) + (w/e)));

% Fetch peak locations
[edges, center] = PeakDerivative(x,y,'center', window_center,'width', window_size, 'coverage', 0.50);

% Curve fitting algorithm
for i = 1:length(y(1,:))
    
    % Define variables
    c = center(i);
    w = edges(i,2) - edges(i,1);
    h = y(find(x >= c, 1), i);
    e = 0.5;
    
    % Proceed if peak center within limits
    if c ~= 0 && c-(w/2) > min(x) && c+(w/2) < max(x)
        
        % Find peak edges
        left = find(x >= edges(i, 1), 1);
        right = find(x >= edges(i, 2), 1);
        middle = find(x >= c, 1);
        
        % Find height at peak edges
        left_y = y(left, i);
        right_y = y(right, i);

        % Set edges to equal height
        if left_y < right_y
           right = find(y(left+1:end, i) < left_y, 1) + left - 1;
        elseif left_y < right_y
           left = right - find(flipud(y(1:right-1, i)) < right_y, 1) - 1 ;
        end
        
        % Distance of edges from center
        a = c - x(left);
        b = x(right) - c;
        
        % Check for incorrect peak edges (e.g. in cases of peak overlap)
        if c / abs(b-a) < 50
            if b > a
                right = middle + (middle - left);
            elseif a > b
                left = middle - (right - middle);
            end
        end
            
        % Optimize fit parameters within edge boundaries
        opt_x = x(left:right);
        opt_y = y(left:right, i);
    
        % Optimize fit parameters
        opt = [w,e];
        optimize = @(opt) sum((opt_y - exponential_gaussian(opt_x,c,h,opt(1),opt(2))).^2);
        opt = fminsearch(optimize, opt, optimset('display', 'off'));

        % Calculate fit using optimized parameters
        fit = exponential_gaussian(x,c,h,opt(1),opt(2));
        residuals = y(:,i) - fit;

        % Replace any NaNs with zero
        fit(isnan(fit)) = 0;
        residuals(isnan(residuals)) = 0;

        % Replace any Infs with zero
        fit(isinf(fit)) = 0;
        residuals(isinf(residuals)) = 0;
        
        % Find edges of integration by looking at derivative signal
        dy = fit(2:end) - fit(1:end-1);
        [~, dy_min] = min(dy);
        [~, dy_max] = max(dy);

        right = find(dy(dy_min:end) >= -10^-2, 1) + dy_min - 1;
        left = dy_max - find(flipud(dy(1:dy_max)) <= 10^-2, 1) - 1;

        % Proceed if values exist
        if ~isempty(right) && ~isempty(left) && left < right
        
            % Set integration limits
            right_x = x(right);
            left_x = x(left);

            % Calculate peak area
            area = integral(@(x)exponential_gaussian(x,c,h,opt(1),opt(2)), left_x, right_x);

            % Calculate root-mean-square deviations of fit
            rmsd = sqrt(sum(residuals(left:right).^2)/(right-left+1));

            % Normalized RMSD
            norm_rmsd = rmsd / (max(y(left:right,i)) - min(y(left:right,i)));
            fit_error = norm_rmsd * 100;
        else
            area = 0;
            fit_error = 0;
        end
    else 
        opt = [0,0];
        area = 0;
        fit_error = 0;
        fit = zeros(length(y(:,i)),1);
        residuals = zeros(length(y(:,i)),1);
    end
    
    % Update output data
    peaks.peak_time(i) = c;
    peaks.peak_width(i) = w;
    peaks.peak_height(i) = h;
    peaks.peak_area(i) = area;
    peaks.peak_fit(:,i) = fit;
    peaks.peak_fit_residuals(:,i) = residuals;
    peaks.peak_fit_error(i) = fit_error;
    peaks.peak_fit_options(i) = opt(2);
end
end