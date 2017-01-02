function data = ImportAgilent(varargin)
% ------------------------------------------------------------------------
% Method      : ImportAgilent
% Description : Read Agilent data files (.D, .MS, .CH, .UV)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file or folder path
%       empty (default) | cell array of strings
%
%   'depth' -- subfolder search depth
%       1 (default) | integer
%
%   'content' -- read file header, signal data, or both
%       'all' (default) | 'header'
%
%   'verbose' -- show progress in command window
%       'on' (default) | 'off'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent('file', '00159F.D')
%   data = ImportAgilent('file', {'/Data/2016/04/', '00201B.D'})
%   data = ImportAgilent('file', {'/Data/2016/'}, 'depth', 4)
%   data = ImportAgilent('content', 'header', 'depth', 8)
%   data = ImportAgilent('verbose', 'off')

% ---------------------------------------
% Data
% ---------------------------------------
data.file_path       = [];
data.file_name       = [];
data.file_size       = [];
data.file_info       = [];
data.file_version    = [];
data.sample_name     = [];
data.sample_info     = [];
data.operator        = [];
data.datetime        = [];
data.instrument      = [];
data.inlet           = [];
data.detector        = [];
data.method          = [];
data.seqindex        = [];
data.vial            = [];
data.replicate       = [];
data.sampling_rate   = [];
data.time            = [];
data.intensity       = [];
data.channel         = [];
data.time_units      = [];
data.intensity_units = [];
data.channel_units   = [];

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file      = [];
default.depth     = 1;
default.content   = 'all';
default.verbose   = 'on';
default.formats   = {'.MS', '.CH', '.UV'};

% ---------------------------------------
% Platform
% ---------------------------------------
if exist('OCTAVE_VERSION', 'builtin')
    more('off');
end

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;
    
addParameter(p, 'file',    default.file);
addParameter(p, 'depth',   default.depth,   @isscalar);    
addParameter(p, 'content', default.content, @ischar);
addParameter(p, 'verbose', default.verbose, @ischar);
    
parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
option.file    = p.Results.file;
option.depth   = p.Results.depth;
option.content = p.Results.content;
option.verbose = p.Results.verbose;

% ---------------------------------------
% Validate
% ---------------------------------------

% Parameter: 'file'
if ~isempty(option.file)
    if iscell(option.file)
        option.file(~cellfun(@ischar, option.file)) = [];
    elseif ischar(option.file)
        option.file = {option.file};
    end
end
    
% Parameter: 'depth'
if ~isnumeric(option.depth)
    option.depth = default.depth;
elseif option.depth < 0 || isnan(option.depth) || isinf(option.depth)
    option.depth = default.depth;
else
    option.depth = round(option.depth);
end

% Parameter: 'content'
if ~any(strcmpi(option.content, {'default', 'all', 'header'}))
    option.content, 'all';
end

% Parameter: 'verbose'
if any(strcmpi(option.verbose, {'off', 'no', 'n', 'false', '0'}))
    option.verbose = false;
else
    option.verbose = true;
    status(option.verbose, 1);
end

% ---------------------------------------
% File selection
% ---------------------------------------
file = [];

if isempty(option.file)
    
    % Get files using file selection interface
    [file, fileError] = FileUI();
    
else
    
    % Get files from user input
    for i = 1:length(option.file)

        [~, filepath] = fileattrib(option.file{i});
        
        if isstruct(filepath)
            file = [file; filepath];
        end       
    end
    
end

% Check selection for files
if exist('fileError', 'var') && fileError == 1
    status(option.verbose, 7);
    status(option.verbose, 3);
    return
elseif exist('fileError', 'var') && fileError == 2
    status(option.verbose, 9);
    status(option.verbose, 3);
    return
elseif isempty(file)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
end

% Check selection for subfolders
if sum([file.directory]) == 0
    option.depth = 0;
else
    status(option.verbose, 8);
end

% ---------------------------------------
% Search subfolders
% ---------------------------------------
n = [1, length(file)];
l = option.depth;

while l >= 0
    
    for i = n(1):n(2)
        
        [~, ~, ext] = fileparts(file(i).Name);
        
        if any(strcmpi(ext, {'.M', '.git', '.lnk', '.raw'}))
            continue
            
        elseif file(i).directory == 1
            
            f = dir(file(i).Name);
            f(cellfun(@(x) any(strcmpi(x, {'.', '..'})), {f.name})) = [];
            
            for j = 1:length(f)
                
                filepath = [file(i).Name, filesep, f(j).name];
                [~, filepath] = fileattrib(filepath);
                
                if isstruct(filepath)
                    
                    [~, ~, ext] = fileparts(filepath.Name);
                    
                    if any(strcmpi(ext, default.formats)) || filepath.directory
                        file = [file; filepath];
                    end
                end
            end
        end
    end
    
    % Exit subfolder search
    if length(file) <= n(2)
        break
    end
    
    % Update values
    n = [n(2) + 1, length(file)];
    l = l - 1;
    
end

% ---------------------------------------
% Filter unsupported files
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

file(cellfun(@(x) ~any(strcmpi(x, default.formats)), ext)) = [];

% Check selection for files
if isempty(file)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
else
    status(option.verbose, 5, length(file));
end

% ---------------------------------------
% Import
% ---------------------------------------
for i = 1:length(file)
    
    % ---------------------------------------
    % Permissions
    % ---------------------------------------
    if ~file(i).UserRead
       continue
    end
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    [fdir, fname, fext] = fileparts(file(i).Name);
    
    if strcmpi(fdir(end-1:end), '.D')
        [fdir, fname, fext] = fileparts(fdir);
    end

    data(i,1).file_path = fdir;
    data(i,1).file_name = [fname, fext];
    data(i,1).file_size = subsref(dir(file(i).Name), substruct('.', 'bytes'));
    
    % ---------------------------------------
    % Status
    % ---------------------------------------
    [~, statusPath] = fileparts(data(i,1).file_path); 
    statusPath = ['..', filesep, statusPath, filesep, data(i,1).file_name]; 
    
    status(option.verbose, 6, i, length(file), statusPath);

    % ---------------------------------------
    % Read
    % ---------------------------------------
    f = fopen(file(i).Name, 'r');
    
    switch option.content
        
        case {'all', 'default'}
            data(i,1) = parseinfo(f, data(i,1));
            data(i,1) = parsedata(f, data(i,1));
            
        case 'header'
            data(i,1) = parseinfo(f, data(i,1));
    end
    
    fclose(f);
    
end

status(option.verbose, 3);

end

% ---------------------------------------
% Status
% ---------------------------------------
function status(varargin)
        
    % Check verbose
    if ~varargin{1}
        return
    end

    % Display status
    switch varargin{2}
            
        % [IMPORT]
        case 1
            fprintf(['\n', repmat('-',1,50), '\n']);
            fprintf(' IMPORT');
            fprintf(['\n', repmat('-',1,50), '\n\n']);

        % [ERROR]
        case 2
            fprintf([' STATUS  No files found...', '\n']);
                
        % [EXIT]
        case 3
            fprintf(['\n', repmat('-',1,50), '\n']);
            fprintf(' EXIT');
            fprintf(['\n', repmat('-',1,50), '\n']);
    
        % [STATUS]
        case 4
            fprintf([' STATUS  Depth   : ', num2str(varargin{3}), '\n']);
            fprintf([' STATUS  Folders : ', num2str(varargin{4}), '\n']);
            
        % [STATUS]
        case 5
            fprintf([' STATUS  Importing ', num2str(varargin{3}), ' files...', '\n\n']);

        % [LOADING]
        case 6
            n = num2str(varargin{3});
            m = num2str(varargin{4});
            numZeros = length(m) - length(n);
            
            fprintf([' [', [repmat('0',1,numZeros), n], '/', m, ']']);
            fprintf(' %s \n', varargin{5});
        
        % [STATUS]
        case 7
            fprintf([' STATUS  No files selected...', '\n']);
        
        % [STATUS]
        case 8
            fprintf([' STATUS  Searching subfolders...', '\n']);
        
        % [STATUS]
        case 9
            fprintf([' STATUS  Unable to load file selection interface...', '\n']);
    end
end

% ---------------------------------------
% FileUI 
% ---------------------------------------
function [file, status] = FileUI()

% ---------------------------------------
% Variables
% ---------------------------------------
file  = [];

% ---------------------------------------
% JFileChooser (Java)
% ---------------------------------------
if ~usejava('swing')
    status = 2;
    return
end

fc = javax.swing.JFileChooser(java.io.File(pwd));

% ---------------------------------------
% Options
% ---------------------------------------
fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
fc.setMultiSelectionEnabled(true);
fc.setAcceptAllFileFilterUsed(false);

% ---------------------------------------
% Filter: Agilent (.D, .MS, .CH, .UV)
% ---------------------------------------
agilent = com.mathworks.hg.util.dFilter;

agilent.setDescription('Agilent files (*.D, *.MS, *.CH, *.UV)');
agilent.addExtension('d');
agilent.addExtension('ms');
agilent.addExtension('ch');
agilent.addExtension('uv');

fc.addChoosableFileFilter(agilent);

% ---------------------------------------
% Initialize UI
% ---------------------------------------
status = fc.showOpenDialog(fc);

if status == fc.APPROVE_OPTION
    
    % Get file selection
    fs = fc.getSelectedFiles();
    
    for i = 1:size(fs, 1)
        
        % Get file information
        [~, f] = fileattrib(char(fs(i).getAbsolutePath));
        
        % Append to file list
        if isstruct(f)
            file = [file; f];
        end
    end
end

end

% ---------------------------------------
% File information
% ---------------------------------------
function data = parseinfo(f, data)

data.file_version = fpascal(f, 0, 'uint8');

if isnan(str2double(data.file_version))
    data.file_version = [];
end

if isempty(data.file_version)
    return
end

switch data.file_version

    case {'2', '8', '81', '30', '31'}
        
        data.file_info   = fpascal(f,  4,   'uint8');
        data.sample_name = fpascal(f,  24,  'uint8');
        data.sample_info = fpascal(f,  86,  'uint8');
        data.operator    = fpascal(f,  148, 'uint8');
        data.datetime    = fpascal(f,  178, 'uint8');
        data.detector    = fpascal(f,  208, 'uint8');
        data.inlet       = fpascal(f,  218, 'uint8');
        data.method      = fpascal(f,  228, 'uint8');
        data.seqindex    = fnumeric(f, 252, 'int16');
        data.vial        = fnumeric(f, 254, 'int16');
        data.replicate   = fnumeric(f, 256, 'int16');
    
    case {'130', '131', '179', '181'}
     
        data.file_info   = fpascal(f,  347,  'uint16');
        data.sample_name = fpascal(f,  858,  'uint16');
        data.sample_info = fpascal(f,  1369, 'uint16');
        data.operator    = fpascal(f,  1880, 'uint16');
        data.datetime    = fpascal(f,  2391, 'uint16');
        data.detector    = fpascal(f,  2492, 'uint16');
        data.inlet       = fpascal(f,  2533, 'uint16');
        data.method      = fpascal(f,  2574, 'uint16');
        data.seqindex    = fnumeric(f, 252,  'int16');
        data.vial        = fnumeric(f, 254,  'int16');
        data.replicate   = fnumeric(f, 256,  'int16');
end

% Parse datetime
if ~isempty(data.datetime)
    data.datetime = parsedate(data.datetime);
end

% Fix formatting
data.detector = upper(data.detector);
data.inlet    = upper(data.inlet);
data.operator = upper(data.operator);

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

if isempty(data.file_version)
    return
end

% ---------------------------------------
% Data offset
% ---------------------------------------
switch data.file_version
    
    case {'2'}
        
        offset = fnumeric(f, 260, 'int32') * 2 - 2;
        scans  = fnumeric(f, 278, 'int32');
        
    case {'8', '81', '179', '181', '30', '130'}
        
        offset = (fnumeric(f, 264, 'int32') - 1) * 512 ;
        scans  = fnumeric(f, 278, 'int32');  
end

% ---------------------------------------
% Time values
% ---------------------------------------
switch data.file_version
    
    case {'81', '179', '181'}
        
        t0 = fnumeric(f, 282, 'float32') / 60000;
        t1 = fnumeric(f, 286, 'float32') / 60000;
        
    case {'2', '8', '30', '130'}
        
        t0 = fnumeric(f, 282, 'int32') / 60000;
        t1 = fnumeric(f, 286, 'int32') / 60000;
end

% ---------------------------------------
% Intensity values
% ---------------------------------------
switch data.file_version
    
    case {'2'}
        
        data.intensity = farray(f, offset + 8, 'int32', scans, 8);
        data.time      = farray(f, offset + 4, 'int32', scans, 8) ./ 60000;
        
        offset = farray(f, offset, 'int32', scans, 8) * 2 - 2;
        data   = fpacket(f, data, offset);
        
    case {'8', '30', '130'}

        data.intensity = fdelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'81', '181'}
        
        data.intensity = fdoubledelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'179'}
        
        if fnumeric(f, offset, 'int32') == 2048
            offset = offset + 2048;
        end
        
        data.intensity = fdoublearray(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
end

% ---------------------------------------
% Units
% ---------------------------------------
switch data.file_version
    
    case {'2'}
        
        data.time_units      = 'minutes';
        data.intensity_units = 'counts';
        data.channel_units   = 'm/z';
        
    case {'8', '81', '30'}
        
        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f,  580, 'uint8');
        data.channel_units   = fpascal(f,  596, 'uint8');
        
    case {'31'}

        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 326, 'uint8');
        data.channel_units   = '';

    case {'130', '179', '181'}

        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 4172, 'uint16');
        data.channel_units   = fpascal(f, 4213, 'uint16');

    case {'131'}

        data.time_units      = 'minutes';
        data.intensity_units = fpascal(f, 3093, 'uint16');
        data.channel_units   = '';     
end

% ---------------------------------------
% Scaling
% ---------------------------------------
switch data.file_version
    
    case {'8'}
        
        version   = fnumeric(f, 542, 'int32');
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        switch version    
            case {1, 2, 3}
                data.intensity = data.intensity .* 1.33321110047553;
            otherwise
                data.intensity = data.intensity .* slope + intercept;
        end
        
    case {'30'}
        
        version   = fnumeric(f, 542, 'int32');
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        switch version
            case {1}
                data.intensity = data.intensity .* 1;
            case {2}
                data.intensity = data.intensity .* 0.00240841663372301;
            otherwise
                data.intensity = data.intensity .* slope + intercept;
        end

    case {'81'}
        
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        data.intensity = data.intensity .* slope + intercept;
        
    case {'130'}
        
        version   = fnumeric(f, 4134, 'int32');
        intercept = fnumeric(f, 4724, 'float64');
        slope     = fnumeric(f, 4732, 'float64');
        
        switch version
            case {1}
                data.intensity = data.intensity .* 1;
            case {2}
                data.intensity = data.intensity .* 0.00240841663372301;
            otherwise
                data.intensity = data.intensity .* slope + intercept;
        end
        
    case {'179', '181'}
        
        intercept = fnumeric(f, 4724, 'float64');
        slope     = fnumeric(f, 4732, 'float64');
        
        data.intensity = data.intensity .* slope + intercept;
end

% ---------------------------------------
% Instrument
% ---------------------------------------
data.instrument = parseinstrument(data);

% ---------------------------------------
% Sampling Rate
% ---------------------------------------
if ~isempty(data.time)
    data.sampling_rate = round(1./mean(diff(data.time)));
end

end

% ---------------------------------------
% Data = datetime
% ---------------------------------------
function dateStr = parsedate(dateStr)

% Platform
if exist('OCTAVE_VERSION', 'builtin')
    return
end

% ISO 8601
formatOut = 'yyyy-mm-ddTHH:MM:SS';

% Possible Formats
dateFormat = {...
    'dd mmm yy HH:MM PM',...
    'dd mmm yy HH:MM',...
    'mm/dd/yy HH:MM:SS PM',...
    'mm/dd/yy HH:MM:SS',...
    'mm/dd/yyyy HH:MM',...
    'mm/dd/yyyy HH:MM:SS PM',...
    'mm.dd.yyyy HH:MM:SS',...
    'dd-mmm-yy HH:MM:SS',...
    'dd-mmm-yy, HH:MM:SS'};

dateRegex = {...
    '\d{1,2} \w{3} \d{1,2}\s*\d{1,2}[:]\d{2} \w{2}',...
    '\d{2} \w{3} \d{2}\s*\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{2}\s*\d{2}[:]\d{2}[:]\d{2} \w{2}',...
    '\d{1,2}[/]\d{1,2}[/]\d{2}\s*\d{1,2}[:]\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{4}\s*\d{2}[:]\d{2}',...
    '\d{1,2}[/]\d{1,2}[/]\d{4}\s*\d{1,2}[:]\d{2}[:]\d{2} \w{2}',...
    '\d{2}[.]\d{2}[.]\d{4}\s*\d{2}[:]\d{2}[:]\d{2}',...
    '\d{2}[-]\w{3}[-]\d{2}\s*\d{2}[:]\d{2}[:]\d{2}',...
    '\d{2}[-]\w{3}[-]\d{2}[,]\s*\d{2}[:]\d{2}[:]\d{2}'};

if ~isempty(dateStr)
    
    dateMatch = regexp(dateStr, dateRegex, 'match');
    dateIndex = find(~cellfun(@isempty, dateMatch), 1);
    
    if ~isempty(dateIndex)
        dateNum = datenum(dateStr, dateFormat{dateIndex});
        dateStr = datestr(dateNum, formatOut);
    end
    
end

end

% ---------------------------------------
% Data = instrument
% ---------------------------------------
function instrStr = parseinstrument(data)

instrMatch = @(x,str) any(cellfun(@any, regexpi(x, str)));

instrStr = [...
    data.file_info,...
    data.inlet,...
    data.detector,...
    data.channel_units];

if isempty(instrStr)
    return
end

switch data.file_version

    case {'2'}
        
        if instrMatch(instrStr, {'CE'})
            instrStr = 'CE/MS';
        elseif instrMatch(instrStr, {'LC'})
            instrStr = 'LC/MS';
        elseif instrMatch(instrStr, {'GC'})
            instrStr = 'GC/MS';
        else
            instrStr = 'MS';
        end
            
    case {'8', '81', '179', '181'}
        
        if instrMatch(instrStr, {'GC'})
            instrStr = 'GC/FID'; 
        else
            instrStr = 'GC';
        end
        
    case {'30', '31', '130', '131'}
        
        if instrMatch(instrStr, {'DAD', '1315', '4212', '7117'})
            instrStr = 'LC/DAD';
        elseif instrMatch(instrStr, {'VWD', '1314', '7114'})
            instrStr = 'LC/VWD';
        elseif instrMatch(instrStr, {'MWD', '1365'})
            instrStr = 'LC/MWD';
        elseif instrMatch(instrStr, {'FLD', '1321'})
            instrStr = 'LC/FLD';
        elseif instrMatch(instrStr, {'ELS', '4260', '7102'})
            instrStr = 'LC/ELSD';
        elseif instrMatch(instrStr, {'RID', '1362'})
            instrStr = 'LC/RID';
        elseif instrMatch(instrStr, {'ADC', '35900'})
            instrStr = 'LC/ADC';
        elseif instrMatch(instrStr, {'CE'})
            instrStr = 'CE';
        else
            instrStr = 'LC';
        end
end

end

% ---------------------------------------
% Data = pascal string
% ---------------------------------------
function str = fpascal(f, offset, type)

fseek(f, offset, 'bof');
str = fread(f, fread(f, 1, 'uint8'), [type, '=>char'], 'l')';

if length(str) > 255
    str = '';
else
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = numeric
% ---------------------------------------
function num = fnumeric(f, offset, type)

fseek(f, offset, 'bof');
num = fread(f, 1, type, 'b');

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function num = farray(f, offset, type, count, skip)

fseek(f, offset, 'bof');
num = fread(f, count, type, skip, 'b');

end

% ---------------------------------------
% Data = packet
% ---------------------------------------
function data = fpacket(f, data, offset)

n = [];
y = [];

for i = 1:length(offset)
    
    fseek(f, offset(i)+12, 'bof');
    
    %x(i,1) = fread(f, 1, 'int32', 6, 'b');
    n(i,1) = fread(f, 1, 'int16', 4, 'b');
    y(:,end+1:end+n(i)) = fread(f, [2, n(i)], 'uint16', 'b');
    
end

% Mass values
y(1,:) = y(1,:) ./ 20;

data.channel = unique(y(1,:));

[~, index] = ismember(y(1,:), data.channel);

data.channel = [0, data.channel];

% Intensity values
data.intensity(numel(data.time), numel(data.channel)) = 0;

n(:,2) = cumsum(n);
n(:,3) = n(:,2) - n(:,1) + 1;

e = bitand(int32(y(2,:)), int32(49152));
y = bitand(int32(y(2,:)), int32(16383));

while any(e) ~= 0
    y(e~=0) = bitshift(int32(y(e~=0)), 3);
    e(e~=0) = e(e~=0) - 16384;
end
    
for i = 1:numel(data.time)
    data.intensity(i, index(n(i,3):n(i,2))+1) = y(n(i,3):n(i,2));
end

end

% ---------------------------------------
% Data = time vector
% ---------------------------------------
function x = ftime(start, stop, count)

if count > 2
    x = linspace(start, stop, count)';
else
    x = [start; stop];
end

end

% ---------------------------------------
% Data = delta compression
% ---------------------------------------
function y = fdelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
y = zeros(floor(n/2), 1);

buffer = [0,0,0,0,0];

while ftell(f) < n
    
    buffer(1) = fread(f, 1, 'int16', 'b');
    buffer(2) = buffer(4);
    
    if bitshift(int16(buffer(1)), -12) ~= 0
        
        for j = 1:bitand(int16(buffer(1)), int16(4095))
            
            buffer(3) = fread(f, 1, 'int16', 'b');
            buffer(5) = buffer(5) + 1;
            
            if buffer(3) ~= -32768
                buffer(2) = buffer(2) + buffer(3);
            else
                buffer(2) = fread(f, 1, 'int32', 'b');
            end
            
            y(buffer(5),1) = buffer(2);
            
        end
        
        buffer(4) = buffer(2);
        
    else
        break
    end
    
end

if buffer(5)+1 < length(y)
    y(buffer(5)+1:end) = [];
end

end

% ---------------------------------------
% Data = double delta compression
% ---------------------------------------
function y = fdoubledelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
y = zeros(floor(n/2), 1);

buffer = [0,0,0,0];

while ftell(f) < n
    
    buffer(3) = fread(f, 1, 'int16', 'b');
    buffer(4) = buffer(4) + 1;
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(f, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(f, 1, 'int32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    y(buffer(4),1) = buffer(1);
    
end

if buffer(4)+1 < length(y)
    y(buffer(4)+1:end) = [];
end

end

% ---------------------------------------
% Data = double array
% ---------------------------------------
function y = fdoublearray(f, offset)

fseek(f, 0, 'eof');
n = floor((ftell(f) - offset) / 8);

fseek(f, offset, 'bof');
y = fread(f, n, 'float64', 'l');

end