% Method: import
%  -Import chromatography data into the MATLAB workspace
%
% Syntax
%   data = import(filetype)
%   data = import(filetype, 'OptionName', optionvalue...)
%
% Input
%   filetype    : '.CDF', '.D', '.MS', '.RAW'
%
% Options
%   'append'    : structure
%   'precision' : integer
%   'progress'  : 'on', 'off'
%
% Description
%   filetype    : file extension (e.g. '.D', '.MS', '.CDF', '.RAW')
%   'append'    : append data structure (default = none)
%   'precision' : number of decimal places allowed for m/z values (default = 3)
%   'progress'  : display import progress (default = 'on')
%
% Examples
%   data = obj.import('.CDF')
%   data = obj.import('.D', 'append', data)
%   data = obj.import('.MS', 'progress', 'off', 'precision', 2)
%   data = obj.import('.RAW', 'append', data, 'progress', 'on')

function varargout = import(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Check for errors
if isempty(data) && isempty(options)
    disp('Unrecognized file format.');
    return
end

% Supress warnings
warning off all

% Open file selection dialog
files = dialog(obj, varargin{1});

% Check for any file selections
if isempty(files)
    varargout{1} = data;
    return
end

% Remove entries with incorrect filetype
files(~strcmpi(files(:,3), varargin{1}), :) = [];

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
            import_data{i} = ImportCDF(strcat(files{i,2},files{i,3}), 'precision', options.precision);
            
            % Stop timer
            compute_time(i) = toc;
            
            % Check data
            if isempty(import_data(i))
                continue
            end
            
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
            import_data{i} = ImportAgilent(file_path, 'precision', options.precision);
            
            % Stop timer
            compute_time(i) = toc;
            
            % Check data
            if isempty(import_data{i})
                disp(['Unrecognized file format (', num2str(i), '/', num2str(length(files(:,1))), ').']);
                continue
            end
            
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
            import_data{i} = ImportAgilent(file_path, 'precision', options.precision);
            
            % Stop timer
            compute_time(i) = toc;
            
            % Remove file from path
            rmpath(file_path);
            
            % Check data
            if isempty(import_data{i})
                disp(['Unrecognized file format (', num2str(i), '/', num2str(length(files(:,1))), ').']);
                continue
            end
            
            % Display import progress
            options.compute_time = options.compute_time + compute_time(i);
            update(i, length(files(:,1)), options.compute_time, options.progress);
        end
        
    % Import Thermo Finnigan data with the '*.RAW' extension
    case {'.RAW'}
        
        for i = 1:length(files(:,1))
            
            % Start timer
            tic;
            
            % Import data
            import_data{i} = ImportThermo(strcat(files{i,2},files{i,3}), 'precision', options.precision);
            
            % Stop timer
            compute_time(i) = toc;
            
            % Check data
            if isempty(import_data{i})
                disp(['Unrecognized file format (', num2str(i), '/', num2str(length(files(:,1))), ').']);
                continue
            end
            
            % Check fields
            if ~isfield(import_data{i}, 'xic')
                import_data{i}.xic = [];
            end
            
            if isfield(import_data{i}, 'ms2')
                options.extra = 'ms2';
            end
            
            % Display import progress
            options.compute_time = options.compute_time + compute_time(i);
            update(i, length(files(:,1)), options.compute_time, options.progress);
        end
end

% Remove missing data
import_data(cellfun(@isempty, import_data)) = [];

% Check remaining data
if isempty(import_data)
    varargout{1} = data;
    return

else    
    % Add file names
    for i = 1:length(import_data)
        
        % Check for multiple files
        if length(import_data{i}) == 1
            import_data{i}.file.name = strcat(files{i,2}, files{i,3});
        else
            for j = 1:length(import_data{i})
                import_data{i}(j).file.name = strcat(files{i,2}, files{i,3}); 
            end
        end
    end
    
    % Convert to structure
    import_data = [import_data{:}];
end

% Add missing fields to data structure
if ~isempty(options.extra)
    data = obj.format('validate', data, 'extra', options.extra);
    import_data = obj.format('validate', import_data, 'extra', options.extra);
elseif isfield(data, 'ms2')
    import_data = obj.format('validate', import_data, 'extra', 'ms2');
else
    import_data = obj.format('validate', import_data);
end

% Check data
if ~isempty(data) && isempty(data(1).id) && isempty(data(1).name)
    data(1) = [];
end

% Update data structure
for i = 1:length(import_data)
    
    % File information
    import_data(i).id = length(data) + i;
    import_data(i).name = import_data(i).sample.name;
    import_data(i).file.type = options.filetype;
    
    % Data backup
    import_data(i).tic.backup = import_data(i).tic.values;
    import_data(i).xic.backup = import_data(i).xic.values;
    
    % Initialize baseline values
    import_data(i).tic.baseline = [];
    import_data(i).xic.baseline = [];
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
    error('Not enough input arguments.');
elseif ~ischar(varargin{1})
    error('Undefined input arguments of type ''filetype''.');
end

% Check for supported file extension
if ~any(find(strcmp(varargin{1}, obj.options.import)))
    varargout{1} = [];
    varargout{2} = [];
    return
else
    options.filetype = varargin{1};
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Append
if ~isempty(input('append'))
    options.append = varargin{input('append')+1};
    
    % Check for valid input
    if isstruct(options.append)
        data = obj.format('validate', options.append);
    else
        data = obj.format();
    end
else
    data = obj.format();
end

% Precision
if ~isempty(input('precision'))
    precision = varargin{input('precision')+1};
    
    % Check for valid input
    if ~isnumeric(precision)
        options.precision = 3;
        
    elseif precision < 0
        
        % Check for case: -x
        if precision >= -9 && precision <= 0
            options.precision = abs(precision);
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
        
    elseif precision > 0 && log10(precision) < 0
        
        % Check for case: 10^-x
        if log10(precision) >= -9 && log10(precision) <= 0
            options.precision = abs(log10(precision));
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
 
    elseif precision > 9
        
        % Check for case: 10^x
        if log10(precision) <= 9 && log10(precision) >= 0
            options.precision = log10(precision);
        else
            options.precision = 3;
            disp('Input arguments of type ''precision'' invalid. Value set to: ''3''.');
        end
    else
        options.precision = precision;
    end
else
    options.precision = 3;
end

% Progress
if ~isempty(input('progress'))
    options.progress = varargin{input('progress')+1};
    
    % Check for valid input
    if any(strcmpi(options.progress, {'off', 'hide'}))
        options.progress = 'off';
    elseif any(strcmpi(options.progress, {'default', 'on', 'show', 'display'}))
        options.progress = 'on';
    else
        options.progress = 'on';
    end
else
    options.progress = 'on';
end

% Variables
options.compute_time = 0;
options.extra = '';

% Return input
varargout{1} = data;
varargout{2} = options;
end