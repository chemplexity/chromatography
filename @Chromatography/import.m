% Method: import
%  -Import chromatography data into the MATLAB workspace
%
% Syntax
%   data = import(filetype)
%   data = import(filetype, data)
%   data = import(filetype, data, 'OptionName', optionvalue...)
%
% Input
%   filetype   : '.CDF', '.D', '.MS'
%   data       : structure
%
% Options
%   'progress' : 'on', 'off'
%
% Description
%   filetype   : valid file extension (e.g. '.D', '.MS', '.CDF')
%   data       : append an existing data structure -- (default: none)
%   'progress' : print current import progress in the command window -- (default: 'on')
%
% Examples
%   data = obj.import('.D')
%   data = obj.import('.CDF')
%   data = obj.import('.D', data)
%   data = obj.import('.MS', 'progress', 'off')
%   data = obj.import('.D', data, 'progress', 'on')

function data = import(obj, varargin)
            
% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
elseif ~ischar(varargin{1})
    error('Undefined input arguments of type ''filetype''');
elseif nargin > 2 && isstruct(varargin{2})
    data = DataStructure('validate', varargin{2});
else
    data = DataStructure();
end

% Check file extension
if ~any(find(strcmp(varargin{1}, obj.options.import)))
    error('Unrecognized file format');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check progress options
if ~isempty(input('progress'))
    options.progress = varargin{input('progress') + 1};
    options.compute_time = 0;
    
    % Check user input
    if strcmpi(options.progress, 'off') || strcmpi(options.progress, 'hide')
        options.progress = 'off';
    elseif strcmpi(options.progress, 'on') || strcmpi(options.progress, 'show')
        options.progress = 'on';
    end
else
    options.progress = 'on';
    options.compute_time = 0;
end
    
% Open file selection dialog
files = dialog(obj, varargin{1});

% Check for any file selections
if isempty(files)
    return
end

% Remove entries with incorrect filetype
files(~strcmp(files(:,3), varargin{1}), :) = [];

% Set MATLAB path to selected folder
path(files{1,1}, path);

% Import files
switch varargin{1}

    % Import data with the '*.CDF' extension
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

    % Import data with the '*.MS' extension
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

    % Import data with the '*.D' extension
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
    
    % Update file information
    import_data(i).id = id(i);
    import_data(i).file_type = varargin{1};
    
    % Update diagnostics
    import_data(i).diagnostics.system_date = now;
    import_data(i).diagnostics.system_os = obj.options.system_os;
    import_data(i).diagnostics.matlab_version = obj.options.matlab_version;
    import_data(i).diagnostics.toolbox_version = obj.options.toolbox_version;
    
    % Update statistics
    import_data(i).statistics.compute_time(end+1) = compute_time(i);
    import_data(i).statistics.function{end+1} = 'import';
    import_data(i).statistics.calls(end+1) = 1;
end
            
% Concatenate imported data with existing data
data = [data, import_data];

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

% Determine paths of selected files
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

% Update console with progress
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