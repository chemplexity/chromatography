function varargout = ImportThermo(varargin)
% ------------------------------------------------------------------------
% Method      : ImportThermo
% Description : Read Thermo data files (.RAW)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportThermo()
%   data = ImportThermo( __ , Name, Value)
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
%   data = ImportThermo()
%   data = ImportThermo('file', '00159F.RAW')
%   data = ImportThermo('file', {'/Data/2016/04/', '00201B.RAW'})
%   data = ImportThermo('file', {'/ThermoData/2014/'}, 'depth', 4)
%   data = ImportThermo('content', 'header', 'depth', 8)
%   data = ImportThermo('verbose', 'off')
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   'unfinnigan'
%
% ------------------------------------------------------------------------
% Issues
% ------------------------------------------------------------------------
%   * Large files > 200 MB
%   * Unable to import 'profile' MS/MS data
%   * Supported file versions: V.57, V.62, V.63

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.RAW'};

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
if ~any(strcmpi(option.content, {'default', 'all', 'header'}))
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
    if ~file(i).UserRead
        continue
    end
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    [filePath, fileName, fileExt] = fileparts(file(i).Name);
    
    data(i,1).file_path = filePath;
    data(i,1).file_name = [fileName, fileExt];
    data(i,1).file_size = subsref(dir(file(i).Name), substruct('.', 'bytes'));   
    
    % ---------------------------------------
    % Status
    % ---------------------------------------
    [~, statusPath] = fileparts(data(i,1).file_path);
    statusPath = ['..', filesep, statusPath, filesep, data(i,1).file_name];
    
    status(option.verbose, 'loading_file', i, length(file));
    status(option.verbose, 'file_name', statusPath);
    status(option.verbose, 'loading_stats', data(i,1).file_size);
    
    % ---------------------------------------
    % Read
    % ---------------------------------------
    f = fopen(file(i).Name, 'r');
    
    switch option.content
        
        case {'all', 'default'}
            
            data = parseinfo(f, data(i,1));
            %data(i,1) = parsedata(f, data(i,1));
            
        case {'header'}
            
            data = parseinfo(f, data(i,1));
            
    end
    
    fclose(f);
    
end

% ---------------------------------------
% Exit
% ---------------------------------------
status(option.verbose, 'stats', length(data), toc, sum([data.file_size]));
status(option.verbose, 'exit');

varargout{1} = data;

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

% JFileChooser (Java)
if ~usejava('swing')
    status = 2;
    return
end

fc = javax.swing.JFileChooser(java.io.File(pwd));

% Options
fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
fc.setMultiSelectionEnabled(true);
fc.setAcceptAllFileFilterUsed(false);

% Filter: Thermo (.RAW)
thermo = com.mathworks.hg.util.dFilter;

thermo.setDescription('Thermo files (*.RAW)');
thermo.addExtension('raw');

fc.addChoosableFileFilter(thermo);

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
% Data = byte string
% ---------------------------------------
function str = parsebytes(x)

if x > 1E9
    str = [num2str(x/1E6, '%.1f'), ' GB'];
elseif x > 1E6
    str = [num2str(x/1E6, '%.1f'), ' MB'];
elseif x > 1E3
    str = [num2str(x/1E3, '%.1f'), ' KB'];
else
    str = [num2str(x/1E3, '%.3f'), ' KB'];
end

end

% ---------------------------------------
% Data = time string
% ---------------------------------------
function str = parsetime(x)

if x > 60
    str = [num2str(x/60, '%.1f'), ' min'];
else
    str = [num2str(x, '%.1f'), ' sec'];
end

end

% ---------------------------------------
% File header
% ---------------------------------------
function data = parseinfo(f, data)

% Data: file header
data.file_header_offset = 0;
data.file_header = FileHeader(f, data.file_header_offset);

% Data: sequence row
data.seq_row_offset = 1356;

switch data.file_header.version
    
    case {7, 8}
        data.seq_row = SeqRowA(f, data.seq_row_offset);
    case {50, 57}
        data.seq_row = SeqRowB(f, data.seq_row_offset);
    case {60, 62, 63, 64, 66}
        data.seq_row = SeqRowC(f, data.seq_row_offset); 
        
end

% Data: auto sampler info
data.autosample_info_offset = ftell(f);
data.autosampler_info = AutoSamplerInfo(f, data.autosample_info_offset);

% Data: raw file info
data.raw_file_info_offset = ftell(f);

switch data.file_header.version
    
    case {7, 8}
        data.raw_file_info = RawFileInfo8(f, data.raw_file_info_offset);
    case {50, 57, 60, 62, 63}
        data.raw_file_info = RawFileInfo32(f, data.raw_file_info_offset);
    case {64}
        data.raw_file_info = RawFileInfo64(f, data.raw_file_info_offset, 1008);
    case {66}
        data.raw_file_info = RawFileInfo64(f, data.raw_file_info_offset, 1024);

end

% Data: run header
switch data.file_header.version
    
    case {7, 8}
        data.run_header_offset = ftell(f);
    case {50, 57, 60, 62, 63, 64, 66}
        data.run_header_offset = data.raw_file_info.preamble.run_header_addr;
        
end

switch data.file_header.version
    
    case {7, 8}
        data.run_header = RunHeader8(f, data.run_header_offset);
    case {50, 57, 60, 62, 63}
        data.run_header = RunHeader32(f, data.run_header_offset);
    case {64, 66}
        data.run_header = RunHeader64(f, data.run_header_offset);

end

% Data: instrument id
data.instrument_id_offset = ftell(f);
data.instrument_id = InstID(f, data.instrument_id_offset);

% Data: method file

% Data: scan data

% Data: intstrument log

% Data: error log

% Data: scan event hiearchy

% Data: scan parameters stream
%data.scan_parameters_offset = data.run_header.scan_parameter_address;

% Data: tune file

% Data: scan index stream

% Data: scan event stream
%data.scan_trailer_offset    = data.run_header.scan_trailer_address;

end

function data = FileHeader(f, o)

data.magic_number           = fnumeric(f, o,        'uint16');
data.signature              = fstring(f,  o+2,      'uint16', 9);
data.unknown_long_1         = fnumeric(f, o+20,     'uint32');
data.unknown_long_2         = fnumeric(f, o+24,     'uint32');
data.unknown_long_3         = fnumeric(f, o+28,     'uint32');
data.unknown_long_4         = fnumeric(f, o+32,     'uint32');
data.version                = fnumeric(f, o+36,     'uint32');
data.audit_start            = AuditTag(f, o+40);
data.audit_end              = AuditTag(f, o+152);
data.unknown_long_5         = fnumeric(f, o+264,    'uint32');
data.unknown_area           = farray(f,   o+268,    '*ubit8', 60, 0);
data.tag                    = fstring(f,  o+328,    'uint16', 1028);

if ~isempty(data.magic_number)
    data.magic_number = dec2hex(data.magic_number);
end

end

function data = AuditTag(f, o)

data.timestamp_win64        = fnumeric(f, o,        'uint64');
data.tag_1                  = fstring(f,  o+8,      'uint16', 25);
data.tag_2                  = fstring(f,  o+58,     'uint16', 25);
data.unknown_long_1         = fnumeric(f, o+108,    'uint32');

end

function data = SeqRowA(f, o)

data.injection_data         = InjectionData(f, o);
data.unknown_text_1         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_2         = fpascal(f,  ftell(f), 'uint16');
data.id                     = fpascal(f,  ftell(f), 'uint16');
data.comment                = fpascal(f,  ftell(f), 'uint16');
data.user_label_1           = fpascal(f,  ftell(f), 'uint16');
data.user_label_2           = fpascal(f,  ftell(f), 'uint16');
data.user_label_3           = fpascal(f,  ftell(f), 'uint16');
data.user_label_4           = fpascal(f,  ftell(f), 'uint16');
data.user_label_5           = fpascal(f,  ftell(f), 'uint16');
data.instrument_method      = fpascal(f,  ftell(f), 'uint16');
data.processing_method      = fpascal(f,  ftell(f), 'uint16');
data.file_name              = fpascal(f,  ftell(f), 'uint16');
data.file_path              = fpascal(f,  ftell(f), 'uint16');

end

function data = SeqRowB(f, o)

data.injection_data         = InjectionData(f, o);
data.unknown_text_1         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_2         = fpascal(f,  ftell(f), 'uint16');
data.id                     = fpascal(f,  ftell(f), 'uint16');
data.comment                = fpascal(f,  ftell(f), 'uint16');
data.user_label_1           = fpascal(f,  ftell(f), 'uint16');
data.user_label_2           = fpascal(f,  ftell(f), 'uint16');
data.user_label_3           = fpascal(f,  ftell(f), 'uint16');
data.user_label_4           = fpascal(f,  ftell(f), 'uint16');
data.user_label_5           = fpascal(f,  ftell(f), 'uint16');
data.instrument_method      = fpascal(f,  ftell(f), 'uint16');
data.processing_method      = fpascal(f,  ftell(f), 'uint16');
data.file_name              = fpascal(f,  ftell(f), 'uint16');
data.file_path              = fpascal(f,  ftell(f), 'uint16');
data.vial                   = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_3         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_4         = fpascal(f,  ftell(f), 'uint16');
data.unknown_long_1         = fnumeric(f, ftell(f), 'uint32');

end

function data = SeqRowC(f, o)

data.injection_data         = InjectionData(f, o);
data.unknown_text_1         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_2         = fpascal(f,  ftell(f), 'uint16');
data.id                     = fpascal(f,  ftell(f), 'uint16');
data.comment                = fpascal(f,  ftell(f), 'uint16');
data.user_label_1           = fpascal(f,  ftell(f), 'uint16');
data.user_label_2           = fpascal(f,  ftell(f), 'uint16');
data.user_label_3           = fpascal(f,  ftell(f), 'uint16');
data.user_label_4           = fpascal(f,  ftell(f), 'uint16');
data.user_label_5           = fpascal(f,  ftell(f), 'uint16');
data.instrument_method      = fpascal(f,  ftell(f), 'uint16');
data.processing_method      = fpascal(f,  ftell(f), 'uint16');
data.file_name              = fpascal(f,  ftell(f), 'uint16');
data.file_path              = fpascal(f,  ftell(f), 'uint16');
data.vial                   = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_3         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_4         = fpascal(f,  ftell(f), 'uint16');
data.unknown_long_1         = fnumeric(f, ftell(f), 'uint32');
data.unknown_text_5         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_6         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_7         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_8         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_9         = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_10        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_11        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_12        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_13        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_14        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_15        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_16        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_17        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_18        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text_19        = fpascal(f,  ftell(f), 'uint16');

end

function data = InjectionData(f, o)

data.unknown_long_1         = fnumeric(f, o,        'uint32');
data.n                      = fnumeric(f, o+4,      'uint32');
data.unknown_long_1         = fnumeric(f, o+8,      'uint32');
data.vial                   = fstring(f,  o+12,     'uint16', 6);
data.inj_volume             = fnumeric(f, o+24,     'float64');
data.weight                 = fnumeric(f, o+32,     'float64');
data.volume                 = fnumeric(f, o+40,     'float64');
data.istd_amount            = fnumeric(f, o+48,     'float64');
data.dilution_factor        = fnumeric(f, o+56,     'float64');
        
end

function data = AutoSamplerInfo(f, o)

data.preamble               = AutoSamplerInfoPreamble(f, o);
data.text                   = fpascal(f,  ftell(f), 'uint16');

end

function data = AutoSamplerInfoPreamble(f, o)

data.unknown_long_1         = fnumeric(f, o,        'int32');
data.unknown_long_2         = fnumeric(f, o+4,      'int32');
data.number_of_wells        = fnumeric(f, o+8,      'int32');
data.unknown_long_3         = fnumeric(f, o+12,     'int32');
data.unknown_long_4         = fnumeric(f, o+16,     'int32');
data.unknown_long_5         = fnumeric(f, o+20,     'int32');

end

function data = RawFileInfo8(f, o)

data.preamble               = RawFileInfoPreamble8(f, o);
data.label_heading_1        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_2        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_3        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_4        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_5        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text           = fpascal(f,  ftell(f), 'uint16');

end

function data = RawFileInfoPreamble8(f, o)

data.unknown_long_1         = fnumeric(f, o,        'uint32');
data.datetime               = farray(f,   o+4,      'uint16', 8, 0);

if ~isempty(data.datetime)
    data.datetime = parsedate(data.datetime);
end

end

function data = RawFileInfo32(f, o)

data.preamble               = RawFileInfoPreamble32(f, o);
data.label_heading_1        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_2        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_3        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_4        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_5        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text           = fpascal(f,  ftell(f), 'uint16');

end

function data = RawFileInfoPreamble32(f, o)

data.unknown_long_1         = fnumeric(f, o,        'uint32');
data.datetime               = farray(f,   o+4,      'uint16', 8, 0);
data.unknown_long_2         = fnumeric(f, o+20,     'uint32');
data.data_addr              = fnumeric(f, o+24,     'uint32');
data.unknown_long_3         = fnumeric(f, o+28,     'uint32');
data.unknown_long_4         = fnumeric(f, o+32,     'uint32');
data.unknown_long_5         = fnumeric(f, o+36,     'uint32');
data.unknown_long_6         = fnumeric(f, o+40,     'uint32');
data.run_header_addr        = fnumeric(f, o+44,     'uint32');
data.unknown_area           = farray(f,   o+48,     '*ubit8', 756, 0);

if ~isempty(data.datetime)
    data.datetime = parsedate(data.datetime);
end

end

function data = RawFileInfo64(f, o, bytes)

data.preamble               = RawFileInfoPreamble64(f, o, bytes);
data.label_heading_1        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_2        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_3        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_4        = fpascal(f,  ftell(f), 'uint16');
data.label_heading_5        = fpascal(f,  ftell(f), 'uint16');
data.unknown_text           = fpascal(f,  ftell(f), 'uint16');

end

function data = RawFileInfoPreamble64(f, o, bytes)

data.unknown_long_1         = fnumeric(f, o,        'uint32');
data.datetime               = farray(f,   o+4,      'uint16', 8, 0);
data.unknown_long_2         = fnumeric(f, o+20,     'uint32');
data.data_addr_32           = fnumeric(f, o+24,     'uint32');
data.unknown_long_3         = fnumeric(f, o+28,     'uint32');
data.unknown_long_4         = fnumeric(f, o+32,     'uint32');
data.unknown_long_5         = fnumeric(f, o+36,     'uint32');
data.unknown_long_6         = fnumeric(f, o+40,     'uint32');
data.run_header_addr_32     = fnumeric(f, o+44,     'uint32');
data.unknown_area_1         = farray(f,   o+48,     '*ubit8', 760, 0);
data.data_addr              = fnumeric(f, o+808,    'uint64');
data.unknown_long_7         = fnumeric(f, o+816,    'uint32');
data.unknown_long_8         = fnumeric(f, o+820,    'uint32');
data.run_header_addr        = fnumeric(f, o+824,    'uint64');
data.unknown_area_2         = farray(f,   o+832,    '*ubit8', bytes, 0);

if ~isempty(data.datetime)
    data.datetime = parsedate(data.datetime);
end

end

function data = RunHeader8(f, o)

data.sample_info            = SampleInfo(f, o);
data.original_file_name     = fpascal(f,  ftell(f),    'uint16');
data.file_name_1            = fpascal(f,  ftell(f), 'uint16');
data.file_name_2            = fpascal(f,  ftell(f), 'uint16');
data.file_name_3            = fpascal(f,  ftell(f), 'uint16');

end

function data = RunHeader32(f, o)

data.sample_info            = SampleInfo(f, o);
data.file_name_1            = fstring(f,  o+592,    'uint16', 520);
data.file_name_2            = fstring(f,  o+1112,   'uint16', 520);
data.file_name_3            = fstring(f,  o+1632,   'uint16', 520);
data.file_name_4            = fstring(f,  o+2152,   'uint16', 520);
data.file_name_5            = fstring(f,  o+2672,   'uint16', 520);
data.file_name_6            = fstring(f,  o+3192,   'uint16', 520);
data.unknown_double_1       = fnumeric(f, o+3712,   'float64'); 
data.unknown_double_2       = fnumeric(f, o+3720,   'float64'); 
data.file_name_7            = fstring(f,  o+3728,   'uint16', 520);
data.file_name_8            = fstring(f,  o+4248,   'uint16', 520);
data.file_name_9            = fstring(f,  o+4768,   'uint16', 520);
data.file_name_10           = fstring(f,  o+5288,   'uint16', 520);
data.file_name_11           = fstring(f,  o+5808,   'uint16', 520);
data.file_name_12           = fstring(f,  o+6328,   'uint16', 520);
data.file_name_13           = fstring(f,  o+6848,   'uint16', 520);
data.scan_trailer_addr      = fnumeric(f, o+7368,   'uint32');
data.scan_params_addr       = fnumeric(f, o+7372,   'uint32');
data.unknown_length_1       = fnumeric(f, o+7376,   'uint32');
data.unknown_length_2       = fnumeric(f, o+7380,   'uint32');
data.number_of_segments     = fnumeric(f, o+7384,   'uint32');
data.unknown_long_1         = fnumeric(f, o+7388,   'uint32');
data.unknown_long_2         = fnumeric(f, o+7392,   'uint32');
data.own_addr               = fnumeric(f, o+7396,   'uint32');
data.unknown_long_3         = fnumeric(f, o+7400,   'uint32');
data.unknown_long_4         = fnumeric(f, o+7404,   'uint32');

end

function data = RunHeader64(f, o)

data.sample_info            = SampleInfo(f, o);
data.file_name_1            = fstring(f,  o+592,    'uint16', 520);
data.file_name_2            = fstring(f,  o+1112,   'uint16', 520);
data.file_name_3            = fstring(f,  o+1632,   'uint16', 520);
data.file_name_4            = fstring(f,  o+2152,   'uint16', 520);
data.file_name_5            = fstring(f,  o+2672,   'uint16', 520);
data.file_name_6            = fstring(f,  o+3192,   'uint16', 520);
data.unknown_double_1       = fnumeric(f, o+3712,   'float64'); 
data.unknown_double_2       = fnumeric(f, o+3720,   'float64'); 
data.file_name_7            = fstring(f,  o+3728,   'uint16', 520);
data.file_name_8            = fstring(f,  o+4248,   'uint16', 520);
data.file_name_9            = fstring(f,  o+4768,   'uint16', 520);
data.file_name_10           = fstring(f,  o+5288,   'uint16', 520);
data.file_name_11           = fstring(f,  o+5808,   'uint16', 520);
data.file_name_12           = fstring(f,  o+6328,   'uint16', 520);
data.file_name_13           = fstring(f,  o+6848,   'uint16', 520);
data.scan_trailer_addr_32   = fnumeric(f, o+7368,   'uint32');
data.scan_params_addr_32    = fnumeric(f, o+7372,   'uint32');
data.unknown_length_1       = fnumeric(f, o+7376,   'uint32');
data.unknown_length_2       = fnumeric(f, o+7380,   'uint32');
data.number_of_segments     = fnumeric(f, o+7384,   'uint32');
data.unknown_long_1         = fnumeric(f, o+7388,   'uint32');
data.unknown_long_2         = fnumeric(f, o+7392,   'uint32');
data.own_addr_32            = fnumeric(f, o+7396,   'uint32');
data.unknown_long_3         = fnumeric(f, o+7400,   'uint32');
data.unknown_long_4         = fnumeric(f, o+7404,   'uint32');
data.scan_index_addr        = fnumeric(f, o+7408,   'uint64');
data.data_addr              = fnumeric(f, o+7416,   'uint64');
data.instrument_log_addr    = fnumeric(f, o+7424,   'uint64');
data.error_log_addr         = fnumeric(f, o+7432,   'uint64');
data.unknown_addr_1         = fnumeric(f, o+7440,   'uint64');
data.scan_trailer_addr      = fnumeric(f, o+7448,   'uint64');
data.scan_params_addr       = fnumeric(f, o+7456,   'uint64');
data.unknown_addr_2         = fnumeric(f, o+7464,   'uint64');
data.own_addr               = fnumeric(f, o+7472,   'uint64');
data.unknown_long_5         = fnumeric(f, o+7480,   'uint32');
data.unknown_long_6         = fnumeric(f, o+7484,   'uint32');
data.unknown_long_7         = fnumeric(f, o+7488,   'uint32');
data.unknown_long_8         = fnumeric(f, o+7492,   'uint32');
data.unknown_long_9         = fnumeric(f, o+7496,   'uint32');
data.unknown_long_10        = fnumeric(f, o+7500,   'uint32');
data.unknown_long_11        = fnumeric(f, o+7504,   'uint32');
data.unknown_long_12        = fnumeric(f, o+7508,   'uint32');
data.unknown_long_13        = fnumeric(f, o+7512,   'uint32');
data.unknown_long_14        = fnumeric(f, o+7516,   'uint32');
data.unknown_long_15        = fnumeric(f, o+7520,   'uint32');
data.unknown_long_16        = fnumeric(f, o+7524,   'uint32');
data.unknown_long_17        = fnumeric(f, o+7528,   'uint32');
data.unknown_long_18        = fnumeric(f, o+7532,   'uint32');
data.unknown_long_19        = fnumeric(f, o+7536,   'uint32');
data.unknown_long_20        = fnumeric(f, o+7540,   'uint32');
data.unknown_long_21        = fnumeric(f, o+7544,   'uint32');
data.unknown_long_22        = fnumeric(f, o+7548,   'uint32');
data.unknown_long_23        = fnumeric(f, o+7552,   'uint32');
data.unknown_long_24        = fnumeric(f, o+7556,   'uint32');
data.unknown_long_25        = fnumeric(f, o+7560,   'uint32');
data.unknown_long_26        = fnumeric(f, o+7564,   'uint32');
data.unknown_long_27        = fnumeric(f, o+7568,   'uint32');
data.unknown_long_28        = fnumeric(f, o+7572,   'uint32');

end

function data = SampleInfo(f, o)

data.unknown_long_1         = fnumeric(f, o,        'uint32');
data.unknown_long_2         = fnumeric(f, o+4,      'uint32');
data.first_scan_number      = fnumeric(f, o+8,      'uint32');
data.last_scan_number       = fnumeric(f, o+12,     'uint32');
data.instrument_log_length  = fnumeric(f, o+16,     'uint32');
data.unknown_long_3         = fnumeric(f, o+20,     'uint32');
data.unknown_long_4         = fnumeric(f, o+24,     'uint32');
data.scan_index_addr        = fnumeric(f, o+28,     'uint32');
data.data_addr              = fnumeric(f, o+32,     'uint32');
data.instrument_log_addr    = fnumeric(f, o+36,     'uint32');
data.error_log_addr         = fnumeric(f, o+40,     'uint32');
data.unknown_long_5         = fnumeric(f, o+44,     'uint32');
data.max_ion_current        = fnumeric(f, o+48,     'float64');
data.low_mz                 = fnumeric(f, o+56,     'float64');
data.high_mz                = fnumeric(f, o+64,     'float64');
data.scan_start_time        = fnumeric(f, o+72,     'float64');
data.scan_end_time          = fnumeric(f, o+80,     'float64');
data.unknown_area           = farray(f,   o+88,     '*ubit8', 56, 0);
data.tag_1                  = fstring(f,  o+144,    'uint16', 44);
data.tag_2                  = fstring(f,  o+232,    'uint16', 20);
data.tag_3                  = fstring(f,  o+272,    'uint16', 160);

end

function data = InstID(f, o)

data.unknown_data           = farray(f,   o,        '*ubit8', 8, 0);
data.unknown_long_1         = fnumeric(f, o+8,      'uint32');
data.model_1                = fpascal(f,  ftell(f), 'uint16');
data.model_2                = fpascal(f,  ftell(f), 'uint16');
data.serial_number          = fpascal(f,  ftell(f), 'uint16');
data.software_version       = fpascal(f,  ftell(f), 'uint16');
data.tag_1                  = fpascal(f,  ftell(f), 'uint16');
data.tag_2                  = fpascal(f,  ftell(f), 'uint16');
data.tag_3                  = fpascal(f,  ftell(f), 'uint16');
data.tag_4                  = fpascal(f,  ftell(f), 'uint16');

end


function [file, data] = ScanInfo2(file, data)

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

function varargout = FormatData2(file, mz, xic, size, rows)

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

% ---------------------------------------
% Data = datetime
% ---------------------------------------
function x = parsedate(x)

% Platform
if exist('OCTAVE_VERSION', 'builtin')
    return
end

% ISO 8601
formatOut = 'yyyy-mm-ddTHH:MM:SS';

if isnumeric(x) && length(x) >= 7
    x = datenum([x(1), x(2), x(4), x(5), x(6), x(7)]);
    x = datestr(x, formatOut);
end

end

% ---------------------------------------
% Data = pascal string
% ---------------------------------------
function str = fpascal(f, offset, type)

fseek(f, offset, 'bof');

n = fread(f, 1, 'uint32');

if n > 0
    str = fread(f, n, [type, '=>char'], 'l')';
else
    str = '';
end

if length(str) > 512
    str = '';
elseif ~isempty(str)
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = fixed-length string
% ---------------------------------------
function str = fstring(f, offset, type, count)

fseek(f, offset, 'bof');

str = fread(f, count, [type, '=>char'], 'l')';

if length(str) > 512
    str = '';
elseif ~isempty(str)
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = numeric
% ---------------------------------------
function x = fnumeric(f, offset, type)

fseek(f, offset, 'bof');
x = fread(f, 1, type, 'l');

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function x = farray(f, offset, type, count, skip)

fseek(f, offset, 'bof');
x = fread(f, count, type, skip, 'l');

end