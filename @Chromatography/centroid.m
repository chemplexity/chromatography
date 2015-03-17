% Method: centroid
%  -Centroid raw mass spectrometer data
%
% Syntax
%   data = obj.centroid(data)
%   data = obj.centroid(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'    : 'all', [index]
%
% Description
%   data         : data structure
%   'samples'    : row index of samples (default = 'all')
%
% Examples
%   data = obj.centroid(data)
%   data = obj.centroid(data, 'samples', [2:5, 8, 10])

function varargout = centroid(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;

for i = 1:length(samples)
    
    % Input values
    y = data(i).xic.values;
    mz = data(i).mz;
    
    % Centroid data
    [mz, y] = Centroid(mz, y);
    
    % Output values
    data(i).xic.values = y;
    data(i).mz = mz;
end

% Return data
varargout{1} = data;
end

% Parse input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments.');
elseif isstruct(varargin{1})
    data = obj.format('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''.');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Sample options
if ~isempty(input('samples'))
    samples = varargin{input('samples')+1};

    % Set keywords
    samples_all = {'default', 'all'};
        
    % Check for valid input
    if any(strcmpi(samples, samples_all))
        samples = 1:length(data);

    % Check input type
    elseif ~isnumeric(samples)
        
        % Check string input
        samples = str2double(samples);
        
        % Check for numeric input
        if ~any(isnan(samples))
            samples = round(samples);
        else
            samples = 1:length(data);
        end
    end
    
    % Check maximum input value
    if max(samples) > length(data)
        samples = samples(samples <= length(data));
    end
    
    % Check minimum input value
    if min(samples < 1)
        samples = samples(samples >= 1);
    end
    
    options.samples = samples;
    
else
    options.samples = 1:length(data);
end

% Return input
varargout{1} = data;
varargout{2} = options;
end
