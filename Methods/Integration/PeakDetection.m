% Method: PeakDetection
%  -Locate and determine peak boundaries
%
% Syntax
%   PeakDetection(y)
%   PeakDetection(x, y)
%   PeakDetection(x, y, 'OptionName', optionvalue...)
%
% Input
%   x        : array
%   y        : arrary or matrix
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
%   peaks = PeakDerivative(y)
%   peaks = PeakDerivative(y, 'width', 1.5)
%   peaks = PeakDerivative(x, y, 'center', 22.10)
%   peaks = PeakDerivative(x, y, 'center', 12.44, 'width', 0.24)

function varargout = PeakDetection(varargin)

% Check input
[x, y, options] = parse(varargin);

% Determine peak locations
for i = 1:length(y(1,:))

    % Set variables
    if length(options.center) == length(y(1,:))
        c = options.center(i);
    else
        c = options.center(1);
    end
    if length(options.width) == length(y(1,:))
        w = options.width(i);
    else
        w = options.width(1);
    end
        
    % Index downward points: y(n) > y(n+1)
    d = y(:,i) > circshift(y(:,i), [-1, 0]);
    
    % Index upward points: y(n) > y(n-1)
    u = y(:,i) >= circshift(y(:,i), [1, 0]);

    % Determine local maxima: y(n-1) < y(n) > y(n+1)
    lx = x(d & u);
    ly = y(d & u, i);

    % Filter local maxima outside window
    window = lx > c-(w/2) & lx < c+(w/2);
    lx = lx(window);
    ly = ly(window);
    
    % Determine highest local maxima inside window
    center = lx(find(ly >= max(ly), 1));
    
    % Determine signal derivative inside window
    window = x > c-(w/2) & x < c+(w/2);
    dx = x(window);
    dy = y(window,i) - circshift(y(window,i), [1,0]);
    
    % Remove bad values
    dy(1) = 0;
    dy(isinf(dy)|isnan(dy)) = 0;
    
    % Find inflection points
    l = dx(find(dy == max(dy),1));
    r = dx(find(dy == min(dy),1));
    
    % Check values
    if l >= center && r > center
        l = center - (r - center);
    elseif l < center && r <= center
        r = center + (center - l);
    elseif l >= center && r <= center
        l = center - 0.1;
        r = center + 0.1;
    end
    
    % Assign values
    peak.center(i) = center;
    peak.left(i) = l;
    peak.right(i) = r;
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

% Return input
varargout{1} = x;
varargout{2} = y;
varargout{3} = options;
end