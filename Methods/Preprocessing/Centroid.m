% Method: Centroid
%  -Centroid raw mass spectrometer data
%
% Syntax
%   Centroid(x, y)
%   Centroid(x, y, 'OptionName', optionvalue...)
%
% Input
%   x       : array
%   y       : array or matrix
%
% Options
%   'width' : 0.001 to 1
%
% Description
%   x       : array with mass values
%   y       : array or matrix with intensity values
%   'width' : desired m/z width of centroid filter
%
% Examples
%   Centroid(x, y)
%   Centroid(x, y, 'width', 0.1)

function varargout = Centroid(x, y, varargin)

% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
elseif ~isnumeric(x)
    error('Undefined input arguments of type ''x''');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
elseif length(x(:,1)) > 1 && length(x(1,:)) > 1
    error('Undefined input arguments of type ''x''');
elseif length(x(:,1)) ~= length(y(:,1)) && length(x(1,:)) ~= length(y(1,:))
    error('Input arguments of unequal length');
end
   
% Check input precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end
   
% Check mass resolution
options.resolution = (max(x) - min(x)) / length(x);

% Predict data type
if options.resolution > 1
    options.type = 'sim';
elseif options.resolution <= 1
    options.type = 'full';
end
    
% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check width options
if ~isempty(input('width'))
    options.width = varargin{input('width') + 1};
                    
    % Check user input
    if ~isnumeric(options.width)
        options.width = options.resolution * 2;
    elseif options.width <= options.resolution
        error('Invalid input arguments of type ''width''');
    elseif options.width > (max(x) - min(x)) / 2;
        error('Invalid input arguments of type ''width''');
    end
else
    options.width = options.resolution * 2;
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