% Method: ImportCDF
%  -Extract mass spectrometry data from netCDF (.CDF) files
%
% Syntax:
%   data = ImportCDF(file)
%
% Description:
%   file: name of data file with valid extension (.CDF)
%
% Examples:
%   data = ImportCDF('001-0510.CDF')

function varargout = ImportCDF(varargin)

% Check input
if ischar(varargin{1})
    file = varargin{1};
else
    error('Undefined input arguments of type ''file''');
end

% Read file_name
data.file_name = file;

% Read file information
info = ncinfo(file);

% Check for attributes
if isfield(info, 'Attributes')
    
    % Check for sample name
    if any(strcmpi('experiment_title', {info.Attributes.Name}))
        
        % Read sample name
        data.sample_name = strtrim(ncreadatt(file, '/', 'experiment_title'));
    else
        data.sample_name = '';
    end
    
    % Check for method name
    if any(strcmpi('external_file_ref_0', {info.Attributes.Name}))
        
        % Read method name
        data.method_name = strtrim(ncreadatt(file, '/', 'external_file_ref_0'));
    else
        data.method_name = '';
    end
    
    % Check for experiment data
    if any(strcmpi('experiment_date_time_stamp', {info.Attributes.Name}))
        
        % Read experiment date
        datetime = ncreadatt(file, '/', 'experiment_date_time_stamp');
        date = datenum([str2double(datetime(1:4)), str2double(datetime(5:6)), str2double(datetime(7:8)),...
                        str2double(datetime(9:10)), str2double(datetime(10:11)), str2double(datetime(12:13))]);
        
        data.experiment_date = strtrim(datestr(date, 'mm/dd/yy'));
        data.experiment_time = strtrim(datestr(date, 'HH:MM PM'));
    else
        data.experiment_date = '';
        data.experiment_time = '';
    end
else
    data.sample_name = '';
    data.method_name = '';
    data.experiment_date = '';
    data.experiment_time = '';
end

% Check for variables
if isfield(info, 'Variables')
  
    % Check for time values
    if any(strcmpi('scan_acquisition_time', {info.Variables.Name}))
    
        % Read time_values
        data.time_values = ncread(file, 'scan_acquisition_time') / 60;
    else
        return
    end
    
    % Check for total intensity values
    if any(strcmpi('total_intensity', {info.Variables.Name}))
    
        % Read total intensity values
        data.total_intensity_values = ncread(file, 'total_intensity');
    else
        data.total_intensity_values = [];
    end
        
    % Check for mass values
    if any(strcmpi('mass_values', {info.Variables.Name}))
    
        % Read mass_values
        mass_values = ncread(file, 'mass_values');
    else
        return
    end
        
    % Check for intensity values
    if any(strcmpi('intensity_values', {info.Variables.Name}))
    
        % Read intensity_values
        intensity_values = ncread(file, 'intensity_values');
    else
        return
    end
    
else
    return
end
        
% Reshape data (rows = time, columns = m/z) 
if length(mass_values) == length(intensity_values) / length(data.time_values)
    
    % Reshape mass values
    data.mass_values = transpose(unique(mass_values));
    
    % Reshape intensity values
    data.intensity_values = reshape(intensity_values, length(data.mass_values), length(data.time_values));
    data.intensity_values = transpose(data.intensity_values);
else
    
    % Reshape mass values
    data.mass_values = transpose(unique(mass_values));
    
    % Read scan_index
    scan_index = double(ncread(file, 'scan_index'));
    scan_index(:,2) = circshift(scan_index, [-1,0]);
    scan_index(:,1) = scan_index(:,1) + 1;
    scan_index(end,2) = length(mass_values);
   
    % Pre-allocate memory
    data.intensity_values = zeros(length(data.time_values), length(data.mass_values), 'single');
    
    for i = 1:length(scan_index(:,1))-1
        
        % Determine row index of current frame
        frame = scan_index(i,1):scan_index(i,2);
        offset = scan_index(i,1) - 1;
        
        % Determine column index of current frame
        [~, row_index, column_index] = intersect(mass_values(frame), data.mass_values);
        
        % Reshape intensity_values
        data.intensity_values(i, column_index) = intensity_values(row_index + offset);
    end
end

varargout{1} = data;
end