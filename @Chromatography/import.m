% ------------------------------------------------------------------------
% Method      : Chromatography.import
% Description : Import instrument data files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.import(filetype)
%   data = obj.import( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   filetype -- file extension of data file
%       '.D' | '.CDF' | '.RAW' | '.MS'
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'append' -- append new data to existing data structure
%       structure
%
%   'precision' -- maximum decimal places for m/z values
%       3 (default) | number
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

function varargout = import(obj, varargin)

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

% Remove entries with incorrect filetype
if ~isempty(files)
    files(~strcmpi(files(:,3), varargin{1}), :) = [];
end

if isempty(files)
    
    fprintf(['\n',...
        '[IMPORT]\n\n',...
        '[WARNING] No files selected...\n\n',...
        '[COMPLETE]\n\n']);

    varargout{1} = data;
    return
    
else
    
    fprintf(['\n',...
        '[IMPORT]\n\n',...
        'Importing ', num2str(length(files(:,1))), ' files...\n\n',...
        'Format : ', options.filetype, '\n\n']);
end

% Set path to selected folder
path(files{1,1}, path);

% Variables
import_data = {};
options.file_count = length(files(:,1));

% Import files
switch options.filetype
    
    % Import netCDF data with the '*.CDF' extension
    case {'.CDF'}
        
        for i = 1:length(files(:,1))
            
            % Absolute file path
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            % Check file path
            if status
                filepath = fattrib.Name;
                fileinfo = dir(filepath);
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue;
            end
            
            % Start timer
            tic;
            
            % Import data
            fdata = ImportCDF(filepath, 'precision', options.precision);
            
            % Stop timer
            options.compute_time = options.compute_time + toc;
            
            if ~isempty(fdata)
                
                % Check last value
                if sum(fdata.xic.values(end,:)) == 0
                    fdata.time(end) = [];
                    fdata.tic.values(end) = [];
                    fdata.xic.values(end,:) = [];
                end
                
                import_data{end+1} = fdata;
                
                % File info
                import_data{end}.file.path = filepath;
                import_data{end}.file.name = regexp(filepath, '(?i)\w+[.]CDF', 'match');
                import_data{end}.file.name = import_data{end}.file.name{1};
                import_data{end}.file.bytes = fileinfo.bytes;
                
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Error loading ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue;
            end
            
            % Display import progress
            options.import_bytes = options.import_bytes + fileinfo.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, fileinfo.bytes);
        end
        
        % Import Agilent data with the '*.MS' extension
    case {'.MS'}
        
        for i = 1:length(files(:,1))
            
            % Absolute file path
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            % Check file path
            if status
                filepath = fattrib.Name;
                fileinfo = dir(filepath);
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue;
            end
            
            % Start timer
            tic;
            
            % Import data
            fdata = ImportAgilent('file', filepath, 'verbose', 'off');
            %fdata = ImportAgilent(filepath);
            
            % Stop timer
            options.compute_time = options.compute_time + toc;
            
            if ~isempty(fdata)
                
                import_data{end+1} = [];
                
                % File info
                import_data{end}.file.path = fdata.file_path;
                import_data{end}.file.name = fdata.file_name;
                import_data{end}.file.bytes = 0;
                %import_data{end}.file.path = filepath;
                %import_data{end}.file.name = regexp(filepath, '(?i)\w+[.]MS', 'match');
                %import_data{end}.file.name = import_data{end}.file.name{1};
                %import_data{end}.file.bytes = fileinfo.bytes;
                
                % File header
                import_data{end}.sample.name = fdata.sample_name;
                import_data{end}.method.name = fdata.method;
                
                % File data
                import_data{end}.time = [];
                import_data{end}.tic.values = [];
                import_data{end}.xic.values = [];
                import_data{end}.mz = [];
                
                if isfield(fdata, 'time')
                    import_data{end}.time = fdata.time;
                end
                
                if isfield(fdata, 'intensity')
                    
                    if length(fdata.intensity(1,:)) > 1
                        import_data{end}.tic.values = fdata.intensity(:,1);
                        import_data{end}.xic.values = fdata.intensity(:,2:end);
                    end
                    
                    if length(fdata.intensity(1,:)) == 1
                        import_data{end}.tic.values = fdata.intensity;
                    end
                    
                end
                
                if isfield(fdata, 'channel')
                    import_data{end}.mz = fdata.channel;
                end
                
                if isfield(fdata, 'tic')
                    import_data{end}.tic.values = fdata.tic;
                end
                
                if isfield(fdata, 'xic')
                    import_data{end}.xic.values = fdata.xic;
                end
                
                if isfield(fdata, 'mz')
                    import_data{end}.mz = fdata.mz;
                end
                
                rmpath(filepath);
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Error loading ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                rmpath(filepath);
                continue
            end
            
            % Display import progress
            options.import_bytes = options.import_bytes + fileinfo.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, fileinfo.bytes);
        end
        
        % Import Agilent data with the '*.D' extension
    case {'.D'}
        
        for i = 1:length(files(:,1))
            
            % Absolute file path
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            
            [status, fattrib] = fileattrib(filepath);
            
            % Check file path
            if status
                filepath = fattrib.Name;
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue;
            end
            
            % Start timer
            tic;
            
            % Import file data
            fdata = ImportAgilent('file', filepath, 'verbose', 'off');
            
            % Stop timer
            options.compute_time = options.compute_time + toc;
            
            if ~isempty(fdata)
                
                for j = 1:length(fdata)
                    
                    if isfield(fdata, 'tic') && nnz(fdata(j).tic) == 0 && nnz(fdata(j).xic) == 0
                        fprintf([...
                            '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                            ' No data found ''', '%s', '''\n'], filepath);
                        continue;
                    end
                    
                    import_data{end+1} = [];
                    
                    % File info
                    import_data{end}.file.path = fdata(j).file_path;
                    import_data{end}.file.name = fdata(j).file_name;%regexp(filepath, '(?i)\w+[.]D', 'match');
                    %import_data{end}.file.name = regexp(filepath, '(?i)\w+[.]D', 'match');
                    %import_data{end}.file.name = import_data{end}.file.name{1};
                    %import_data{end}.file.bytes = fdata(j).file.bytes;
                    import_data{end}.file.bytes = 0;
                    
                    % File header
                    import_data{end}.sample.name = fdata(j).sample_name;
                    import_data{end}.method.name = fdata(j).method;
                    
                    % File data
                    import_data{end}.time = [];
                    import_data{end}.tic.values = [];
                    import_data{end}.xic.values = [];
                    import_data{end}.mz = [];
                    
                    if isfield(fdata, 'time')
                        import_data{end}.time = fdata(j).time;
                    end
                    
                    if isfield(fdata, 'intensity')
                        
                        import_data{end}.xic.values = fdata(j).intensity;
                        
                        if length(fdata(j).intensity(1,:)) == 1
                            import_data{end}.tic.values = import_data{end}.xic.values;
                        else
                            import_data{end}.tic.values = sum(fdata(j).intensity, 2);
                        end
                        
                    end
                    
                    if isfield(fdata, 'channel')
                        import_data{end}.mz = fdata(j).channel;
                        
                        if length(import_data{end}.mz) > 1 && import_data{end}.mz(1) == 0
                            import_data{end}.xic.values(:,1) = [];
                            import_data{end}.mz(:,1)= [];
                        end
                    end
                    
                    if isfield(fdata, 'tic')
                        import_data{end}.tic.values = fdata(j).tic;
                    end
                    
                    if isfield(fdata, 'xic')
                        import_data{end}.xic.values = fdata(j).xic;
                    end
                    
                    if isfield(fdata, 'mz')
                        import_data{end}.mz = fdata(j).mz;
                    end
                    
                    if isfield(fdata, 'sample_info')
                        import_data{end}.sample.description = fdata(j).sample_info;
                    end
                    
                    if isfield(fdata, 'seqindex')
                        import_data{end}.sample.sequence = fdata(j).seqindex;
                    end
                    
                    if isfield(fdata, 'vial')
                        import_data{end}.sample.vial = fdata(j).vial;
                    end
                    
                    if isfield(fdata, 'replicate')
                        import_data{end}.sample.replicate = fdata(j).replicate;
                    end
                    
                    if isfield(fdata, 'operator')
                        import_data{end}.method.operator = fdata(j).operator;
                    end
                    
                    if isfield(fdata, 'instrument')
                        import_data{end}.method.instrument = fdata(j).instrument;
                    end
                    
                    if isfield(fdata, 'datetime')
                        import_data{end}.method.date = fdata(j).datetime;
                    end
                    
                    % Update progress
                    options.import_bytes = options.import_bytes + import_data{end}.file.bytes;
                    update(i, length(files(:,1)), options.compute_time, options.progress, import_data{end}.file.bytes);
                end
                
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue
            end
        end
        
        % Import Thermo Finnigan data with the '*.RAW' extension
    case {'.RAW'}
        
        for i = 1:length(files(:,1))
            
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            % Check file path
            if status
                filepath = fattrib.Name;
                fileinfo = dir(filepath);
            else
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue;
            end
            
            % Start timer
            tic;
            
            % Import data
            fdata = ImportThermo(filepath, 'precision', options.precision);
            
            % Stop timer
            options.compute_time = options.compute_time + toc;
            
            if ~isempty(fdata)
                
                import_data{end+1} = fdata;
                
                % File info
                import_data{end}.file.path = filepath;
                import_data{end}.file.name = regexp(filepath, '(?i)\w+[.]RAW', 'match');
                import_data{end}.file.name = import_data{end}.file.name{1};
                import_data{end}.file.bytes = fileinfo.bytes;
                
                if ~isfield(import_data{end}, 'xic')
                    import_data{end}.xic = [];
                end
                
                if isfield(import_data{i}, 'ms2')
                    options.extra = 'ms2';
                end
                
            else                
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue
            end
            
            % Display import progress
            options.import_bytes = options.import_bytes + fileinfo.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, fileinfo.bytes);
        end
end

% Remove missing data
import_data(cellfun(@isempty, import_data)) = [];

% Check remaining data
if isempty(import_data)
    
    fprintf('Unable to import selection\n');
    
    varargout{1} = data;
    
    return
else
    
    % Convert to structure
    import_data = [import_data{:}];
end

% Check missing fields
if ~isempty(options.extra)
    import_data = obj.format('validate', import_data, 'extra', options.extra);
    data = obj.format('validate', data, 'extra', options.extra);
    
elseif isfield(data, 'ms2')
    import_data = obj.format('validate', import_data, 'extra', 'ms2');
    
else
    import_data = obj.format('validate', import_data);
end

% Check data
if ~isempty(data) && isempty(data(1).id) && isempty(data(1).name)
    data(1) = [];
end

% Prepare output data
for i = 1:length(import_data)
    
    % File information
    import_data(i).id = length(data) + i;
    import_data(i).name = import_data(i).file.name;
    
    % Backup
    import_data(i).backup.time = import_data(i).time;
    import_data(i).backup.tic = import_data(i).tic.values;
    import_data(i).backup.xic = import_data(i).xic.values;
    import_data(i).backup.mz = import_data(i).mz;
    
    % Baseline
    import_data(i).tic.baseline = [];
    import_data(i).xic.baseline = [];
    
    % Status
    import_data(i).status.centroid = 'N';
    import_data(i).status.baseline = 'N';
    import_data(i).status.smoothed = 'N';
    import_data(i).status.integrate = 'N';
end

% Return data
varargout{1} = [data, import_data];

% Display summary
if options.compute_time > 60
    elapsed = [num2str(options.compute_time/60, '%.1f'), ' min'];
else
    elapsed = [num2str(options.compute_time, '%.1f'), ' sec'];
end

fprintf(['\n',...
    'Found   : ', num2str(length(import_data)+options.error_count), '\n',...
    'Errors  : ', num2str(options.error_count), '\n',...
    'Elapsed : ', elapsed, '\n',...
    'Bytes   : ', num2str(options.import_bytes/1E6, '%.2f'), ' MB\n']);

fprintf('\n[COMPLETE]\n\n');
end


% Open dialog box to select files
function varargout = dialog(obj, varargin)

% Set filetype
extension = upper(varargin{1});

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
if strcmpi(varargin{4}, 'off')
    return
end

m = num2str(varargin{1});
n = num2str(varargin{2});

if varargin{3} > 60
    t = [num2str(varargin{3}/60, '%.1f'), ' min'];
else
    t = [num2str(varargin{3}, '%.1f'), ' sec'];
end

if varargin{5} > 1E6
    size = [num2str(varargin{5}/1E6,'%.1f'), ' MB'];
else
    size = [num2str(varargin{5}/1E3,'%.1f'), ' KB'];
end

% Display progress
fprintf(['[', m, '/', n, '] in ', t, ' (', size, ')\n']);

end


% Parse user input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1
    error('Not enough input arguments...');
    
elseif ~ischar(varargin{1})
    error('Undefined input arguments of type ''filetype''...');
    
elseif ischar(varargin{1})
    varargin{1} = upper(varargin{1});
end

% Check for supported file extension
if ~any(find(strcmpi(varargin{1}, obj.options.import)))
    
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
if ~isempty(input('verbose'))
    options.progress = varargin{input('verbose')+1};
    
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
options.import_bytes = 0;

options.file_count = 0;
options.error_count = 0;
options.extra = '';

% Return input
varargout{1} = data;
varargout{2} = options;

end