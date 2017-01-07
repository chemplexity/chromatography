function varargout = import(obj, varargin)
% ------------------------------------------------------------------------
% Method      : Chromatography.import
% Description : Read instrument data files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.import()
%   data = obj.import( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file or folder path
%       empty (default) | cell array of strings
%
%   'filetype' -- file extension or manufacturer name
%       'agilent' | '.D', '.MS', '.CH'
%       'netcdf'  | '.CDF'
%       'nist'    | '.MSP'
%       'thermo'  | '.RAW'
%
%   'depth' -- subfolder search depth
%       1 (default) | integer
%
%   'content' -- read all data or header only
%       'all' (default) | 'header'
%
%   'append' -- append new data to existing data structure
%       empty (default) | structure
%
%   'verbose' -- display import progress in command window
%       'on' (default) | 'off'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = obj.import('.CDF')
%   data = obj.import('.D', 'append', data)
%   data = obj.import('.MS', 'verbose', 'off', 'precision', 2)
%   data = obj.import('.RAW', 'append', data, 'verbose', 'on')

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.type    = [];
default.append  = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'d', 'ms', 'ch', 'uv', 'cdf', 'msp', 'raw'};

% ---------------------------------------
% Variables
% ---------------------------------------
data = {};
totalBytes = 0;

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

addParameter(p, 'file',     default.file);
addParameter(p, 'filetype', default.type);
addParameter(p, 'depth',    default.depth);
addParameter(p, 'content',  default.content, @ischar);
addParameter(p, 'append',   default.append,  @isstruct);
addParameter(p, 'verbose',  default.verbose, @ischar);

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
option.file    = p.Results.file;
option.type    = p.Results.filetype;
option.depth   = p.Results.depth;
option.content = p.Results.content;
option.append  = p.Results.append;
option.verbose = p.Results.verbose;
option.extra   = '';

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

% Parameter: 'type'
if ischar(option.type) && strcmpi(option.type, 'all')
    option.type = default.formats;
elseif ischar(option.type)
    option.type = {option.type};
elseif ~ischar(option.type) && ~iscellstr(option.type)
    option.type = default.formats;
end

if ~isempty(option.type)
    option.type = parseformat(option.type);
    option.type(cellfun(@(x) ~any(strcmpi(x, default.formats)), option.type)) = [];
end

if isempty(option.type)
    option.type = parseformat(default.formats);
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

% Parameter: 'append'
varargout{1} = option.append;

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
    [file, fileError] = FileUI(option.type, []);
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
    status(option.verbose, 'selection_error');
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
    option.type(cellfun(@(x) any(strcmpi(x, 'd')), option.type)) = [];
    file = parsesubfolder(file, option.depth, option.type);
end

% ---------------------------------------
% Filter unsupported files
% ---------------------------------------
[~,~,fileExt] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

fileExt = regexp(fileExt, '\w+', 'match', 'once');

file(cellfun(@(x) ~any(strcmpi(x, option.type)), fileExt)) = [];

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
    % Status
    % ---------------------------------------
    [filePath, fileName, fileExt] = fileparts(file(i).Name);
    [parentPath, parentName, parentExt] = fileparts(filePath);
    
    if strcmpi(parentExt, '.D')
        
        [~, statusPath, statusExt] = fileparts(parentPath);
        
        statusPath = ['..',...
            filesep, statusPath, statusExt,...
            filesep, parentName, parentExt,...
            filesep, fileName, fileExt];
    else
        
        statusPath = ['..',...
            filesep, parentName, parentExt,...
            filesep, fileName, fileExt];
    end
    
    status(option.verbose, 'loading_file', i, size(file,1));
    status(option.verbose, 'file_name', statusPath);
    
    % ---------------------------------------
    % Read
    % ---------------------------------------
    switch lower(fileExt)
        
        case {'.d', '.ch', '.ms', '.uv'}
            
            % ---------------------------------------
            % Agilent
            % ---------------------------------------
            x = loadfile(file(i), option, 'agilent');
            
            for j = 1:length(x)
                
                data{end+1} = obj.format('validate', []);
                
                data{end}.file.path         = parsefield(x(j), {'file_path'});
                data{end}.file.name         = parsefield(x(j), {'file_name'});
                data{end}.file.bytes        = parsefield(x(j), {'file_size'});
                data{end}.sample.name       = parsefield(x(j), {'sample_name'});
                data{end}.sample.info       = parsefield(x(j), {'barcode'});
                data{end}.sample.sequence   = parsefield(x(j), {'seqindex'});
                data{end}.sample.vial       = parsefield(x(j), {'vial'});
                data{end}.sample.replicate  = parsefield(x(j), {'replicate'});
                data{end}.method.name       = parsefield(x(j), {'method_name'});
                data{end}.method.operator   = parsefield(x(j), {'operator'});
                data{end}.method.instrument = parsefield(x(j), {'instmodel'});
                data{end}.method.datetime   = parsefield(x(j), {'datetime'});
                data{end}.time              = parsefield(x(j), {'time'});
                data{end}.tic.values        = parsefield(x(j), {'total_intensity', 'ordinate_values'});
                data{end}.xic.values        = parsefield(x(j), {'intensity'});
                data{end}.mz                = parsefield(x(j), {'channel'});
                
                if size(x(j).intensity, 2) == 1
                    data{end}.tic.values = data{end}.xic.values;
                elseif ~isempty(x(j).intensity)
                    data{end}.tic.values = sum(x(j).intensity, 2);
                end
                
                if size(data{end}.mz, 2) > 1 && data{end}.mz(1) == 0
                    data{end}.xic.values(:,1) = [];
                    data{end}.mz(:,1)= [];
                end
                
                totalBytes = loadstats(file(i), data{end}, option, totalBytes);
                
            end
            
        case {'.cdf'}
            
            % ---------------------------------------
            % netCDF
            % ---------------------------------------
            x = loadfile(file(i), option, 'netcdf');
            
            for j = 1:length(x)
                
                data{end+1} = obj.format('validate', []);
                
                data{end}.file.path          = parsefield(x(j), {'file_path'});
                data{end}.file.name          = parsefield(x(j), {'file_name'});
                data{end}.file.bytes         = parsefield(x(j), {'file_size'});
                data{end}.sample.name        = parsefield(x(j), {'experiment_title'});
                data{end}.sample.info        = parsefield(x(j), {'administrative_comments'});
                data{end}.method.name        = parsefield(x(j), {'external_file_ref_0'});
                data{end}.method.datetime    = parsefield(x(j), {'experiment_date_time_stamp'});
                data{end}.method.operator    = parsefield(x(j), {'operator_name'});
                data{end}.method.instrument  = parsefield(x(j), {'instrument', 'instrument_name'});
                data{end}.time               = parsefield(x(j), {'scan_acquisition_time'});
                data{end}.tic.values         = parsefield(x(j), {'total_intensity', 'ordinate_values'});
                data{end}.xic.values         = parsefield(x(j), {'intensity_values'});
                data{end}.mz                 = parsefield(x(j), {'mass_values'});
                
                if ~isempty(data{end}.time)
                    if strcmpi(parsefield(x, {'time_values_units', 'units'}), 'seconds')
                        data{end}.time = data{end}.time ./ 60;
                    end
                end
                
                totalBytes = loadstats(file(i), data{end}, option, totalBytes);
                
            end
            
        case {'.msp'}
            
            % ---------------------------------------
            % NIST
            % ---------------------------------------
            x = loadfile(file(i), option, 'nist');
            
            for j = 1:length(x)
                
                data{end+1} = obj.format('validate', []);
                
                data{end}.file.path   = parsefield(x(j), {'file_path'});
                data{end}.file.name   = parsefield(x(j), {'file_name'});
                data{end}.file.bytes  = parsefield(x(j), {'file_size'});
                data{end}.sample.name = parsefield(x(j), {'compound_name'});
                data{end}.sample.info = parsefield(x(j), {'comments'});
                data{end}.xic.values  = parsefield(x(j), {'intensity'});
                data{end}.mz          = parsefield(x(j), {'mz'});
                
                if ~isempty(data{end}.xic.values)
                    data{end}.tic.values = sum(data{end}.xic.values, 2);
                end
                
                totalBytes = loadstats(file(i), data{end}, option, totalBytes);
                
            end
            
        case {'.raw'}
            
            % ---------------------------------------
            % Thermo
            % ---------------------------------------
            x = loadfile(file(i), option, 'thermo');
            
            for j = 1:length(x)
                
                data{end+1} = obj.format('validate', []);
                
                data{end}.file.path  = parsefield(x(j), {'file_path'});
                data{end}.file.name  = parsefield(x(j), {'file_name'});
                data{end}.file.bytes = parsefield(x(j), {'file_size'});
                
                if isfield(x, 'ms2')
                    option.extra = 'ms2';
                end
                
                totalBytes = loadstats(file(i), data{end}, option, totalBytes);
                
            end
            
    end
end

totalTime = toc;

% ---------------------------------------
% Filter data
% ---------------------------------------
data(cellfun(@isempty, data)) = [];

if ~isempty(data)
    data = [data{:}];
else
    fprintf(' Unable to import selection\n');
    return
end

if ~isempty(option.append) && isempty(option.append(1).id) && isempty(option.append(1).name)
    option.append(1) = [];
end

% ---------------------------------------
% Check MS/MS data
% ---------------------------------------
if ~isempty(option.extra)
    option.append = obj.format('validate', option.append, 'extra', option.extra);
    data = obj.format('validate', data, 'extra', option.extra);
    
elseif isfield(option.append, 'ms2')
    data = obj.format('validate', data, 'extra', 'ms2');
    
else
    data = obj.format('validate', data);
end

% ---------------------------------------
% Prepare output
% ---------------------------------------
for i = 1:length(data)
    
    data(i).id               = length(option.append)+i;
    data(i).name             = data(i).file.name;
    data(i).backup.time      = data(i).time;
    data(i).backup.tic       = data(i).tic.values;
    data(i).backup.xic       = data(i).xic.values;
    data(i).backup.mz        = data(i).mz;
    data(i).tic.baseline     = [];
    data(i).xic.baseline     = [];
    data(i).status.centroid  = 'N';
    data(i).status.baseline  = 'N';
    data(i).status.smoothed  = 'N';
    data(i).status.integrate = 'N';
    
end

% ---------------------------------------
% Exit
% ---------------------------------------
status(option.verbose, 'stats', length(data), totalTime, totalBytes);
status(option.verbose, 'exit');

varargout{1} = [option.append, data];

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
        
    case 'loading_error'
        fprintf([' Error loading ''', '%s', '''\n'], varargin{3});
        
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
function [fileSelection, fileStatus] = FileUI(fileExtension, fileSelection)

% Variables
fileExtension = regexp(fileExtension, '\w{1,4}', 'match');

% JFileChooser (Java)
if ~usejava('swing')
    fileStatus = 2;
    return
end

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

if any(cellfun(@(x) any(strcmpi(x, {'agilent', 'd', 'ms', 'cd', 'uv'})), fileExtension))
    fc.addChoosableFileFilter(agilent);
end

% Filter: netCDF (.CDF)
netcdf = com.mathworks.hg.util.dFilter;

netcdf.setDescription('netCDF files (*.CDF)');
netcdf.addExtension('cdf');

if any(cellfun(@(x) any(strcmpi(x, {'netcdf', 'cdf'})), fileExtension))
    fc.addChoosableFileFilter(netcdf);
end

% Filter: NIST (.MSP)
nist = com.mathworks.hg.util.dFilter;

nist.setDescription('NIST files (*.MSP)');
nist.addExtension('msp');

if any(cellfun(@(x) any(strcmpi(x, {'nist', 'msp'})), fileExtension))
    fc.addChoosableFileFilter(nist);
end

% Filter: Thermo (.RAW)
thermo = com.mathworks.hg.util.dFilter;

thermo.setDescription('Thermo files (*.RAW)');
thermo.addExtension('raw');

if any(cellfun(@(x) any(strcmpi(x, {'thermo', 'raw'})), fileExtension))
    fc.addChoosableFileFilter(thermo);
end

% Initialize UI
fileStatus = fc.showOpenDialog(fc);

if fileStatus == fc.APPROVE_OPTION
    
    % Get file selection
    fs = fc.getSelectedFiles();
    
    for i = 1:size(fs, 1)
        
        % Get file information
        [~, f] = fileattrib(char(fs(i).getAbsolutePath));
        
        % Append to file list
        if isstruct(f)
            fileSelection = [fileSelection; f];
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
        fileExt = regexp(fileExt, '\w+', 'match', 'once');
        
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
% Data = raw data
% ---------------------------------------
function data = loadfile(file, option, fileType)

if ~file.UserRead
    return
end

switch fileType
    
    case 'agilent'
        
        data = ImportAgilent(...
            'file', file.Name,....
            'content', option.content,...
            'verbose', 'off');
        
    case 'netcdf'
        
        data = ImportCDF(...
            'file', file.Name,...
            'content', option.content,...
            'verbose', 'off');
        
    case 'nist'
        
        data = ImportNIST(...
            'file', file.Name,...
            'content', option.content,...
            'verbose', 'off');
        
    case 'thermo'
        
        data = ImportThermo(...
            'file', file.Name,...
            'content', option.content,...
            'verbose', 'off');
        
    otherwise
        
        data = [];
        
end

end

% ---------------------------------------
% Data = total bytes
% ---------------------------------------
function x = loadstats(file, data, option, x)

n = data.file.bytes;

if isempty(n)
    status(option.verbose, 'loading_error', file.Name);
else
    status(option.verbose, 'loading_stats', n);
    x = x + n;
end

end

% ---------------------------------------
% Data = file extension
% ---------------------------------------
function str = parseformat(str)

str = regexp(str, '\w+', 'match');
str = cellfun(@lower, str);

if ischar(str)
    str = {str};
end

if any(cellfun(@(x) any(strcmpi(x, {'agilent', 'd'})), str))
    str(cellfun(@(x) any(strcmpi(x, {'agilent', 'd'})), str)) = [];
    str = [str, 'ms', 'ch', 'uv'];
end



if any(strcmpi(str, 'netcdf'))
    str(strcmpi(str, 'netcdf')) = [];
    str = [str, 'cdf'];
end

if any(strcmpi(str, 'nist'))
    str(strcmpi(str, 'nist')) = [];
    str = [str, 'msp'];
end

if any(strcmpi(str, 'thermo'))
    str(strcmpi(str, 'thermo')) = [];
    str = [str, 'raw'];
end

str = unique(str);

end

% ---------------------------------------
% Data = structure contents
% ---------------------------------------
function x = parsefield(data, field)

x = [];

for i = 1:length(field)
    
    if isfield(data, field{i}) && ~isempty(data.(field{i}))
        x = data.(field{i});
    end
    
end

end