function [x, y] = Filter(varargin)
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

% ---------------------------------------
% Defaults
% ---------------------------------------
default.xrange = [];
default.xmin   = [];
default.xmax   = [];

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'x', @ismatrix);
addRequired(p, 'y', @ismatrix);

addParameter(p, 'xrange', default.xrange, @isvector);
addParameter(p, 'xmin',   default.xmin,   @isscalar);
addParameter(p, 'xmax',   default.xmax,   @isscalar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
x      = p.Results.x;
y      = p.Results.y;
xrange = p.Results.xrange;
xmin   = p.Results.xmin;
xmax   = p.Results.xmax;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: x, y
if size(x,1) ~= size(y,1)
    return
end

if size(x,1) <= 1
    return
end

% Parameter: 'xrange', 'xmin', 'xmax'
if isempty(xrange) && isempty(xmin) && isempty(xmax)
    return
end

if ~isempty(xmin) && ~isempty(xmax)
    xfilter = x >= xmin(1) & x <= xmax(1);
elseif ~isempty(xmin)
    xfilter = x >= xmin(1); 
elseif ~isempty(xmax)
    xfilter = x <= xmax(1);
else
    xfilter(1:length(x)) = false;
end

if length(xrange) >= 2
    xfilter = x >= xrange(1) & x <= xrange(2);
end

% ---------------------------------------
% Filter
% ---------------------------------------
x = x(xfilter);
y = y(xfilter, :);

end