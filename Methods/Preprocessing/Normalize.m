% Method: Normalize
%  -Normalize signal between 0 and 1
%
% Syntax
%   y = Normalize(y, 'OptionName', optionvalue...)
%
% Input
%   y        : array or matrix
%
% Options
%   'type'   : 'local', 'global'
%   
% Description
%   'local'  : normalize vectors individually (default)
%   'global' : normalize vectors to global maximum
%
% Examples
%   y = Normalize(y)
%   y = Normalize(y, 'type', 'local')
%   y = Normalize(y, 'type', 'global')

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

% Global normalization values
if strcmpi(type, 'global')
    ymax = max(max(y));
    ymin = min(min(y));
elseif strcmpi(type, 'local')
    ymax = max(y);
    ymin = min(y);
end
    
% Normalize signal
y = bsxfun(@rdivide, bsxfun(@minus, y, ymin), (ymax-ymin));
    
% Set output
varargout{1} = y;
end