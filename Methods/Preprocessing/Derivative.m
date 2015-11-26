% ------------------------------------------------------------------------
% Method      : Derivative
% Description : Calculate the nth derivative of a signal
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   dy = Derivative(y)
%   dy = Derivative(x, y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   x (optional)
%       Description : time values
%       Type        : array
%
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   order (optional)
%       Description : return derivative of specifed order
%       Type        : number
%       Default     : 1
%       Range       : 1 to 9
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   dy = Derivative(y)
%   dy = Derivative(x, y)
%   dy = Derivative(x, y, 'order', 1)
%   dy = Derivative(y, 'order', 4)
%

function varargout = Derivative(varargin)

[x, y, options] = parse(varargin);

% Determine array length
rows = length(y(:,1));

% Calculate derivative
for i = 1:options.degree
    
    y = bsxfun(@rdivide,...
        bsxfun(@minus, y(2:end,:), y(1:end-1,:)),...
        bsxfun(@minus, x(2:end,:), x(1:end-1,:)));
    
    if mod(i,2) == 0
        y = circshift(y, [1,0]);
        y(1,:) = 0;
    end
    
    y(rows,:) = 0;
end

% Set output
varargout{1} = y;

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
switch nargin
    
    case 0
        error('Not enough input arguments.');
        
    case 1
        if isnumeric(varargin{1})
            x = 1:length(varargin{1});
            x = x';
            y = varargin{1};
        else
            error('Undefined input arguments of type ''y''.');
        end
        
    otherwise
        if isnumeric(varargin{1}) && isnumeric(varargin{2})
            x = varargin{1};
            y = varargin{2};
        elseif isnumeric(varargin{1}) && ~isnumeric(varargin{2})
            x = 1:length(varargin{1});
            x = x';
            y = varargin{1};
        else
            error('Undefined input arguments of type ''y''.');
        end
end

% Determine size of x and y
sx = size(x);
sy = size(y);

% Check x matrix
if sx(1) ~= 1 && sx(2) ~= 1
    
    % Check x dimensions
    if sx(2) == sy(1) && sx(2) ~= sx(1)
        x = x';
        sx = size(x);
    end
    
    % Check y dimensions
    if sy(2) == sx(1) && sy(2) ~= sy(1)
        y = y';
    end
    
    % Check x vector
elseif sx(1) == 1 || sx(2) == 1
    
    % Check x for columns > rows
    if sx(2) > sx(1)
        x = x';
        sx = size(x);
    end
    
    % Check y dimensions
    if sy(2) == sx(1) && sy(2) ~= sy(1)
        y = y';
        sy = size(y);
    end
    
    x = repmat(x, [1, sy(2)]);
end

% Check precision
if ~isa(x,'double')
    x = double(x);
end
if ~isa(y,'double')
    y = double(y);
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check for degree input
if ~isempty(input('degree'))
    degree = varargin{input('degree')+1};
    
    % Check input type
    if iscell(degree)
        degree = degree{1};
    end
    
    % Check for valid input
    if ~isnumeric(degree)
        
        fprintf(['\n',...
            'Unrecognized input arguments of type ''degree''.',...
            'Setting to first derivative... \n']);
        
        options.degree = 1;
        
    elseif isnumeric(degree)
        
        % Check for integer input
        degree = round(degree(1));
        
        % Check for invalid input
        if degree < 1
            options.degree = 1;
            
        elseif degree > 1000
            options.degree = 1000;
            
        else
            options.degree = degree;
        end
        
    else
        options.degree = 1;
    end
    
else
    options.degree = 1;
end

% Return input
varargout{1} = x;
varargout{2} = y;
varargout{3} = options;

end
