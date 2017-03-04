function data = ImportCDF(varargin)
% ------------------------------------------------------------------------
% Method      : ImportCDF
% Description : Read netCDF data files (.CDF, .NC)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportCDF()
%   data = ImportCDF( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file or folder path
%       empty (default) | string | cell array
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
%   data = ImportCDF()
%   data = ImportCDF('file', '001-0510.CDF')
%   data = ImportCDF('file', {'092-05.CDF, '002-06.CDF'}, 'verbose', 'off')
%   data = ImportCDF('file', '/Data/2015/06/', 'depth', 3)

% ---------------------------------------
% Data
% ---------------------------------------
data.file_path = [];
data.file_name = [];
data.file_size = [];

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.CDF', '.NC'};

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
    
    if data(i,1).file_size == 0
        continue
    end
    
    % ---------------------------------------
    % Read
    % ---------------------------------------
    try
        f = netcdf.open(file(i).Name, 'NOWRITE');
    catch
        continue
    end
    
    switch option.content
        
        case {'all', 'default'}
            
            data = parseinfo(f, data);
            data = parsedata(f, data);
            
        case {'header'}
            
            data = parseinfo(f, data);
            
    end
    
    netcdf.close(f);
    
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

% Filter: netCDF (.CDF)
netcdf = com.mathworks.hg.util.dFilter;

netcdf.setDescription('netCDF files (*.CDF, *.NC)');
netcdf.addExtension('cdf');
netcdf.addExtension('nc');

fc.addChoosableFileFilter(netcdf);

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
% File header
% ---------------------------------------
function data = parseinfo(f, data)

[~, ~, numAttr] = netcdf.inq(f);

% Read global attributes
for i = 1:numAttr
    
    attrKey = netcdf.inqAttName(f, netcdf.getConstant('NC_GLOBAL'), i-1);
    attrVal = netcdf.getAtt(f, netcdf.getConstant('NC_GLOBAL'), attrKey);
    
    if ischar(attrKey)
        data(end,1).(attrKey) = attrVal;
    end
    
end

% Convert datetime to ISO 8601
dateFields = {...
    'experiment_date_time_stamp',...
    'netcdf_file_date_time_stamp',...
    'source_file_date_time_stamp',...
    'injection_date_time_stamp',...
    'dataset_date_time_stamp',...
    'peak_processing_date_time_stamp',...
    'date_time_stamp',...
    'HP_injection_time'};

for i = 1:length(dateFields)
    
    if isfield(data, dateFields{i}) && ~isempty(data(end,1).(dateFields{i}))
        data(end,1).(dateFields{i}) = parsedate(data(end,1).(dateFields{i}));
    end
    
end

end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

[~, numVar] = netcdf.inq(f);

% Read variables
for i = 1:numVar
    
    [varKey, ~, ~, numAttr] = netcdf.inqVar(f, i-1);
    varVal = netcdf.getVar(f, i-1);
    
    if ischar(varVal)
        varVal = strtrim(deblank(varVal'));
    elseif isnumeric(varVal)
        if all(all(varVal == -9999)) || all(all(varVal > 9E36))
            varVal = [];
        elseif all(~any(varVal))
            varVal = [];
        end
    end
    
    if ~isempty(varVal)
        data(end,1).(varKey) = varVal;
    end
    
    % Read attributes
    for j = 1:numAttr
        
        attrKey = netcdf.inqAttName(f, i-1, j-1);
        attrVal = netcdf.getAtt(f, i-1, attrKey);
        
        if ischar(attrVal)
            attrVal = strtrim(deblank(attrVal));
        end
        
        if ~isempty(attrVal)
            data(end,1).([varKey, '_', attrKey]) = attrVal;
        end
    end
    
end

% Reshape data
if all(isfield(data, {'point_count', 'intensity_values', 'mass_values'}))
    
    % Variables
    z = unique(data(end,1).mass_values);
    n = data(end,1).point_count;
    
    numPoints = numel(data(end,1).intensity_values);
    numRows   = numel(n);
    numCols   = numel(z);
    
    % Memory Allocation
    maxArrayBytes = 200E6;
    curArrayType  = class(data(end,1).intensity_values);
    
    switch curArrayType
        case {'double', 'int64', 'uint64'}
            numBytes = 8;
        case {'single', 'int32', 'uint32'}
            numBytes = 4;
        case {'int16', 'uint16'}
            numBytes = 2;
        case {'int8', 'uint8'}
            numBytes = 1;
        otherwise
            numBytes = 8;
    end
    
    if (numRows * numCols * numBytes) > maxArrayBytes
        y = spalloc(numRows, numCols, numPoints);
    else
        y = zeros(numRows, numCols, curArrayType);
    end
    
    if numRows && numCols && numPoints
        
        % Column indexing
        [~, idx] = ismember(data(end,1).mass_values, z);
        
        if sum(n) == numPoints
            
            n(:,2) = cumsum(n);
            n(:,1) = n(:,2) - n(:,1) + 1;
            
        elseif isfield(data, 'scan_index') && ~isempty(data(end,1).scan_index)
            
            n(:,1) = data(end,1).scan_index + 1;
            n(:,2) = [n(2:end,1) - 1; numPoints];
            
        end
        
        for i = 1:numel(data(end,1).point_count)
            
            % Row values
            ni = idx(n(i,1):n(i,2));
            zi = data(end,1).mass_values(n(i,1):n(i,2));
            yi = data(end,1).intensity_values(n(i,1):n(i,2));
            
            if all(~strcmpi(class(zi), {'single', 'double'}))
                zi = single(zi);
            end
            
            % Combine duplicates
            if numel(unique(zi)) ~= numel(yi)
                
                [~, yy] = uniquetol(zi, 0, 'outputallindices', 1);
                yy(~cellfun(@(x) length(x) > 1, yy)) = [];
                
                for j = 1:length(yy)
                    yi(yy{j}(1)) = sum(yi(yy{j}));
                    yi(yy{j}(2:end)) = 0;
                end
                
            end
            
            % Reshape values
            ii = logical(yi);
            y(i,ni(ii)) = yi(ii);
            
        end
        
        data(end,1).intensity_values = y;
        data(end,1).mass_values = z';
        
    end
end

% Intensity values
if isfield(data, 'intensity_values') && ~isempty(data(end,1).intensity_values)
    
    if isfield(data, 'intensity_values_add_offset') && ~isempty(data(end,1).intensity_values_add_offset)
        if data(end,1).intensity_values_add_offset ~= 0
            data(end,1).intensity_values = data(end,1).intensity_values + data(end,1).intensity_values_add_offset;
        end
    end
    
    if isfield(data, 'intensity_values_scale_factor') && ~isempty(data(end,1).intensity_values_scale_factor)
        if data(end,1).intensity_values_scale_factor ~= 1
            data(end,1).intensity_values = data(end,1).intensity_values .* data(end,1).intensity_values_scale_factor;
        end
    end
    
end

% Mass values
if isfield(data, 'mass_values') && ~isempty(data(end,1).mass_values)
    
    if isfield(data, 'mass_values_add_offset') && ~isempty(data(end,1).mass_values_add_offset)
        if data(end,1).mass_values_add_offset ~= 0
            data(end,1).mass_values = data(end,1).mass_values + data(end,1).mass_values_add_offset;
        end
    end
    
    if isfield(data, 'mass_values_scale_factor') && ~isempty(data(end,1).mass_values_scale_factor)
        if data(end,1).mass_values_scale_factor ~= 1
            data(end,1).mass_values = data(end,1).mass_values .* data(end,1).mass_values_scale_factor;
        end
    end
    
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

% netCDF Formats
dateFormat = {...
    'yyyymmddHHMMSS',...
    'yyyymmddHHMMSS',...
    'yyyy,mm,dd,HH:MM:SS',...
    'mm/dd/yyyy HH:MM',...
    'dd mmm yy HH:MM PM'};

dateRegex = {...
    '\d{14}-\d{3,4}',...
    '\d{14}',...
    '\d{4}[,]\d{2}[,]\d{2}[,]\d{2}[:]\d{2}[:]\d{2}',...
    '\d{2}[/]\d{2}[/]\d{4}\s*\d{2}[:]\d{2}',...
    '\d{1,2} \w{3} \d{1,2}\s*\d{1,2}[:]\d{2} \w{2}'};

if ~isempty(str)
    
    dateMatch = regexp(str, dateRegex, 'match');
    dateIndex = find(~cellfun(@isempty, dateMatch), 1);
    
    if ~isempty(dateIndex)
        dateNum = datenum(str, dateFormat{dateIndex});
        str = datestr(dateNum, formatOut);
    end
    
end

end