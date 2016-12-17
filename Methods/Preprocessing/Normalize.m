% ------------------------------------------------------------------------
% Method      : Normalize
% Description : Scale values between 0 and 1
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize( __ , Name, Value)
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
%   'scope' -- normalize values by row, by column, or by matrix
%       'column' (default) | 'row' | 'matrix'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, 'scope', 'matrix')
%   y = Normalize(y, 'scope', 'column')

function y = Normalize(varargin)

% ---------------------------------------
% Defaults
% ---------------------------------------
default.scope = 'column';

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y', @ismatrix);

addParameter(p, 'scope', default.scope, @ischar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
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
        
    otherwise
        
        ymin = min(y);
        ymax = max(y);
        
end

y = bsxfun(@rdivide,...
    bsxfun(@minus, y, ymin),...
    bsxfun(@minus, ymax, ymin));

end