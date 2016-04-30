% ------------------------------------------------------------------------
% Method      : Normalize
% Description : Scale values between 0 and 1
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
%   'scope' (optional)
%       Description : normalize values by row, by column, or by matrix
%       Type        : string
%       Options     : 'row', 'column', 'matrix'
%       Default     : 'column'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, 'scope', 'matrix')
%   y = Normalize(y, 'scope', 'column')


function varargout = Normalize(varargin)

% ---------------------------------------
% Defaults
% ---------------------------------------
default.scope = 'column';

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',...
    @(x) validateattributes(x, {'numeric'}, {'nonnan', 'nonempty'}));

addParameter(p, 'scope',...
    default.scope,...
    @(x) validateattributes(x, {'char'}, {'nonempty'}));

parse(p, varargin{:});

% ---------------------------------------
% Variables
% ---------------------------------------
y     = p.Results.y;
scope = p.Results.scope;

% ---------------------------------------
% Normalize
% ---------------------------------------
switch scope
    
    case {'matrix', 'mat', 'm'}
        
        ymin = min(min(y));
        ymax = max(max(y));
        
    case {'column', 'col', 'c'}
        
        ymin = min(y);
        ymax = max(y);
        
    case {'row', 'r'}
        
        ymin = min(y,[],2);
        ymax = max(y,[],2);
        
end

y = bsxfun(@rdivide,...
    bsxfun(@minus, y, ymin),...
    bsxfun(@minus, ymax, ymin));

% ---------------------------------------
% Output
% ---------------------------------------
varargout{1} = y;

end