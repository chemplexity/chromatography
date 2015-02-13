% Method: ImportCDF
%  -Extract data from netCDF (.CDF) files
%
% Syntax:
%   data = ImportCDF(file)
%
% Input
%   file : string
%
% Description
%   file : file name with valid extension (.CDF)
%
% Examples:
%   data = ImportCDF('001-0510.CDF')

function varargout = ImportCDF(varargin)

% Check input
if ~ischar(varargin{1})
    return
end

% Check extension
[~, file_name, extension] = fileparts(varargin{1});

if strcmpi(extension, '.CDF')
    file = varargin{1};
else
    return
end

% Read file information
info = ncinfo(file);

% Check for attributes
if isfield(info, 'Attributes')

    % Check for sample name
    if any(strcmpi('experiment_title', {info.Attributes.Name}))

        % Read sample name
        data.sample.name = strtrim(ncreadatt(file, '/', 'experiment_title'));
        
        if isempty(data.sample.name)
            data.sample.name = file_name;
        end
    else
        data.sample.name = '';
    end

    % Check for method name
    if any(strcmpi('external_file_ref_0', {info.Attributes.Name}))

        % Read method name
        data.method.name = strtrim(ncreadatt(file, '/', 'external_file_ref_0'));

        if strcmpi(data.method.name, 'DB5PWF30')
            data.method.name = '';
        end
    end
    
    % Check for experiment data
    if any(strcmpi('experiment_date_time_stamp', {info.Attributes.Name}))
        
        % Read experiment date
        datetime = ncreadatt(file, '/', 'experiment_date_time_stamp');
        date = datenum([str2double(datetime(1:4)), str2double(datetime(5:6)), str2double(datetime(7:8)),...
                        str2double(datetime(9:10)), str2double(datetime(10:11)), str2double(datetime(12:13))]);

        data.method.date = strtrim(datestr(date, 'mm/dd/yy'));
        data.method.time = strtrim(datestr(date, 'HH:MM PM'));
    else
        data.method.date = '';
        data.method.time = '';
    end
else
    data.sample.name = '';
    data.method_name = '';
    data.method.date = '';
    data.method.time = '';
end

% Check for variables
if isfield(info, 'Variables')
  
    % Check for time values
    if any(strcmpi('scan_acquisition_time', {info.Variables.Name}))
    
        % Read time values
        data.time = ncread(file, 'scan_acquisition_time') / 60;
    else
        return
    end
    
    % Check for total intensity values
    if any(strcmpi('total_intensity', {info.Variables.Name}))
    
        % Read total intensity values
        data.tic.values = ncread(file, 'total_intensity');
    else
        data.tic.values = [];
    end
        
    % Check for mass values
    if any(strcmpi('mass_values', {info.Variables.Name}))
    
        % Read mass values
        mz = ncread(file, 'mass_values');
    else
        return
    end
        
    % Check for intensity values
    if any(strcmpi('intensity_values', {info.Variables.Name}))
    
        % Read intensity values
        xic = ncread(file, 'intensity_values');
    else
        return
    end
    
else
    return
end
        
% Reshape data (rows = time, columns = m/z) 
if length(mz) == length(xic) / length(data.time)
    
    % Reshape mass values
    data.mz = transpose(unique(mz));
    
    % Reshape intensity values
    data.xic.values = reshape(xic, length(data.mz), length(data.time));
    data.xic.values = transpose(data.xic.values);
else
    
    % Reshape mass values
    data.mz = transpose(unique(mz));
    
    % Read scan index
    scan_index = double(ncread(file, 'scan_index'));
    scan_index(:,2) = circshift(scan_index, [-1,0]);
    scan_index(:,1) = scan_index(:,1) + 1;
    scan_index(end,2) = length(mz);
   
    % Pre-allocate memory
    data.xic.values = zeros(length(data.time), length(data.mz), 'single');
    
    for i = 1:length(scan_index(:,1))
        
        % Determine row index of current frame
        frame = scan_index(i,1):scan_index(i,2);
        offset = scan_index(i,1) - 1;
        
        % Determine column index of current frame
        [~, row_index, column_index] = intersect(mz(frame), data.mz);
        
        % Reshape intensity values
        data.xic.values(i, column_index) = xic(row_index + offset);
    end
end

varargout{1} = data;
end