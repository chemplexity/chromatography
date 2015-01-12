% Method: Centroid
%  -Centroid mass spectrometer data
%
% Syntax
%   Centroid(x, y)
%   Centroid(x, y, 'OptionName', optionvalue...)
%
% Options
%   'width'   : 0.001 to 1
%
% Description
%   x       : vector with mass values
%   y       : matrix with intensity values
%   'width' : mass resolution of centroid -- (default: 0.5)
%
% Examples
%   Centroid(x, y)
%   Centroid(x, y, 'width', 0.1)

function varargout = Centroid(data, varargin)

% Check number of inputs
if nargin < 1
    error('Not enough input arguments');
elseif isstruct(data)
    data = DataStructure('Validate', data);
else
    error('Undefined input arguments of type ''data''');
end
    
% Default options
samples = 1:length(data);
binsize = 0.50;
    
% Check sample options
if ~isempty(find(strcmpi(varargin, 'samples'),1))
    options.samples = varargin{find(strcmpi(varargin, 'samples'),1) + 1};
                    
    % Check user input
    if strcmpi(options.samples, 'all')
        options.samples = 1:length(data);
    elseif ~isnumeric(options.samples)
        error('Undefined input arguments of type ''samples''');
    elseif max(options.samples) > length(data) || min(options.samples) < 1
        error('Index exceeds matrix dimensions')
    end
        
else
    % Default samples options
    options.samples = 1:length(data);
end

% Check centroid width options
if ~isempty(find(strcmpi(varargin, 'width'),1))
    options.width = varargin{find(strcmpi(varargin, 'width'),1) + 1};
                    
    % Check user input
    if ~isnumeric(options.width)
        options.width = 0.5;
    elseif options.width < 0.001
        options.width = 0.001;
    elseif options.width > 1
        options.width = 1;
    end
        
else
    % Default centroid width options
    options.width = 0.25;
end

% Calculate centroid data
for i = 1:length(options.samples)
    
    % Centroid data
    mass_values = data(samples(i)).mass_values;
    intensity_values = data(samples(i)).intensity_values;
    
    % Round mass values
    mass_values = round(mass_values / options.width) * options.width;
    
    zeros(length(intensity_values(:,1)), length(mass_values_bin));
    
    for j = 1:length(mass_values_bin)

        % Index mass values within current bin
        index = logical(...
            (mass_values > mass_values_bin(j) - binsize) - ...
            (mass_values > mass_values_bin(j) + binsize));
        
        % Sum mass values within current bin
        if sum(index) > 0
            intensity_values_bin(:,j) = sum(intensity_values(:, index), 2);
        end
    end
    
    % Update intensity values
    data(samples(i)).intensity_values = intensity_values_bin;
    data(samples(i)).mass_values = mass_values_bin;
end

varargout{1} = data;
end