% Method: ImportCDF
%  -Extract LC/MS data from netCDF (.CDF) files
%
% Syntax:
%   data = ImportCDF(file)
%
% Description:
%   file: name of data file with valid extension (.CDF)
%
% Examples:
%   data = ImportCDF('001-0510.CDF')

function data = ImportCDF(file)

% Read file_name, file_path
data.file_name = file;

% Read sample_name
data.sample_name = '';

% Read method_name
data.method_name = '';

% Read experiment_date, experiment_time
datetime = ncreadatt(file, '/', 'experiment_date_time_stamp');
datetime = datenum([str2double(datetime(1:4)), str2double(datetime(5:6)), str2double(datetime(7:8))]);

data.experiment_date = datestr(datetime, 'mm/dd/yy');
data.experiment_time = '';

% Read time_values
data.time_values = ncread(file, 'scan_acquisition_time') / 60;

% Read total_intensity_values
data.total_intensity_values = ncread(file, 'total_intensity');

% Read mass_values
mass_values = roundn(ncread(file, 'mass_values'), -1);
data.mass_values = unique(mass_values);

% Read intensity_values
intensity_values = ncread(file, 'intensity_values');

% Determine optimal reshaping method
if length(data.mass_values) == length(intensity_values) / length(data.time_values)
    
    % Reshape intensity_values
    data.intensity_values = reshape(intensity_values, length(data.mass_values), length(data.time_values));
    data.intensity_values = transpose(data.intensity_values);

else
    
    % Read scan_index
    scan_index = ncread(file, 'scan_index');
    scan_index(1) = [];
    scan_index(end+1) = length(mass_values);
    
    % Determine max/min mass_values
    mass_values = mass_values * 10;
    max_mass = max(mass_values);
    min_mass = min(mass_values);
    
    % Pre-allocate memory
    data.intensity_values = zeros(length(data.time_values), max_mass-min_mass, 'single');
    
    for i = 2:length(scan_index)
        
        % Determine column_range, column_index
        column_range = [scan_index(i-1), scan_index(i)];
        column_index = mass_values(column_range(1):column_range(2)) - min_mass + 1;
        
        % Reshape intensity_values
        data.intensity_values(i, column_index) = intensity_values(column_range(1):column_range(2));
    end
    
    % Determine which columns contain no data
    del_col(mass_values) = 1;
    del_col(1:min_mass) = [];
    del_col = find(del_col == 0) + 1;
    data.intensity_values(:, del_col) = [];
end
end