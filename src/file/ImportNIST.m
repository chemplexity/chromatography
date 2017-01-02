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
%   'verbose' -- show progress in command window
%       'on' (default) | 'off'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportNIST()
%   data = ImportNIST('file', {'/Data/2016/'}, 'depth', 4)
%   data = ImportNIST('file', '56-55-3.MSP', 'verbose', 'off')

% ---------------------------------------
% Data
% ---------------------------------------
data.file_path        = [];
data.file_name        = [];
data.file_size        = [];
data.compound_name    = [];
data.compound_formula = [];
data.compound_mw      = [];
data.cas_id           = [];
data.nist_id          = [];
data.db_id            = [];
data.comments         = [];
data.num_peaks        = [];
data.mz               = [];
data.intensity        = [];

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file      = [];
default.depth     = 1;
default.verbose   = 'on';
default.formats   = {'.MSP'};

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
addParameter(p, 'verbose', default.verbose, @ischar);
    
parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
option.file    = p.Results.file;
option.depth   = p.Results.depth;
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
if exist('fileError', 'var') && fileError
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
    f = fileread(file(i).Name);
    
    if ~isempty(f)
        data(i,1) = parseinfo(f, data(i,1));
        data(i,1) = parsedata(f, data(i,1));
    end
    
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
            fprintf(['\n', repmat('-',1,50), '\n\n']);
    
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
% Filter: NIST (.MSP)
% ---------------------------------------
nist = com.mathworks.hg.util.dFilter;

nist.setDescription('NIST files (*.MSP)');
nist.addExtension('msp');

fc.addChoosableFileFilter(nist);

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

data.compound_name    = parsefield(f, 'Name');
data.compound_formula = parsefield(f, 'Formula');
data.compound_mw      = parsefield(f, 'MW');
data.cas_id           = parsefield(f, 'CAS[#]');
data.nist_id          = parsefield(f, 'NIST[#]');
data.db_id            = parsefield(f, 'DB[#]');
data.comments         = parsefield(f, 'Comments');
data.num_peaks        = parsefield(f, 'Peaks');

if ~isempty(data.compound_mw)
    data.compound_mw = parsenumber(data.compound_mw);
end

if ~isempty(data.num_peaks)
    data.num_peaks = parsenumber(data.num_peaks);
end

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

[data.mz, data.intensity] = parsearray(f);

end

% ---------------------------------------
% Data = string
% ---------------------------------------
function str = parsefield(f, name)

switch name

    case {'CAS[#]'}
        strRegEx = ['(?:', name, '[:]\s*)(\S[ ]|\S+)+(?:(\r|[;]))'];
        
    otherwise
        strRegEx = ['(?:', name, '[:]\s*)(\S[ ]+|\S+)+(?:(\r|[;]))'];
        
end

strMatch = regexp(f, strRegEx, 'tokens', 'once');

if isempty(strMatch)
    str = '';
else
    str = strtrim(deblank(strMatch{1}));
end

end

% ---------------------------------------
% Data = number
% ---------------------------------------
function num = parsenumber(str)

num = str2double(str);

if isnan(num)
    num = str;
end

end

% ---------------------------------------
% Data = array
% ---------------------------------------
function [x, y] = parsearray(f)

strRegEx = '(\d+ \d+)';
strMatch = regexp(f, strRegEx, 'match');

if isempty(strMatch)
    x = [];
    y = [];
else
    xy = cellfun(@(x) strsplit(x,' '), strMatch, 'uniformoutput', 0);
    xy = reshape(str2double([xy{:}]), 2, []);
    x = xy(1,:);
    y = xy(2,:);
end

end