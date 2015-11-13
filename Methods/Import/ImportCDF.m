% ------------------------------------------------------------------------
% Method      : ImportCDF
% Description : Import data stored in netCDF (.CDF) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportCDF(file)
%   data = ImportCDF(file, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   file (required)
%       Description : name of netCDF file
%       Type        : string
%
%   'precision' (optional)
%       Description : maximum decimal places for m/z values
%       Type        : number
%       Default     : 3
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportCDF('001-0510.CDF')
%   data = ImportCDF('002-23.CDF', 'precision', 2)
%

function varargout = ImportCDF(varargin)

% Check input
[file, options] = parse(varargin);

% Check file name
if isempty(file)
    
    varargout{1} = [];
    
    disp('[ERROR] Input file invalid....');
    return
end

% Read file information
info = ncinfo(file);

% Check for attributes
if isfield(info, 'Attributes')
    
    % Sample name
    data.sample.name = '';
    
    if any(strcmpi('experiment_title', {info.Attributes.Name}))
        data.sample.name = strtrim(ncreadatt(file, '/', 'experiment_title'));
    end
    
    % Operator name
    data.method.operator = '';
    
    if any(strcmpi('operator_name', {info.Attributes.Name}))
        data.method.operator = strtrim(ncreadatt(file, '/', 'operator_name'));
    end
    
    % Method name
    data.method.name = '';
    
    if any(strcmpi('external_file_ref_0', {info.Attributes.Name}))
        data.method.name = strtrim(ncreadatt(file, '/', 'external_file_ref_0'));
        
        if strcmpi(data.method.name, 'DB5PWF30')
            data.method.name = '';
        end
    end
    
    % Date/Time
    data.method.date = '';
    data.method.time = '';
    
    if any(strcmpi('experiment_date_time_stamp', {info.Attributes.Name}))
        datetime = ncreadatt(file, '/', 'experiment_date_time_stamp');
        
        try
            date = datenum([str2double(datetime(1:4)), str2double(datetime(5:6)), str2double(datetime(7:8)),...
                str2double(datetime(9:10)), str2double(datetime(10:11)), str2double(datetime(12:13))]);
            
            data.method.date = strtrim(datestr(date, 'mm/dd/yy'));
            data.method.time = strtrim(datestr(date, 'HH:MM PM'));
        catch
        end
    end
    
    % Instrument type
    data.method.instrument = '';
    
else
    data.sample.name = '';
    data.method.name = '';
    data.method.operator = '';
    data.method.instrument = '';
    data.method.date = '';
    data.method.time = '';
end

% Check sample name
if isempty(data.sample.name)
    [~, name] = fileparts(file);
else
    name = data.sample.name;
end

% Remove path from sample name
if any('\' == name)
    data.sample.name = name(find(name == '\', 1, 'last')+1:end);
    
elseif any('/' == name)
    data.sample.name = name(find(name == '/', 1, 'last')+1:end);
    
else
    data.sample.name = name;
end

% Data
data.time = [];
data.tic.values = [];
data.mz = [];
data.xic.values = [];

% Check for variables
if isfield(info, 'Variables')
    
    % Check for time values
    if any(strcmpi('scan_acquisition_time', {info.Variables.Name}))
        data.time = ncread(file, 'scan_acquisition_time') ./ 60;
    end
    
    % Check for total intensity values
    if any(strcmpi('total_intensity', {info.Variables.Name}))
        data.tic.values = ncread(file, 'total_intensity');
    end
    
    % Check for total intensity values (legacy)
    if any(strcmpi('global_intensity_max', {info.Variables.Name})) && isempty(data.tic.values)
        data.tic.values = ncread(file, 'global_intensity_max');
    end
    
    % Check for mass values
    if any(strcmpi('mass_values', {info.Variables.Name}))
        data.mz = ncread(file, 'mass_values');
    end
    
    % Check for intensity values
    if any(strcmpi('intensity_values', {info.Variables.Name}))
        data.xic.values = ncread(file, 'intensity_values');
    end
end

% Check data
if isempty(data.xic.values) && isempty(data.tic.values)
    varargout{1} = [];
    return
    
elseif isempty(data.xic.values)
    varargout{1} = data;
    return
end

% Variables
precision = options.precision;

% Determine precision of mass values
mz = round(data.mz .* 10^precision) ./ 10^precision;
data.mz = unique(mz, 'sorted');

% Reshape data (rows = time, columns = m/z)
if length(data.mz) == length(data.xic.values) / length(data.time)
    
    % Reshape intensity values
    data.xic.values = reshape(data.xic.values, length(data.mz), length(data.time))';
    data.mz = data.mz';
    
else
    
    % Determine data index
    index.start = double(ncread(file, 'scan_index'));
    index.end = circshift(index.start, [-1,0]);
    index.start(:,1) = index.start(:,1) + 1;
    index.end(end,2) = length(mz);
    
    % Pre-allocate memory
    xic = zeros(length(data.time), length(data.mz), 'single');
    
    % Determine column index for reshaping
    [~, column_index] = ismember(mz, data.mz);
    
    for i = 1:length(data.time)
        
        % Variables
        m = index.start(i);
        n = index.end(i);
        
        % Reshape instensity values
        xic(i, column_index(m:n)) = data.xic.values(m:n);
    end
    
    % Output data
    data.mz = data.mz';
    data.xic.values = xic;
end

varargout{1} = data;

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1 || ~ischar(varargin{1})
    error('Undefined input arguments of type ''file''.');
    
elseif ischar(varargin{1})
    file = varargin{1};
    
else
    varargout{2} = [];
    return
end

% Check file extension
[~, ~, extension] = fileparts(file);

if ~strcmpi(extension, '.CDF')
    varargout{2} = [];
    return
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Precision
if ~isempty(input('precision'))
    precision = varargin{input('precision')+1};
    
    % Check for valid input
    if ~isnumeric(precision)
        options.precision = 3;
        
    elseif precision < 0
        
        % Check for case: -x
        if precision >= -9 && precision <= 0
            options.precision = abs(precision);
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    elseif precision > 0 && log10(precision) < 0
        
        % Check for case: 10^-x
        if log10(precision) >= -9 && log10(precision) <= 0
            options.precision = abs(log10(precision));
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    elseif precision > 9
        
        % Check for case: 10^x
        if log10(precision) <= 9 && log10(precision) >= 0
            options.precision = log10(precision);
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    else
        options.precision = precision;
    end
    
else
    options.precision = 3;
end

varargout{1} = file;
varargout{2} = options;

end