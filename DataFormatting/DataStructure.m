% Method: DataStructure
% Description: Create or validate a chromatography data structure 
%
% Syntax:
%   data = DataStructure('OptionName', optionvalue...)
%
%   Options:
%       Validate : data
%
% Examples:
%   data = DataStructure()
%   data = DataStructure('Validate', data)

function varargout = DataStructure(varargin)

% Field names
basic_fields = {...
    'id',...
    'file_name',...
    'file_type',...
    'sample_name',...
    'method_name',...
    'experiment_date',...
    'experiment_time'...
    'time_values',...
    'mass_values',...
    'mass_values_id',...
    'total_intensity_values',...
    'total_intensity_values_baseline',...
    'total_intensity_values_peaks',...
    'intensity_values',...
    'intensity_values_baseline',...
    'intensity_values_peaks',...
    'diagnostics'
    };

peak_fields = {...
    'peak_time',...
    'peak_width',...
    'peak_height',...
    'peak_area',...
    'peak_fit',...
    'peak_fit_residuals',...
    'peak_fit_error',...
    'peak_fit_options'...
    };

diagnostic_fields = {...
    'processing_time_import',...
    'processing_time_baseline',...
    'processing_time_peaks'...
    };

% Check number of inputs
if nargin < 2
    
    % Create an empty data structure
    values{length(basic_fields)} = [];
    varargout{1} = cell2struct(values, basic_fields, 2);
    
    % Clear first line
    varargout{1}(1) = [];

elseif nargin >= 2
    
    % Check input
    data_index = find(strcmp(varargin, 'Validate'));
    
    % Check for empty values
    if ~isempty(data_index)
        data = varargin{data_index + 1};
    else
        return
    end
    
    % Check for basic fields
    data = check(data, basic_fields);
    
    % Check for peak fields
    for i = 1:length(data)
        data(i).total_intensity_values_peaks = check(data(i).total_intensity_values_peaks, peak_fields);
        data(i).intensity_values_peaks = check(data(i).intensity_values_peaks, peak_fields);
    end
    
    % Check for processing time fields
    for i = 1:length(data)
        data(i).diagnostics = check(data(i).diagnostics, diagnostic_fields);
    end
    
    varargout{1} = data;
end
end

% Validate structure
function varargout = check(structure, fields)

% Check structure input
if ~isstruct(structure)
    structure = [];
end

% Check fields input
if ~iscell(fields)
    return
end

% Check for empty structure
if isempty(structure)
    
    values{length(fields)} = [];
    structure = cell2struct(values, fields, 2);
    
% Check for missing fields
else
    missing_fields = ~isfield(structure, fields);
    missing_fields = fields(missing_fields);
            
    % Add missing peak fields to structure
    if ~isempty(missing_fields)
        for i = 1:length(missing_fields)
            structure = setfield(structure, {1}, missing_fields{i}, []);
        end
    end
end

% Output modified structure
varargout{1} = structure;
end