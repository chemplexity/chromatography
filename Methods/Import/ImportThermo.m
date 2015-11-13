% ------------------------------------------------------------------------
% Method      : ImportThermo
% Description : Import data stored in Thermo (.RAW) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportThermo(file)
%   data = ImportThermo(file, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   file (required)
%       Description : name of Thermo data file
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
%   data = ImportThermo('001-32-2.RAW')
%   data = ImportThermo('06b.RAW', 'precision', 4)
%
% ------------------------------------------------------------------------
% Compatibility
% ------------------------------------------------------------------------
%   LTQ XL : V.57, V.62, V.63
%   LCQ XP : V.57, V.62, V.63
%
% ------------------------------------------------------------------------
% Issues
% ------------------------------------------------------------------------
%   1) Large files > 200 MB
%   2) Unable to import 'profile' MS/MS data
%

function varargout = ImportThermo(varargin)

% Check input
[file, data] = parse(varargin);

% Check file name
if isempty(file)
    varargout{1} = [];
    
    disp('Error: Input file invalid.');
    return
end

% Open file
file.name = fopen(file.name, 'r', 'l', 'UTF-8');

% Read file header
[file, data] = FileHeader(file, data);

% Check version
if isempty(file.key)
    varargout{1} = [];
    
    disp(['Input data of type ''V.', num2str(file.version), ''' is currently unsupported.']);
    return
end

% Read data
[file, data] = InjectionData(file, data);
[file, data] = SequenceData(file, data);
[file, data] = AutosamplerData(file, data);
[file, data] = FileInfo(file, data);
[file, data] = RunHeader(file, data);
[file, data] = InstrumentInfo(file, data);
[file, data] = ScanInfo(file, data);
[file, data] = ScanData(file, data);

% Close file
fclose(file.name);

% Output data
varargout{1} = data;
varargout{2} = file;
end


function [file, data] = FileHeader(file, data)

% Read address
file.address.file_header = ftell(file.name);

% Read version
fseek(file.name, 36, 'bof');
file.version = fread(file.name, 1, 'uint32');

% Check version
switch file.version
    
    case {62, 63}
        file.key = 32;
        
    case 57
        file.key = 17;
        
    otherwise
        file.key = [];
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
file.filename = '';
file.path = '';

% Function to read size of pascal string
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
        
        % ID
        case 3
            file.id = deblank(fread(file.name, n, 'uint16=>char')');
            
            % Method name
        case 10
            data.method.name = deblank(fread(file.name, n, 'uint16=>char')');
            
            % File name
        case 12
            file.filename = deblank(fread(file.name, n, 'uint16=>char')');
            
            % Path name
        case 13
            file.path = deblank(fread(file.name, n, 'uint16=>char')');
            
            % Vial
        case 14
            file.vial = deblank(fread(file.name, n, 'uint16=>char')');
            
            % Skip field
        otherwise
            fread(file.name, n, 'uint16=>char');
    end
end

% Check sample name
if isempty(data.sample.name) && ~isempty(file.filename)
    [~, name, ~] = fileparts(file.filename);
    
    % Check for valid name
    if any('\' == name)
        data.sample.name = name(find(name == '\', 1, 'last')+1:end);
    elseif any('/' == name)
        data.sample.name = name(find(name == '/', 1, 'last')+1:end);
    else
        data.sample.name = name;
    end
end

% Check method name
if ~isempty(data.method.name)
    name = data.method.name;
    
    % Remove path from method name
    if any('\' == name)
        data.method.name = name(find(name == '\', 1, 'last')+1:end);
    elseif any('/' == name)
        data.method.name = name(find(name == '/', 1, 'last')+1:end);
    else
        data.method.name = name;
    end
else
    data.method.name = 'N/A';
end

% Address of next section
file.address.autosampler_data = ftell(file.name);
end


function [file, data] = AutosamplerData(file, data)

% Find section
fseek(file.name, file.address.autosampler_data, 'bof');

% Skip to end of section
fseek(file.name, 24, 'cof');

% Read autosampler type
n = fread(file.name, 1, 'uint32');

if n ~= 0
    file.autosampler = deblank(fread(file.name, n, 'uint16=>char')');
end

% Address of next section
file.address.file_information = ftell(file.name);
end


function [file, data] = FileInfo(file, data)

% Variables
offset = file.address.file_information;

% Read date/time
fseek(file.name, offset+4, 'bof');
x = fread(file.name, 8, 'uint16');
x = datenum([x(1), x(2), x(4), x(5), x(6), x(7)]);

% Format date/time
data.method.date = strtrim(datestr(x, 'mm/dd/yy'));
data.method.time = strtrim(datestr(x, 'HH:MM PM'));

% Determine offset of address values
switch file.version
    
    case {62, 63}
        n = offset + 24;
        m = offset + 44;
        
    case {64}
        n = offset + 808;
        m = offset + 824;
        
    otherwise
        n = offset + 24;
        m = offset + 44;
end

% Read data address
fseek(file.name, n, 'bof');
file.address.data = fread(file.name, 1, 'uint32');

% Read run header address
fseek(file.name, m, 'bof');
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

% Read m/z range
fseek(file.name, offset+56, 'bof');
file.low_mz = fread(file.name, 1, 'float64');
file.high_mz = fread(file.name, 1, 'float64');

% Read time range
fseek(file.name, offset+72, 'bof');
file.start_time = fread(file.name, 1, 'float64');
file.end_time = fread(file.name, 1, 'float64');

% Read scan trailer and scan parameters address
fseek(file.name, offset+7368, 'bof');
file.address.scan_trailer = fread(file.name, 1, 'uint32');
file.address.scan_parameters = fread(file.name, 1, 'uint32');

% Address of next section
file.address.instrument_id = file.address.run_header + 7408;
end


function [file, data] = InstrumentInfo(file, data)

% Variables
data.method.instrument = '';
offset = file.address.instrument_id;

% Anonymous functions
pascal = @(x) fread(x, 1, 'uint32');
skip = @(x,n) fread(x, n, 'uint16=>char');

% Read instrument model
fseek(file.name, offset+12, 'bof');
n = pascal(file.name);

if n > 0 && n <= 100
    file.model = deblank(fread(file.name, n, 'uint16=>char')');
else
    file.model = [];
end

% Read instrument model extended
n = pascal(file.name);

if n > 0 && n <= 100
    if isempty(file.model) || n > length(file.model)
        file.model = deblank(fread(file.name, n, 'uint16=>char')');
    else
        skip(file.name, n);
    end
end

% Read serial number
n = pascal(file.name);

if n > 0 && n <= 100
    file.serial = deblank(fread(file.name, n, 'uint16=>char')');
else
    file.serial = [];
end

% Read software version
n = pascal(file.name);

if n > 0 && n <= 100
    file.software = deblank(fread(file.name, n, 'uint16=>char')');
else
    file.software = [];
end

% Check instrument model
if ~isempty(file.model)
    data.method.instrument = strcat(file.model, ' V.', num2str(file.version));
    data.method.instrument = ['Thermo ', data.method.instrument];
else
    data.method.instrument = strcat('V.', num2str(file.version));
    data.method.instrument = ['Thermo ', data.method.instrument];
end
end


function [file, data] = ScanInfo(file, data)

% Variables
offset = file.address.scan_index;
n = file.scan.end - file.scan.start;

% Pre-allocate memory
file.offset = zeros(n, 1);
file.level = zeros(n, 1);
file.size = zeros(n, 1);
data.time = zeros(n, 1);
data.tic.values = zeros(1,n);

% Read offset values
fseek(file.name, offset+10, 'bof');
file.offset = fread(file.name, n, 'uint32=>single', 68);

% Read scan level
fseek(file.name, offset+16, 'bof');
file.level = fread(file.name, n, 'uint32=>single', 68);

% Read scan size
fseek(file.name, offset+20, 'bof');
file.size = fread(file.name, n, 'uint32=>single', 68);

% Read time values
fseek(file.name, offset+24, 'bof');
data.time = fread(file.name, n, 'float64=>single', 64);

% Read total intensity values
fseek(file.name, offset+32, 'bof');
data.tic.values = fread(file.name, n, 'float64=>single', 64);
end


function [file, data] = ScanData(file, data)

% Check available data types
levels = unique(file.level, 'sorted');

for i = 1:length(levels)
    
    switch levels(i)
        
        % MS1 / No Header
        case 15
            
            % Variables
            offset = file.address.data;
            n = sum(file.size);
            
            % Initialize data
            mz = [];
            
            % Read intensity values
            fseek(file.name, offset, 'bof');
            xic = fread(file.name, n, 'uint32=>single', 4);
            xic = xic / 256;
            
            % Read mass values integer
            fseek(file.name, offset+4, 'bof');
            mz.integer = fread(file.name, n, 'uint16=>single', 6);
            
            % Read mass values decimal
            fseek(file.name, offset+6, 'bof');
            mz.decimal = fread(file.name, n, 'uint16=>single', 6);
            mz.decimal = mz.decimal / 65536;
            
            % Calculate mass values
            mz = mz.integer + mz.decimal;
            
            % Variables
            size = cumsum(file.size);
            rows = sum(file.level == 15);
            
            % Reduce memory
            mz = single(mz);
            xic = single(xic);
            
            % Reshape data
            [data.mz, data.xic.values] = FormatData(file, mz, xic, size, rows);
            
            % Clear memory
            clear mz xic
            
            % MS1 / Header
        case 21
            
            % Variables
            offset = [file.address.data; file.address.data + cumsum(file.size(1:end-1))];
            index = offset(file.level == 21);
            
            % Initialize data
            xic = [];
            mz = [];
            n = [];
            
            for j = 1:length(index)
                
                % Profile size
                fseek(file.name, index(j)+4, 'bof');
                list.profile(j) = fread(file.name, 1, 'uint32');
                
                % Centroid size
                list.centroid(j) = fread(file.name, 1, 'uint32');
                
                if list.centroid > 0
                    
                    % Variables
                    offset = index(j) + 40 + (list.profile(j) * 4);
                    
                    % Read size
                    fseek(file.name, offset, 'bof');
                    n(end+1) = fread(file.name, 1, 'uint32');
                    
                    % Read mass values
                    fseek(file.name, offset+4, 'bof');
                    mz(end+1:end+n(j)) = fread(file.name, n(j), 'float32=>single', 4);
                    
                    % Read intensity values
                    fseek(file.name, offset+8, 'bof');
                    xic(end+1:end+n(j)) = fread(file.name, n(j), 'float32=>single', 4);
                else
                    n(end+1) = 0;
                end
            end
            
            % Variables
            size = cumsum(n)';
            rows = sum(file.level == 21);
            
            % Reduce memory
            mz = single(mz);
            xic = single(xic);
            
            % Reshape data
            [data.mz, data.xic.values] = FormatData(file, mz', xic, size, rows);
            
            % Clear memory
            clear mz xic
            
            % MS2 / Centroid
        case 18
            
            % Variables
            offset = [file.address.data; file.address.data + cumsum(file.size(1:end-1))];
            index = offset(file.level == 18);
            scan = file.size(file.level == 18);
            
            % Initialize data
            xic = [];
            mz = [];
            cols = [];
            
            for j = 1:length(index)
                
                % Profile size
                fseek(file.name, index(j)+4, 'bof');
                p = fread(file.name, 1, 'uint32');
                
                % Check allowable size
                if p > scan(j)
                    cols(end+1) = 0;
                    continue
                end
                
                if fread(file.name, 1, 'uint32') > 0
                    
                    % Variables
                    offset = index(j) + 40 + (p*4);
                    
                    % Read size
                    fseek(file.name, offset, 'bof');
                    n = fread(file.name, 1, 'uint32');
                    
                    % Check allowable size
                    if n > scan(j)
                        cols(end+1) = 0;
                        continue
                    end
                    
                    % Read mass values
                    fseek(file.name, offset+4, 'bof');
                    mz(end+1:end+n) = fread(file.name, n, 'float32', 4);
                    
                    % Read intensity values
                    fseek(file.name, offset+8, 'bof');
                    xic(end+1:end+n) = fread(file.name, n, 'float32', 4);
                    
                    % Update column index
                    cols(end+1) = n;
                else
                    cols(end+1) = 0;
                end
            end
            
            % Variables
            data.ms2.time = data.time(file.level == 18);
            data.ms2.time(cols == 0) = [];
            
            size = cumsum(cols)';
            size(cols == 0) = [];
            
            rows = length(data.ms2.time);
            
            % Reduce memory
            mz = single(mz);
            xic = single(xic);
            
            % Reshape data
            [data.ms2.mz, data.ms2.xic] = FormatData(file, mz', xic, size, rows);
            
            % Clear memory
            clear mz xic
    end
end

end


function varargout = FormatData(file, mz, xic, size, rows)

% Variables
precision = file.precision;

% Determine precision of mass values
mz = round(mz .* 10^precision) ./ 10^precision;
z = unique(mz, 'sorted');

% Determine column index for reshaping
[~, column_index] = ismember(mz, z);

% Clear m/z from memory
clear mz

% Determine data index
index.end = size;
index.start = circshift(index.end,[1,0]);
index.start = index.start + 1;
index.start(1,1) = 1;

% Pre-allocate memory
if rows * length(z) > 6.25E6
    y = spalloc(rows, length(z), length(xic));
else
    y = zeros(rows, length(z));
end

for i = 1:length(index.start)
    
    % Variables
    m = index.start(i);
    n = index.end(i);
    
    % Reshape instensity values
    y(i, column_index(m:n)) = xic(m:n);
end

% Clear xic from memory
clear xic

% Output data
varargout{1} = z';
varargout{2} = y;

end


% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1 || ~ischar(varargin{1})
    error('Undefined input arguments of type ''file''.');
    
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
        
    elseif precision < 0
        
        % Check for case: -x
        if precision >= -9 && precision <= 0
            file.precision = abs(precision);
        else
            file.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    elseif precision > 0 && log10(precision) < 0
        
        % Check for case: 10^-x
        if log10(precision) >= -9 && log10(precision) <= 0
            file.precision = abs(log10(precision));
        else
            file.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    elseif precision > 9
        
        % Check for case: 10^x
        if log10(precision) <= 9 && log10(precision) >= 0
            file.precision = log10(precision);
        else
            file.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
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