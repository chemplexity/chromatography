% ------------------------------------------------------------------------
% Method      : Normalize
% Description : Normalize signal between 0 and 1
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   scope (optional)
%       Description : scale to array ('local') or matrix ('global') min/max
%       Type        : string
%       Options     : 'local', 'global'
%       Default     : 'local'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, 'scope', 'local')
%   y = Normalize(y, 'scope', 'global')
%

function varargout = Normalize(varargin)

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'scope',...
    'local',...
    @(x) validateattributes(x, {'char'}, {'nonempty'}));

parse(p, varargin{:});

% ---------------------------------------
% Variables
% ---------------------------------------
y = p.Results.y;
scope = p.Results.scope;

% ---------------------------------------
% Normalize
% ---------------------------------------
if strcmpi(scope, 'global')
    ymin = min(min(y));
    ymax = max(max(y));
else
    ymin = min(y);
    ymax = max(y);
end

y = bsxfun(@rdivide,...
    bsxfun(@minus, y, ymin),...
    bsxfun(@minus, ymax, ymin));

% ---------------------------------------
% Output
% ---------------------------------------
varargout{1} = y;

end