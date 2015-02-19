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

    % Set path
    path(file.Name, path);
    
    % Determine OS and parse file names
    if ispc
        contents = cellstr(ls(file.Name));
        contents(strcmp(contents, '.') | strcmp(contents, '..')) = [];
    elseif isunix
        contents = strsplit(ls(file.Name))';
        contents(cellfun(@isempty, contents)) = [];
    end
    
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
            varargout{1} = [];
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

% Read directory offset
fseek(file, 260, 'bof');
offset.tic = fread(file, 1, 'int') * 2 - 2;

% Read number of scans
fseek(file, 278, 'bof');
scans = fread(file, 1, 'uint');

% Pre-allocate memory
data.time = zeros(scans, 1, 'single');
data.tic.values = zeros(scans, 1, 'single');
offset.xic = zeros(scans, 1, 'single');

% Read data offset
fseek(file, offset.tic, 'bof');
offset.xic = fread(file, scans, 'int', 8) * 2 - 2;

% Read time values
fseek(file, offset.tic+4, 'bof');
data.time = fread(file, scans, 'int', 8) / 60000;

% Read total intensity values
fseek(file, offset.tic+8, 'bof');
data.tic.values = fread(file, scans, 'int', 8);

% Variables
xic = [];
mz = [];

for i = 1:scans

    % Read scan size
    fseek(file, offset.xic(i,1), 'bof');
    n = (fread(file, 1, 'short') - 18) / 2;

    % Read mass values
    fseek(file, offset.xic(i,1)+18, 'bof');
    mz(end+1:end+n) = fread(file, n, 'ushort', 2);
    
    % Read intensity values
    fseek(file, offset.xic(i,1)+20, 'bof');
    xic(end+1:end+n) = fread(file, n, 'short', 2);
    
    % Variables
    offset.xic(i,2) = n;
end

% Close file
fclose(file);

% Format mass values
mz = mz / 20;
data.mz = unique(mz);

% Determine data index
index.end = cumsum(offset.xic(:,2));
index.start = circshift(index.end,[1,0]);
index.start = index.start + 1;
index.start(1,1) = 1;

% Pre-allocate memory
data.xic.values = zeros(length(data.time), length(data.mz), 'single');

for i = 1:scans
    
    % Determine row index of current frame
    frame = index.start(i):index.end(i);
    offset = index.start(i) - 1;
    
    % Determine column index of current frame
    [~, row_index, column_index] = intersect(mz(frame), data.mz);
    
    % Reshape intensity values
    data.xic.values(i, column_index) = xic(row_index + offset);
end

% Return data
varargout{1} = data;
end