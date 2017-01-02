function data = ImportCDF(varargin)
% ------------------------------------------------------------------------
% Method      : ImportCDF
% Description : Read netCDF data files (.CDF)
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
%   'content' -- read file header, signal data, or both
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
data.file_path                    = [];
data.file_name                    = [];
data.file_size                    = [];

% ---------------------------------------
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.CDF'};

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

while l > 0
    
    for i = n(1):n(2)
        
        [~, ~, ext] = fileparts(file(i).Name);
        
        if any(strcmpi(ext, {'.m', '.git', '.lnk', '.raw'}))
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

% Remove unsupported file extensions
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
    try 
        f = netcdf.open(file(i).Name, 'NOWRITE');
    catch
        continue
    end
    
    switch option.content
        
        case {'all', 'default'}
            data = parseinfo(f, data);
            data = parsedata(f, data);
            
        case 'header'
            data = parseinfo(f, data);
    end
    
    netcdf.close(f);
    
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
% Filter: netCDF (.CDF)
% ---------------------------------------
netcdf = com.mathworks.hg.util.dFilter;

netcdf.setDescription('netCDF files (*.CDF');
netcdf.addExtension('cdf');

fc.addChoosableFileFilter(netcdf);

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
        if all(varVal == -9999) || ~any(varVal) || all(varVal > 9E36)
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

% ---------------------------------------
% Reshape data
% ---------------------------------------
if all(isfield(data, {'point_count', 'intensity_values', 'mass_values'}))

    % ---------------------------------------
    % Variables
    % ---------------------------------------
    z = unique(data(end,1).mass_values);
    n = data(end,1).point_count;
    
    numPoints = numel(data(end,1).intensity_values);
    numRows   = numel(n);
    numCols   = numel(z);
    
    % ---------------------------------------
    % Memory Allocation
    % ---------------------------------------
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
    
        % ---------------------------------------
        % Column indexing
        % ---------------------------------------
        [~, idx] = ismember(data(end,1).mass_values, z);
    
        if sum(n) == numPoints
            
            n(:,2) = cumsum(n);
            n(:,1) = n(:,2) - n(:,1) + 1;
            
        elseif isfield(data, 'scan_index') && ~isempty(data(end,1).scan_index)
            
            n(:,1) = data(end,1).scan_index + 1;
            n(:,2) = [n(2:end,1) - 1; numPoints];
            
        end

        for i = 1:numel(data(end,1).point_count)
        
            % ---------------------------------------
            % Row values
            % ---------------------------------------
            ni = idx(n(i,1):n(i,2));
            zi = data(end,1).mass_values(n(i,1):n(i,2));
            yi = data(end,1).intensity_values(n(i,1):n(i,2));
            
            if all(~strcmpi(class(zi), {'single', 'double'}))
                zi = single(zi);
            end
            
            % ---------------------------------------
            % Combine duplicates
            % ---------------------------------------
            if numel(unique(zi)) ~= numel(yi)
                
                [~, yy] = uniquetol(zi, 0, 'outputallindices', 1);
                yy(~cellfun(@(x) length(x) > 1, yy)) = [];
                
                for j = 1:length(yy)
                    yi(yy{j}(1)) = sum(yi(yy{j}));
                    yi(yy{j}(2:end)) = 0;
                end
                
            end
            
            % ---------------------------------------
            % Reshape values
            % ---------------------------------------
            ii = logical(yi);
            y(i,ni(ii)) = yi(ii);

        end
        
        data(end,1).intensity_values = y;
        data(end,1).mass_values = z';
        
    end
end

% ---------------------------------------
% Intensity values
% ---------------------------------------
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

% ---------------------------------------
% Mass values
% ---------------------------------------
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
function dateStr = parsedate(dateStr)

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

if ~isempty(dateStr)
    
    dateMatch = regexp(dateStr, dateRegex, 'match');
    dateIndex = find(~cellfun(@isempty, dateMatch), 1);
    
    if ~isempty(dateIndex)
        dateNum = datenum(dateStr, dateFormat{dateIndex});
        dateStr = datestr(dateNum, formatOut);
    end
    
end

end