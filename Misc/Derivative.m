% Method: Derivative
% Description: Calculate derivative of a signal
%
% Syntax:
%   dy = Derivative(x, y, 'OptionName', optionvalue...)
%   dy = Derivative(y, 'OptionName', optionvalue...)
%
%   Input:
%       x : vector
%       y : vector or matrix
%
%   Options:
%       'Degree'    : degree
%       'Smoothing' : smoothing
%   
%   Details:
%       'degree'    : degree of derivative to calculate (e.g. first, second, third...)
%       'smoothing' : smooth signal before calculating derivative
%
% Examples:
%   dy = Derivative(y)
%   dy = Derivative(x,y)
%   dy = Derivative(x,y, 'Degree', 1)
%   dy = Derivative(x,y, 'Degree', 4, 'Smoothing', true)

function varargout = Derivative(varargin)

% Determine xy values
if nargin >= 2 && isnumeric(varargin{2})
    x = varargin{1};
    y = varargin{2};
else
    x(:,1) = 1:length(varargin{1});
    y = varargin{1};
end

% Check for degree input
if ~isempty(find(strcmp(varargin, 'Degree') | strcmp(varargin, 'degree'),1))
    degree = varargin{find(strcmp(varargin, 'Degree') | strcmp(varargin, 'degree'),1) + 1};
    
    % Check input for string
    if ischar(degree)
        switch degree
            % Convert string to value
            case 'first'
                degree = 1;
            case 'second'
                degree = 2;
            case 'third'
                degree = 3;
            case 'fourth'
                degree = 4;
            otherwise
                fprintf('Unrecognized string, defaulting to first derivative');
                degree = 1;
        end
    elseif isnumeric(degree)
        degree = degree(1);
    else
        degree = 1;
    end
else
    % Default value is first derivative
    degree = 1;
end

% Check for smoothing input
if ~isempty(find(strcmp(varargin, 'Smoothing') | strcmp(varargin, 'smoothing'),1))
    smoothing = varargin{find(strcmp(varargin, 'Smoothing') | strcmp(varargin, 'smoothing'),1) + 1};
    
    % Check input for string
    if ischar(smoothing)
        switch smoothing
            case 'on'
                smoothing = true;
            case 'off'
                smoothing = false;
            otherwise
                smoothing = false;
        end
    elseif ~islogical(smoothing)
        switch smoothing
            case 1
                smoothing = true;
            case 0
                smoothing = false;
            otherwise
                smoothing = false;
        end
    end
else
    % Default value is no data smoothing
    smoothing = false;
end

% Vector length
length_y = length(y(:,1));

% Calculate derivative to nth degree
for i = 1:degree

    % Smooth data if selected
    if smoothing
        y = WhittakerSmoother(y, 'Asymmetry', 0.1, 'Smoothness', 100);
    end
        
    % Calculate signal derivative
    y = bsxfun(@rdivide, bsxfun(@minus, y(2:end,:), y(1:end-1,:)), bsxfun(@minus, x(2:end), x(1:end-1)));
    
    % Preserve vector length
    y(length_y,:) = 0;
end

% Set output
varargout{1} = y;
end
 