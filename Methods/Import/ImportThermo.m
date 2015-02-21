% Method: ImportThermo
%  -Extract data from Thermo (.RAW) files
%
% Syntax
%   data = ImportThermo(file)
%   data = ImportThermo(file, 'OptionName', optionvalue...)
%
% Input
%   file        : string
%
% Options
%   'precision' : integer
%
% Description
%   file        : file name with valid extension (.RAW)
%   'precision' : number of decimal places allowed for m/z values (default = 3)
%
% Examples
%   data = ImportThermo('001-32-2.RAW')
%   data = ImportThermo('06b.RAW', 'precision', 4)

function varargout = ImportThermo(varargin)

% Check input
[file, data] = parse(varargin);

% Open file
file.name = fopen(file.name, 'r', 'l', 'UTF-8');

% Read file
[file, data] = FileHeader(file, data);
[file, data] = InjectionData(file, data);
[file, data] = SequenceData(file, data);
[file, data] = AutosamplerData(file, data);
[file, data] = FileInfo(file, data);
[file, data] = RunHeader(file, data);
[file, data] = ScanInfo(file, data);
[file, data] = ScanData(file, data);
    
% Close file
fclose(file.name);

% Format data
[file, data] = FormatData(file, data);

% Output data
varargout{1} = data;
varargout{2} = file;
end


function [file, data] = FileHeader(file, data)

% Read address
file.address.file_header = ftell(file.name);

% Read version
fseek(file.name, 36, 'bof');
version = fread(file.name, 1, 'uint32');

% Check version
switch version
    case {62, 63}
        file.key = 32;
    case 57
        file.key = 17;
    otherwise
        if version > 63
            file.key = 32;
        else
            file.key = 13;
        end
end

% Skip to end of section
fseek(file.name, 1356, 'bof');
file.address.injection_data = ftell(file.name);
end


function [file, data] = InjectionData(file, data)

% Find section
fseek(file.name, file.address.injection_data, 'bof');

% Skip to end of section
fseek(file.name, 64, 'cof');
file.address.sequence_data = ftell(file.name);
end


function [file, data] = SequenceData(file, data)

% Find section
fseek(file.name, file.address.sequence_data, 'bof');

% Variables
data.sample.name = '';
data.method.name = '';
data.method.date = '';
data.method.time = '';

% Read pascal string header
pascal = @(x) fread(x, 1, 'uint32');

% Read sequence data
for i = 1:file.key
        
    % Read size of pascal string
    n = pascal(file.name);
    
    % Check value
    if n <= 0 || i == 17
        continue
    end
    
    % Read pascal string
    switch i
        
        % Method name
        case 10
            data.method.name = deblank(fread(file.name, n, 'uint16=>char')');
            
        % File path
        case 12
            file.path = deblank(fread(file.name, n, 'uint16=>char')');
      
        % Skip field
        otherwise
            fread(file.name, n, 'uint16=>char');
    end
end

% Check sample name
if isempty(data.sample.name) && ~isempty(file.path)
    [~, name, ~] = fileparts(file.path);
    
    % Check for valid name
    if any('\' == name)
        data.sample.name = name(find(name == '\', 1, 'last')+1:end);
    elseif any('/' == name)
        data.sample.name = name(find(name == '/', 1, 'last')+1:end);
    else
        data.sample.name = name;
    end
end

file.address.autosampler_data = ftell(file.name);
end


function [file, data] = AutosamplerData(file, data)

% Find section
fseek(file.name, file.address.autosampler_data, 'bof');

% Skip to end of section
fseek(file.name, 24, 'cof');
fseek(file.name, fread(file.name, 1, 'uint32'), 'cof');
file.address.file_information = ftell(file.name);
end
    
    
function [file, data] = FileInfo(file, data)

% Find section
fseek(file.name, file.address.file_information, 'bof');

% Read date/time
fseek(file.name, 4, 'cof');
x = fread(file.name, 8, 'uint16');
x = datenum([x(1), x(2), x(4), x(5), x(6), x(7)]);

% Format date/time
data.method.date = strtrim(datestr(x, 'mm/dd/yy'));
data.method.time = strtrim(datestr(x, 'HH:MM PM'));

% Read data address
fseek(file.name, 4, 'cof');
file.address.data = fread(file.name, 1, 'uint32');

% Read run header address
fseek(file.name, 16, 'cof');
file.address.run_header = fread(file.name, 1, 'uint32');
end


function [file, data] = RunHeader(file, data)

% Variables
offset = file.address.run_header;

% Read scan range
fseek(file.name, offset+8, 'bof');
file.scan.start = fread(file.name, 1, 'uint32');
file.scan.end = fread(file.name, 1, 'uint32');

% Read scan index address
fseek(file.name, offset+28, 'bof');
file.address.scan_index = fread(file.name, 1, 'uint32');

% Read scan trailer and scan parameters address
fseek(file.name, offset+7368, 'bof');
file.address.scan_trailer = fread(file.name, 1, 'uint32');
file.address.scan_parameters = fread(file.name, 1, 'uint32');
end


function [file, data] = ScanInfo(file, data)

% Variables
offset = file.address.scan_index;
n = file.scan.end - file.scan.start;

% Pre-allocate memory
file.offset = zeros(1,n, 'uint32');
file.size = zeros(1, n, 'uint32');
data.time = zeros(1,n);
data.tic.values = zeros(1,n);

% Read offset values
fseek(file.name, offset+10, 'bof');
file.offset = fread(file.name, n, 'uint32', 68);

% Read scan size
fseek(file.name, offset+20, 'bof');
file.size = fread(file.name, n, 'uint32', 68);

% Read time values
fseek(file.name, offset+24, 'bof');
data.time = fread(file.name, n, 'float64', 64);

% Read total intensity values
fseek(file.name, offset+32, 'bof');
data.tic.values = fread(file.name, n, 'float64', 64);
end


function [file, data] = ScanData(file, data)

% Variables
offset = file.address.data(1);
n = sum(file.size);

% Pre-allocate memory
data.xic.values = zeros(1, n, 'single');
mz.integer = zeros(1, n, 'single');
mz.decimal = zeros(1, n, 'single');

% Read intensity values
fseek(file.name, offset, 'bof');
data.xic.values = fread(file.name, n, 'uint32=>single', 4);
data.xic.values = data.xic.values / 256;

% Read mass values integer
fseek(file.name, offset+4, 'bof');
mz.integer = fread(file.name, n, 'uint16=>single', 6);

% Read mass values decimal
fseek(file.name, offset+6, 'bof');
mz.decimal = fread(file.name, n, 'uint16=>single', 6);
mz.decimal = mz.decimal / 65536;

% Determine mass values
data.mz = mz.integer + mz.decimal;
end


function [file, data] = FormatData(file, data)

% Variables
precision = file.precision;

% Determine precision of mass values
mz = round(data.mz * 10^precision) / 10^precision;
data.mz = unique(mz, 'sorted');

% Determine data index
index.end = cumsum(file.size);
index.start = circshift(index.end,[1,0]);
index.start = index.start + 1;
index.start(1,1) = 1;

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

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1
    error('Not enough input arguments');
elseif ~ischar(varargin{1})
    error('Undefined input arguments of type ''file''');
elseif ischar(varargin{1})
    file.name = varargin{1};
else
    varargout{2} = [];
    return
end

% Check file extension
[~, ~, extension] = fileparts(file.name);

if ~strcmpi(extension, '.RAW')
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
        file.precision = 3;
        
    % Check input range
    elseif precision < 0
        
        % Check for case: 10^-x
        if log10(precision) >= -9 && log10(precision) <= 0
            file.precision = abs(log10(precision));
        else
            file.precision = 1;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''0'''); 
        end
        
    elseif precision > 9
        
        % Check for case: 10^x
        if log10(precision) <= 9 && log10(precision) >= 0
            file.precision = log10(precision);
        else
            file.precision = 9;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''9''');
        end
    else
        file.precision = precision;
    end
else
    file.precision = 3;
end

varargout{1} = file;
varargout{2} = [];
end