% Method: ExponentialGaussian
%  -Curve fitting with the exponentially modified gaussian hybrid
%
% Syntax
%   peaks = ExponentialGaussian(y)
%   peaks = ExponentialGaussian(x, y)
%   peaks = ExponentialGaussian(x, y, 'OptionName', optionvalue...)
%
% Input
%   x        : array
%   y        : array or matrix
%
% Options
%   'center' : value or array
%   'width'  : value or array
%
% Description
%   x        : time values
%   y        : intensity values
%   'center' : window center (default = x at max(y))
%   'width'  : window width (default = %5 of length(x))
%
% Examples
%   peaks = ExponentialGaussian(y)
%   peaks = ExponentialGaussian(y, 'width', 1.5)
%   peaks = ExponentialGaussian(x, y, 'center', 22.10)
%   peaks = ExponentialGaussian(x, y, 'center', 12.44, 'width', 0.24)
%
% References
%   K. Lan, et. al. Journal of Chromatography A, 915 (2001) 1-13

function varargout = ExponentialGaussian(varargin)

% Check input
[x, y, options] = parse(varargin);

if isempty(y)
    varargout{1} = [];
    return
end

% Initialize peak data
peaks = {'time','width','height','area','fit','error'};
peaks = cell2struct(cell(1,length(peaks)), peaks, 2);

% Determine peak boudaries
peak = PeakDetection(x, y, 'center', options.center, 'width', options.width);

% Set exponential gaussian hybrid fitting equations
EGH.y = @(x,c,h,w,e) h .* exp((-(x-c).^2) ./ ((2.*(w.^2)) + (e.*(x-c))));
EGH.w = @(a,b,alpha) sqrt((-1 ./ (2.*log(alpha))) .* (a.*b));
EGH.e = @(a,b,alpha) (-1 ./ log(alpha)) .* (b-a);

% Set exponential gaussian hybrid area equations
EGH.a = @(h,w,e,e0) h .* (w .* sqrt(pi/8) + abs(e)) .* e0;
EGH.t = @(w,e) atan(abs(e)./w);

% Set proporationality constants (for peak area calculation)
EGH.factors = [4, -6.293724, 9.232834, -11.34291, 9.123978, -4.173753, 0.827797];
EGH.c = @(t,a0) a0(1) + a0(2)*t + a0(3)*t^2 + a0(4)*t^3 + a0(5)*t^4 + a0(6)*t^5 + a0(7)*t^6;

% Evaluate exponential gaussian model
for i = 1:length(y(1,:))
    
    % Check peak data
    if isempty(peak) || any(peak.center(:,i) == 0)
        peaks = zero(peaks, y, i);
        continue
    end
    
    %  Variables
    c = peak.center(:,i);
    h = peak.height(:,i);
    
    % Determine peak width
    w = EGH.w(peak.a(:,i), peak.b(:,i), peak.alpha(:,i));
    
    % Determine peak decay
    e = EGH.e(peak.a(:,i), peak.b(:,i), peak.alpha(:,i));
    
    % Pre-allocate memory
    yfit = zeros(length(y(:,i)),2);
    
    % Determine limits of function
    lim(:,1) = (2 * w(1)^2) + (e(1) .* (x-c(1))) > 0;
    lim(:,2) = (2 * w(2)^2) + (e(2) .* (x-c(2))) > 0;
    
    % Calculate fit
    yfit(lim(:,1),1) = EGH.y(x(lim(:,1)),c(1),h(1),w(1),e(1));
    yfit(lim(:,2),2) = EGH.y(x(lim(:,2)),c(2),h(2),w(2),e(2));
    
    % Set values outside normal range to zero
    yfit(yfit(:,1) < h(1)*10^-6 | yfit(:,1) > h(1)*2, 1) = 0;
    yfit(yfit(:,2) < h(2)*10^-6 | yfit(:,2) > h(2)*2, 2) = 0;
    
    % Calculate residuals
    r = repmat(y(:,i),[1,2]) - yfit;
    
    % Determine bounds for error calculation
    lim(:,1) = x >= c(1)-w(1) & x <= c(1)+w(1);
    lim(:,2) = x >= c(2)-w(2) & x <= c(2)+w(2);
    
    % Determine fit error
    rmsd(1) = sqrt(sum(r(lim(:,1),1).^2) ./ sum(lim(:,1))) / (h(1) - min(min(y))) * 100;
    rmsd(2) = sqrt(sum(r(lim(:,2),2).^2) ./ sum(lim(:,2))) / (h(2) - min(min(y))) * 100;
    
    % Determine better fit
    if rmsd(1) <= rmsd(2)
        index = 1;
    else
        index = 2;
    end
    
    % Determine area factors
    t = EGH.t(w(index),e(index));
    e0 = EGH.c(t, EGH.factors);
    
    % Determine area
    area = EGH.a(h(index),w(index),e(index),e0);
    
    % Check results
    if isnan(area) || isnan(rmsd(index))
        peaks = zero(peaks, y, i);
        continue
    end
    
    % Update output data
    peaks.time(i) = c(index);
    peaks.height(i) = h(index);
    peaks.width(i) = w(index);
    peaks.area(i) = area;
    peaks.fit(:,i) = yfit(:,index);
    peaks.error(i) = rmsd(index);
end

% Output
varargout{1} = peaks;
end


% Output data
function peaks = zero(peaks, y, i)

% Set values to zero
peaks.time(i) = 0;
peaks.height(i) = 0;
peaks.width(i) = 0;
peaks.area(i) = 0;
peaks.fit(:,i) = zeros(length(y(:,i)),1);
peaks.error(i) = 0;

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif nargin >= 1 && isnumeric(varargin{1}) && ~isnumeric(varargin{2})
    y = varargin{1};
    x = 1:length(y(:,1));
    
elseif nargin >1 && isnumeric(varargin{1}) && isnumeric(varargin{2})
    x = varargin{1};
    y = varargin{2};
else
    error('Undefined input arguments of type ''xy''.');
end

if isempty(y)
    varargout{1} = [];
    varargout{2} = [];
    varargout{3} = [];
    return
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

if length(y(1,:)) == length(x(:,1))  && length(y(1,:)) ~= length(y(:,1))
    y = y';
end

if length(x(:,1)) ~= length(y(:,1))
    error('Input dimensions must agree.');
end

% Check data length
if length(x) <= 1
    return
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
    error('Undefined input arguments of type ''center''.');
end

% Check width options
if ~isempty(input('width'))
    options.width = varargin{input('width')+1};
    
elseif ~isempty(input('time'))
    options.width = varargin{input('window')+1};
    
else
    options.width(1:length(options.center)) = max(x) * 0.05;
end

% Check for valid input
if isempty(options.width) || min(options.width) <= 0
    options.width(1:length(options.center),1) = max(x) * 0.05;
    
elseif ~isnumeric(options.width)
    error('Undefined input arguments of type ''width''.');
end

% Find out of range center values (maximum)
if any(options.center >= max(x))
    index = options.center >= max(x);
    options.center(index) = x(end-1);
end

% Find out of range center values (minimum)
if any(options.center <= min(x))
    index = options.center <= min(x);
    options.center(index) = x(2);
end

% Find out of range width values (maximum)
if any(options.center + (options.width/2)) >= max(x)
    index = options.center + (options.width/2) >= max(x);
    options.width(index) =  max(x) - (options.width(index)/2);
end

% Find out of range width values (minimum)
if any(options.center - (options.width/2)) <= min(x)
    index = options.center - (options.width/2) <= min(x);
    options.width(index) =  min(x) + (options.width(index)/2);
end

% Return input
varargout{1} = x;
varargout{2} = y;
varargout{3} = options;

end