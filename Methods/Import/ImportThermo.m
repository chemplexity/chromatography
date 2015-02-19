% Method: ImportThermo
%  -Extract data from Thermo (.RAW) files
%
% Syntax:
%   data = ImportThermo(file)
%
% Input
%   file : string
%
% Description:
%   file : file name with valid extension (.RAW)
%
% Examples:
%   data = ImportThermo('MyData.RAW')

function varargout = ImportThermo(varargin)

% Variables
data = [];
file = [];

% Settings
file.limit = 10;

% Open file
file.name = fopen(varargin{1}, 'r', 'l', 'UTF-8');

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
        file.key = 13;
end

% Skip to next section
fseek(file.name, 1356, 'bof');
file.address.injection_data = ftell(file.name);
end


function [file, data] = InjectionData(file, data)

% Find section
fseek(file.name, file.address.injection_data, 'bof');

% Skip to next section
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

% Read sequence data
for i = 1:file.key
    switch i
        
        % Read method name
        case 10
            offset = fread(file.name, 1, 'uint32');
            if offset > 0
                data.method.name = deblank(fread(file.name, offset, 'uint16=>char')');
            end
            
        % Read method name
        case 12
            offset = fread(file.name, 1, 'uint32');
            if offset > 0
                file.path = deblank(fread(file.name, offset, 'uint16=>char')');
            end
            
        % Skip unknown long
        case 17
            fseek(file.name, 4, 'cof');
            
        % Skip pascal string
        otherwise
            offset = fread(file.name, 1, 'uint32');
            if offset > 0
                fread(file.name, offset, 'uint16=>char');
            end
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

% Skip to next section
file.address.autosampler_data = ftell(file.name);
end


function [file, data] = AutosamplerData(file, data)

% Find section
fseek(file.name, file.address.autosampler_data, 'bof');

% Skip to next section
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
data.mz = zeros(1, n, 'single');
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
data.mz = round(data.mz * file.limit) / file.limit;
mz = unique(data.mz);
n = length(data.time);
m = length(mz);

% Determine data index
index.end = cumsum(file.size);
index.start = circshift(index.end,[1,0]);
index.start = index.start + 1;
index.start(1,1) = 1;

% Pre-allocate memory
xic = zeros(n, m, 'single');

for i = 1:n-1
    
    % Determine current frame
    frame = index.start(i):index.end(i);
    offset = index.start(i) - 1;
    
    % Determine column index of current frame
    [~, row_index, column_index] = intersect(data.mz(frame), mz);
    
    % Reshape instensity values
    xic(i, column_index) = data.xic.values(row_index + offset);
end

% Output data
data.mz = mz';
data.xic.values = xic;
end
