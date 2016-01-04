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
%       Default     : 1:length(y)
%
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   order (optional)
%       Description : calculate nth order derivative
%       Type        : integer
%       Options     : >=1
%       Default     : 1
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

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addOptional(p, 'x',...
    [],...
    @(x) validateattributes(x, {'numeric'}, {'nonnan'}));

addParameter(p, 'order',...
    1,...
    @(x) validateattributes(x, {'numeric'}, {'positive', 'scalar'}));

parse(p, varargin{:});

% ---------------------------------------
% Variables
% ---------------------------------------
x = p.Results.x;
y = p.Results.y;
order = p.Results.order;

% ---------------------------------------
% Validation
% ---------------------------------------
if ~isempty(x)
    y = p.Results.x;
    x = p.Results.y;
else
    x = (1:size(y,1))';
end

if size(y,1) == 1 && size(y,2) ~= 1
    y = y';
end

if size(x,1) == 1 && size(x,2) == size(y,1)
    x = x';
elseif size(x,1) ~= size(y,1)
    x = (1:size(y,1))';
end

% ---------------------------------------
% Derivative
% ---------------------------------------
dx = x;
dy = y;
n = round(order(1));

for i = 1:n
    
    dy = bsxfun(@rdivide,...
        bsxfun(@minus, dy, circshift(dy,[1,0])),...
        bsxfun(@minus, dx, circshift(dx,[1,0])));
    
    if mod(i,2) == 0
        dy = circshift(dy,[1,0]);
    end
    
    dy([1,end],:) = 0;
    
end

% ---------------------------------------
% Output
% ---------------------------------------
dy(isnan(dy)|isinf(dy)) = 0;
varargout{1} = dy;

end
