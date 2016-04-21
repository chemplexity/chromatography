% ------------------------------------------------------------------------
% Method      : ImportAgilent
% Description : Import data stored in Agilent (.D, .MS, .CH) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportAgilent(file)
%   data = ImportAgilent(file, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   file (required)
%       Description : name of Agilent data file
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
%   data = ImportAgilent('MSD1.MS')
%   data = ImportAgilent('Trial1.D')
%
% ------------------------------------------------------------------------
% Compatibility
% ------------------------------------------------------------------------
%   LC/MS  : V.2, V.20
%   GC/MS  : V.2, V.20
%   GC/FID : V.8, V.81, V.179, V.181
%

function varargout = ImportAgilent(varargin)

% Parse user input
[files, options] = parse(varargin);

data{length(files(:,1))} = [];

% Import functions
for i = 1:length(files(:,1))
    
    switch files{i,2};
        
        %
        % Agilent // Mass Spectrometer (GC/MS, LC/MS)
        %
        case {'.MS', '.ms'}
            data{i} = AgilentMS(files{i,1}, options);
            
            %
            % Agilent // Other Detectors (GC/FID, LC/DAD, LC/ELSD,...)
            %
        case {'.CH', '.ch'}
            data{i} = AgilentCH(files{i,1}, options);
            
        otherwise
            data{i} = [];
    end
end

data(cellfun(@isempty, data)) = [];

% Output
varargout(1) = {[data{:}]};
end

%
% Agilent // Mass Spectrometer
%
function varargout = AgilentMS(varargin)

%
% File Information
%
    function [data, options] = FileInfo(file, data, options)
        
        % Sample name
        fseek(file, 24, 'bof');
        data.sample.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        % Sample description
        fseek(file, 86, 'bof');
        data.sample.description = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        fseek(file, 252, 'bof');
        data.sample.sequence = fread(file, 1, 'short', 0, 'b');
        data.sample.vial = fread(file, 1, 'short', 0, 'b');
        data.sample.replicate = fread(file, 1, 'short', 0, 'b');
        
        % Method name
        fseek(file, 228, 'bof');
        data.method.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        % Method operator
        fseek(file, 148, 'bof');
        data.method.operator = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        % Method date/time
        fseek(file, 178, 'bof');
        date = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        data.method.date = '';
        data.method.time = '';
        
        try
            date = datenum(date, 'dd mmm yy HH:MM PM');
            data.method.date = datestr(date, 'mm/dd/yy');
            data.method.time = datestr(date, 'HH:MM PM');
        catch
            try
                date = datenum(date, 'mm/dd/yy HH:MM:SS PM');
                data.method.date = datestr(date, 'mm/dd/yy');
                data.method.time = datestr(date, 'HH:MM PM');
            catch
                try
                    date = datenum(date, 'dd-mmm-yy, HH:MM:SS');
                    data.method.date = datestr(date, 'mm/dd/yy');
                    data.method.time = datestr(date, 'HH:MM PM');
                catch
                    data.method.date = date;
                    data.method.time = date;
                end
            end
        end
        
        data.method.date = strtrim(deblank(data.method.date));
        data.method.time = strtrim(deblank(data.method.time));
        
        % Instrument name
        fseek(file, 208, 'bof');
        data.instrument.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        % Instrument inlet
        fseek(file, 218, 'bof');
        data.instrument.inlet = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')'));
        
        % Total scans
        fseek(file, 278, 'bof');
        options.scans = fread(file, 1, 'uint', 'b');
        
        % TIC offset
        fseek(file, 260, 'bof');
        options.offset.tic = fread(file, 1, 'int', 'b') .* 2 - 2;
        
        % XIC offset
        fseek(file, options.offset.tic, 'bof');
        options.offset.xic = fread(file, options.scans, 'int', 8, 'b') .* 2 - 2;
        
        % Nomalization offset
        fseek(file, 272, 'bof');
        options.offset.normalization = fread(file, 1, 'int', 'b') .* 2 - 2;
    end

%
% TIC
%
    function [data, options] = ImportTIC(file, data, options)
        
        % Variables
        scans = options.scans;
        offset = options.offset.tic;
        
        % Pre-allocate memory
        data.time = zeros(scans, 1);
        data.tic = zeros(scans, 1);
        
        % Time values
        fseek(file, offset+4, 'bof');
        data.time = fread(file, scans, 'int', 8, 'b') ./ 60000;
        
        % Total intensity values
        fseek(file, offset+8, 'bof');
        data.tic = fread(file, scans, 'int', 8, 'b');
    end

%
% XIC
%
    function [data, options] = ImportXIC(file, data, options)
        
        % Variables
        if ~isfield(options, 'scans') && ~isfield(options, 'offset')
            return
        end
        
        scans = options.scans;
        offset = options.offset.xic;
        
        mz = [];
        xic = [];
        
        for i = 1:scans
            
            % Scan size
            fseek(file, offset(i,1), 'bof');
            n(i) = (fread(file, 1, 'int16', 0, 'b') - 18) / 2 + 2;
            
            % Mass values
            fseek(file, offset(i,1)+18, 'bof');
            mz(end+1:end+n(i)) = fread(file, n(i), 'uint16', 2, 'b');
            
            % Intensity values
            fseek(file, offset(i,1)+20, 'bof');
            xic(end+1:end+n(i)) = fread(file, n(i), 'uint16', 2, 'b');
        end
        
        % Correct intensity values (mantissa/exponent)
        xic = bitand(xic, 16383, 'uint16') .* (8 .^ abs(bitshift(xic, -14, 'uint16')));
        
        % Correct mass values (20-bit ADC)
        mz = mz ./ 20;
        
        % Round mass values
        mz = round(mz .* 10^options.precision) ./ 10^options.precision;
        data.mz = unique(mz, 'sorted');
        
        index(:,2) = cumsum(n);
        index(:,1) = circshift(index(:,2), [1,0]) + 1;
        index(1,1) = 1;
            
        % Pre-allocate memory
        data.xic = zeros(length(data.time), length(data.mz));
            
        % Index columns
        [~, cols] = ismember(mz, data.mz);
            
        for i = 1:scans
            data.xic(i, cols(index(i,1):index(i,2))) = xic(index(i,1):index(i,2));
        end
    end

% Variables
filename = varargin{1};
options = varargin{2};

data = struct(...
    'file', [],...
    'sample', [],...
    'method', [],...
    'instrument', [],...
    'time', [],...
    'tic', [],...
    'xic', [],...
    'mz', []);

% File info
[flag, filepath] = fileattrib(filename);
fileinfo = dir(filepath.Name);

% Check for hidden file
if flag && filepath.hidden == 1
    varargout{1} = [];
    varargout{2} = options;
    return
end

% Open file
file = fopen(filename, 'r', 'b');

% Version
options.version = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

switch options.version
    
    case {'2', '20'}
        [data, options] = FileInfo(file, data, options);
        [data, options] = ImportTIC(file, data, options);
        [data, options] = ImportXIC(file, data, options);
end

% Close file
fclose(file);

if ~isempty(data)
    data.file.path = fileinfo.name;
    data.file.bytes = fileinfo.bytes;
end

% Output
varargout{1} = data;
varargout{2} = options;

end


%
% Agilent // Other Detectors (FID)
%
function varargout = AgilentCH(varargin)

%
% Flame Ionization Detector (8, 81, 179, 181)
%
    function [data, options] = FileInfo(file, data, options)
        
        if any(strcmpi(options.version, {'8', '81'}))
            encoding = 'uint8=>char';
        else
            encoding = 'uint16=>char';
        end
        
        % Sample name
        fseek(file, options.offset.sample, 'bof');
        data.sample.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        fseek(file, options.offset.description, 'bof');
        data.sample.description = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        % Method name
        fseek(file, options.offset.method, 'bof');
        data.method.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        % Method operator
        fseek(file, options.offset.operator, 'bof');
        data.method.operator = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        fseek(file, 252, 'bof');
        data.sample.sequence = fread(file, 1, 'short', 0, 'b');
        data.sample.vial = fread(file, 1, 'short', 0, 'b');
        data.sample.replicate = fread(file, 1, 'short', 0, 'b');
        
        % Method date/time
        fseek(file, options.offset.date, 'bof');
        date = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        try
            date = datenum(date, 'dd mmm yy HH:MM PM');
            data.method.date = datestr(date, 'mm/dd/yy');
            data.method.time = datestr(date, 'HH:MM PM');
        catch
            try
                date = datenum(date, 'mm/dd/yy HH:MM:SS PM');
                data.method.date = datestr(date, 'mm/dd/yy');
                data.method.time = datestr(date, 'HH:MM PM');
            catch
                try
                    date = datenum(date, 'dd-mmm-yy, HH:MM:SS');
                    data.method.date = datestr(date, 'mm/dd/yy');
                    data.method.time = datestr(date, 'HH:MM PM');
                catch
                    data.method.date = date;
                    data.method.time = date;
                end
            end
        end
        
        data.method.date = strtrim(deblank(data.method.date));
        data.method.time = strtrim(deblank(data.method.time));
        
        % Instrument type
        fseek(file, options.offset.instrument, 'bof');
        data.instrument.name = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
        
        % Instrument units
        fseek(file, options.offset.units, 'bof');
        data.instrument.units = strtrim(deblank(fread(file, fread(file, 1, 'uint8'), encoding, 'l')'));
    end

% Variables
file = varargin{1};
options = varargin{2};

data = struct(...
    'file', [],...
    'sample', [],...
    'method', [],...
    'instrument', [],...
    'time', [],...
    'tic', [],...
    'xic', [],...
    'mz', []);

% File info
[flag, filepath] = fileattrib(file);
fileinfo = dir(filepath.Name);

% Check for hidden file
if flag && filepath.hidden == 1
    varargout{1} = [];
    varargout{2} = options;
    return
end

% Open file
file = fopen(file, 'r', 'b');

% Version
options.version = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

switch options.version
    
    case {'8'}
        
        % Sample Info
        options.offset.sample = 24;
        options.offset.description = 86;
        
        % Method Info
        options.offset.method = 228;
        options.offset.operator = 148;
        options.offset.date = 178;
        
        % Instrument Info
        options.offset.instrument = 218;
        options.offset.inlet = 208;
        options.offset.units = 580;
        
        fseek(file, 264, 'bof');
        offset = (fread(file, 1, 'int32', 'b') - 1) * 512;
        
        [data, options] = FileInfo(file, data, options);
        data.tic = DeltaCompression(file, offset);
        
        fseek(file, 282, 'bof');
        xmin = fread(file, 1, 'int32', 'b') / 60000;
        xmax = fread(file, 1, 'int32', 'b') / 60000;
        
        data.time = linspace(xmin, xmax, length(data.tic))';
        
        fseek(file, 542, 'bof');
        header = fread(file, 1, 'int32', 'b');
        
        if any(header == [1,2,3])
            data.tic = data.tic * 1.33321110047553;
        else
            fseek(file, 636, 'bof');
            intercept =  fread(file, 1, 'float64', 'b');
            
            fseek(file, 644, 'bof');
            slope = fread(file, 1, 'float64', 'b');
            
            data.tic = data.tic * slope + intercept;
        end
        
    case '81'
        
        % Sample Info
        options.offset.sample = 24;
        options.offset.description = 86;
        
        % Method Info
        options.offset.method = 228;
        options.offset.operator = 148;
        options.offset.date = 178;
        
        % Instrument Info
        options.offset.instrument = 218;
        options.offset.inlet = 208;
        options.offset.units = 580;
        
        fseek(file, 264, 'bof');
        offset = (fread(file, 1, 'int32', 'b') - 1) * 512;
        
        [data, options] = FileInfo(file, data, options);
        data.tic = DoubleDeltaCompression(file, offset);
        
        fseek(file, 282, 'bof');
        xmin = fread(file, 1, 'float32', 'b') / 60000;
        xmax = fread(file, 1, 'float32', 'b') / 60000;
        
        data.time = linspace(xmin, xmax, length(data.tic))';
        
        fseek(file, 636, 'bof');
        intercept =  fread(file, 1, 'float64', 'b');
        
        fseek(file, 644, 'bof');
        slope = fread(file, 1, 'float64', 'b');
        
        data.tic = data.tic * slope + intercept;
        
        % Flame Ionization Detector (181)
    case {'179'}
        
        % Sample Info
        options.offset.sample = 858;
        options.offset.description = 1369;
        
        % Method Info
        options.offset.method = 2574;
        options.offset.operator = 1880;
        options.offset.date = 2391;
        
        % Instrument Info
        options.offset.instrument = 2533;
        options.offset.inlet = 2492;
        options.offset.units = 4172;
        
        fseek(file, 264, 'bof');
        offset = (fread(file, 1, 'int32', 'b') - 1) * 512;
        
        [data, options] = FileInfo(file, data, options);
        data.tic = DoubleArray(file, offset);
        
        fseek(file, 282, 'bof');
        xmin = fread(file, 1, 'float32', 'b') / 60000;
        xmax = fread(file, 1, 'float32', 'b') / 60000;
        
        data.time = linspace(xmin, xmax, length(data.tic))';
        
        fseek(file, 4724, 'bof');
        intercept =  fread(file, 1, 'float64', 'b');
        
        fseek(file, 4732, 'bof');
        slope = fread(file, 1, 'float64', 'b');
        
        data.tic = data.tic * slope + intercept;
        
        % Flame Ionization Detector (181)
    case {'181'}
        
        % Sample Info
        options.offset.sample = 858;
        options.offset.description = 1369;
        
        % Method Info
        options.offset.method = 2574;
        options.offset.operator = 1880;
        options.offset.date = 2391;
        
        % Instrument Info
        options.offset.instrument = 2533;
        options.offset.inlet = 2492;
        options.offset.units = 4172;
        
        fseek(file, 264, 'bof');
        offset = (fread(file, 1, 'int32', 'b') - 1) * 512;
        
        [data, options] = FileInfo(file, data, options);
        data.tic = DoubleDeltaCompression(file, offset);
        
        fseek(file, 282, 'bof');
        xmin = fread(file, 1, 'float32', 'b') / 60000;
        xmax = fread(file, 1, 'float32', 'b') / 60000;
        
        data.time = linspace(xmin, xmax, length(data.tic))';
        
        fseek(file, 4724, 'bof');
        intercept =  fread(file, 1, 'float64', 'b');
        
        fseek(file, 4732, 'bof');
        slope = fread(file, 1, 'float64', 'b');
        
        data.tic = data.tic * slope + intercept;
end

% Close file
fclose(file);

if ~isempty(data)
    data.file.path = fileinfo.name;
    data.file.bytes = fileinfo.bytes;
end

% Output
varargout{1} = data;
varargout{2} = options;

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

% Method      : DeltaCompression
% Description : Decode delta compressed signal
%
function signal = DeltaCompression(file, offset)

if ftell(file) == -1
    signal = [];
    return;
    
else
    fseek(file, 0, 'eof');
    stop = ftell(file);
    
    fseek(file, offset, 'bof');
    start = ftell(file);
end

signal = zeros(round((stop-start)/2), 1);
buffer = zeros(4, 1);
index = 1;

while ftell(file) < stop
    
    buffer(1) = fread(file, 1, 'int16', 'b');
    buffer(2) = buffer(4);
    
    if bitshift(buffer(1), 12, 'int16') == 0
        signal(index:end) = [];
        break
    end
    
    for i = 1:bitand(buffer(1), 4095, 'int16');
        
        buffer(3) = fread(file, 1, 'int16', 'b');
        
        if buffer(3) ~= -32768
            buffer(2) = buffer(2) + buffer(3);
        else
            buffer(2) = fread(file, 1, 'int32', 'b');
        end
        
        signal(index) = buffer(2);
        index = index + 1;
    end
    
    buffer(4) = buffer(2);
end

end

%
% Method      : DoubleDeltaCompression
% Description : Decode double delta compressed signal
%
function signal = DoubleDeltaCompression(file, offset)

% File validation
if isnumeric(file)
    fseek(file, 0, 'eof');
    fsize = ftell(file);
else
    return
end

% Read data
fseek(file, offset, 'bof');

signal = zeros(fsize/2, 1);
count = 1;
buffer = zeros(1,3);

while ftell(file) < fsize
    
    buffer(3) = fread(file, 1, 'int16', 'b');
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(file, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(file, 1, 'uint32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    signal(count, 1) = buffer(1);
    count = count + 1;
end

signal(count:end,:) = [];

end

%
% Method      : DoubleArray
% Description : Load signal from double array
%
function signal = DoubleArray(file, offset)

% File validation
if isnumeric(file)
    fseek(file, 0, 'eof');
    fsize = ftell(file);
else
    signal = [];
    return
end

% Read data
fseek(file, offset, 'bof');
signal = fread(file, (fsize - offset) / 8, 'double', 'l');

end
