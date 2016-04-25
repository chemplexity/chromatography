% ------------------------------------------------------------------------
% Method      : ImportAgilent
% Description : Import Agilent data files (.D, .MS, .CH, .UV)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent(Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   'filepath' (optional)
%       Description : file or folder path
%       Type        : string or cell
%       Default     : opens file selection interface
%
%   'filedepth' (optional)
%       Description : subfolder search depth
%       Type        : integer
%       Options     : >= 0
%       Default     : 1
%
%   'filecontent' (optional)
%       Description : import file metadata or raw signal data or both
%       Type        : string
%       Options     : 'all', 'metadata', 'data'
%       Default     : 'all'
%
%   'verbose' (optional)
%       Description : display import progress in command window
%       Type        : string
%       Options     : 'on', 'off'
%       Default     : 'on'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportAgilent()
%   data = ImportAgilent('filepath', {'/Data/2014/01/', '/Data/2013/01/'})
%   data = ImportAgilent('filepath', {'00201F.D', '00201B.D', '00301F.D'})
%   data = ImportAgilent('filepath', '/Data/2014/', 'filedepth', 6)
%   data = ImportAgilent('filedepth', 6)
%   data = ImportAgilent('filetype', '.CH')
%   data = ImportAgilent('filecontent', 'metadata', 'filedepth', 8)
%   data = ImportAgilent('verbose', 'off')


function data = ImportAgilent(varargin)

% ---------------------------------------
% Initialize
% ---------------------------------------
data      = [];
filelist  = [];
supported = {'.MS', '.CH', '.UV'};

% ---------------------------------------
% Defaults
% ---------------------------------------
default.path    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.D', '.MS', '.CH', '.UV'};

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addParameter(p,...
    'filepath',...
    default.path,...
    @(x) validateattributes(x, {'char', 'cell'}, {'nonempty'}));

addParameter(p,...
    'filedepth',...
    default.depth,...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));

addParameter(p,...
    'filecontent',...
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
option.path    = p.Results.filepath;
option.depth   = p.Results.filedepth;
option.content = p.Results.filecontent;
option.verbose = p.Results.verbose;

% ---------------------------------------
% Validate
% ---------------------------------------
if ~isempty(option.path)
    
    if iscell(option.path)
        option.path(~cellfun(@ischar, option.path)) = [];
        
    elseif ischar(option.path)
        option.path = {option.path};    
    end
    
end
    
if ~any(strcmpi(option.content, {'all', 'metadata', 'data'}))
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
if isempty(option.path)
    
    % Get files from file selection interface
    filelist = FileUI();
    
else
    
    % Get files from user input
    for i = 1:length(option.path)

        [~, filepath] = fileattrib(option.path{i});
        
        if isstruct(filepath)
            filelist = [filelist; filepath];
        end        
    end
end

if isempty(filelist)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
end

if sum([filelist.directory]) == 0
    option.depth = 0;
end

% ---------------------------------------
% Search subfolders
% ---------------------------------------
n = [1, length(filelist)];
l = 1;

% Recursive file search
while option.depth > 0
    
    status(option.verbose, 4, l, n(2)-n(1)+1);
    
    for i = n(1):n(2)
        
        [~,~,ext] = fileparts(filelist(i).Name);
        
        if any(strcmpi(ext, {'.M', '.git', '.lnk'}))
            continue
            
        elseif filelist(i).directory == 1
            
            f = dir(filelist(i).Name);
            f(cellfun(@(x) any(strcmpi(x,{'.','..'})), {f.name})) = [];
            
            for j = 1:length(f)
                
                filepath = [filelist(i).Name, filesep, f(j).name];
                [~, filepath] = fileattrib(filepath);
                
                if isstruct(filepath)
                    [~, ~, ext] = fileparts(filepath.Name);
                    
                    if any(strcmpi(ext, supported)) || filepath.directory
                        filelist = [filelist; filepath];
                    end
                end
            end
        end
    end
    
    if length(filelist) <= n(2)
        break
    end
    
    n = [n(2) + 1, length(filelist)];
    l = l + 1;
    
    option.depth = option.depth - 1;
end

% ---------------------------------------
% Filter 
% ---------------------------------------
[~,~,filetype] = cellfun(@(x) fileparts(x), {filelist.Name}, 'uniformoutput', 0);

filelist(cellfun(@(x) ~any(strcmpi(x, {'.MS','.CH','.UV'})), filetype)) = [];

if isempty(filelist)
    status(option.verbose, 2);
    status(option.verbose, 3);
    return
else
    status(option.verbose, 5, length(filelist));
end

% ---------------------------------------
% Data
% ---------------------------------------
data.file.version     = [];
data.file.info        = [];
data.sample.name      = [];
data.sample.info      = [];
data.sample.operator  = [];
data.sample.datetime  = [];
data.sample.inlet     = [];
data.sample.detector  = [];
data.sample.method    = [];
data.sample.seqindex  = [];
data.sample.vial      = [];
data.sample.replicate = [];
data.time             = [];
data.intensity        = [];
data.channel          = [];

% ---------------------------------------
% Import
% ---------------------------------------
for i = 1:length(filelist)
    
    status(option.verbose, 6, i, length(filelist), filelist(i).Name);

    data(i,1).file.name = filelist(i).Name;
    
    f = fopen(filelist(i).Name, 'r');
    
    switch option.content
        
        case {'all', 'data'}
            data(i,1) = parseinfo(f);
            data(i,1) = parsedata(f, data(i,1));
            
        case 'metadata'
            data(i,1) = parseinfo(f);
    end
    
    fclose(f);
    
end

file = [data.file];
data(cellfun(@isempty, {file.version})) = [];

status(option.verbose, 3);

end

% ---------------------------------------
% Status
% ---------------------------------------
function status(varargin)
        
    if ~varargin{1}
        return
    end

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
            fprintf(['[STATUS] Files   : ', num2str(varargin{3}), '\n\n']);

        % [LOADING]
        case 6
            fprintf(['[LOADING] (', num2str(varargin{3}), '/', num2str(varargin{4}), ')']);
            fprintf(' %s \n', varargin{5});

    end
end

% ---------------------------------------
% FileUI
% ---------------------------------------
function filelist = FileUI()

% ---------------------------------------
% JFileChooser (Java)
% ---------------------------------------
fc = javax.swing.JFileChooser(java.io.File(pwd));

% Selection options
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
filelist = [];
status = fc.showOpenDialog(fc);

if status == fc.APPROVE_OPTION
    
    % Get file selection
    fs = fc.getSelectedFiles();
    
    for i = 1:size(fs, 1)
        
        % Get file information
        [~, f] = fileattrib(char(fs(i).getAbsolutePath));
        
        % Append to file list
        if isstruct(f)
            filelist = [filelist; f];
        end
    end
end

end

% ---------------------------------------
% File information
% ---------------------------------------
function data = parseinfo(f)

data.file.version = fpascal(f, 0, 'uint8');

switch data.file.version

    case {'2', '8', '81', '30', '31'}
        
        data.file.info        = fpascal(f,  4,   'uint8');
        data.sample.name      = fpascal(f,  24,  'uint8');
        data.sample.info      = fpascal(f,  86,  'uint8');
        data.sample.operator  = fpascal(f,  148, 'uint8');
        data.sample.datetime  = parsedate(fpascal(f, 178, 'uint8'));
        data.sample.detector  = fpascal(f,  208, 'uint8');
        data.sample.inlet     = fpascal(f,  218, 'uint8');
        data.sample.method    = fpascal(f,  228, 'uint8');
        data.sample.seqindex  = fnumeric(f, 252, 'int16');
        data.sample.vial      = fnumeric(f, 254, 'int16');
        data.sample.replicate = fnumeric(f, 256, 'int16');
    
    case {'130', '131', '179', '181'}
     
        data.file.info        = fpascal(f,  347,  'uint16');
        data.sample.name      = fpascal(f,  858,  'uint16');
        data.sample.info      = fpascal(f,  1369, 'uint16');
        data.sample.operator  = fpascal(f,  1880, 'uint16');
        data.sample.datetime  = parsedate(fpascal(f, 2391, 'uint16'));
        data.sample.detector  = fpascal(f,  2492, 'uint16');
        data.sample.inlet     = fpascal(f,  2533, 'uint16');
        data.sample.method    = fpascal(f,  2574, 'uint16');
        data.sample.seqindex  = fnumeric(f, 252,  'int16');
        data.sample.vial      = fnumeric(f, 254,  'int16');
        data.sample.replicate = fnumeric(f, 256,  'int16');

    otherwise
        
        data.file.info        = [];
        data.sample.name      = [];
        data.sample.info      = [];
        data.sample.operator  = [];
        data.sample.datetime  = [];
        data.sample.detector  = [];
        data.sample.inlet     = [];
        data.sample.method    = [];
        data.sample.seqindex  = [];
        data.sample.vial      = [];
        data.sample.replicate = [];
end

data.time      = [];
data.intensity = [];
data.channel   = [];

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

switch data.file.version
    
    case {'2'}
        
        offset = fnumeric(f, 260, 'int32') * 2 - 2;
        scans  = fnumeric(f, 278, 'int32');
        
    case {'8', '81', '179', '181', '30', '130'}

        offset = (fnumeric(f, 264, 'int32') - 1) * 512 ;
        scans  = fnumeric(f, 278, 'int32');
end

switch data.file.version
    
    case {'81', '179', '181'}
        
        t0 = fnumeric(f, 282, 'float32') / 60000;
        t1 = fnumeric(f, 286, 'float32') / 60000;
        
    case {'2', '8', '30', '130'}
        
        t0 = fnumeric(f, 282, 'int32') / 60000;
        t1 = fnumeric(f, 286, 'int32') / 60000;
end

switch data.file.version
    
    case {'2'}
        
        offset = farray(f, offset, 'int32', scans, 8) * 2 - 2;
        data   = fpacket(f, data, offset);
        
    case {'8', '30', '130'}

        data.channel   = 1;
        data.intensity = fdelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'81', '181'}
        
        data.channel   = 1;
        data.intensity = fdoubledelta(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
        
    case {'179'}
        
        data.channel   = 1;
        data.intensity = fdoublearray(f, offset);
        data.time      = ftime(t0, t1, numel(data.intensity));
end

switch data.file.version
    
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
        
    case {'179, 181'}
        
        intercept = fnumeric(f, 4724, 'float64');
        slope     = fnumeric(f, 4732, 'float64');
        
        if slope ~= 0
            data.intensity = data.intensity .* slope + intercept;
        end
end

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
    'mm.dd.yyyy HH:MM:SS',...
    'dd-mmm-yy HH:MM:SS',...
    'dd-mmm-yy, HH:MM:SS'};

dateRegex = {...
    '\d{1,2} \w{3} \d{1,2}\s*\d{1,2}[:]\d{2} \w{2}',...
    '\d{2} \w{3} \d{2}\s*\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{2}\s*\d{2}[:]\d{2}[:]\d{2} \w{2}',...
    '\d{1,2}[/]\d{1,2}[/]\d{2}\s*\d{1,2}[:]\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{4}\s*\d{2}[:]\d{2}',...
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