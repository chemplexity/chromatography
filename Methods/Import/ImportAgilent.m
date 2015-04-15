% ImportAgilent
%   Extract raw data from Agilent (.D, .MS, .CH) files
%
% Syntax
%   data = ImportAgilent(file)
%   data = ImportAgilent(file, 'OptionName', optionvalue...)
%
% Input
%   file        : string
%
% Description
%   file        : file name with valid extension (.D, .MS)
%
% Examples
%   data = ImportAgilent('MSD1.MS')
%   data = ImportAgilent('Trial1.D')
%
% Compatibility
%   Agilent, LC
%       6100 Series Single Quadrupole LC/MS
%       1100 Series Diode Arrary Detector (DAD)
%   Agilent, GC
%       5970 Series GC/MSD
%       6890 Series GC/FID

function varargout = ImportAgilent(varargin)

% Parse user input
[files, options] = parse(varargin);

% Import functions
for i = 1:length(files(:,1))
    
    switch files{i,2};
        
        %
        % Agilent // Mass Spectrometer (GC/MS, LC/MS)
        %
        case {'.MS', '.ms'}
            data{i} = AgilentMS(files{i,1}, options);
        
        %
        % Agilent // Other Detectors (GC/FID, LC/DAD, LC/ELSD,...)
        %
        case {'.CH', '.ch'}
            data{i} = AgilentCH(files{i,1}, options);
            
        otherwise
            data{i} = [];
    end
end

data(cellfun(@isempty, data)) = [];

% Output
varargout(1) = {[data{:}]};

end

% 
% Agilent // Mass Spectrometer
%
function varargout = AgilentMS(varargin)

    %
    % File Information
    %
    function [data, options] = FileInfo(file, data, options)
        
        % Sample name
        fseek(file, 40, 'bof');
        data.sample.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');
        
        % Sample description
        fseek(file, 86, 'bof');
        data.sample.description = strtrim(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

        % Sample vial number
        fseek(file, 254, 'bof');
        data.sample.vial = fread(file, 1, 'short', 0, 'b');
        
        % Sample trial number
        fseek(file, 256, 'bof');
        data.sample.trial = fread(file, 1, 'short', 0, 'b');
        
        % Method name
        fseek(file, 228, 'bof');
        data.method.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

        % Method operator
        fseek(file, 148, 'bof');
        data.method.operator = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');
        
        % Method date/time
        fseek(file, 178, 'bof');
        date = datevec(deblank(fread(file, 20, 'uint8=>char')'));
        
        data.method.date = strtrim(datestr(date, 'mm/dd/yy'));
        data.method.time = strtrim(datestr(date, 'HH:MM PM'));
        
        % Instrument name
        fseek(file, 208, 'bof');
        data.instrument.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');
        
        % Instrument inlet
        fseek(file, 218, 'bof');
        data.instrument.inlet = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');
        
        % Total scans
        fseek(file, 278, 'bof');
        options.scans = fread(file, 1, 'uint', 'b');
        
        % TIC offset
        fseek(file, 260, 'bof');
        options.offset.tic = fread(file, 1, 'int', 'b') .* 2 - 2;
        
        % XIC offset
        fseek(file, options.offset.tic, 'bof');
        options.offset.xic = (fread(file, options.scans, 'int', 8, 'b')) .* 2 - 2;
        
        % Nomalization offset
        fseek(file, 272, 'bof');
        options.offset.normalization = fread(file, 1, 'int', 'b') .* 2 - 2;
    end

    %
    % TIC
    %
    function [data, options] = ImportTIC(file, data, options)
 
        % Variables
        scans = options.scans;
        offset = options.offset.tic;
        
        % Pre-allocate memory
        data.time = zeros(scans, 1);
        data.tic = zeros(scans, 1);
        
        % Time values
        fseek(file, offset+4, 'bof');
        data.time = fread(file, scans, 'int', 8, 'b') ./ 60000;
        
        % Total intensity values
        fseek(file, offset+8, 'bof');
        data.tic = fread(file, scans, 'int', 8, 'b');
    end

    %
    % XIC
    % 
    function [data, options] = ImportXIC(file, data, options)
       
        % Variables
        if ~isfield(options, 'scans') && ~isfield(options, 'offset')
            return
        end
        
        scans = options.scans;
        offset = options.offset.xic;
        
        mz = [];
        xic = [];
        
        for i = 1:scans
    
            % Scan size
            fseek(file, offset(i,1), 'bof');
            n(i) = (fread(file, 1, 'int16', 0, 'b') - 18) / 2 + 2;
    
            % Mass values
            fseek(file, offset(i,1)+18, 'bof');
            mz(end+1:end+n(i)) = fread(file, n(i), 'uint16', 2, 'b');
    
            % Intensity values
            fseek(file, offset(i,1)+20, 'bof');
            xic(end+1:end+n(i)) = fread(file, n(i), 'int16', 2, 'b');
        end
        
        % Correct intensity values (mantissa/exponent)
        xic = bitand(xic, 16383, 'int16') .* (8 .^ abs(bitshift(xic, -14, 'int16')));
        
        % Correct mass values (20-bit ADC)
        mz = mz ./ 20;
        
        % Round mass values
        mz = round(mz .* 10^options.precision) ./ 10^options.precision;
        data.mz = unique(mz, 'sorted');
        
        % Reshape intensity values (rows = time, columns = m/z)
        if length(data.mz) == length(xic) / length(data.time)
            
            % Fixed scan size
            data.xic = reshape(xic, length(data.mz), length(data.time))';
        else
            
            % Variable scan size
            index(:,2) = cumsum(n);
            index(:,1) = circshift(index(:,2), [1,0]) + 1;
            index(1,1) = 1;
            
            % Pre-allocate memory
            data.xic = zeros(length(data.time), length(data.mz));
           
            % Index columns
            [~, cols] = ismember(mz, data.mz);
            
            for i = 1:scans
                data.xic(i, cols(index(i,1):index(i,2))) = xic(index(i,1):index(i,2));
            end
        end
    end

% Variables
file = varargin{1};
data = [];
options = varargin{2};

% Open file
file = fopen(file, 'r', 'b');

% Version
options.version = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

switch options.version
    
    case {'2', '20'}
        [data, options] = FileInfo(file, data, options);
        [data, options] = ImportTIC(file, data, options);
        [data, options] = ImportXIC(file, data, options);
end

% Close file
fclose(file);

% Output
varargout{1} = data;
varargout{2} = options;
end


% 
% Agilent // Other Detectors (FID)
%
function varargout = AgilentCH(varargin)

    %
    % Flame Ionization Detector (8, 81, 181)
    %
    function [data, options] = FileInfo(file, data, options)
        
        % Sample name
        fseek(file, options.offset.sample, 'bof');
        data.sample.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
        
        % Method name
        fseek(file, options.offset.method, 'bof');
        data.method.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
       
        % Method operator
        fseek(file, options.offset.operator, 'bof');
        data.method.operator = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
       
        % Method date/time
        fseek(file, options.offset.date, 'bof');
        date = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
        
        try
            data.method.date = strtrim(datestr(date, 'mm/dd/yy'));
            data.method.time = strtrim(datestr(date, 'HH:MM PM'));
        catch
        end
        
        % Instrument type
        fseek(file, options.offset.method, 'bof');
        data.instrument.name = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
       
        % Instrument units
        fseek(file, options.offset.units, 'bof');
        data.instrument.units = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char', 1, 'b')');
    end

    %
    % Flame Ionization Detector (8, 81)
    %
    function [data, options] = ImportFID1(file, data, options)
    
        % Determine file size
        fseek(file, 0, 'eof');
        n = ftell(file) - options.offset.data - 2;
                
        % Variables
        data.intensity = 0;
        y = 0;
        
        % Intensity values
        fseek(file, options.offset.data, 'bof');
       
        y0 = fread(file, 1, 'int16', 0, 'b');
        
        while n > 0
        
            % Read data
            dy = fread(file, 1, 'int16', 0, 'b');
            
            if dy == y0
                n = n - 2;
                data.intensity(end+1) = y;
            
            elseif dy == -32767
                n = n - 6;
                dy = fread(file, 1, 'int', 0, 'b');
                
            else
                n = n - 2;
                y = y + dy;
                data.intensity(end+1) = y;
            end
        end
                
        data.intensity(1) = [];
        
        % Time values
        fseek(file, 282, 'bof');
        
        switch options.version
            case '8'
                t0 = fread(file, 1, 'int', 0, 'b') / 60000;
                t1 = fread(file, 1, 'int', 0, 'b') / 60000;
            case '81'
                t0 = fread(file, 1, 'float', 0, 'b') / 60000;
                t1 = fread(file, 1, 'float', 0, 'b') / 60000;
        end
        
        data.time = linspace(t0, t1, length(data.intensity));
    end

    %
    % Flame Ionization Detector (181)
    %
    function [data, options] = ImportFID2(file, data, options)
    
        % Determine file size
        fseek(file, 0, 'eof');
        n = ftell(file) - options.offset.data;
                
        % Variables
        data.intensity = 0;
        yy = 0;
       
        % Intensity values
        fseek(file, options.offset.data, 'bof');
        
        while n > 0
            
            % Read data
            y = fread(file, 1, 'int16', 0, 'b');
            
            if y == 32767
                
                % Update variables
                yy = 0;
                n = n - 8;
                
                % Add data point
                a = fread(file, 1, 'int32', 0, 'b');
                b = fread(file, 1, 'uint16', 0, 'b');
                data.intensity(end+1) = a * 65534 + b;
            else
                
                % Update variables
                yy = yy + y;
                n = n - 2;
                
                % Add data point
                data.intensity(end+1) = data.intensity(end) + yy;
            end
        end
        
        data.intensity(1) = [];
        
        % Time values
        fseek(file, 282, 'bof');
        t0 = fread(file, 1, 'float', 0, 'b') / 60000;
        t1 = fread(file, 1, 'float', 0, 'b') / 60000;
        
        data.time = linspace(t0, t1, length(data.intensity));
    end
 
% Variables
file = varargin{1};
data = [];
options = varargin{2};

% Open file
file = fopen(file, 'r', 'b');

% Version
options.version = deblank(fread(file, fread(file, 1, 'uint8'), 'uint8=>char')');

switch options.version
    
    % Flame Ionization Detector (8, 81)
    case {'8', '81'}
        
        % Sample Info
        options.offset.sample = 24;
       
        % Method Info
        options.offset.method = 228;
        options.offset.operator = 148;
        options.offset.date = 178;
        
        % Instrument Info
        options.offset.instrument = 218;
        options.offset.inlet = 208;
        options.offset.units = 580;
        
        % Data
        options.offset.data = 6144;
        
        [data, options] = FileInfo(file, data, options);
        [data, options] = ImportFID1(file, data, options);
        
    % Flame Ionization Detector (181)
    case {'181'}
        
        % Sample Info
        options.offset.sample = 858;
 
        % Method Info
        options.offset.method = 2574;
        options.offset.operator = 1880;
        options.offset.date = 2391; 
        
        % Instrument Info
        options.offset.instrument = 2533;
        options.offset.inlet = 2492;
        options.offset.units = 4172;
        
        % Data
        options.offset.data = 6144;       

        [data, options] = FileInfo(file, data, options);
        [data, options] = ImportFID2(file, data, options);
end

% Close file
fclose(file);

% Output
varargout{1} = data;
varargout{2} = options;

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check number of inputs
if nargin < 1 || ~ischar(varargin{1})
    error('Undefined input arguments of type ''file''.');
elseif ischar(varargin{1})
    file = varargin{1};
else
    varargout{2} = [];
    return
end

% Check file extension
[~, file] = fileattrib(file);

% Check file exists
if strcmpi(file, 'No such file or directory.')
    error('Undefined input arguments of type ''file''.');
end

[~, ~, extension] = fileparts(file.Name);

% Read Agilent '.D' files
if strcmpi(extension, '.D')
    
    % Set path
    path(file.Name, path);
    
    % Determine OS and parse file names
    if ispc
        contents = cellstr(ls(file.Name));
        contents(strcmp(contents, '.') | strcmp(contents, '..')) = [];
    elseif isunix
        contents = strsplit(ls(file.Name))';
        contents(cellfun(@isempty, contents)) = [];
    end
    
    % Parse folder contents
    files(:,1) = fullfile(file.Name, contents);
    [~, ~, files(:,2)] = cellfun(@fileparts, contents, 'uniformoutput', false);
    
else
    files{1,1} = file.Name;
    files{1,2} = extension;
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

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

varargout{1} = files;
varargout{2} = options;
end