% Method: DataBinning
% Description: LC/MS data binning of full scan spectra
%
% Syntax:
%   data = DataBinning(data, 'OptionName', optionvalue...)
%
%   Options:
%       Samples : 'all', [sampleindex]
%       BinSize : binsize
%
% Examples:
%   data = DataBinning(data)
%   data = DataBinning(data, 'Samples', [1:6, 9, 12])
%   data = DataBinning(data, 'BinSize', 0.5)
%   data = DataBinning(data, 'Samples', 'all', 'BinSize', 0.25)

function varargout = DataBinning(data, varargin)

% Check number of inputs
if nargin < 2
    
    % Check data
    if isstruct(data)
        data = DataStructure('Validate', data);
    else
        return
    end
    
    % Default options
    samples = 1:length(data);
    binsize = 0.50;
    
elseif nargin > 2

    % Check options
    samples_index = find(strcmp(varargin, 'Samples'));
    binsize_index = find(strcmp(varargin, 'BinSize'));
           
     % Check samples options
    if ~isempty(samples_index)
        samples = varargin{samples_index + 1};
    else
        samples = 1:length(data);
    end
    
    % Check bin size options
    if ~isempty(binsize_index)
        binsize = varargin{binsize_index + 1};
    else
        binsize = 0.50;
    end
    
    % Check sample values
    if strcmp(samples, 'all')
        samples = 1:length(data);
        
    % Check for invalid index values
    elseif any(samples > length(data))
        samples = samples(samples < length(data));
    end 
end

% Bin intensity values
for i = 1:length(samples)
    
    % Bin data
    mass_values = data(samples(i)).mass_values;
    intensity_values = data(samples(i)).intensity_values;
    
    % Round mass values
    mass_values_bin = unique(round(mass_values / 1.0) * 1.0);
    intensity_values_bin = zeros(length(intensity_values(:,1)), length(mass_values_bin));
    
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