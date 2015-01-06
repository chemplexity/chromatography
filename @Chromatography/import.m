% Method: import
%  -Import raw LC/MS data into the MATLAB workspace
%
% Syntax
%   import(filetype)
%   import(filetype, data)
%   import(filetype, data, 'OptionName', optionvalue...)
%
% Options
%   'progress' : 'on', 'off'
%   'centroid' : 'on', 'off'
%
% Description
%   filetype   : valid file extension (.D, .MS, .CDF)
%   data       : append an existing data structure -- (default: none)
%   'progress' : print current import progress to command window -- (default: 'on')
%   'centroid' : calculate the centroid spectrum of dataset -- (default: 'on')
%
% Examples
%   data = obj.import('.D')
%   data = obj.import('.CDF')
%   data = obj.import('.D', data)
%   data = obj.import('.MS', 'progress', 'off')
%   data = obj.import('.D', 'centroid', 'off')

function data = import(obj, varargin)
            
% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
elseif nargin >2 && isstruct(varargin{2})
    data = DataStructure('validate', varargin{2});
else
    data = DataStructure();
end

% Check file extension
if ~any(find(strcmp(varargin{1}, obj.options.import)))
    error('Unknown file format');
end

% Check progress options
if ~isempty(find(strcmpi(varargin, 'progress'),1))
    options.progress = varargin{find(strcmpi(varargin, 'progress'),1) + 1};
   
    % Check user input
    if strcmpi(options.progress, 'off') || strcmpi(options.progress, 'hide')
        options.progress = 0;
    else
        options.progress = 1;
    end
else
    options.progress = 1;
end

% Check centroid options
if ~isempty(find(strcmpi(varargin, 'centroid'),1))
    options.centroid = varargin{find(strcmpi(varargin, 'centroid'),1) + 1};
   
    % Check user input
    if strcmpi(options.centroid, 'off')
        options.centroid = 0;
    else
        options.centroid = 1;
    end
else
    options.centroid = 1;
end
    
% Open file selection dialog
files = dialog(obj, varargin{1});

% Check for any selections
if isempty(files)
    return
end

% Remove entries with incorrect filetype
files(~strcmp(files(:,3), varargin{1}), :) = [];
   
% Set path to selected folder
path(files{1,1}, path);

% Store runtime information
options.runtime = 0;

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
            processing_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            
            % Display import progress
            options.runtime = options.runtime + processing_time(i);
            update(i, length(files(:,1)), options.runtime, options.progress); 
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
            processing_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            
            % Display import progress
            options.runtime = options.runtime + processing_time(i);
            update(i, length(files(:,1)), options.runtime, options.progress); 
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
            processing_time(i) = toc;
            % Assign a unique id
            id(i) = length(data) + i;
            % Remove file from path
            rmpath(file_path);
            
            % Display import progress
            options.runtime = options.runtime + processing_time(i);
            update(i, length(files(:,1)), options.runtime, options.progress); 
        end
end

% Add missing fields to data structure
import_data = DataStructure('Validate', import_data);

% Update data structure
for i = 1:length(id)
    import_data(i).id = id(i);
    import_data(i).file_type = varargin{1};

    % Update diagnostics
    import_data(i).diagnostics.system_os = computer;
    import_data(i).diagnostics.system_version = version;
    import_data(i).diagnostics.system_date = now;
    
    % Update import diagnostics
    import_data(i).diagnostics.import.processing_time = processing_time(i);
    import_data(i).diagnostics.import.processing_spectra = length(import_data(i).mass_values);
    import_data(i).diagnostics.import.processing_spectra_length = length(import_data(i).time_values);
end
            
% Concatenate imported data with existing data
data = [data, import_data];

% Centroid data
if options.centroid == 4
    data = Centroid(data);
end

end

% Open dialog box to select files
function varargout = dialog(obj, varargin)
            
% Set filetype
file_extension = varargin{1};
            
% Initialize JFileChooser object
fileChooser = javax.swing.JFileChooser(java.io.File(cd));
            
% Select directories if certain filetype
if strcmp(file_extension, '.D')
    fileChooser.setFileSelectionMode(fileChooser.DIRECTORIES_ONLY);
end
            
% Determine file description and file extension
filter = com.mathworks.hg.util.dFilter;
description = [obj.options.import{strcmp(obj.options.import(:,1), file_extension), 2}];
extension = lower(file_extension(2:end));
            
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
    fileinfo = fileChooser.getSelectedFiles();
    
    % Parse file information
    for i = 1:size(fileinfo, 1)
        [files{i,1}, files{i,2}, files{i,3}] = ...
            fileparts(char(fileinfo(i).getAbsolutePath));
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
    if varargin{4} == 0
        return
    end

    % Display progress
    disp([...
        num2str(varargin{1}),...
        '/',...
        num2str(varargin{2}),...
        ' in ',...
        num2str(varargin{3}, '% 10.3f'),...
        ' sec.'...
        ]);
end