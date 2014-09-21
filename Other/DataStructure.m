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

function data = DataStructure(varargin)

% Field names
fields = {...
    'id',...
    'file_name',...
    'file_type',...
    'sample_name',...
    'method_name',...
    'experiment_date',...
    'experiment_time',...
    'time_values',...
    'mass_values',...
    'total_intensity_values',...
    'total_intensity_values_baseline',...
    'intensity_values',...
    'intensity_values_baseline',...   
    'processing_time_import',...
    'processing_time_baseline'};

values{length(fields)} = [];
            
% Check number of inputs
if nargin < 2
    % Create an empty data structure
    data = cell2struct(values, fields, 2);
    data(1) = [];

elseif nargin >= 2
    
    % Check input
    data_index = find(strcmp(varargin, 'Validate'));
    
    % Check for empty values
    if ~isempty(data_index)
        data = varargin{data_index + 1};
    else
        return
    end
    
    % Check for missing fields
    missing_fields = fields(~isfield(data, fields));

    % Add missing fields
    if ~isempty(missing_fields)
        for i = 1:length(missing_fields)
            data = setfield(data, {1} , missing_fields{i}, []);
        end
    end
end