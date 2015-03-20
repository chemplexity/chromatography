% Method: ImportAgilent
%  -Extract raw data from Agilent (.D, .MS) files
%
% Syntax
%   data = ImportAgilent(file)
%   data = ImportAgilent(file, 'OptionName', optionvalue...)
%
% Input
%   file        : string
%
% Options
%   'precision' : integer
%
% Description
%   file        : file name with valid extension (.D, .MS)
%   'precision' : number of decimal places allowed for m/z values (default = 3)
%
% Examples
%   data = ImportAgilent('MSD1.MS')
%   data = ImportAgilent('Trial1.D', 'precision', 2)
%
% Compatibility
%   Agilent, LC/MS
%       6100 Series Single Quadrupole LC/MS
%   Agilent, GC/MS
%       5970 Series GC/MSD

function varargout = ImportAgilent(varargin)

% Check input
[files, options] = parse(varargin);

% Check file name
if isempty(files)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Load data
for i = 1:length(files(:,1))
    
    switch files{i,2};
        
        case {'.MS', '.ms'}
            data{i} = AgilentMS(files{i,1}, options);
            
        case {'.CH'}
            data{i} = [];
            
        otherwise
            data{i} = [];
    end
end

% Remove missing data
data(cellfun(@isempty, data)) = [];

% Output
if ~isempty(data)
    varargout(1) = {[data{:}]};
else
    varargout{1} = [];
end
end

% Agilent '.MS'
function varargout = AgilentMS(varargin)

% Variables
file = varargin{1};
options = varargin{2};

% Open file
file = fopen(file, 'r', 'b', 'UTF-8');

% Read sample name
fseek(file, 25, 'bof');
data.sample.name = strtrim(deblank(fread(file, 61, 'char=>char')'));

% Read method name
fseek(file, 229, 'bof');
data.method.name = deblank(fread(file, 19, 'char=>char')');

% Read instrument name
fseek(file, 209, 'bof');
data.method.instrument = deblank(fread(file, 9, 'char=>char')');
data.method.instrument = ['Agilent ', data.method.instrument];

% Read date/time
fseek(file, 179, 'bof');
datetime = datevec(deblank(fread(file, 20, 'char=>char')'));

data.method.date = strtrim(datestr(datetime, 'mm/dd/yy'));
data.method.time = strtrim(datestr(datetime, 'HH:MM PM'));

% Read directory offset
fseek(file, 260, 'bof');
offset.tic = fread(file, 1, 'int') .* 2 - 2;

% Read number of scans
fseek(file, 278, 'bof');
scans = fread(file, 1, 'uint');

% Pre-allocate memory
data.time = zeros(scans, 1, 'single');
data.tic.values = zeros(scans, 1, 'single');
offset.xic = zeros(scans, 1, 'single');

% Read data offset
fseek(file, offset.tic, 'bof');
offset.xic = fread(file, scans, 'int', 8);
offset.xic = (offset.xic .* 2) - 2;

% Read time values
fseek(file, offset.tic+4, 'bof');
data.time = fread(file, scans, 'int', 8) ./ 60000;

% Read total intensity values
fseek(file, offset.tic+8, 'bof');
data.tic.values = fread(file, scans, 'int', 8);

% Variables
mz = [];
xic = [];

for i = 1:scans
    
    % Read scan size
    fseek(file, offset.xic(i,1), 'bof');
    n = fread(file, 1, 'short') - 18;
    n = (n/2) + 2;
    
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

% Convert intensity values to abundance (mantissa and exponent)
xic = bitand(xic, 16383, 'int16') .* (8 .^ bitshift(xic, -14, 'int16'));

% Convert mass values to m/z (20-bit ADC)
mz = mz ./ 20;

% Limit precision of mass values
mz = round(mz .* 10^options.precision) ./ 10^options.precision;
data.mz = unique(mz, 'sorted');

% Reshape vector to matrix (rows = time, columns = m/z)
if length(data.mz) == length(xic) / length(data.time)
    
    % Reshape intensity values
    data.xic.values = reshape(xic, length(data.mz), length(data.time))';
else
    
    % Determine data index
    index.end = cumsum(offset.xic(:,2));
    index.start = circshift(index.end,[1,0]);
    index.start = index.start + 1;
    index.start(1,1) = 1;
    
    % Pre-allocate memory
    data.xic.values = zeros(length(data.time), length(data.mz), 'single');
    
    % Determine column index for reshaping
    [~, column_index] = ismember(mz, data.mz);
    
    for i = 1:scans
        
        % Variables
        m = index.start(i);
        n = index.end(i);
        
        % Reshape instensity values
        data.xic.values(i, column_index(m:n)) = xic(m:n);
    end
end

% Check values
if isempty(data.sample.name)
    name = varargin{1};
    
    % Remove path from sample name
    if any('\' == name)
        data.sample.name = name(find(name == '\', 1, 'last')+1:end);
    elseif any('/' == name)
        data.sample.name = name(find(name == '/', 1, 'last')+1:end);
    else
        data.sample.name = name;
    end
end

% Output data
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
[~, file] = fileattrib(file);

% Check file exists
if strcmpi(file, 'No such file or directory.')
    error('Undefined input arguments of type ''file''.');
end

[~, ~, extension] = fileparts(file.Name);

% Read Agilent '.D' files
if strcmpi(extension, '.D')
    
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

varargout{1} = files;
varargout{2} = options;
end