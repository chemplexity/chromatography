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
% Initialize
% ---------------------------------------
file = [];

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
% Defaults
% ---------------------------------------
default.file    = [];
default.depth   = 1;
default.content = 'all';
default.verbose = 'on';
default.formats = {'.CDF'};

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addParameter(p,...
    'file',...
    default.file,...
    @(x) validateattributes(x, {'cell', 'char'}, {'nonempty'}));

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

if ~any(strcmpi(option.content, {'all', 'header'}))
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
% Filter unsupported files
% ---------------------------------------
[~,~,ext] = cellfun(@(x) fileparts(x), {file.Name}, 'uniformoutput', 0);

% Remove unsupported file extensions
file(cellfun(@(x) ~any(strcmpi(x, {'.CDF'})), ext)) = [];

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
    
    % Update file infomation
    [fdir, fname, fext] = fileparts(file(i).Name);
    
    data(i,1).file_path = fdir;
    data(i,1).file_name = upper([fname, fext]);
    
     % Update status
    status(option.verbose, 6, i, length(file), data(i,1).file_name);

    switch option.content
        
        case 'all'
            data(i,1) = parseinfo(f, data(i,1));
            data(i,1) = parsedata(f, data(i,1));
            
        case 'header'
            data(i,1) = parseinfo(f, data(i,1));
            
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
% Filter: netCDF (.CDF)
% ---------------------------------------
netcdf = com.mathworks.hg.util.dFilter;

netcdf.setDescription('netCDF files (*.CDF');
netcdf.addExtension('cdf');

fc.addChoosableFileFilter(netcdf);

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

% Get file header
header = ncinfo(f);

% Parse file attributes
if isfield(header, 'Attributes')
    attributes = {header.Attributes.Name};
else
    return
end
    
% Parse file info
data.file_version = fstring(f, attributes, 'ms_template_revision');
data.sample_name  = fstring(f, attributes, 'experiment_title');
data.operator     = fstring(f, attributes, 'operator_name');
data.datetime     = fstring(f, attributes, 'experiment_date_time_stamp');
data.method       = fstring(f, attributes, 'external_file_ref_0');


end

% ---------------------------------------
% File data
% ---------------------------------------
function data = parsedata(f, data)

% Get file header
header = ncinfo(f);

% Parse file variables
if isfield(header, 'Variables')
    variables = {header.Variables.Name};
else
    return
end

% Parse file data
data.time      = fvalue(f, variables, 'scan_acquisition_time');
data.intensity = fvalue(f, variables, 'intensity_values');
data.channel   = fvalue(f, variables, 'mass_values');

% total intensity = total_intensity OR global_intensity_max (LEGACY)


    


% Determine precision of mass values
%mz = round(data.mz .* 10^precision) ./ 10^precision;
%data.mz = unique(mz, 'sorted');

% Determine data index
%index.start = double(ncread(file, 'scan_index'));
    index.end = circshift(index.start, [-1,0]);
    index.start(:,1) = index.start(:,1) + 1;
    index.end(end,2) = length(mz);
    
    % Pre-allocate memory
    xic = zeros(length(data.time), length(data.mz), 'single');
    
    % Determine column index for reshaping
    [~, column_index] = ismember(mz, data.mz);
    
    for i = 1:length(data.time)
        
        % Variables
        m = index.start(i);
        n = index.end(i);
        
        % Reshape instensity values
        xic(i, column_index(m:n)) = data.xic.values(m:n);
    end
    
    % Output data
    data.mz = data.mz';
    data.xic.values = xic;
end

% ---------------------------------------
% Data = attribute
% ---------------------------------------
function str = fattribute(file, header, key)

if any(strcmpi(key, header))
    str = ncreadatt(file, '/', key);
else
    str = '';
end

if length(str) > 255
    str = '';
else
    str = strtrim(deblank(str));
end

end

% ---------------------------------------
% Data = string
% ---------------------------------------
function str = fstring(file, header, key)

if any(strcmpi(key, header))
    str = ncread(file, key);
else
    str = '';
end

if length(str) > 255
    str = '';
else
    str = strtrim(deblank(str'));
end

end

% ---------------------------------------
% Data = value
% ---------------------------------------
function value = fvalue(file, header, key)

if any(strcmpi(key, header))
    value = ncread(file, key);
else
    value = [];
end

end