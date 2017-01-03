function dy = Derivative(varargin)
% ------------------------------------------------------------------------
% Method      : Derivative
% Description : Calculate the nth derivative of a signal
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   dy = Derivative(y)
%   dy = Derivative(x, y)
%   dy = Derivative( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Optional)
% ------------------------------------------------------------------------
%   x -- time values
%       array
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   y -- intensity values
%       array | matrix
%       
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'order' -- nth order derivative
%       1 (default) | integer
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   dy = Derivative(y)
%   dy = Derivative(x, y)
%   dy = Derivative(x, y, 'order', 1)
%   dy = Derivative(y, 'order', 4)

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y', @ismatrix);

addOptional(p, 'x', [], @isnumeric);

addParameter(p, 'order', 1, @isscalar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
x     = p.Results.x;
y     = p.Results.y;
order = p.Results.order;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: x
if ~isempty(x)
    y = p.Results.x;
    x = p.Results.y;
else
    x = (1:size(y,1))';
end

% Input: y
if size(y,1) == 1 && size(y,2) ~= 1
    y = y';
end

if size(x,1) == 1 && size(x,2) == size(y,1)
    x = x';
elseif size(x,1) ~= size(y,1)
    x = (1:size(y,1))';
end

% Parameter: 'order' 
if order < 0
    order = 0;
end

% ---------------------------------------
% Derivative
% ---------------------------------------
dx = x;
dy = y;
n  = round(order(1));

for i = 1:n
    
    dy = bsxfun(@rdivide,...
        bsxfun(@minus, dy, circshift(dy,[1,0])),...
        bsxfun(@minus, dx, circshift(dx,[1,0])));
    
    if mod(i,2) == 0
        dy = circshift(dy,[1,0]);
    end
    
    dy([1,end],:) = 0;
    
end

dy(isnan(dy)|isinf(dy)) = 0;

end
