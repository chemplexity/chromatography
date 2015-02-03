% Method: DataStructure
%  -Create or validate a chromatography data structure 
%
% Syntax
%   data = DataStructure('OptionName', optionvalue...)
%
% Options
%   'validate' : structure
%
% Description
%   'validate' : check data structure for missing fields
% 
% Examples
%   data = DataStructure()
%   data = DataStructure('validate', data)

function data = DataStructure(varargin)

% Field names
basic = {...
    'id',...
    'file_name',...
    'file_type',...
    'sample_name',...
    'method_name',...
    'experiment_date',...
    'experiment_time'...
    'time_values',...
    'mass_values',...
    'total_intensity_values',...
    'total_intensity_values_baseline',...
    'total_intensity_values_peaks',...
    'intensity_values',...
    'intensity_values_baseline',...
    'intensity_values_peaks',...
    'diagnostics',...
    'statistics'};

peaks = {...
    'time',...
    'height',...
    'width',...
    'a',...
    'b',...
    'area',...
    'fit',...
    'error'};

diagnostics = {...
    'system_os',...
    'system_date',...
    'matlab_version',...
    'toolbox_version'};

statistics = {...
    'compute_time',...
    'function',...
    'calls'};

% Check number of inputs
if nargin < 2
    
    % Create an empty data structure
    data = cell2struct(cell(1,length(basic)), basic, 2);
    
    % Clear first line
    data(1) = [];

elseif nargin >= 2
    
    % Check for validate options
    if ~isempty(find(strcmpi(varargin, 'validate'),1))
        data = varargin{find(strcmpi(varargin, 'validate'),1)+1};
    else
        return
    end
    
    % Check basic fields
    data = check(data, basic);
    
    % Check nested fields
    for i = 1:length(data)
        data(i).total_intensity_values_peaks = check(data(i).total_intensity_values_peaks, peaks);
        data(i).intensity_values_peaks = check(data(i).intensity_values_peaks, peaks);
        data(i).diagnostics = check(data(i).diagnostics, diagnostics);
        data(i).statistics = check(data(i).statistics, statistics);
    end
end
end

% Validate structure
function structure = check(structure, fields)

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
    structure = cell2struct(cell(1,length(fields)), fields, 2);
    
% Check for missing fields
elseif ~isempty(~isfield(structure, fields))
    missing = fields(~isfield(structure, fields));
            
    % Add missing peak fields to structure
    if ~isempty(missing)
        for i = 1:length(missing)
            structure = setfield(structure, {1}, missing{i}, []);
        end
    end
end
end