% Method: Derivative
%  -Calculate derivative of a signal
%
% Syntax
%   Derivative(y, 'OptionName', optionvalue...)
%   Derivative(x, y, 'OptionName', optionvalue...)
%
% Input
%   x          : array
%   y          : array or matrix
%
% Options
%  'degree'    : 1 to 10
%  'smoothing' : 'on', 'off'
%   
% Description
%   x          : time values
%   y          : intensity values
%  'degree'    : degree of derivative (default = 1)
%  'smoothing' : smooth before each derivative (default = 'off')
%
% Examples
%   Derivative(y)
%   Derivative(x, y)
%   Derivative(x, y, 'degree', 1)
%   Derivative(x, y, 'degree', 4, 'smoothing', true)

function varargout = Derivative(varargin)

% Check number of inputs
if nargin < 1
    error('Not enough input arguments');
elseif nargin >= 2 && isnumeric(varargin{2})
    x = varargin{1};
    y = varargin{2};
elseif isnumeric(varargin{1})
    x(:,1) = 1:length(varargin{1}(:,1));
    y = varargin{1};
else
    error('Undefined input arguments of type ''data''');
end

% Check for valid input
if length(x(:,1)) ~= length(y(:,1))
    if length(x(1,:)) == length(y(1,:))
        x = x';
        y = y';
    else
        x(:,1) = 1:length(y(:,1));
    end
end

% Check for matrix input
if length(y(1,:)) > 1
    if length(y(1,:)) ~= length(x(1,:))
        for i = 1:length(y(1,:))
            x(:,i) = x(:,1);
        end
    end
end

% Check precision
if ~isa(x,'double')
    x = double(x);
end
if ~isa(y,'double')
    y = double(y);
end

% Check for degree input
if ~isempty(find(strcmpi(varargin, 'degree'),1))
    degree = varargin{find(strcmpi(varargin, 'degree'),1) + 1};
    
    % Check user input
    if ~isnumeric(degree)
        fprintf('Unrecognized input arguments of type ''degree'', defaulting to first derivative');
        degree = 1;
        
    elseif isnumeric(degree)
        degree = round(degree(1));
        
        % Check for invalid input
        if degree < 1
            degree = 1;
        elseif degree > 10
            degree = 10;
        end
    else
        degree = 1;
    end
else
    % Default to first derivative
    degree = 1;
end

% Check for smoothing input
if ~isempty(find(strcmpi(varargin, 'smoothing'),1))
    smoothing = varargin{find(strcmpi(varargin, 'smoothing'),1) + 1};
    
    % Check user input
    if strcmpi(smoothing, 'on')
        smoothing = true;
    elseif ~strcmpi(smoothing, 'on')
        smoothing = false;
    elseif ~islogical(smoothing)
        smoothing = false;
    end
else
    smoothing = false;
end

% Determine array length
rows = length(y(:,1));

% Calculate derivative
for i = 1:degree

    % Smooth data
    if smoothing
        y = Smooth(y, 'asymmetry', 0.1, 'smoothness', 100);
    end
        
    % Calculate derivative
    y = bsxfun(@rdivide, bsxfun(@minus, y(2:end,:), y(1:end-1,:)), bsxfun(@minus, x(2:end,:), x(1:end-1,:)));
    
    % Preserve array length
    y(rows,:) = 0;
end

% Set output
varargout{1} = y;
end
 