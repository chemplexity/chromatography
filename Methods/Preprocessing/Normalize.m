% ------------------------------------------------------------------------
% Method      : Normalize
% Description : Normalize signal between 0 and 1
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(x, y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   type (optional)
%       Description : scale to array ('local') or matrix ('global') min/max
%       Type        : 'local', 'global'
%       Default     : 'local'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = Normalize(y)
%   y = Normalize(y, 'type', 'local')
%   y = Normalize(y, 'type', 'global')
%

function varargout = Normalize(y, varargin)

% Check for input options
if ~isempty(find(strcmpi(varargin, 'type'),1))
    
    type = varargin{find(strcmpi(varargin, 'type'),1)+1};
    
    % Check for valid input
    if ~ischar(type)
        type = 'local';
    else
        type = lower(type);
    end
    
    if ~strcmpi(type, 'global') && ~strcmpi(type, 'local')
        type = 'local';
    end
    
else
    type = 'local';
end

% Set normalization boundaries
if strcmpi(type, 'global')
    ymax = max(max(y));
    ymin = min(min(y));
    
elseif strcmpi(type, 'local')
    ymax = max(y);
    ymin = min(y);
end

% Normalize signal
y = bsxfun(@rdivide,...
    bsxfun(@minus, y, ymin), (ymax-ymin));

% Set output
varargout{1} = y;

end