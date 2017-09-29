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
%   'content' -- read all data or header only
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
%   data = ImportAgilent('content', 'metadata', 'depth', 8)
%   data = ImportAgilent('verbose', 'off')

% ---------------------------------------
% Data
% ---------------------------------------
data = struct(...
    'file_path',        [],...
    'file_name',        [],...
    'file_size',        [],...
    'file_info',        [],...
    'file_version',     [],...
    'sample_name',      [],...
    'sample_info',      [],...
    'barcode',          [],...
    'operator',         [],...
    'datetime',         [],...
    'instrument',       [],...
    'instmodel',        [],...
    'inlet',            [],...
    'method_name',      [],...
    'seqindex',         [],...
    'vial',             [],...
    'replicate',        [],...
    'glp_flag',         [],...
    'data_source',      [],...
    'firmware_rev',     [],...
    'software_rev',     [],...
    'dir_type',         [],...
    'dir_offset',       [],...
    'data_offset',      [],...
    'num_records',      [],...
    'start_time',       [],...
    'end_time',         [],...
    'channel_max',      [],...
    'channel_min',      [],...
    'channel_detector', [],...
    'channel_desc',     [],...
    'signal_version',   [],... 
    'signal_slope',     [],...
    'signal_intercept', [],...
    'sampling_rate',    [],...
    'time',             [],...
    'intensity',        [],...
    'channel',          [],...
    'time_units',       [],...
    'intensity_units',  [],...
    'channel_units',    []);

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.MS', '.CH', '.UV'};

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
addParameter(p, 'depth',   default.depth);
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
if ischar(option.depth) && ~isnan(str2double(option.depth))
    option.depth = round(str2double(default.depth));
elseif ~isnumeric(option.depth)
    option.depth = default.depth;
elseif option.depth < 0 || isnan(option.depth) || isinf(option.depth)
    option.depth = default.depth;
else
    option.depth = round(option.depth);
end

% Parameter: 'content'
if ~any(strcmpi(option.content, {'default', 'all', 'metadata', 'header'}))
    option.content = 'all';
end

% Parameter: 'verbose'
if any(strcmpi(option.verbose, {'off', 'no', 'n', 'false', '0'}))
    option.verbose = false;
else
    option.verbose = true;
end

% ---------------------------------------
% File selection
% ---------------------------------------
status(option.verbose, 'import');

if isempty(option.file)
    [file, fileError] = FileUI([]);
else
    file = FileVerify(option.file, []);
end

if exist('fileError', 'var') && fileError == 1
    status(option.verbose, 'selection_cancel');
    status(option.verbose, 'exit');
    return
    
elseif exist('fileError', 'var') && fileError == 2
    status(option.verbose, 'java_error');
    status(option.verbose, 'exit');
    return
    
elseif isempty(file)
    status(option.verbose, 'file_error');
    status(option.verbose, 'exit');
    return
end

% ---------------------------------------
% Search subfolders
% ---------------------------------------
if sum([file.directory]) == 0
    option.depth = 0;
else
    status(option.verbose, 'subfolder_search');
    file = parsesubfolder(file, option.depth, default.formats);
end

% ---------------------------------------
% Filter unsupported files
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

file(cellfun(@(x) ~any(strcmpi(x, default.formats)), ext)) = [];

if isempty(file)
    status(option.verbose, 'selection_error');
    status(option.verbose, 'exit');
    return
else
    status(option.verbose, 'file_count', length(file));
end

% ---------------------------------------
% Import
% ---------------------------------------
tic;

for i = 1:length(file)
    
    % ---------------------------------------
    % Permissions
    % ---------------------------------------
    if ~file(i).UserRead || file(i). directory
        continue
    end
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    [filePath, fileName, fileExt] = fileparts(file(i).Name);
    [parentPath, parentName, parentExt] = fileparts(filePath);
    
    if strcmpi(parentExt, '.D')
        data(i,1).file_path = parentPath;
        data(i,1).file_name = [parentName, parentExt, filesep, fileName, fileExt];
    else
        data(i,1).file_path = filePath;
        data(i,1).file_name = [fileName, fileExt];
    end
    
    data(i,1).file_size = subsref(dir(file(i).Name), substruct('.', 'bytes'));
    
    % ---------------------------------------
    % Status
    % ---------------------------------------
    [~, statusPath] = fileparts(data(i,1).file_path);
    statusPath = ['..', filesep, statusPath, filesep, data(i,1).file_name];
    
    status(option.verbose, 'loading_file', i, length(file));
    status(option.verbose, 'file_name', statusPath);
    status(option.verbose, 'loading_stats', data(i,1).file_size);
    
    if data(i,1).file_size == 0
        continue
    end
    
    % ---------------------------------------
    % Read
    % ---------------------------------------
    f = fopen(file(i).Name, 'r');
    
    switch option.content
        
        case {'all', 'default'}
            
            data(i,1) = parseinfo(f, data(i,1));
            data(i,1) = parsedata(f, data(i,1));
            
        case {'metadata', 'header'}
            
            data(i,1) = parseinfo(f, data(i,1));
            
    end
    
    fclose(f);
    
end

% ---------------------------------------
% Exit
% ---------------------------------------
status(option.verbose, 'stats', length(data), toc, sum([data.file_size]));
status(option.verbose, 'exit');

end

% ---------------------------------------
% Status
% ---------------------------------------
function status(varargin)

if ~varargin{1}
    return
end

switch varargin{2}
    
    case 'exit'
        fprintf(['\n', repmat('-',1,50), '\n']);
        fprintf(' EXIT');
        fprintf(['\n', repmat('-',1,50), '\n']);
        
    case 'file_count'
        fprintf([' STATUS  Importing ', num2str(varargin{3}), ' files...', '\n\n']);
        
    case 'file_name'
        fprintf(' %s', varargin{3});
        
    case 'import'
        fprintf(['\n', repmat('-',1,50), '\n']);
        fprintf(' IMPORT');
        fprintf(['\n', repmat('-',1,50), '\n\n']);
        
    case 'java_error'
        fprintf([' STATUS  Unable to load file selection interface...', '\n']);
        
    case 'loading_file'
        m = num2str(varargin{3});
        n = num2str(varargin{4});
        fprintf([' [', [repmat('0', 1, length(n) - length(m)), m], '/', n, ']']);
        
    case 'loading_stats'
        fprintf([' (', parsebytes(varargin{3}), ')\n']);
        
    case 'selection_cancel'
        fprintf([' STATUS  No files selected...', '\n']);
        
    case 'selection_error'
        fprintf([' STATUS  No files found...', '\n']);
        
    case 'subfolder_search'
        fprintf([' STATUS  Searching subfolders...', '\n']);
        
    case 'stats'
        fprintf(['\n Files   : ', num2str(varargin{3})]);
        fprintf(['\n Elapsed : ', parsetime(varargin{4})]);
        fprintf(['\n Bytes   : ', parsebytes(varargin{5}),'\n']);
        
end

end

% ---------------------------------------
% FileUI
% ---------------------------------------
function [file, status] = FileUI(file)

if ~usejava('swing')
    status = 2;
    return
end

% JFileChooser (Java)
fc = javax.swing.JFileChooser(java.io.File(pwd));

% Options
fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
fc.setMultiSelectionEnabled(true);
fc.setAcceptAllFileFilterUsed(false);

% Filter: Agilent (.D, .MS, .CH, .UV)
agilent = com.mathworks.hg.util.dFilter;

agilent.setDescription('Agilent files (*.D, *.MS, *.CH, *.UV)');
agilent.addExtension('d');
agilent.addExtension('ms');
agilent.addExtension('ch');
agilent.addExtension('uv');

fc.addChoosableFileFilter(agilent);

% Initialize UI
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
% File verification
% ---------------------------------------
function file = FileVerify(str, file)

for i = 1:length(str)
    
    [~, f] = fileattrib(str{i});
    
    if isstruct(f)
        file = [file; f];
    end
    
end

end

% ---------------------------------------
% Subfolder contents
% ---------------------------------------
function file = parsesubfolder(file, searchDepth, fileType)

searchIndex = [1, length(file)];

while searchDepth >= 0
    
    for i = searchIndex(1):searchIndex(2)
        
        [~, ~, fileExt] = fileparts(file(i).Name);
        
        if any(strcmpi(fileExt, {'.m', '.git', '.lnk'}))
            continue
        elseif file(i).directory == 1
            file = parsedirectory(file, i, fileType);
        end
        
    end
    
    if length(file) > searchIndex(2)
        searchDepth = searchDepth-1;
        searchIndex = [searchIndex(2)+1, length(file)];
    else
        break
    end
end

end

% ---------------------------------------
% Directory contents
% ---------------------------------------
function file = parsedirectory(file, fileIndex, fileType)

filePath = dir(file(fileIndex).Name);
filePath(cellfun(@(x) any(strcmpi(x, {'.', '..'})), {filePath.name})) = [];

for i = 1:length(filePath)
    
    fileName = [file(fileIndex).Name, filesep, filePath(i).name];
    [~, fileName] = fileattrib(fileName);
    
    if isstruct(fileName)
        [~, ~, fileExt] = fileparts(fileName.Name);
        
        if fileName.directory || any(strcmpi(fileExt, fileType))
            file = [file; fileName];
        end
    end
end

end

% ---------------------------------------
% Format byte string
% ---------------------------------------
function str = parsebytes(x)

if x > 1E9
    str = [num2str(x/1E9, '%.1f'), ' GB'];
elseif x > 1E6
    str = [num2str(x/1E6, '%.1f'), ' MB'];
elseif x > 1E3
    str = [num2str(x/1E3, '%.1f'), ' KB'];
else
    str = [num2str(x/1E3, '%.3f'), ' KB'];
end

end

% ---------------------------------------
% Format time string
% ---------------------------------------
function str = parsetime(x)

if x > 60
    str = [num2str(x/60, '%.1f'), ' min'];
else
    str = [num2str(x, '%.1f'), ' sec'];
end

end

% ---------------------------------------
% File metadata
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
    
    case {'2'}
        
        data.file_info        = fpascal(f,   4,    'uint8');
        data.sample_name      = fpascal(f,   24,   'uint8');
        data.sample_info      = fpascal(f,   86,   'uint8');
        data.operator         = fpascal(f,   148,  'uint8');
        data.datetime         = fpascal(f,   178,  'uint8');
        data.instmodel        = fpascal(f,   208,  'uint8');
        data.inlet            = fpascal(f,   218,  'uint8');
        data.method_name      = fpascal(f,   228,  'uint8');
        data.seqindex         = fnumeric(f,  252,  'int16');
        data.vial             = fnumeric(f,  254,  'int16');
        data.replicate        = fnumeric(f,  256,  'int16');
        
    case {'8', '81', '30', '31'}
        
        data.file_info        = fpascal(f,   4,    'uint8');
        data.sample_name      = fpascal(f,   24,   'uint8');
        data.barcode          = fpascal(f,   86,   'uint8');
        data.operator         = fpascal(f,   148,  'uint8');
        data.datetime         = fpascal(f,   178,  'uint8');
        data.instmodel        = fpascal(f,   208,  'uint8');
        data.inlet            = fpascal(f,   218,  'uint8');
        data.method_name      = fpascal(f,   228,  'uint8');
        data.seqindex         = fnumeric(f,  252,  'int16');
        data.vial             = fnumeric(f,  254,  'int16');
        data.replicate        = fnumeric(f,  256,  'int16');
        
    case {'130', '131', '179', '181'}
        
        data.file_info        = fpascal(f,   347,  'uint16');
        data.sample_name      = fpascal(f,   858,  'uint16');
        data.barcode          = fpascal(f,   1369, 'uint16');
        data.operator         = fpascal(f,   1880, 'uint16');
        data.datetime         = fpascal(f,   2391, 'uint16');
        data.instmodel        = fpascal(f,   2492, 'uint16');
        data.inlet            = fpascal(f,   2533, 'uint16');
        data.method_name      = fpascal(f,   2574, 'uint16');
        data.seqindex         = fnumeric(f,  252,  'int16');
        data.vial             = fnumeric(f,  254,  'int16');
        data.replicate        = fnumeric(f,  256,  'int16');
        
end

switch data.file_version
    
    case {'81', '179', '181'}
        
        data.start_time       = fnumeric(f,  282,  'float32');
        data.end_time         = fnumeric(f,  286,  'float32');
        data.channel_max      = fnumeric(f,  290,  'float32');
        data.channel_min      = fnumeric(f,  294,  'float32');
        
    case {'2', '8', '30', '31', '130', '131'}
        
        data.start_time       = fnumeric(f,  282,  'int32');
        data.end_time         = fnumeric(f,  286,  'int32');
        data.channel_max      = fnumeric(f,  290,  'int32');
        data.channel_min      = fnumeric(f,  294,  'int32');
        
end

if ~isempty(data.start_time)
    data.start_time = data.start_time / 6E4;
end

if ~isempty(data.end_time)
    data.end_time = data.end_time / 6E4;
end

switch data.file_version
    
    case {'2'}
        
        data.dir_type         = fnumeric(f,  258,  'int16');
        data.dir_offset       = fnumeric(f,  260,  'int32');
        data.data_offset      = fnumeric(f,  264,  'int32');
        data.num_records      = fnumeric(f,  278,  'int32');
        
        if ~isempty(data.dir_offset)
            data.dir_offset = data.dir_offset * 2 - 2;
        end
        
        if ~isempty(data.data_offset)
            data.data_offset = data.data_offset * 2 - 2;
        end
        
    case {'8', '30', '31', '81', '130', '131', '179', '181'}
        
        data.dir_type         = fnumeric(f,  258,  'int16');
        data.dir_offset       = fnumeric(f,  260,  'int32');
        data.data_offset      = fnumeric(f,  264,  'int32');
        data.num_records      = fnumeric(f,  278,  'int32');
        
        if data.dir_type && ~isempty(data.dir_offset)
            data.dir_offset = (data.dir_offset - 1) * 512;
        end
        
        if ~isempty(data.data_offset)
            data.data_offset = (data.data_offset - 1) * 512;
        end
        
end

switch data.file_version
    
    case {'30'}
        
        data.glp_flag         = fnumeric(f,  318,  'int32');
        data.data_source      = fpascal(f,   322,  'uint8');
        data.firmware_rev     = fpascal(f,   355,  'uint8');
        data.software_rev     = fpascal(f,   405,  'uint8');
        
    case {'130', '179'}%, '181'}
        
        data.glp_flag         = fnumeric(f,  3085, 'int32');
        data.data_source      = fpascal(f,   3089, 'uint16');
        data.firmware_rev     = fpascal(f,   3601, 'uint16');
        data.software_rev     = fpascal(f,   3802, 'uint16');
        
end

% Acquisition
switch data.file_version
    
    case {'2'}
        
        data.intensity_units  = 'counts';
        data.channel_units    = 'm/z';
        
    case {'8', '81', '30'}
        
        data.channel_detector = fnumeric(f,  514,  'int16');
        data.channel_units    = fpascal(f,   580,  'uint8');
        data.channel_desc     = fpascal(f,   596,  'uint8');
        
    case {'31'}
        
        data.channel_detector = fnumeric(f,  342,  'int16');
        data.channel_units    = fpascal(f,   326,  'uint8');
        data.channel_desc     = fpascal(f,   344,  'uint8');
        
    case {'130', '179', '181'}
        
        data.channel_detector = fnumeric(f,  4106, 'int16');
        data.channel_units    = fpascal(f,   4172, 'uint16');
        data.channel_desc     = fpascal(f,   4213, 'uint16');
        
    case {'131'}
        
        data.channel_detector = fnumeric(f,  3134, 'int16');
        data.channel_units    = fpascal(f,   3093, 'uint16');
        data.channel_desc     = fpascal(f,   3136, 'uint16');
        
end

if ~isempty(data.datetime)
    data.datetime = parsedate(data.datetime);
end

data.instrument = parseinstrument(data);
data.instmodel  = upper(data.instmodel);
data.inlet      = upper(data.inlet);
data.operator   = upper(data.operator);

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

if isempty(data.file_version)
    return
end

% Read total intensity values
switch data.file_version
    
    case {'2'}
        
        x = fdirectory(f, data.dir_offset, data.num_records);
        
        data.data_offset = x.spectrum_offset;
        data.time        = x.retention_time;
        data.intensity   = x.total_abundance;
        
end

% Read intensity values
switch data.file_version
    
    case {'2'}
        
        data = fscan(f, data, data.data_offset);
        
    case {'8', '30', '130'}
        
        data.intensity  = fdelta(f, data.data_offset);
        data.time       = ftime(data.start_time, data.end_time, numel(data.intensity));
        
    case {'81', '181'}
        
        data.intensity = fdoubledelta(f, data.data_offset);
        data.time      = ftime(data.start_time, data.end_time, numel(data.intensity));
        
    case {'179'}
        
        if fnumeric(f, data.data_offset, 'int32') == 2048
            data.data_offset = data.data_offset + 2048;
        end
        
        data.intensity = fdoublearray(f, data.data_offset);
        data.time      = ftime(data.start_time, data.end_time, numel(data.intensity));
        
end

% Units
switch data.file_version
    
    case {'2'}
        
        if ~isempty(data.time)
            data.time_units = 'minutes';
        end
        
    case {'8', '30', '31', '81', '130', '131', '179', '181'}
        
        if ~isempty(data.time)
            data.time_units = 'minutes';
        end
        
end

% Scaling
switch data.file_version
    
    case {'30'}
        
        data.signal_version = fnumeric(f, 542, 'int32');
        
        switch data.signal_version
            case {1}
                data.signal_intercept = 0;
                data.signal_slope     = 1;
            case {2}
                data.signal_intercept = 0;
                data.signal_slope     = 0.00240841663372301;
            otherwise
                data.signal_intercept = fnumeric(f, 636, 'float64');
                data.signal_slope     = fnumeric(f, 644, 'float64');
        end
        
    case {'130'}
        
        data.signal_version = fnumeric(f, 4134, 'int32');
        
        switch data.signal_version
            case {1}
                data.signal_intercept = 0;
                data.signal_slope     = 1;
            case {2}
                data.signal_intercept = 0;
                data.signal_slope     = 0.00240841663372301;
            otherwise
                data.signal_intercept = fnumeric(f, 4724, 'float64');
                data.signal_slope     = fnumeric(f, 4732, 'float64');
        end
        
    case {'8'}
        
        data.signal_version = fnumeric(f, 542, 'int32');
        
        switch data.signal_version
            case {1, 2, 3}
                data.signal_intercept = 0;
                data.signal_slope     = 1.33321110047553;
            otherwise
                data.signal_intercept = fnumeric(f, 636, 'float64');
                data.signal_slope     = fnumeric(f, 644, 'float64');
        end
        
    case {'81'}
        
        data.signal_intercept = fnumeric(f, 636, 'float64');
        data.signal_slope     = fnumeric(f, 644, 'float64');
        
    case {'179', '181'}
        
        data.signal_intercept = fnumeric(f, 4724, 'float64');
        data.signal_slope     = fnumeric(f, 4732, 'float64');
        
end

switch data.file_version
    
    case {'8', '30', '31', '81', '130', '131', '179', '181'}
     
        if ~isempty(data.intensity)
            if ~isempty(data.signal_slope) && ~isempty(data.signal_intercept)
                data.intensity = data.intensity .* data.signal_slope + data.signal_intercept;
            end
        end
        
end

% Sampling Rate
if ~isempty(data.time)
    data.sampling_rate = round(1./mean(diff(data.time.*60)));
end

end

% ---------------------------------------
% Data = datetime
% ---------------------------------------
function str = parsedate(str)

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

if ~isempty(str)
    
    dateMatch = regexp(str, dateRegex, 'match');
    dateIndex = find(~cellfun(@isempty, dateMatch), 1);
    
    if ~isempty(dateIndex)
        dateNum = datenum(str, dateFormat{dateIndex});
        str = datestr(dateNum, formatOut);
    end
    
end

end

% ---------------------------------------
% Data = instrument string
% ---------------------------------------
function str = parseinstrument(data)

instrMatch = @(x,str) any(cellfun(@any, regexpi(x, str)));

str = [...
    data.file_info,...
    data.inlet,...
    data.instmodel,...
    data.channel_units,...
    data.channel_desc];

if isempty(str)
    return
end

switch data.file_version
    
    case {'2'}
        
        if instrMatch(str, {'CE'})
            str = 'CE/MS';
        elseif instrMatch(str, {'LC'})
            str = 'LC/MS';
        elseif instrMatch(str, {'GC'})
            str = 'GC/MS';
        else
            str = 'MS';
        end
        
    case {'8', '81', '179', '181'}
        
        if instrMatch(str, {'GC'})
            str = 'GC/FID';
        else
            str = 'GC';
        end
        
    case {'30', '31', '130', '131'}
        
        if instrMatch(str, {'DAD', '1315', '4212', '7117'})
            str = 'LC/DAD';
        elseif instrMatch(str, {'VWD', '1314', '7114'})
            str = 'LC/VWD';
        elseif instrMatch(str, {'MWD', '1365'})
            str = 'LC/MWD';
        elseif instrMatch(str, {'FLD', '1321'})
            str = 'LC/FLD';
        elseif instrMatch(str, {'ELS', '4260', '7102'})
            str = 'LC/ELSD';
        elseif instrMatch(str, {'RID', '1362'})
            str = 'LC/RID';
        elseif instrMatch(str, {'ADC', '35900'})
            str = 'LC/ADC';
        elseif instrMatch(str, {'CE'})
            str = 'CE';
        else
            str = 'LC';
        end
        
    otherwise
        str = 'Unknown';
        
end

end

% ---------------------------------------
% Data = pascal string
% ---------------------------------------
function str = fpascal(f, offset, type)

fseek(f, offset, 'bof');
str = fread(f, fread(f, 1, 'uint8'), [type, '=>char'], 'l')';

if length(str) > 512
    str = '';
else
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = numeric
% ---------------------------------------
function x = fnumeric(f, offset, type)

fseek(f, offset, 'bof');
x = fread(f, 1, type, 'b');

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function x = farray(f, offset, type, count, skip)

fseek(f, offset, 'bof');
x = fread(f, count, type, skip, 'b');

end

% ---------------------------------------
% Data = mass spectra scan (quick)
% ---------------------------------------
function data = fscan(f, data, offset)

n = [];
y = [];

for i = 1:length(offset)
    fseek(f, offset(i)+12, 'bof');
    n(i,1) = fread(f, 1, 'int16', 4, 'b');
    y(:,end+1:end+n(i)) = fread(f, [2, n(i)], 'uint16', 'b');
end

% Mass values
y(1,:) = y(1,:) ./ 20;

data.channel = unique(y(1,:));
data.channel = [0, data.channel];

[~, index] = ismember(y(1,:), data.channel(2:end));

% Intensity values
e = bitand(int32(y(2,:)), int32(49152));
y = bitand(int32(y(2,:)), int32(16383));

while any(e) ~= 0
    y(e~=0) = bitshift(int32(y(e~=0)), 3);
    e(e~=0) = e(e~=0) - 16384;
end

data.intensity(numel(data.time), numel(data.channel)) = 0;

n(:,2) = cumsum(n);
n(:,3) = n(:,2) - n(:,1) + 1;

for i = 1:numel(data.time)
    data.intensity(i, index(n(i,3):n(i,2))+1) = y(n(i,3):n(i,2));
end

end

% ---------------------------------------
% Data = mass spectra directory
% ---------------------------------------
function data = fdirectory(f, offset, scans)

data = struct(...
    'spectrum_offset', [],...
    'retention_time',  [],...
    'total_abundance', []);

fseek(f, offset, 'bof');

% Read directory contents
data.spectrum_offset = farray(f, offset,   'int32', scans, 8);
data.retention_time  = farray(f, offset+4, 'int32', scans, 8);
data.total_abundance = farray(f, offset+8, 'int32', scans, 8);

% Apply correction factors
data.spectrum_offset = data.spectrum_offset * 2 - 2;
data.retention_time  = data.retention_time  / 6E4;

end

% ---------------------------------------
% Data = mass spectra scan (long)
% ---------------------------------------
function data = fscanmz(f, offset)

data = struct(...
    'spectrum_offset',  [],...
    'total_words',      [],...
    'retention_time',   [],...
    'num_words',        [],...
    'data_type',        [],...
    'status_word',      [],...
    'num_peaks',        [],...
    'base_mass',        [],...
    'base_abundance',   [],...
    'mass_values',      [],...
    'abundance_values', []);

for i = 1:length(offset)
    
    fseek(f, offset(i), 'bof');
    
    % Read spectra properties
    data(i).spectrum_offset  = ftell(f);
    data(i).total_words      = fread(f, 1, 'int16',  'b');
    data(i).retention_time   = fread(f, 1, 'int32',  'b');
    data(i).num_words        = fread(f, 1, 'int16',  'b');
    data(i).data_type        = fread(f, 1, 'int16',  'b');
    data(i).status_word      = fread(f, 1, 'int16',  'b');
    data(i).num_peaks        = fread(f, 1, 'int16',  'b');
    data(i).base_mass        = fread(f, 1, 'uint16', 'b');
    data(i).base_abundance   = fread(f, 1, 'int16',  'b');
    
    % Read spectra data
    data(i).mass_values      = farray(f, offset(i)+18, 'uint16', data(i).num_peaks, 2);
    data(i).abundance_values = farray(f, offset(i)+20, 'int16',  data(i).num_peaks, 2);
    
    % Apply correction factors
    data(i).total_words      = data(i).total_words    * 2 - 2;
    data(i).num_words        = data(i).num_words      * 2 - 2;
    data(i).retention_time   = data(i).retention_time / 6E4;
    data(i).base_mass        = data(i).base_mass      / 2E1;
    data(i).mass_values      = data(i).mass_values    / 2E1;
    data(i).base_abundance   = unpack(data(i).base_abundance);
    data(i).abundance_values = unpack(data(i).abundance_values);
    
end

end

% ---------------------------------------
% Data = wavelength scan
% ---------------------------------------
function data = fscanvis(f, offset, detector)

data = struct(...
    'spectrum_offset',    [],...
    'identifier',         [],...
    'record_length',      [],...
    'retention_time',     [],...
    'wavelength_start',   [],...
    'wavelength_end',     [],...
    'wavelength_step',    [],...
    'spectrum_attribute', [],...
    'additional_info',    [],...
    'intensity_values',   []);

for i = 1:length(offset)
    
    fseek(f, offset(i), 'bof');
    
    % Read spectrum properties
    data(i).spectrum_offset    = ftell(f);
    data(i).identifier         = fread(f, 1, 'int16', 'l');
    data(i).record_length      = fread(f, 1, 'int16', 'l');
    data(i).retention_time     = fread(f, 1, 'int32', 'l');
    data(i).wavelength_start   = fread(f, 1, 'int16', 'l');
    data(i).wavelength_end     = fread(f, 1, 'int16', 'l');
    data(i).wavelength_step    = fread(f, 1, 'int16', 'l');
    data(i).spectrum_attribute = fread(f, 1, 'int16', 'l');
    
    % Read additional info
    n = fread(f, 1, 'int16', 'l');
    
    switch detector
        
        case 1
            % DAD: exposure_time
            data(i).additional_info = fread(f, 1, 'int32', 'l');
            
        case 2
            % FLD: complement_wavelength, scan_speed
            data(i).additional_info = fread(f, [1,2], 'int16', 'l');
            
        otherwise
            fseek(f, n, 'cof');
            
    end
    
    % Calculate number of data points
    n = (data(i).wavelength_end - data(i).wavelength_start) / data(i).wavelength_step + 1;
    n = floor(n);
    
    % Read spectrum data
    data(i).intensity_values = zeros(n, 1);
    
    if data(i).identifier ~= 65        
        
        x0 = zeros(2,1);
        
        for j = 1:n
            
            x0(1) = fread(f, 1, 'int16', 'l');
            
            if x0(1) ~= -32768
                x0(2) = x0(1) + x0(2);
            else
                x0(2) = fread(f, 1, 'int32', 'l');
            end
            
            data(i).intensity_values(j, 1) = x0(2);
            
        end
        
    else
        data(i).intensity_values = fread(f, n, 'int32', 'l');
    end
    
    % Apply correction factors
    data(i).retention_time   = data(i).retention_time   / 6E4;
    data(i).wavelength_start = data(i).wavelength_start / 2E1;
    data(i).wavelength_end   = data(i).wavelength_end   / 2E1;
    data(i).wavelength_step  = data(i).wavelength_step  / 2E1;
    
end

end

% ---------------------------------------
% Data = time vector
% ---------------------------------------
function x = ftime(start, stop, count)

if start >= stop
    x = zeros(count,1);
elseif count > 2
    x = linspace(start, stop, count);
else
    x = [start, stop];
end

x = x(:);

end

% ---------------------------------------
% Data = delta compression
% ---------------------------------------
function x = fdelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
x  = zeros(floor(n/2), 1);
x0 = zeros(5,1);

while ftell(f) < n
    
    x0(1) = fread(f, 1, 'int16', 'b');
    x0(2) = x0(4);
    
    if bitshift(int16(x0(1)), -12) ~= 0
        
        for j = 1:bitand(int16(x0(1)), int16(4095))
            
            x0(3) = fread(f, 1, 'int16', 'b');
            x0(5) = x0(5) + 1;
            
            if x0(3) ~= -32768
                x0(2) = x0(2) + x0(3);
            else
                x0(2) = fread(f, 1, 'int32', 'b');
            end
            
            x(x0(5),1) = x0(2);
            
        end
        
        x0(4) = x0(2);
        
    else
        break
    end
    
end

if x0(5)+1 < length(x)
    x(x0(5)+1:end) = [];
end

end

% ---------------------------------------
% Data = double delta compression
% ---------------------------------------
function x = fdoubledelta(f, offset)

fseek(f, 0, 'eof');
n = ftell(f);

fseek(f, offset, 'bof');
x  = zeros(floor(n/2), 1);
x0 = zeros(4,1);

while ftell(f) < n
    
    x0(3) = fread(f, 1, 'int16', 'b');
    x0(4) = x0(4) + 1;
    
    if x0(3) ~= 32767
        x0(2) = x0(2) + x0(3);
        x0(1) = x0(1) + x0(2);
    else
        x0(1) = fread(f, 1, 'int16', 'b') * 4294967296;
        x0(1) = fread(f, 1, 'uint32', 'b') + x0(1);
        x0(2) = 0;
    end
    
    x(x0(4),1) = x0(1);
    
end

if x0(4)+1 < length(x)
    x(x0(4)+1:end) = [];
end

end

% ---------------------------------------
% Data = double array
% ---------------------------------------
function x = fdoublearray(f, offset)

fseek(f, 0, 'eof');
n = floor((ftell(f) - offset) / 8);

fseek(f, offset, 'bof');
x = fread(f, n, 'float64', 'l');

end

% ---------------------------------------
% Data = int16 to int32
% ---------------------------------------
function x = unpack(x)

e = bitand(int32(x), int32(49152));
x = bitand(int32(x), int32(16383));

while any(e) ~= 0
    x(e~=0) = bitshift(int32(x(e~=0)), 3);
    e(e~=0) = e(e~=0) - 16384;
end

end