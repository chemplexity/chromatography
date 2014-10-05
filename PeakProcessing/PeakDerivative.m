% Method: PeakDerivative
% Description: Find peak inflection points from derivative signal
%
% Syntax:
%   [edges, center] = PeakDerivative(x, y, 'OptionName', optionvalue...)
%
%   Options:
%       WindowCenter : center
%       WindowSize   : width
%       Extend     : amount
%
% Examples:
%   [edges, center] = PeakDerivative(x, y)
%   [edges, center] = PeakDerivative(x, y, 'WindowCenter', 10.5, 'WindowSize', 5)
%   [edges, center] = PeakDerivative(x, y, 'WindowSize', 4, 'Extended', 0.50)

function varargout = PeakDerivative(x, y, varargin)

% Check input type
if ~isnumeric(x) || ~isnumeric(y)
    fprintf('[Error] Invalid format (non-array)');
    return
% Check input vector length
elseif length(x(:,1)) ~= length(y(:,1))
    fprintf('[Error] Invalid format (x,y unequal lengths)');
    return
else
    x = double(x);
    y = double(y);
end
    
% Check for window center input
if ~isempty(find(strcmp(varargin, 'WindowCenter'), 1))
    center = varargin{find(strcmp(varargin, 'WindowCenter')) + 1};
    
    % Allow empty input
    if isempty(center)
        [~, index] = max(y);
        center = x(index);
    end
else
    [~, index] = max(y);
    center = x(index);
end
    
% Check for window size input
if ~isempty(find(strcmp(varargin, 'WindowSize'), 1))
    width = varargin{find(strcmp(varargin, 'WindowSize')) + 1};
    
    % Allow empty input
    if isempty(width)
        width = 2.5;
    end
else
    width = 2.5;
end
    
% Check for extend input
if ~isempty(find(strcmp(varargin, 'Extend'), 1))
    extend = varargin{find(strcmp(varargin, 'Extend')) + 1};
else
    extend = 1;
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