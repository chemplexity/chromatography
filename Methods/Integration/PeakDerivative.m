% Method: PeakDerivative
%  -Find peak inflection points from derivative signal
%
% Syntax
%   PeakDerivative(x, y)
%   PeakDerivative(x, y, 'OptionName', optionvalue...)
%
% Options
%   'center'   : value
%   'width'    : value
%   'coverage' : value
%
% Description
%   x          : array
%   y          : array or matrix
%   'center'   : search for peak at center value -- (default: x at max(y))
%   'width'    : search for peak at center +/- width/2 -- (default: 2)
%   'coverage' : amount to extend past inflection points to search peak boundaries (default: 1)
%
% Examples
%   [edges, center] = PeakDerivative(x, y)
%   [edges, center] = PeakDerivative(x, y, 'center', 22.10)
%   [edges, center] = PeakDerivative(x, y, 'center', 12.44, 'width', 0.24)

function varargout = PeakDerivative(x, y, varargin)

% Check input type
if ~isnumeric(x) || ~isnumeric(y)
    error('Undefined input arguments of type ''xy''');
elseif length(x(:,1)) ~= length(y(:,1))
    error('Index of input arguments unequal');
else
    x = double(x);
    y = double(y);
end
    
% Check for window center input
if ~isempty(find(strcmpi(varargin, 'center'), 1))
    center = varargin{find(strcmpi(varargin, 'center')) + 1};
    
    % Check user input
    if isempty(center)
        [~, index] = max(y);
        center = x(index);    
    elseif ~isnumeric(center)
        error('Undefined input arguments of type ''center''');
    elseif center > max(x) || center < min(x)
        center = [];
    end
else
    [~, index] = max(y);
    center = x(index);
end
    
% Check for window size input
if ~isempty(find(strcmpi(varargin, 'width'), 1))
    width = varargin{find(strcmpi(varargin, 'width')) + 1};
    
    % Allow empty input
    if isempty(width)
        width = 3;
    elseif ~isnumeric(width)
        error('Undefined input arguments of type ''width''');
    elseif width > max(x) || width < 0
        width = [];
    end
else
    width = 2;
end
    
% Check for extend input
if ~isempty(find(strcmpi(varargin, 'coverage'), 1))
    extend = varargin{find(strcmpi(varargin, 'coverage')) + 1};
else
    extend = 0.1;
end
        
% Initialize functions
derivative = @(x,y) (y(2:end) - y(1:end-1)) ./ (x(2:end) - x(1:end-1));
normalize = @(y) ((y - min(y)) / (max(y) - min(y)));

% Single vector or matrix input
for i = 1:length(y(1,:))

    if length(center) == length(y(1,:))
        c = center(i);
    else
        c = center(1);
    end
    
    % Normalize and take derivative of input signal
    y(:,i) = normalize(y(:,i));
    dy(:,i) = derivative(x,y(:,i));

    % Create window around center point
    if c + width/2 < max(x)
        upper(i) = find(x >= c + width/2, 1);
    else
        upper(i) = length(x) - 1;
    end

    if c - width/2 > min(x)
        lower(i) = find(x >= c - width/2, 1);
    else
        lower(i) = 1;
    end

    % Find max/min of dy within window
    [dy_max(i), dy_max_index(i)] = max(dy(lower(i):upper(i),i));
    [dy_min(i), dy_min_index(i)] = min(dy(lower(i):upper(i),i));

    % Corrected index
    dy_max_index(i) = dy_max_index(i) + lower(i) - 1;
    dy_min_index(i) = dy_min_index(i) + lower(i) - 1;

    % If dy minimum occurs after dy maximum
    if dy_min_index(i) > dy_max_index(i)
   
        % Find peak center from dy
        dy_center_index(i) = find(dy(dy_max_index(i):dy_min_index(i),i) <= 0, 1) + dy_max_index(i) - 1;

        % Find edges extending past inflection points
        dy_max_index(i) = dy_max_index(i) - find(flipud(dy(1:dy_max_index(i),i)) <= dy_max(i) * extend, 1) - 1;
        dy_min_index(i) = find(dy(dy_min_index(i):end,i) >= dy_min(i) * extend, 1) + dy_min_index(i) - 1;

        % Peak center, half height boundaries
        peak_center(i,1) = x(dy_center_index(i));
        peak_left(i,1) = x(dy_max_index(i));
        peak_right(i,1) = x(dy_min_index(i));

    else
        peak_center(i,1) = 0;
        peak_left(i,1) = 0;
        peak_right(i,1) = 0;
    end
end

% Output
varargout{1} = [peak_left, peak_right];
varargout{2} = peak_center;
end