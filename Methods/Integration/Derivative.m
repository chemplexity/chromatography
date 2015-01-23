% Method: Derivative
%  -Calculate derivative of a signal
%
% Syntax:
%   Derivative(x, y, 'OptionName', optionvalue...)
%   Derivative(y, 'OptionName', optionvalue...)
%
% Options:
%  'degree'    : 1 to 9
%  'smoothing' : 'on', 'off'
%   
% Description:
%   x          : vector
%   y          : vector or matrix
%  'degree'    : degree of derivative to calculate -- (default: 'first')
%  'smoothing' : smooth signal before calculating derivative -- (default: 'off')
%
% Examples:
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
    if ischar(smoothing) && strcmpi(smoothing, 'on')
        smoothing = true;
    elseif ischar(smoothing) && ~strcmpi(smoothing, 'on')
        smoothing = false;
    elseif ~islogical(smoothing)
        smoothing = false;
    end
else
    % Default to no smoothing
    smoothing = false;
end

% Determine vector length
rows = length(y(:,1));

% Calculate derivative to specified degree
for i = 1:degree

    % Smooth data if selected
    if smoothing
        y = WhittakerSmoother(y, 'Asymmetry', 0.1, 'Smoothness', 100);
    end
        
    % Calculate signal derivative
    y = bsxfun(@rdivide, bsxfun(@minus, y(2:end,:), y(1:end-1,:)), bsxfun(@minus, x(2:end,:), x(1:end-1,:)));
    
    % Preserve vector length
    y(rows,:) = 0;
end

% Set output
varargout{1} = y;
end
 