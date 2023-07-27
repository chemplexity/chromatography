function data = ImportNIST(varargin)
% ------------------------------------------------------------------------
% Method      : ImportNIST
% Description : Read NIST data files (.MSP)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportNIST()
%   data = ImportNIST( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file or folder path
%       empty (default) | string | cell array of strings
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
%   data = ImportNIST()
%   data = ImportNIST('file', {'/Data/2016/', '/Data/2015/'}, 'depth', 4)
%   data = ImportNIST('file', '56-55-3.MSP', 'verbose', 'off')

% ---------------------------------------
% Data
% ---------------------------------------
data = struct(...
    'file_path',                [],...
    'file_name',                [],...
    'file_size',                [],...
    'compound_name',            [],...
    'compound_synonym',         {},...
    'compound_formula',         [],...
    'compound_mw',              [],...
    'compound_exact_mass',      [],...
    'compound_retention_time',  [],...
    'compound_retention_index', [],...
    'cas_id',                   [],...
    'nist_id',                  [],...
    'db_id',                    [],...
    'smiles',                   [],...
    'inchikey',                 [],...
    'ion_mode',                 [],...
    'collision_energy',         [],...
    'comments',                 [],...
    'num_peaks',                [],...
    'mz',                       [],...
    'intensity',                []);

% ---------------------------------------
% Defaults
% ---------------------------------------
default = struct(...
    'file',    [],...
    'depth',   1,...
    'content', 'all',...
    'verbose', true,...
    'format',  {'.MSP'});

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
addParameter(p, 'verbose', default.verbose);

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
if ~any(strcmpi(option.content, {'default', 'all', 'header', 'metadata'}))
    option.content = 'all';
end

% Parameter: 'verbose'
if isnumeric(option.verbose) && ~any(option.verbose == [0,1])
    option.verbose = default.verbose;
elseif any(strcmpi(option.verbose, {'off', 'no', 'n', 'false', '0'}))
    option.verbose = false;
else
    option.verbose = default.verbose;
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
    file = parsesubfolder(file, option.depth, default.format);
end

% ---------------------------------------
% Filter unsupported files
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

file(cellfun(@(x) ~any(strcmpi(x, default.format)), ext)) = [];

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
    % Read
    % ---------------------------------------
    f = fileread(file(i).Name);
    
    if isempty(f)
        continue
    end
    
    f = parsefile(f);
    
    for j = 1:length(f)
    
        % ---------------------------------------
        % File properties
        % ---------------------------------------
        [filePath, fileName, fileExt] = fileparts(file(i).Name);
    
        data(end+1,1).file_path = filePath;
        data(end,1).file_name = [fileName, fileExt];
        data(end,1).file_size = length(f{j}) + 4;
    
        % ---------------------------------------
        % Status
        % ---------------------------------------
        [~, statusPath] = fileparts(data(end,1).file_path);
        statusPath = ['..', filesep, statusPath, filesep, data(end,1).file_name];
    
        if length(f) > 1
            n = [num2str(i), '-', num2str(j)];
        else
            n = i;
        end
        
        status(option.verbose, 'loading_file', n, length(file));
        status(option.verbose, 'file_name', statusPath);
        status(option.verbose, 'loading_stats', data(end,1).file_size);
    
        if data(end,1).file_size == 0
            continue
        end
    
        switch option.content
        
            case {'all', 'default'}
            
                data(end,1) = parseinfo(f{j}, data(end,1));
                data(end,1) = parsedata(f{j}, data(end,1));
            
            case {'metadata', 'header'}
            
                data(end,1) = parseinfo(f{j}, data(end,1));
            
        end
    
    end
    
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
        fprintf(['\n', repmat('-',1,50), '\n\n']);
        
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

% Filter: NIST (.MSP)
nist = com.mathworks.hg.util.dFilter;

nist.setDescription('NIST files (*.MSP)');
nist.addExtension('msp');

fc.addChoosableFileFilter(nist);

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
% File contents
% ---------------------------------------
function f = parsefile(f)

if ischar(f)
    
    f = strsplit(f, '\r\n\r\n', 'delimitertype', 'regularexpression');
   
    if iscell(f) && isempty(f{end})
        f(end) = [];
    end
    
end

end

% ---------------------------------------
% File metadata
% ---------------------------------------
function data = parseinfo(f, data)

data.compound_name            = parsefield(f, 'Name');
data.compound_synonym         = parsefield(f, 'Synon');
data.compound_formula         = parsefield(f, 'Formula');
data.compound_mw              = parsefield(f, 'MW');
data.compound_exact_mass      = parsefield(f, 'ExactMass');
data.compound_retention_time  = parsefield(f, 'RetentionTime');
data.compound_retention_index = parsefield(f, 'RetentionIndex');
data.cas_id                   = parsefield(f, 'CAS([#]|NO)');
data.nist_id                  = parsefield(f, 'NIST([#]|NO)');
data.db_id                    = parsefield(f, 'DB([#]|NO)');
data.smiles                   = parsefield(f, 'Smiles');
data.inchikey                 = parsefield(f, 'Inchikey');
data.ion_mode                 = parsefield(f, 'IonMode');
data.collision_energy         = parsefield(f, 'CollisionEnergy');
data.comments                 = parsefield(f, 'Comment[s]?');
data.num_peaks                = parsefield(f, 'Peaks');

data.compound_mw              = parsenumber(data.compound_mw);
data.compound_exact_mass      = parsenumber(data.compound_exact_mass);
data.compound_retention_time  = parsenumber(data.compound_retention_time);
data.compound_retention_index = parsenumber(data.compound_retention_index);
data.num_peaks                = parsenumber(data.num_peaks);

if ~isempty(data.compound_synonym) && ischar(data.compound_synonym)
    data.compound_synonym = {data.compound_synonym};
end

% TODO PRECURSORMZ

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

[data.mz, data.intensity] = parsearray(f);

end

% ---------------------------------------
% Data = byte string
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
% Data = string
% ---------------------------------------
function str = parsefield(f, name)

switch name
    
    case {'CAS([#]|NO)'}
        strRegExp = ['(?:', name, '[:]\s*)(\S[ ]|\S+)+(?:(\r|[;]|\n))'];
        
    otherwise
        strRegExp = ['(?:', name, '[:]\s*)(\S[ ]+|\S+)+(?:(\r|[;])|\n)'];
       
end

str = regexpi(f, strRegExp, 'tokens');

if isempty(str)
    str = '';
else
    str = cellfun(@(x) strtrim(deblank(x{1})), str, 'uniformoutput', 0);
end

if iscell(str) && length(str) == 1
    str = str{1};
end

end

% ---------------------------------------
% Data = number
% ---------------------------------------
function str = parsenumber(str)

if isempty(str) || ~ischar(str)
    return
end

x = str2double(str);

if isnan(x)
    x = [];
end

str = x;

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function [x, y] = parsearray(f)

str = regexp(f, '(\d+( |\t)+\d+)', 'match');

if isempty(str)
    x = [];
    y = [];
else
    % Check if tab delimited
    if (strfind(str{1}, char(9)))
        xy = cellfun(@(x) strsplit(x,'\t'), str, 'uniformoutput', 0);
    else
        xy = cellfun(@(x) strsplit(x,' '), str, 'uniformoutput', 0);
    end
    
    xy = reshape(str2double([xy{:}]), 2, []);
    x = xy(1,:);
    y = xy(2,:);
end

end