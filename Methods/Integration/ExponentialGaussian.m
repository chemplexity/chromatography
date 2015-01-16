% Method: ExponentialGaussian
%  -Curve fitting with the exponentially modified gaussian equation
%
% Syntax
%   ExponentialGaussian(y)
%   ExponentialGaussian(x, y)
%   ExponentialGaussian(x, y, 'OptionName', optionvalue...)
%
% Input
%   x        : array
%   y        : array or matrix
%
% Options
%   'center' : value
%   'width'  : value
%
% Description
%   x        : time values
%   y        : intensity values
%   'center' : location of peak center  -- (default: x at max(y))
%   'width'  : estimated peak width  -- (default: %5 of x)
%
% Examples
%   peaks = ExponentialGaussian(y)
%   peaks = ExponentialGaussian(y, 'width', 1.5)
%   peaks = ExponentialGaussian(x, y, 'center', 22.10)
%   peaks = ExponentialGaussian(x, y, 'center', 12.44, 'width', 0.24)
%   
% References
%   Y. Kalambet, et.al, Journal of Chemometrics, 25 (2011) 352

function peaks = ExponentialGaussian(varargin)

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif nargin == 1 && isnumeric(varargin{1})
    y = varargin{1};
    x = 1:length(y(:,1));
elseif nargin >1 && isnumeric(varargin{1}) && isnumeric(varargin{2}) 
    x = varargin{1};
    y = varargin{2};
elseif nargin >1 && isnumeric(varargin{1})
    y = varargin{1};
    x = 1:length(y(:,1));
else
    error('Undefined input arguments of type ''xy''');
end
    
% Check data precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check data orientation
if length(x(1,:)) > length(x(:,1))
    x = x';
end
if length(y(1,:)) == length(x(:,1))
    y = y';
end
if length(x(:,1)) ~= length(y(:,1))
    error('Input dimensions must aggree');
end
    
% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check center options
if ~isempty(input('center'))
    options.center = varargin{input('center')+1};
elseif ~isempty(input('time'))
    options.center = varargin{input('time')+1};
else
    [~,index] = max(y);
    options.center = x(index);
end

% Check for valid input
if isempty(options.center)
    [~,index] = max(y);
    options.center = x(index);
elseif ~isnumeric(options.center)
    error('Undefined input arguments of type ''center''');
end
    
% Check width options
if ~isempty(input('width'))
    options.width = varargin{input('width')+1};
elseif ~isempty(input('time'))
    options.width = varargin{input('window')+1};
elseif max(options.center) > max(x) || min(options.center) < min(x)
    error('Input arguments of type ''center'' exceeds matrix dimensions');
else
    options.width = max(x) * 0.05;
end
    
% Check for valid input
if isempty(options.width)
    options.width = max(x) * 0.05;
elseif ~isnumeric(options.width)
    error('Undefined input arguments of type ''width''');
end
    
% Check for valid range
if options.center + (options.width/2) > max(x)
    options.width = max(x) - (options.width/2);
elseif options.center - (options.width/2) < min(x)
    options.width = min(x) + (options.width/2);
end

% Check expoential factor options
if ~isempty(input('extra'))
    options.exponent = varargin{input('extra')+1};
    
    % Check user input
    if ~isnumeric(options.exponent)
        options.exponent = 0.1;
    elseif length(options.exponent) > 1
        options.exponent = options.exponent(1);
    elseif options.exponent > 1
        options.exponent = 0.1;
    end
else
    options.exponent = 0.1;
end

% Initialize output fields
peak_fields = {'peak_time','peak_width','peak_height','peak_area','peak_fit','peak_fit_residuals','peak_fit_error','peak_fit_options'};

% Initialize data structure
values{length(peak_fields)} = [];
peaks = cell2struct(values, peak_fields, 2);
   
% Determine peak boudaries
p = PeakDetection(x, y, 'center', options.center, 'width', options.width);

% Initialize exponential gaussian model
exponential_gaussian = @(x,c,h,w,e) h * exp(-((c-x).^2) ./ (2*(w^2))) .* (w/e) .* ((pi/2)^0.5) .* erfcx((1/(2^0.5)) .* (((c-x) ./ w) + (w/e)));

% Apply exponential gaussian model
for i = 1:length(y(1,:))
    
    %  Variables
    c = p.center(i);
    w = p.right(i) - p.left(i);
    h = y(find(x >= c, 1), i);
    e = options.exponent;
    
    % Proceed if peak center within limits
    if c ~= 0 && c-(w/2) >= min(x) && c+(w/2) <= max(x)
        
        % Find peak edges
        l = find(x >= p.left(i), 1);
        r = find(x >= p.right(i), 1);
        m = find(x >= c, 1);
        
        % Find height at peak edges
        ly = y(l, i);
        ry = y(r, i);

        % Set edges to equal height
        if ly < ry
           r = find(y(l+1:end, i) <= ly, 1) + l - 1;
        elseif ly < ry
           l = r - find(flipud(y(1:r-1, i)) <= ry, 1) - 1 ;
        end
        
        % Distance of edges from center
        lc = c - x(l);
        rc = x(r) - c;
        
        % Check for center point between edges
        if rc > 0 && lc > 0
        
            % Check for incorrect peak edges (e.g. in cases of peak overlap)
            if c / abs(rc-lc) < 50
                if rc > lc
                    r = m + (m - l);
                elseif lc > rc
                    l = m - (r - m);
                end
            end
            
            % Optimize fit parameters within edge boundaries
            xopt = x(l:r);
            yopt = y(l:r, i);
    
            % Upsample xy with spline interpolation
            resolution = (xopt(end) - xopt(1)) / length(xopt);
            xopt = transpose(xopt(1):(resolution/10):xopt(end));
            yopt = spline(x(l:r), yopt, xopt);
        
            % Optimize fit parameters
            opt = [w,e];
            optimize = @(opt) sum((yopt - exponential_gaussian(xopt,c,h,opt(1),opt(2))).^2);
            opt = fminsearch(optimize, opt, optimset('display', 'off'));

            % Calculate fit using optimized parameters
            yfit = exponential_gaussian(x,c,h,opt(1),opt(2));
            yerror = y(:,i) - yfit;

            % Replace any NaNs with zero
            yfit(isnan(yfit)) = 0;
            yerror(isnan(yerror)) = 0;

            % Replace any Infs with zero
            yfit(isinf(yfit)) = 0;
            yerror(isinf(yerror)) = 0;
        
            % Find edges of integration by looking at derivative signal
            dy = yfit(2:end) - yfit(1:end-1);
            [~, ymin] = min(dy);
            [~, ymax] = max(dy);

            r = find(dy(ymin:end) >= -10^-2, 1) + ymin - 1;
            l = ymax - find(flipud(dy(1:ymax)) <= 10^-2, 1) - 1;    
        else
            opt = [0,0];
            yfit = zeros(length(y(:,i)),1);
            yerror = zeros(length(y(:,i)),1);
            
            % Clear peak boundaries
            r = [];
            l = [];
        end
        
        % Proceed if values exist
        if ~isempty(r) && ~isempty(l) && l < r
        
            % Set integration limits
            rx = x(r);
            lx = x(l);

            % Calculate peak area
            area = integral(@(x) exponential_gaussian(x,c,h,opt(1),opt(2)), lx,rx);

            % Calculate root-mean-square deviations of fit
            rmsd = sqrt(sum(yerror(l:r).^2) / (r-l+1));
    
            % Normalized RMSD
            norm_rmsd = rmsd / (max(y(l:r,i)) - min(y(l:r,i)));
            fit_error = norm_rmsd * 100;
        else
            area = 0;
            fit_error = 0;
        end
    else 
        opt = [0,0];
        area = 0;
        fit_error = 0;
        yfit = zeros(length(y(:,i)),1);
        yerror = zeros(length(y(:,i)),1);
    end
    
    % Check results
    if area == 0
        
        % Clear values
        c = 0;
        w = 0;
        h = 0;
    end
    
    % Update output data
    peaks.peak_time(i) = c;
    peaks.peak_width(i) = w;
    peaks.peak_height(i) = h;
    peaks.peak_area(i) = area;
    peaks.peak_fit(:,i) = yfit;
    peaks.peak_fit_residuals(:,i) = yerror;
    peaks.peak_fit_error(i) = fit_error;
    peaks.peak_fit_options(i) = opt(2);
end
end