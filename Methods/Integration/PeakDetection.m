% ------------------------------------------------------------------------
% Method      : PeakDetection
% Description : Locate peaks and peak boundary points
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   peaks = PeakDetection(x, y)
%   peaks = PeakDetection( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   x -- time values
%       array | matrix
%
%   y -- intensity values
%       array | matrix
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'center' -- search window center
%       x at max(y) (default) | number
%
%   'width' -- search window width
%       1 (default) | number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   peaks = PeakDetection(x, y, 'width', 1.5, 'center', 42)
%   peaks = PeakDetection(x, y, 'center', 22.10)

function peaks = PeakDetection(varargin)

% ---------------------------------------
% Defaults
% ---------------------------------------
default.center = 0;
default.width  = 1;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p,...
    'x',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan'}));

addRequired(p,...
    'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p,...
    'center',...
    default.center,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

addParameter(p,...
    'width',...
    default.width,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
x = p.Results.x;
y = p.Results.y;

options.center = p.Results.center;
options.width  = p.Results.width;

p = [];

% ---------------------------------------
% Validate
% ---------------------------------------
[yrow, ycol] = size(y);

if yrow == 1 && ycol > 1
    y = y';
end

if isempty(x)
    x = 1:length(y(:,1));
end

[xrow, xcol] = size(x);

if xrow == 1 && xcol > 1
    x = x';
end

if length(x(:,1)) ~= length(y(:,1))
    x = 1:length(y(:,1));
end
    
if options.center == 0
    [~,index] = max(y);
    options.center = x(index,1);
elseif options.center < min(x(:,1))
    options.center = min(x(:,1)) + options.width / 2;
elseif options.center > max(x(:,1))
    options.center = max(x(:,1)) - options.width / 2;
end

if options.width < 0
    options.width = 0;
end

% ---------------------------------------
% Initialize
% ---------------------------------------
n = length(y(1,:));

peaks.center(2,n) = 0;
peaks.height(2,n) = 0;
peaks.width(2,n)  = 0;
peaks.a(2,n)      = 0;
peaks.b(2,n)      = 0;
peaks.alpha(2,n)  = 0;

% ---------------------------------------
% Find peaks
% ---------------------------------------
for i = 1:n

    if nnz(y(:,i)) == 0
        continue
    end
    
    if numel(options.center) == n
        center = options.center(i);
    end
    
    if numel(options.width) == n
        width = options.width(i);
    end

    % Index downward points: y(n) > y(n+1)
    dy.d = y(:,i) > circshift(y(:,i), [-1, 0]);
    
    % Index upward points: y(n) > y(n-1)
    dy.u = y(:,i) >= circshift(y(:,i), [1, 0]);
    
    % Determine local maxima: y(n-1) < y(n) > y(n+1)
    p.i = dy.d & dy.u;
    
    % Check for local maxima
    if ~any(dy.d & dy.u)
        continue
    end
    
    p.x = x(p.i);
    p.y = y(p.i, i);
    
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
    n = 2;
    
    if p.x - l.l.x > l.r.x - p.x
        
        % Calculate large spline around peak center
        l.c.x = x(x >= l.l.x & x <= l.r.x);
        l.c.y = spline([l.l.x, p.x, l.r.x], [l.l.y*p.y, p.y, l.r.y*p.y], l.c.x);
        l.c.e = sum((y(x >= l.l.x & x <= l.r.x) - l.c.y) .^ 2);
        
    else
        
        % Calculate small spline around peak center
        step = (x(p.i+n) - x(p.i-n)) / (p.i+n - p.i-n + 1);
        l.c.x = x(p.i-n):(step/10):x(p.i+n);
        l.c.y = spline(x(p.i-n:p.i+n), y(p.i-n:p.i+n,i), l.c.x);
        l.c.e = 0;
        
    end
    
    % Check asymmetry of right side determined boundaries
    if p.x - r.l.x > r.r.x - p.x
        
        % Calculate large spline around peak center
        r.c.x = x(x >= r.l.x & x <= r.r.x);
        r.c.y = spline([r.l.x, p.x, r.r.x], [r.l.y*p.y, p.y, r.r.y*p.y], r.c.x);        
        r.c.e = sum((y(x >= r.l.x & x <= r.r.x) - r.c.y) .^ 2);
        
    else
        
        % Calculate small spline around peak center
        step = (x(p.i+n) - x(p.i-n)) / (p.i+n - p.i-n + 1);
        
        r.c.x = x(p.i-n):(step/10):x(p.i+n);
        r.c.y = spline(x(p.i-n:p.i+n), y(p.i-n:p.i+n,i), r.c.x);
        r.c.e = 0;
        
    end
    
    % Determine peak center and height from interpolated values
    [c.l.y, c.l.i] = max(l.c.y);
    [c.r.y, c.r.i] = max(r.c.y);
    
    if l.c.e < r.c.e
        center = [l.c.x(c.l.i); p.x];
        height = [c.l.y; p.y];
    elseif r.c.e > l.c.e
        center = [r.c.x(c.r.i); p.x];
        height = [c.r.y; p.y];
    else
        center = [mean([l.c.x(c.l.i), r.c.x(c.r.i)]); p.x];
        height = [mean([c.l.y, c.r.y]); p.y];
    end
    
    % Check for valid boundaries
    if l.r.x < center(1) && l.c.e <= r.c.e
        l.r.x = center(1) + (center(1) - l.l.x);
    end
    
    if r.r.x < center(1) && r.c.e <= l.c.e
        r.r.x = center(1) + (center(1) - r.l.x);
    end
    
    % Determine peak width
    if l.c.e < r.c.e
        width = [l.r.x-l.l.x; l.r.x-l.l.x];%r.r.x-r.l.x];
    else
        width = [r.r.x-r.l.x; r.r.x-r.l.x];%r.r.x-r.l.x];
    end
    
    ymin = min(y(:,i));
    
    % Determine peak asymmetry values
    if l.c.e < r.c.e
        
        a = [center(1) - l.l.x; center(2) - l.l.x];
        b = [l.r.x - center(1); l.r.x - center(2)];
    
        alpha(1,1) = ((l.l.y * p.y) - ymin) / (height(1) - ymin);
        alpha(2,1) = ((l.r.y * p.y) - ymin) / (height(2) - ymin);
    
    else
        
        a = [center(1) - r.l.x; center(2) - r.l.x];
        b = [r.r.x - center(1); r.r.x - center(2)];
    
        alpha(1,1) = ((r.l.y * p.y) - ymin) / (height(1) - ymin);
        alpha(2,1) = ((r.r.y * p.y) - ymin) / (height(2) - ymin);
        
    end
        
    % Check for any out of range values
    a(a < 0) = width(a < 0) / 2;
    b(b < 0) = width(a < 0) / 2;
    
    alpha(alpha < 0 | alpha >= 1) = 0.5;
    
    % Update peak values
    peaks.center(:,i) = center;
    peaks.height(:,i) = height;
    peaks.width(:,i)  = width;
    peaks.a(:,i)      = a;
    peaks.b(:,i)      = b;
    peaks.alpha(:,i)  = alpha;
    
end

end
