function varargout = import(obj, varargin)
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
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'filetype' -- file extension of data file
%       '.D', '.MS', '.CH', '.CDF', '.RAW'
%
%   'append' -- append new data to existing data structure
%       structure
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
% Parse input
% ---------------------------------------
[data, options] = parse(obj, varargin);
varargout{1} = data;

% ---------------------------------------
% Check input
% ---------------------------------------
if isempty(data) && isempty(options)
    disp('Unrecognized file format.');
    return
end

% ---------------------------------------
% Select files
% ---------------------------------------
files = dialog(obj, varargin{1});

if ~isempty(files)
    files(~strcmpi(files(:,3), varargin{1}), :) = [];
end

% ---------------------------------------
% Status
% ---------------------------------------
if isempty(files)
    fprintf(['\n',...
        '[IMPORT]\n\n',...
        '[WARNING] No files selected...\n\n',...
        '[COMPLETE]\n\n']);
    return
else
    fprintf(['\n',...
        '[IMPORT]\n\n',...
        'Importing ', num2str(length(files(:,1))), ' files...\n\n',...
        'Format : ', options.filetype, '\n\n']);
end

options.file_count = length(files(:,1));
%path(files{1,1}, path);

% ---------------------------------------
% Import
% ---------------------------------------
import_data = {};

switch options.filetype
    
    case {'.CDF'}
        
        for i = 1:length(files(:,1))
            
            % ---------------------------------------
            % File path
            % ---------------------------------------
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            if ~status
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                continue
            end
            
            filepath = fattrib.Name;
                
            % ---------------------------------------
            % Import netCDF
            % ---------------------------------------
            tic;
            
            fdata = ImportCDF('file', filepath, 'verbose', 'off');
            
            options.compute_time = options.compute_time + toc;
            
            % ---------------------------------------
            % Append data
            % ---------------------------------------
            if isempty(fdata)
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                continue
            end
            
            for j = 1:length(fdata)
                
                if isfield(fdata, 'tic') && nnz(fdata(j).tic) == 0 && nnz(fdata(j).xic) == 0
                    fprintf([...
                        '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                        ' No data found ''', '%s', '''\n'], filepath);
                    continue
                end
                
                import_data{end+1} = [];
                
                import_data{end}.file.path  = fdata(j).file_path;
                import_data{end}.file.name  = fdata(j).file_name;
                import_data{end}.file.bytes = fdata(j).file_size;
                
                if isfield(fdata, 'experiment_title')
                    import_data{end}.sample.name = fdata(j).experiment_title;
                else
                    import_data{end}.sample.name = '';
                end
                
                if isfield(fdata, 'administrative_comments')
                    import_data{end}.sample.description = fdata(j).administrative_comments;
                else
                    import_data{end}.sample.description = '';
                end
                
                if isfield(fdata, 'external_file_ref_0')
                    import_data{end}.method.name = fdata(j).external_file_ref_0;
                else
                    import_data{end}.method.name = '';
                end
                
                if isfield(fdata, 'experiment_date_time_stamp')
                    import_data{end}.method.datetime = fdata(j).experiment_date_time_stamp;
                else
                    import_data{end}.method.datetime = '';
                end
                
                if isfield(fdata, 'operator_name')
                    import_data{end}.method.operator = fdata(j).operator_name;
                else
                    import_data{end}.method.operator = '';
                end
                
                if isfield(fdata, 'instrument')
                    import_data{end}.method.instrument = fdata(j).instrument;
                else
                    import_data{end}.method.instrument = '';
                end
                
                if isfield(fdata, 'instrument_name') && isempty(import_data{end}.method.instrument)
                    import_data{end}.method.instrument = fdata(j).instrument_name;
                end
                
                if isfield(fdata, 'scan_acquisition_time')
                    import_data{end}.time = fdata(j).scan_acquisition_time;

                    if ~isempty(import_data{end}.time)
                        if isfield(fdata, 'time_values_units') && ~isempty(fdata(j).time_values_units)
                            if strcmpi(fdata(j).time_values_units, 'seconds')
                                import_data{end}.time = import_data{end}.time ./ 60;
                            end
                        elseif isfield(fdata, 'units') && ~isempty(fdata(j).units)
                            if strcmpi(fdata(j).units, 'seconds')
                                import_data{end}.time = import_data{end}.time ./ 60;
                            end
                        end 
                    end
                    
                else
                    import_data{end}.time = [];
                end
                
                if isfield(fdata, 'total_intensity')
                    import_data{end}.tic.values = fdata(j).total_intensity;
                else
                    import_data{end}.tic.values = [];
                end
                
                if isfield(fdata, 'ordinate_values') && isempty(import_data{end}.tic.values)
                    import_data{end}.tic.values = fdata(j).ordinate_values;
                end
                
                if isfield(fdata, 'intensity_values')
                    import_data{end}.xic.values = fdata(j).intensity_values;
                else
                    import_data{end}.xic.values = [];
                end
                
                if isfield(fdata, 'mass_values')
                    import_data{end}.mz = fdata(j).mass_values;
                else
                    import_data{end}.mz = [];
                end
                
            end
            
            % ---------------------------------------
            % Update status
            % ---------------------------------------
            options.import_bytes = options.import_bytes + import_data{end}.file.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, import_data{end}.file.bytes);
        end
        
    case {'.D', '.CH', '.MS'}
        
        for i = 1:length(files(:,1))
            
            % ---------------------------------------
            % File path
            % ---------------------------------------
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            if ~status
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                continue
            end
            
            filepath = fattrib.Name;
            
            % ---------------------------------------
            % Import Agilent
            % ---------------------------------------
            tic;
            
            fdata = ImportAgilent('file', {filepath}, 'verbose', 'off');
            
            options.compute_time = options.compute_time + toc;
            
            % ---------------------------------------
            % Append data
            % ---------------------------------------
            if isempty(fdata)
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                continue
            end
                
            for j = 1:length(fdata)
                
                if isfield(fdata, 'tic') && nnz(fdata(j).tic) == 0 && nnz(fdata(j).xic) == 0
                    fprintf([...
                        '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                        ' No data found ''', '%s', '''\n'], filepath);
                    continue
                end
                
                import_data{end+1} = [];
                
                import_data{end}.file.path  = fdata(j).file_path;
                import_data{end}.file.name  = fdata(j).file_name;
                import_data{end}.file.bytes = fdata(j).file_size;
                
                import_data{end}.sample.name = fdata(j).sample_name;
                import_data{end}.method.name = fdata(j).method;
                
                import_data{end}.time = [];
                import_data{end}.tic.values = [];
                import_data{end}.xic.values = [];
                import_data{end}.mz = [];
                
                if isfield(fdata, 'time')
                    import_data{end}.time = fdata(j).time;
                end
                
                if isfield(fdata, 'intensity')
                    
                    import_data{end}.xic.values = fdata(j).intensity;
                    
                    if isempty(fdata(j).intensity)
                        continue
                    elseif length(fdata(j).intensity(1,:)) == 1
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
                    import_data{end}.method.datetime = fdata(j).datetime;
                end
                
                % ---------------------------------------
                % Update status
                % ---------------------------------------
                options.import_bytes = options.import_bytes + import_data{end}.file.bytes;
                update(i, length(files(:,1)), options.compute_time, options.progress, import_data{end}.file.bytes);
            end     
        end
        
    case {'.MSP'}
        
        for i = 1:length(files(:,1))
            
            % ---------------------------------------
            % File path
            % ---------------------------------------
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            if ~status
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']'...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                continue
            end
            
            filepath = fattrib.Name;
            
            % ---------------------------------------
            % Import NIST
            % ---------------------------------------
            tic;
            
            fdata = ImportNIST('file', filepath, 'verbose', 'off');
            
            options.compute_time = options.compute_time + toc;
            
            % ---------------------------------------
            % Append data
            % ---------------------------------------
            if isempty(fdata)
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                continue
            end
            
            for j = 1:length(fdata)
                
                if isfield(fdata, 'tic') && nnz(fdata(j).tic) == 0 && nnz(fdata(j).xic) == 0
                    fprintf([...
                        '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                        ' No data found ''', '%s', '''\n'], filepath);
                    continue
                end
                
                import_data{end+1} = [];
                
                import_data{end}.file.path  = fdata(j).file_path;
                import_data{end}.file.name  = fdata(j).file_name;
                import_data{end}.file.bytes = fdata(j).file_size;
                
                if isfield(fdata, 'compound_name')
                    import_data{end}.sample.name = fdata(j).compound_name;
                else
                    import_data{end}.sample.name = '';
                end
                
                if isfield(fdata, 'comments')
                    import_data{end}.sample.description = fdata(j).comments;
                else
                    import_data{end}.sample.description = '';
                end
                
                if isfield(fdata, 'intensity')
                    import_data{end}.xic.values = fdata(j).intensity;
                    if ~isempty(import_data{end}.xic.values)
                        import_data{end}.tic.values = sum(fdata(j).intensity,2);
                    end
                else
                    import_data{end}.xic.values = [];
                end
                
                if isfield(fdata, 'mz')
                    import_data{end}.mz = fdata(j).mz;
                else
                    import_data{end}.mz = [];
                end
                
            end
            
            % ---------------------------------------
            % Update status
            % ---------------------------------------
            options.import_bytes = options.import_bytes + import_data{end}.file.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, import_data{end}.file.bytes);
        end
        
    case {'.RAW'}
        
        for i = 1:length(files(:,1))
            
            % ---------------------------------------
            % File path
            % ---------------------------------------
            filepath = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
            [status, fattrib] = fileattrib(filepath);
            
            if ~status
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Invalid file path ''', '%s', '''\n'], filepath);
                
                options.error_count = options.error_count + 1;
                continue
            end
            
            filepath = fattrib.Name;
            fileinfo = dir(filepath);
            
            % ---------------------------------------
            % Import Thermo
            % ---------------------------------------
            tic;
            
            fdata = ImportThermo(filepath, 'precision', options.precision);
            
            options.compute_time = options.compute_time + toc;
            
            % ---------------------------------------
            % Append data
            % ---------------------------------------
            if ~isempty(fdata)
                fprintf([...
                    '[', num2str(i), '/', num2str(length(files(:,1))), ']',...
                    ' Error loading ''', '%s', '''\n'], filepath);
                continue
            end
            
            import_data{end+1} = fdata;
            
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
            
            % ---------------------------------------
            % Status
            % ---------------------------------------
            options.import_bytes = options.import_bytes + fileinfo.bytes;
            update(i, length(files(:,1)), options.compute_time, options.progress, fileinfo.bytes);
            
        end
end

% ---------------------------------------
% Filter data
% ---------------------------------------
varargout{1} = data;
import_data(cellfun(@isempty, import_data)) = [];

if ~isempty(import_data)
    import_data = [import_data{:}];
else
    fprintf('Unable to import selection\n');
    return
end

if ~isempty(data) && isempty(data(1).id) && isempty(data(1).name)
    data(1) = [];
end

% ---------------------------------------
% Check MS/MS data
% ---------------------------------------
if ~isempty(options.extra)
    data = obj.format('validate', data, 'extra', options.extra);    
    import_data = obj.format('validate', import_data, 'extra', options.extra);
elseif isfield(data, 'ms2')
    import_data = obj.format('validate', import_data, 'extra', 'ms2');
else
    import_data = obj.format('validate', import_data);
end

% ---------------------------------------
% Prepare output
% ---------------------------------------
for i = 1:length(import_data)
    
    import_data(i).id = length(data) + i;
    import_data(i).name = import_data(i).file.name;
    
    import_data(i).backup.time = import_data(i).time;
    import_data(i).backup.tic = import_data(i).tic.values;
    import_data(i).backup.xic = import_data(i).xic.values;
    import_data(i).backup.mz = import_data(i).mz;
    
    import_data(i).tic.baseline = [];
    import_data(i).xic.baseline = [];
    
    import_data(i).status.centroid = 'N';
    import_data(i).status.baseline = 'N';
    import_data(i).status.smoothed = 'N';
    import_data(i).status.integrate = 'N';
    
end

% ---------------------------------------
% Display summary
% ---------------------------------------
if options.compute_time > 60
    elapsed = [num2str(options.compute_time/60, '%.1f'), ' min'];
else
    elapsed = [num2str(options.compute_time, '%.1f'), ' sec'];
end

fprintf(['\n',...
    'Files   : ', num2str(length(import_data)+options.error_count), '\n',...
    'Elapsed : ', elapsed, '\n',...
    'Bytes   : ', num2str(options.import_bytes/1E6, '%.2f'), ' MB\n']);

fprintf('\n[COMPLETE]\n\n');

% ---------------------------------------
% Output
% ---------------------------------------
varargout{1} = [data, import_data];

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

function update(varargin)

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

fprintf(['[', m, '/', n, '] in ', t, ' (', size, ')\n']);

end

function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

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

input = @(x) find(strcmpi(varargin, x),1);

% Append
if ~isempty(input('append'))
    options.append = varargin{input('append')+1};
    
    if isstruct(options.append)
        data = obj.format('validate', options.append);
    else
        data = obj.format();
    end
else
    data = obj.format();
end

% Precision
options.precision = 3;

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
end

% Verbose
options.progress = 'on';

if ~isempty(input('verbose'))
    options.progress = varargin{input('verbose')+1};
    
    if any(strcmpi(options.progress, {'off', 'hide'}))
        options.progress = 'off'; 
    elseif any(strcmpi(options.progress, {'default', 'on', 'show', 'display'}))
        options.progress = 'on';
    end
end

options.compute_time = 0;
options.import_bytes = 0;
options.file_count   = 0;
options.error_count  = 0;
options.extra        = '';

varargout{1} = data;
varargout{2} = options;

end