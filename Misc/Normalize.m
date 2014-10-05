% Method: Normalize
% Description: Normalize signal between 0 and 1
%
% Syntax:
%   y = Normalize(y, 'OptionName', optionvalue...)
%
%   Input:
%       y : vector or matrix
%
%   Options:
%       'Type' : 'local', 'global'
%   
%   Details:
%       'local'  : normalize vectors individually [default]
%       'global' : normalize vectors to global maximum
%
% Examples:
%   y = Normalize(y)
%   y = Normalize(y, 'Type', 'local')
%   y = Normalize(y, 'Type', 'global')

function varargout = Normalize(y, varargin)

% Check for input options
if ~isempty(find(strcmp(varargin, 'Type') | strcmp(varargin, 'type'),1))
    type = varargin{find(strcmp(varargin, 'Type') | strcmp(varargin, 'type'),1) + 1};
    
    % Check for valid input 
    if ~ischar(type)
        type = 'local';
    else
        type = lower(type);
    end
    
    if ~strcmp(type, 'global') && ~strcmp(type, 'local')
        type = 'local';
    end
else
    type = 'local';
end

% Global normalization values
if strcmp(type, 'global')
    ymax = max(max(y));
    ymin = min(min(y));
elseif strcmp(type, 'local')
    ymax = max(y);
    ymin = min(y);
end
    
% Normalize signal
y = bsxfun(@rdivide, bsxfun(@minus, y, ymin), (ymax-ymin));
    
% Set output
varargout{1} = y;
end