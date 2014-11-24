% Method: ImportAgilent
%  -Extract LC/MS data from Agilent (.D, .MS) files
%
% Syntax:
%   data = ImportAgilent(file)
%
% Description:
%   file: name of data file with valid extension (.D, .MS)
%
% Examples:
%   data = ImportAgilent('MSD1.MS')
%   data = ImportAgilent('Trial1.D')

function data = ImportAgilent(file)

% Check input
if ~ischar(file)
    error('Input must be a string')
end

% Read file_name
data.file_name = file;

% Check file extension
[~, file] = fileattrib(data.file_name);
[~, ~, extension] = fileparts(file.Name);

% Read .MS files
if strcmp(extension, '.MS')
    file = file.Name;

% Read .D files
elseif strcmp(extension, '.D')
    
    % Set folder path
    path(file.Name, path);
    
    % List folder contents
    foldercontents = ls(file.Name);
    
    % Format folder contents
    if length(foldercontents(:,1)) == 1 || length(foldercontents(1,:)) == 1
        foldercontents = strsplit(foldercontents);
    else
        foldercontents = cellstr(foldercontents);
    end
    
    % Check for any input
    if ~length([foldercontents{:}]) > 0
        error('Data not found')
    end
            
    % Parse folder contents
    for i = 1:length(foldercontents)
                
        % List all files
        [files{i,1}, files{i,2}, files{i,3}] = ...
            fileparts(fullfile(file.Name, foldercontents{i}));

        % List all paths
        files{i,4} = fullfile(file.Name, foldercontents{i});
    end
    
    % Remove entries with incorrect filetype
    files(~strcmp(files(:,3), '.MS'), :) = [];
    
    % Check for any input
    if isempty(files{1,3})
        error('Data not found')
    end
            
    % Output data file
    file = files{1,4};

% Incorrect file extension
else
    error('Incorrect file extension');
end

% Open file
file = fopen(file);

% Read sample_name
fseek(file, hex2dec('29'), 'bof');
data.sample_name = deblank(transpose(fread(file, 45, 'uint8=>char')));

% Read method_name
fseek(file, hex2dec('E5'), 'bof');
data.method_name = deblank(transpose(fread(file, 20, 'uint8=>char')));

% Read experiment_date, experiment_time
fseek(file, hex2dec('B3'), 'bof');
datetime = datevec(deblank(transpose(fread(file, 20, 'uint8=>char'))));

data.experiment_date = datestr(datetime, 'mm/dd/yy');
data.experiment_time = strtrim(datestr(datetime, 'HH:MM PM'));

% Read number of scans
fseek(file, hex2dec('118'), 'bof');
scans = fread(file, 1, 'ushort', 0, 'b');

% Read starting location
fseek(file, hex2dec('10A'), 'bof');
start = fread(file, 1, 'ushort', 0, 'b') * 2 - 2;

% Pre-allocate memory
data.time_values = zeros(scans, 1, 'single');
data.total_intensity_values = zeros(scans, 1, 'single');
scan_index = zeros(scans, 3, 'single');
mixed_values = [];

% Read time_values, total_intensity_values
fseek(file, start, 'bof');

% Read data
for i = 1:scans
    
    % Determine position
    position = ftell(file) + fread(file, 1, 'ushort', 0, 'b') * 2;
    
    % Read time_values
    data.time_values(i) = fread(file, 1, 'uint', 0, 'b') / 60000;
    
    % Read scan_index
    fseek(file, ftell(file) + 6, 'bof');
    scan_index(i, 1) = fread(file, 1, 'ushort', 0, 'b') * 2;
    scan_index(i, 2) = ftell(file) + 4;
    
    % Read total_intensity_values
    fseek(file, position - 4, 'bof');
    data.total_intensity_values(i) = fread(file, 1, 'uint', 0, 'b');
    
    % Read intensity_values, mass_values
    fseek(file, scan_index(i, 2), 'bof');
    mixed_values(1, end+1:end+scan_index(i, 1)) = ...
        fread(file, scan_index(i, 1), 'ushort', 0, 'b');
    
    % Reset position
    fseek(file, position, 'bof');
end

% Close file
fclose(file);

% Reshape mixed_values (Row 1 = mass_values; Row 2 = intensity_values)
mixed_values = reshape(mixed_values, 2, []);

% Filter mass_values
data.mass_values = unique(mixed_values(1,:)) / 20;

% Filter intensity_values
mixed_values(2,:) = bitand(mixed_values(2,:),16383) .* 8 .^ bitshift(mixed_values(2,:),-14);

% Determine optimal reshaping method
if length(data.mass_values) == length(mixed_values(2,:)) / length(data.time_values)
    
    % Reshape intensity_values
    data.intensity_values = reshape(mixed_values(2,:), length(data.mass_values), length(data.time_values));
    data.intensity_values = fliplr(transpose(data.intensity_values));
    
else
    
    % Determine scan_index
    scan_index(:, 3) =  cumsum(scan_index(:, 1)) / 2;
    
    % Determine column_index
    column_index = [circshift(scan_index(:,3) + 1, 1), scan_index(:,3)];
    column_index(1,1) = 1;
    
    % Max/min mass_values
    max_mass = max(mixed_values(1,:));
    min_mass = min(mixed_values(1,:));
    
    % Pre-allocate memory
    data.intensity_values = zeros(length(data.time_values), max_mass - min_mass + 1, 'single');
    
    for i = 1:scans
        
        % Determine column_range
        column_range = mixed_values(1, column_index(i,1):column_index(i,2)) - min_mass+1;
        
        % Reshape intensity_values
        data.intensity_values(i, column_range) = mixed_values(2, column_index(i,1):column_index(i,2));
    end
    
    % Remove blank columns from intensity_values
    del_col(mixed_values(1,:)) = 1;
    del_col(1:min_mass) = [];
    del_col = find(del_col == 0) + 1;
    data.intensity_values(:, del_col) = [];
end
end