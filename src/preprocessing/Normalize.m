function y = Normalize(varargin)
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
%   'dim' -- normalize values by row, by column, or by matrix
%       'col' (default) | 'row' | 'mat'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, 'dim', 'mat')
%   y = Normalize(y, 'dim', 'col')
%   y = Normalize(y, 'dim', 2)
%   y = Normalize(y, 'dim', 1)
%   y = Normalize(y, 'dim', 'row')

% ---------------------------------------
% Defaults
% ---------------------------------------
default.dim = 'col';

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y', @ismatrix);

addParameter(p, 'dim', default.dim);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y   = p.Results.y;
dim = p.Results.dim;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: y
if numel(y) <= 1
    return
end

% Parameter: 'dim'
if ischar(dim) && ~isnan(str2double(dim))
    dim = str2double(dim);
end

% ---------------------------------------
% Normalize
% ---------------------------------------
switch dim
    
    case {0, 'matrix', 'mat', 'm'}
        
        ymin = min(min(y));
        ymax = max(max(y));
    
    case {1, 'row', 'r'}
        
        ymin = min(y,[],2);
        ymax = max(y,[],2);
        
    case {2, 'column', 'col', 'c'}
        
        ymin = min(y);
        ymax = max(y);
        
    otherwise
        
        ymin = min(y);
        ymax = max(y);
        
end

y = bsxfun(@rdivide,...
    bsxfun(@minus, y, ymin),...
    bsxfun(@minus, ymax, ymin));

end