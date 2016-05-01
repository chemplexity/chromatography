% ------------------------------------------------------------------------
% Method      : ImportAgilent
% Description : Read Agilent data files (.D, .MS, .CH, .UV)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent(file)
%   data = ImportAgilent( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Optional)
% ------------------------------------------------------------------------
%   file -- name of file or folder path
%       empty (default) | string | cell array
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'depth' -- subfolder search depth
%       1 (default) | integer
%
%   'content' -- read file header, signal data, or both
%       'all' (default) | 'header' | 'signal'
%
%   'verbose' -- show progress in command window
%       'on' (default) | 'off'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent('00159F.D')
%   data = ImportAgilent({'/Data/2016/04/', '00201B.D'})
%   data = ImportAgilent('/Data/2016/', 'depth', 4)
%   data = ImportAgilent('content', 'header', 'depth', 8)
%   data = ImportAgilent('verbose', 'off')

function data = ImportAgilent(varargin)

% ---------------------------------------
% Initialize
% ---------------------------------------
data      = [];
file      = [];
supported = {'.MS', '.CH', '.UV'};

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.D', '.MS', '.CH', '.UV'};

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addOptional(p,...
    'file',...
    default.file,...
    @(x) validateattributes(x, {'char', 'cell'}));

addParameter(p,...
    'depth',...
    default.depth,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));

addParameter(p,...
    'content',...
    default.content,...
    @(x) validateattributes(x, {'char'}, {'nonempty'}));

addParameter(p,...
    'verbose',...
    default.verbose,...
    @(x) validateattributes(x, {'char'}, {'nonempty'}));

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
if ~isempty(option.file)
    
    if iscell(option.file)
        option.file(~cellfun(@ischar, option.file)) = [];
        
    elseif ischar(option.file)
        option.file = {option.file};
    end
    
end

if ~any(strcmpi(option.content, {'all', 'header', 'signal'}))
    option.content, 'all';
end
    
if any(strcmpi(option.verbose, {'off', 'no', 'n'}))
    option.verbose = false;
else
    option.verbose = true;
    status(option.verbose, 1);
end

% ---------------------------------------
% File selection
% ---------------------------------------
if isempty(option.file)
    
    % Get files from file selection interface
    file = FileUI();
    
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
if isempty(file)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
end

% Check selection for folders
if sum([file.directory]) == 0
    option.depth = 0;
end

% ---------------------------------------
% Search subfolders
% ---------------------------------------
n = [1, length(file)];
l = option.depth;

while l > 0
    
    for i = n(1):n(2)
        
        [~, ~, ext] = fileparts(file(i).Name);
        
        if any(strcmpi(ext, {'.M', '.git', '.lnk'}))
            continue
            
        elseif file(i).directory == 1
            
            f = dir(file(i).Name);
            f(cellfun(@(x) any(strcmpi(x, {'.', '..'})), {f.name})) = [];
            
            for j = 1:length(f)
                
                filepath = [file(i).Name, filesep, f(j).name];
                [~, filepath] = fileattrib(filepath);
                
                if isstruct(filepath)
                    
                    [~, ~, ext] = fileparts(filepath.Name);
                    
                    if any(strcmpi(ext, supported)) || filepath.directory
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
% Filter 
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

% Remove unsupported file extensions
file(cellfun(@(x) ~any(strcmpi(x, {'.MS','.CH','.UV'})), ext)) = [];

% Check selection for files
if isempty(file)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
else
    status(option.verbose, 5, length(file));
end

% ---------------------------------------
% Data
% ---------------------------------------
data.file_path       = [];
data.file_name       = [];
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
data.time            = [];
data.intensity       = [];
data.channel         = [];
data.time_units      = [];
data.intensity_units = [];
data.channel_units   = [];

% ---------------------------------------
% Import
% ---------------------------------------
for i = 1:length(file)
    
    % Update file infomation
    [fdir, fname, fext] = fileparts(file(i).Name);
    
    data(i,1).file_path = fdir;
    data(i,1).file_name = upper([fname, fext]);
    
     % Update status
    status(option.verbose, 6, i, length(file), data(i,1).file_name);

    % Open data file
    f = fopen(file(i).Name, 'r');
    
    switch option.content
        
        case {'all', 'signal'}
            data(i,1) = parseinfo(f, data(i,1));
            data(i,1) = parsedata(f, data(i,1));
            
        case 'header'
            data(i,1) = parseinfo(f, data(i,1));
    end
    
    % Close data file
    fclose(f);
    
end

% Remove unsupported files
data(cellfun(@isempty, {data.file_version})) = [];

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
            fprintf('[IMPORT]');
            fprintf(['\n', repmat('-',1,50), '\n\n']);

        % [ERROR]
        case 2
            fprintf(['[ERROR] No files found...', '\n']);
                
        % [EXIT]
        case 3
            fprintf(['\n', repmat('-',1,50), '\n']);
            fprintf('[EXIT]');
            fprintf(['\n', repmat('-',1,50), '\n']);
    
        % [STATUS]
        case 4
            fprintf(['[STATUS] Depth   : ', num2str(varargin{3}), '\n']);
            fprintf(['[STATUS] Folders : ', num2str(varargin{4}), '\n']);
            
        % [STATUS]
        case 5
            fprintf(['[STATUS] Files : ', num2str(varargin{3}), '\n\n']);

        % [LOADING]
        case 6
            fprintf(['[', num2str(varargin{3}), '/', num2str(varargin{4}), ']']);
            fprintf(' %s \n', varargin{5});

    end
end

% ---------------------------------------
% FileUI
% ---------------------------------------
function file = FileUI()

% ---------------------------------------
% JFileChooser (Java)
% ---------------------------------------
if ~usejava('swing')
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
file   = [];
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

% Parse method name
if ~isempty(data.method) && any(strfind(data.method, '.M'));
    [~, data.method] = fileparts(data.method);
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

% Signal information
switch data.file_version
    
    case {'2'}
        
        offset = fnumeric(f, 260, 'int32') * 2 - 2;
        scans  = fnumeric(f, 278, 'int32');
        
    case {'8', '81', '179', '181', '30', '130'}

        offset = (fnumeric(f, 264, 'int32') - 1) * 512 ;
        scans  = fnumeric(f, 278, 'int32');
        
    otherwise
        
        return
        
end

% Time values
switch data.file_version
    
    case {'81', '179', '181'}
        
        t0 = fnumeric(f, 282, 'float32') / 60000;
        t1 = fnumeric(f, 286, 'float32') / 60000;
        
    case {'2', '8', '30', '130'}
        
        t0 = fnumeric(f, 282, 'int32') / 60000;
        t1 = fnumeric(f, 286, 'int32') / 60000;
        
end

% Signal data
switch data.file_version
    
    case {'2'}
        
        offset = farray(f, offset, 'int32', scans, 8) * 2 - 2;
        data   = fpacket(f, data, offset);
        
    case {'8', '30', '130'}

        data.channel   = 0;
        data.intensity = fdelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'81', '181'}
        
        data.channel   = 0;
        data.intensity = fdoubledelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'179'}
        
        if fnumeric(f, offset, 'int32') == 2048
            offset = offset + 2048;
        end
        
        data.channel   = 0;
        data.intensity = fdoublearray(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
end

% Signal units
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

% Signal correction
switch data.file_version
    
    case {'8'}
        
        version   = fnumeric(f, 542, 'int32');
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        if any(version == [1,2,3])
            data.intensity = data.intensity .* 1.33321110047553;
            
        else
            data.intensity = data.intensity .* slope + intercept;
        end
        
    case {'30'}
        
        version   = fnumeric(f, 542, 'int32');
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        if all(version ~= 1,2)
            data.intensity = data.intensity .* slope + intercept;
            
        elseif version == 2
            data.intensity = data.intensity .* 0.00240841663372301;
        end

    case {'81'}
        
        intercept = fnumeric(f, 636, 'float64');
        slope     = fnumeric(f, 644, 'float64');
        
        data.intensity = data.intensity .* slope + intercept;
        
    case {'130'}
        
        version   = fnumeric(f, 4134, 'int32');
        intercept = fnumeric(f, 4724, 'float64');
        slope     = fnumeric(f, 4732, 'float64');
        
        if all(version ~= 1,2)
            data.intensity = data.intensity .* slope + intercept;
            
        elseif version == 2
            data.intensity = data.intensity .* 0.00240841663372301;
        end
        
    case {'179', '181'}
        
        intercept = fnumeric(f, 4724, 'float64');
        slope     = fnumeric(f, 4732, 'float64');
        
        if slope ~= 0
            data.intensity = data.intensity .* slope + intercept;
        end
        
end

% Determine instrument type
data.instrument = parseinstrument(data);

end

% ---------------------------------------
% Data = datetime
% ---------------------------------------
function dateStr = parsedate(dateStr)

formatOut = 'yyyy/mm/dd HH:MM:SS';

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
    
else
    dateStr = [];
end

end

% ---------------------------------------
% Data = instrument
% ---------------------------------------
function instrStr = parseinstrument(data)

instrMatch = @(x,str) any(cellfun(@any, regexpi(x, str)));

instrRegex.DAD = {'DAD', '1040', '1050', '1315', '4212', '7117'};
instrRegex.VWD = {'VWD', '1314', '7114'};
instrRegex.MWD = {'MWD', '1365'};
instrRegex.FLD = {'FLD', '1321'};
instrRegex.RID = {'RID', '1362'};
instrRegex.ADC = {'ADC', '35900'};
instrRegex.ELS = {'ELS', 'GCI', '4260', '7102'};

instrInfo = [...
    data.file_info,...
    data.inlet,...
    data.detector,...
    data.channel_units];

switch data.file_version

    case {'2'}
        
        if instrMatch(instrInfo, {'CE'})
            instrStr = 'CE/MS';
        elseif instrMatch(instrInfo, {'LC'})
            instrStr = 'LC/MS';
        elseif instrMatch(instrInfo, {'GC'})
            instrStr = 'GC/MS';
        else
            instrStr = 'MS';
        end
        
    case {'8', '81', '179', '181'}
        
        if instrMatch(instrInfo, {'GC'})
            instrStr = 'GC/FID'; 
        else
            instrStr = 'GC';
        end
        
    case {'30', '31', '130', '131'}
        
        if instrMatch(instrInfo, instrRegex.DAD)
            instrStr = 'LC/DAD';
        elseif instrMatch(instrInfo, instrRegex.VWD)
            instrStr = 'LC/VWD';
        elseif instrMatch(instrInfo, instrRegex.MWD)
            instrStr = 'LC/MWD';
        elseif instrMatch(instrInfo, instrRegex.FLD)
            instrStr = 'LC/FLD';
        elseif instrMatch(instrInfo, instrRegex.RID)
            instrStr = 'LC/RID';
        elseif instrMatch(instrInfo, instrRegex.ADC)
            instrStr = 'LC/ADC';
        elseif instrMatch(instrInfo, instrRegex.ELS)
            instrStr = 'LC/ELSD';
        elseif instrMatch(instrInfo, {'CE'})
            instrStr = 'CE';
        else
            instrStr = 'LC';
        end
        
    otherwise
        instrStr = '';
        
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

x = [];
y = [];
n = [];

for i = 1:length(offset)
    
    fseek(f, offset(i)+2, 'bof');
    
    x(i,1) = fread(f, 1, 'int32', 6, 'b');
    n(i,1) = fread(f, 1, 'int16', 4, 'b');
    
    y(:,end+1:end+n(i)) = fread(f, [2, n(i)], 'uint16', 'b');
    
end

z = y(1,:) ./ 20;

n(:,2) = cumsum(n);
n(:,3) = n(:,2) - n(:,1) + 1;

% Int to Float
e = bitand(y(2,:), 49152, 'int32');
y = bitand(y(2,:), 16383, 'int32');

while any(e) ~= 0
    y(e~=0) = bitshift(y(e~=0), 3, 'int32');
    e(e~=0) = e(e~=0) - 16384;
end

% Time values
data.time = x ./ 60000;

% Channel values
data.channel = unique(z, 'sorted');

[~, index] = ismember(z, data.channel);

% Intensity values
data.intensity = zeros(numel(data.time), numel(data.channel));

for i = 1:numel(data.time)
    data.intensity(i, index(n(i,3):n(i,2))) = y(n(i,3):n(i,2));
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
    
    if bitshift(buffer(1), -12, 'int16') ~= 0
        
        for j = 1:bitand(buffer(1), 4095, 'int16');
            
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