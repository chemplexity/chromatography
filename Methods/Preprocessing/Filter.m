% ------------------------------------------------------------------------
% Method      : Filter
% Description : Returns input within a provided time range
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   [x, y] = Filter(x, y)
%   [x, y] = Filter( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   x -- time values
%       array (size = m x 1)
%
%   y -- intensity values
%       array | matrix (size = m x n)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'xrange' -- minimum and maximum time values
%       two-element vector
%
%   'xmin' -- minimum time value
%       number
%
%   'xmax' -- maximum time value
%       number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
% [x, y] = Filter(x, y, 'xrange', [10.3, 45.5])
% [x, y] = Filter(x, y, 'xmin', 15.4)
% [x, y] = Filter(x, y, 'xmax', 60.0)

function [x, y] = Filter(varargin)

% ---------------------------------------
% Default
% ---------------------------------------
default.xrange = [];
default.xmin   = [];
default.xmax   = [];

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'x',...
    @(x) validateattributes(x, {'numeric'}, {'nonempty'}));

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonempty'}));

addParameter(p, 'xrange',...
    default.xrange,...
    @(x) validateattributes(x, {'numeric'}, {'numel', 2}));

addParameter(p, 'xmin',...
    default.xmin,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));

addParameter(p, 'xmax',...
    default.xmax,...
    @(x) validateattributes(x, {'numeric'}, {'scalar'}));


parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
x = p.Results.x;
y = p.Results.y;

xrange = p.Results.xrange;
xmin   = p.Results.xmin;
xmax   = p.Results.xmax;

% ---------------------------------------
% Validate
% ---------------------------------------
if length(x(:,1)) ~= length(y(:,1))
    return
end

if length(xrange) <= 1 && isempty(xmin) && isempty(xmax)
    return
end

if ~isempty(xmin) && ~isempty(xmax)
    filter = x >= xmin(1) & x <= xmax(1);
    
elseif ~isempty(xmin)
    filter = x >= xmin(1); 
    
elseif ~isempty(xmax)
    filter = x <= xmax(1);

else
    filter(1:length(x)) = false;
end

if length(xrange) >= 2
    filter = x >= xrange(1) & x <= xrange(2);
end

% ---------------------------------------
% Filter
% ---------------------------------------
x = x(filter);
y = y(filter, :);

end