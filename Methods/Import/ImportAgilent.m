% Method: ImportAgilent
%  -Extract data from Agilent (.D, .MS) files
%
% Syntax
%   data = ImportAgilent(file)
%
% Input
%   file : string
%
% Description
%   file : file name with valid extension (.D, .MS)
%
% Examples
%   data = ImportAgilent('MSD1.MS')
%   data = ImportAgilent('Trial1.D')

function varargout = ImportAgilent(varargin)

% Check input
if ~ischar(varargin{1})
    return
end

% Check file extension
[~, file] = fileattrib(varargin{1});
[~, ~, extension] = fileparts(file.Name);

% Read Agilent '.D' files
if strcmp(extension, '.D')

    % Set path and list folder contents
    path(file.Name, path);
    contents = strsplit(ls(file.Name))';

    % Parse folder contents
    files(:,1) = fullfile(file.Name, contents);
    [~, ~, files(:,2)] = cellfun(@fileparts, contents, 'uniformoutput', false);
    
else
    files{1,1} = file.Name;
    files{1,2} = extension;
end

% Load data
for i = 1:length(files(:,1))

    switch files{i,2};
   
        case {'.MS'}
            varargout{1} = AgilentMS(files{i,1});
            return
        
        case {'.CH'}
            return
    
        otherwise
            continue
    end
end
end


% Agilent '.MS'
function varargout = AgilentMS(varargin)

% Open file
file = fopen(varargin{1}, 'r', 'b', 'UTF-8');

% Read sample name
fseek(file, 25, 'bof');
data.sample.name = strtrim(deblank(fread(file, 61, 'char=>char')'));

% Read method name
fseek(file, 229, 'bof');
data.method.name = deblank(fread(file, 19, 'char=>char')');

% Read date/time
fseek(file, 179, 'bof');
datetime = datevec(deblank(fread(file, 20, 'char=>char')'));

data.method.date = strtrim(datestr(datetime, 'mm/dd/yy'));
data.method.time = strtrim(datestr(datetime, 'HH:MM PM'));

% Read starting location
fseek(file, 264, 'bof');
start = fread(file, 1, 'uint') * 2 - 2;

% Read total scans
fseek(file, 278, 'bof');
scans = fread(file, 1, 'uint');

% Pre-allocate memory
data.time = zeros(scans, 1, 'single');
data.tic.values = zeros(scans, 1, 'single');
scan_index = zeros(scans, 3, 'single');
mixed_values = [];

% Read time values and total intensity values
fseek(file, start, 'bof');

for i = 1:scans

    % Determine position
    position = ftell(file) + fread(file, 1, 'ushort') * 2;

    % Read time values
    data.time(i) = fread(file, 1, 'uint') / 60000;

    % Read scan index
    fseek(file, ftell(file) + 6, 'bof');
    scan_index(i, 1) = fread(file, 1, 'ushort') * 2;
    scan_index(i, 2) = ftell(file) + 4;

    % Read total intensity values
    fseek(file, position-4, 'bof');
    data.tic.values(i) = fread(file, 1, 'uint');

    % Read intensity values, mass values
    fseek(file, scan_index(i, 2), 'bof');
    mixed_values(1, end+1:end+scan_index(i, 1)) = fread(file, scan_index(i, 1), 'ushort');
    
    % Reset position
    fseek(file, position, 'bof');
end

% Close file
fclose(file);

% Reshape mixed values (Row 1 = mass_values; Row 2 = intensity_values)
mixed_values = reshape(mixed_values, 2, []);

% Filter mass values
data.mz = unique(mixed_values(1,:)) / 20;

% Filter intensity values
mixed_values(2,:) = bitand(mixed_values(2,:), 16383) .* 8 .^ bitshift(mixed_values(2,:), -14);

% Determine reshaping method
if length(data.mz) == length(mixed_values(2,:)) / length(data.time)

    % Reshape intensity values
    data.xic.values = reshape(mixed_values(2,:), length(data.mz), length(data.time));
    data.xic.values = fliplr(transpose(data.xic.values));

else

    % Determine scan index
    scan_index(:, 3) =  cumsum(scan_index(:, 1)) / 2;

    % Determine column index
    column_index = [circshift(scan_index(:,3) + 1, 1), scan_index(:,3)];
    column_index(1,1) = 1;

    % Max/min mass values
    min_mass = min(mixed_values(1,:));
    max_mass = max(mixed_values(1,:));

    % Pre-allocate memory
    data.xic.values = zeros(length(data.time), max_mass - min_mass + 1, 'single');

    for i = 1:scans

        % Determine column range
        column_range = mixed_values(1, column_index(i,1):column_index(i,2)) - min_mass + 1;

        % Reshape intensity values
        data.xic.values(i, column_range) = mixed_values(2, column_index(i,1):column_index(i,2));
    end

    % Remove blank columns from intensity values
    remove(mixed_values(1,:)) = 1;
    remove(1:min_mass) = [];
    remove = find(remove == 0) + 1;
    data.xic.values(:, remove) = [];
end

% Return data
varargout{1} = data;
end