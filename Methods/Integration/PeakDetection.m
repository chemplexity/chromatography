% Method: PeakDetection
%  -Find peaks and peak boundary points
%
% Syntax
%   peaks = PeakDetection(y)
%   peaks = PeakDetection(x, y)
%   peaks = PeakDetection(x, y, 'OptionName', optionvalue...)
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
%   'width'  : window width (default = 5% of length(x))
%
% Examples
%   peaks = PeakDetection(y)
%   peaks = PeakDetection(y, 'width', 1.5)
%   peaks = PeakDetection(x, y, 'center', 22.10)

function varargout = PeakDetection(varargin)

% Check input
[x, y, options] = parse(varargin);

% Pre-allocate memory
empty = zeros(2, length(y(1,:)));

% Initialize peak data
peak.center = empty;
peak.height = empty;
peak.width = empty;
peak.a = empty;
peak.b = empty;
peak.alpha = empty;

% Determine peak locations
for i = 1:length(y(1,:))
    
    % Set variables
    if length(options.center) == length(y(1,:))
        center = options.center(i);
    else
        center = options.center(1);
    end
    if length(options.width) == length(y(1,:))
        width = options.width(i);
    else
        width = options.width(1);
    end
    
    % Index downward points: y(n) > y(n+1)
    dy.d = y(:,i) > circshift(y(:,i), [-1, 0]);
    
    % Index upward points: y(n) > y(n-1)
    dy.u = y(:,i) >= circshift(y(:,i), [1, 0]);
    
    % Determine local maxima: y(n-1) < y(n) > y(n+1)
    p.i = dy.d & dy.u;
    p.x = x(p.i);
    p.y = y(p.i, i);
    
    % Check for local maxima
    if ~any(dy.d & dy.u)
        continue
    end
    
    % Filter local maxima outside window
    window = p.x >= center-(width/2) & p.x <= center+(width/2);
    
    % Check for local maxima inside window
    if ~any(window)
        continue
    end
    
    % Determine peak center at max height
    p.x = p.x(p.y == max(p.y(window)),1);
    p.y = p.y(p.y == max(p.y(window)),1);
    
    % Remove duplicate peak maxima
    p.x = p.x(1);
    p.y = p.y(1);
    
    % Determine peak index
    p.i = find(x >= p.x,1);
    
    % Check index within bounds
    if p.i < 3 || p.i > length(y(:,1)) - 3
        continue
    end
    
    % Determine distance from peak center to end
    right = length(x(p.i:end));
    left = length(x(1:p.i));
    
    if left > right
        r.i = p.i + right - 1;
        l.i = p.i - right + 1;
    else
        r.i = p.i + left - 1;
        l.i = p.i - left + 1;
    end
    
    % Extract left and ride side of peak
    r.x = x(p.i:r.i);
    r.y = y(p.i:r.i,i);
    l.x = flipud(x(l.i:p.i));
    l.y = flipud(y(l.i:p.i,i));
    
    % Normalize y-values
    r.y = (r.y - min(r.y)) / (p.y - min(r.y));
    l.y = (l.y - min(l.y)) / (p.y - min(l.y));
    
    % Determine cumulative difference between right and left side of peak
    p.dy = cumsum(abs(r.y-l.y));
    
    % Determine intersection of cumulative difference and peak
    r.r.i = find(p.dy >= r.y, 1);
    l.l.i = find(p.dy >= l.y, 1);
    
    % Right side of peak boundaries
    r.r.x = r.x(r.r.i);
    r.r.y = r.y(r.r.i);
    r.l.y = r.r.y;
    
    % Left side of peak boundaries
    l.l.x = l.x(l.l.i);
    l.l.y = l.y(l.l.i);
    l.r.y = l.l.y;
    
    % Check for valid boundary height
    if r.r.y >= 1
        r.r.y = 0.5;
        r.l.y = 0.5;
    end
    if l.l.y >= 1
        l.l.y = 0.5;
        l.r.y = 0.5;
    end
    
    % Functions for calculating slope and intercept
    m = @(x,y,i) (y(i) - y(i-1)) / (x(i) - x(i-1));
    b = @(x,y,i) y(i) - m(x,y,i) * x(i);
    x0 = @(x,y,i,y0) (y0 - b(x,y,i)) / m(x,y,i);
    
    % Determine intersection of boundary height on opposite side of peak
    r.l.i = find(l.y < r.r.y, 1);
    l.r.i = find(r.y < l.l.y, 1);
    
    % Calculate left boundary at right boundary height
    if isempty(r.l.i)
        r.l.x = r.r.x - p.x;
    elseif r.l.i == 1
        r.l.x = x0(l.x, l.y, r.l.i+1, r.l.y);
    else
        r.l.x = x0(l.x, l.y, r.l.i, r.l.y);
    end
    
    % Calculate right boundary at left boundary height
    if isempty(l.r.i)
        l.r.x = p.x - l.l.x;
    elseif l.r.i == 1
        l.r.x = x0(r.x, r.y, l.r.i+1, l.r.y);
    else
        l.r.x = x0(r.x, r.y, l.r.i, l.r.y);
    end
    
    % Check interpolated peak boundaries for out of range values
    if p.x - r.l.x > (r.r.x - p.x) * 2 || r.l.x > p.x
        r.l.x = p.x - (r.r.x - p.x);
    end
    if l.r.x - p.x > (p.x - l.l.x) * 2 || l.r.x < p.x
        l.r.x = p.x + (p.x - l.l.x);
    end
    
    % Check asymmetry of left side determined boundaries
    if p.x - l.l.x > l.r.x - p.x
        
        % Calculate large spline around peak center
        l.c.x = x(x >= l.l.x & x <= l.r.x);
        l.c.y = spline([l.l.x, p.x, l.r.x], [l.l.y*p.y, p.y, l.r.y*p.y], l.c.x);
    else
        
        % Calculate small spline around peak center
        step = (x(p.i+2) - x(p.i-2)) / (p.i+2 - p.i-2 + 1);
        l.c.x = x(p.i-2):(step/10):x(p.i+2);
        l.c.y = spline(x(p.i-2:p.i+2), y(p.i-2:p.i+2,i), l.c.x);
    end
    
    % Check asymmetry of right side determined boundaries
    if p.x - r.l.x > r.r.x - p.x
        
        % Calculate large spline around peak center
        r.c.x = x(x >= r.l.x & x <= r.r.x);
        r.c.y = spline([r.l.x, p.x, r.r.x], [r.l.y*p.y, p.y, r.r.y*p.y], r.c.x);
    else
        
        % Calculate small spline around peak center
        step = (x(p.i+2) - x(p.i-2)) / (p.i+2 - p.i-2 + 1);
        r.c.x = x(p.i-2):(step/10):x(p.i+2);
        r.c.y = spline(x(p.i-2:p.i+2), y(p.i-2:p.i+2,i), r.c.x);
    end
    
    % Determine peak center and height from interpolated values
    [c.l.y, c.l.i] = max(l.c.y);
    [c.r.y, c.r.i] = max(r.c.y);
    
    center = [l.c.x(c.l.i); r.c.x(c.r.i)];
    height = [c.l.y; c.r.y];
    
    % Check for valid boundaries
    if l.r.x < center(1)
        l.r.x = center(1) + (center(1) - l.l.x);
    end
    if r.r.x < center(2)
        r.r.x = center(2) + (center(2) - r.l.x);
    end
    
    % Determine peak width
    width = [l.r.x-l.l.x; r.r.x-r.l.x];
    
    % Determine peak asymmetry values
    a = [center(1) - l.l.x; center(2) - r.l.x];
    b = [l.r.x - center(1); r.r.x - center(2)];
    alpha(1,1) = ((l.l.y * p.y) - min(y(:,i))) / (height(1) - min(y(:,i)));
    alpha(2,1) = ((r.r.y * p.y) - min(y(:,i))) / (height(2) - min(y(:,i)));
    
    % Check for any out of range values
    a(a < 0) = width(a < 0) / 2;
    b(b < 0) = width(a < 0) / 2;
    alpha(alpha < 0 | alpha >= 1) = 0.5;
    
    % Update peak values
    peak.center(:,i) = center;
    peak.height(:,i) = height;
    peak.width(:,i) = width;
    peak.a(:,i) = a;
    peak.b(:,i) = b;
    peak.alpha(:,i) = alpha;
end

% Output
varargout{1} = peak;
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
    error('Input dimensions must aggree.');
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
elseif max(options.center) > max(x) || min(options.center) < min(x)
    [~,index] = max(y);
    options.center = x(index);
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

% Find out of range values (maximum)
if any(options.center + (options.width/2)) >= max(x)
    index = options.center + (options.width/2) >= max(x);
    options.width(index) =  max(x) - (options.width(index)/2);
end

% Find out of range values (minimum)
if any(options.center - (options.width/2)) <= min(x)
    index = options.center - (options.width/2) <= min(x);
    options.width(index) =  min(x) + (options.width(index)/2);
end

% Return input
varargout{1} = x;
varargout{2} = y;
varargout{3} = options;
end