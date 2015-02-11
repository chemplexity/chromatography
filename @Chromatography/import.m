% Method: import
%  -Import chromatography data into the MATLAB workspace
%
% Syntax
%   data = import(filetype)
%   data = import(filetype, 'OptionName', optionvalue...)
%
% Input
%   filetype   : '.CDF', '.D', '.MS', '.RAW'
%
% Options
%   'append'   : structure
%   'progress' : 'on', 'off'
%
% Description
%   filetype   : file extension (e.g. '.D', '.MS', '.CDF', '.RAW')
%   'append'   : append data structure (default = none)
%   'progress' : display import progress (default = 'on')
%
% Examples
%   data = obj.import('.D')
%   data = obj.import('.CDF')
%   data = obj.import('.D', 'append', data)
%   data = obj.import('.MS', 'progress', 'off')
%   data = obj.import('.D', 'append', data, 'progress', 'on')

function varargout = import(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
options.compute_time = 0;

% Open file selection dialog
files = dialog(obj, varargin{1});

% Check for any file selections
if isempty(files)
    return
end

% Remove entries with incorrect filetype
files(~strcmp(files(:,3), varargin{1}), :) = [];

% Set path to selected folder
path(files{1,1}, path);

% Import files
switch options.filetype
    
    % Import netCDF data with the '*.CDF' extension
    case {'.CDF'}
        
        for i = 1:length(files(:,1))
            % Start timer
            tic;
            % Import data
            import_data(i) = ImportCDF(strcat(files{i,2},files{i,3}));
            % Stop timer
            compute_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            
            % Display import progress
            options.compute_time = options.compute_time + compute_time(i);
            update(i, length(files(:,1)), options.compute_time, options.progress);
        end
        
        % Import Agilent data with the '*.MS' extension
    case {'.MS'}
        
        for i = 1:length(files(:,1))
            % Construct file path
            file_path = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            % Start timer
            tic;
            % Import data
            import_data(i) = ImportAgilent(file_path);
            % Stop timer
            compute_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            
            % Display import progress
            options.compute_time = options.compute_time + compute_time(i);
            update(i, length(files(:,1)), options.compute_time, options.progress);
        end
        
        % Import Agilent data with the '*.D' extension
    case {'.D'}
        
        for i = 1:length(files(:,1))
            % Construct file path
            file_path = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            % Start timer
            tic;
            % Import data
            import_data(i) = ImportAgilent(file_path);
            % Stop timer
            compute_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            % Remove file from path
            rmpath(file_path);
            
            % Display import progress
            options.compute_time = options.compute_time + compute_time(i);
            update(i, length(files(:,1)), options.compute_time, options.progress);
        end
end

% Add missing fields to data structure
import_data = DataStructure('validate', import_data);

% Update data structure
for i = 1:length(id)
    
    % File information
    import_data(i).id = id(i);
    import_data(i).file.name = strcat(files{i,2}, files{i,3});
    import_data(i).file.type = options.filetype;
    
    % Data backup
    import_data(i).tic.backup = import_data(i).tic.values;
    import_data(i).xic.backup = import_data(i).xic.values;
    
    % Initialize baseline values
    import_data(i).tic.baseline = zeros(size(import_data(i).tic.values));
    import_data(i).xic.baseline = zeros(size(import_data(i).xic.values));
end

% Append any existing data with new data
data = [data, import_data];

% Set output
varargout{1} = data;
end


% Open dialog box to select files
function varargout = dialog(obj, varargin)

% Set filetype
extension = varargin{1};

% Initialize JFileChooser object
fileChooser = javax.swing.JFileChooser(java.io.File(cd));

% Select directories if certain filetype
if strcmp(extension, '.D')
    fileChooser.setFileSelectionMode(fileChooser.DIRECTORIES_ONLY);
end

% Determine file description and file extension
filter = com.mathworks.hg.util.dFilter;
description = [obj.options.import{strcmp(obj.options.import(:,1), extension), 2}];
extension = lower(extension(2:end));

% Set file description and file extension
filter.setDescription(description);
filter.addExtension(extension);
fileChooser.setFileFilter(filter);

% Enable multiple file selections and open dialog box
fileChooser.setMultiSelectionEnabled(true);
status = fileChooser.showOpenDialog(fileChooser);

% Determine selected file paths
if status == fileChooser.APPROVE_OPTION
    
    % Get file information
    info = fileChooser.getSelectedFiles();
    
    % Parse file information
    for i = 1:size(info, 1)
        [files{i,1}, files{i,2}, files{i,3}] = fileparts(char(info(i).getAbsolutePath));
    end
else
    % If file selection was cancelled
    files = [];
end

% Return selected files
varargout{1} = files;
end


% Display import progress
function update(varargin)

% Check user options
if strcmpi(varargin{4},'off')
    return
end

% Display progress
disp([...
    num2str(varargin{1}), '/',...
    num2str(varargin{2}), ' in ',...
    num2str(varargin{3}, '% 10.3f'), ' sec.']);
end


% Parse user input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1
    error('Not enough input arguments');
elseif ~ischar(varargin{1})
    error('Undefined input arguments of type ''filetype''');
end

% Check for supported file extension
if ~any(find(strcmp(varargin{1}, obj.options.import)))
    error('Unrecognized file format');
else
    options.filetype = varargin{1};
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Append options
if ~isempty(input('append'))
    options.append = varargin{input('append')+1};
    
    % Check for valid input
    if isstruct(options.append)
        data = DataStructure('validate', options.append);
    else
        data = DataStructure();
    end
else
    data = DataStructure();
end

% Progress options
if ~isempty(input('progress'))
    options.progress = varargin{input('progress')+1};
    
    % Check for valid input
    if ~strcmpi(options.progress, 'off')
        options.progress = 'on';
    end
else
    options.progress = 'on';
end

% Return input
varargout{1} = data;
varargout{2} = options;
end