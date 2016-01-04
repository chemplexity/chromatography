% ------------------------------------------------------------------------
% Method      : ImportMZXML [EXPERIMENTAL]
% Description : Import data stored in mzXML (.MZXML) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportMZXML(file)
%   data = ImportMZXML(file, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   file (required)
%       Description : name of mzXML file
%       Type        : string
%
%   'precision' (optional)
%       Description : maximum decimal places for m/z values
%       Type        : number
%       Default     : 3
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportMZXML('31a-051c.mzXML')
%   data = ImportMZXML('43f-trial1.mzxml', 'precision', 4)
%
% ------------------------------------------------------------------------
% Issues
% ------------------------------------------------------------------------
%   1) Large files > 200 MB
%   2) Files with 'zlib' compression
%

function varargout = ImportMZXML(varargin)

% Check input
[mzxml, data] = parse(varargin);

% Check file name
if isempty(mzxml)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Anonymous functions
file.key = @(x,y,i) x.item(i).getElementsByTagName(y);
file.value = @(x,y,i) char(x.item(i).getAttribute(y));

file.element = @(x,y) x.getElementsByTagName(y);
file.attribute = @(x,y) char(x.getAttribute(y));

file.read = @(x,i) x.item(i).getTextContent;

% Open document
document = xmlread(mzxml);

% Read document elements
file.mzxml = document.getDocumentElement;

% Header fields
[file] = FileHeader(file);

if isempty(file.version)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Information
[file, data] = FileInfo(file, data);
[file, data] = InstrumentInfo(file, data);
[file, data] = ProcessingInfo(file, data);

% Indexing
[file, data] = ScanInfo(file, data);

% Data
[file, data] = ReadTIC(file, data);
[file, data] = PeakInfo(file, data);
%[file, data] = ReadXIC(file, data);

varargout{1} = data;
varargout{2} = file;
end


%
% File Header
%
function [file, options] = FileHeader(file, options)

% Base URL
url = 'http://sashimi.sourceforge.net/schema_revision/mzXML_';

% mzXML Version
switch file.attribute(file.mzxml, 'xmlns')
    
    case [url, '1.1.1']
        file.version = 1.1;
    case [url, '2.0']
        file.version = 2.0;
    case [url, '2.1']
        file.version = 2.1;
    case [url, '2.2']
        file.version = 2.2;
    case [url, '3.0']
        file.version = 3.0;
    case [url, '3.1']
        file.version = 3.1;
    case [url, '3.2']
        file.version = 3.2;
        
    otherwise
        file.version = [];
        return
end

% Read primary fields
file.msRun = file.element(file.mzxml, 'msRun');
file.index = file.element(file.mzxml, 'index');
file.indexOffset = file.element(file.mzxml, 'indexOffset');
file.sha1 = file.element(file.mzxml, 'sha1');
end


%
% File Information
%
function [file, data] = FileInfo(file, data)

% Anonymous functions
key = file.key;
value = file.value;

% /msRun/parentFile
parentFile = key(file.msRun, 'parentFile', 0);

if parentFile.getLength > 0
    
    % /msRun/parentFile/fileName
    data.file.fileName = value(parentFile, 'fileName', 0);
    
    % /msRun/parentFile/fileType
    data.file.fileType = value(parentFile, 'fileType', 0);
end
end


%
% Instrument Information
%
function [file, data] = InstrumentInfo(file, data)

% Anonymous functions
key = file.key;
value = file.value;

% /msRun/msInstrument
msInstrument = key(file.msRun, 'msInstrument', 0);

if msInstrument.getLength > 0
    
    % /msRun/msInstrument/msManufacturer
    msManufacturer = key(msInstrument, 'msManufacturer', 0);
    
    if msManufacturer.getLength > 0
        data.instrument.manufacturer = value(msManufacturer, 'value', 0);
    end
    
    % /msRun/msInstrument/msModel
    msModel = key(msInstrument, 'msModel', 0);
    
    if msModel.getLength > 0
        data.instrument.model = value(msModel, 'value', 0);
    end
    
    % /msRun/msInstrument/msIonisation
    msIonisation = key(msInstrument, 'msIonisation', 0);
    
    if msIonisation.getLength > 0
        data.instrument.ionization = value(msIonisation, 'value', 0);
    end
    
    % /msRun/msInstrument/msMassAnalyzer
    msMassAnalyzer = key(msInstrument, 'msMassAnalyzer', 0);
    
    if msMassAnalyzer.getLength > 0
        data.instrument.analyzer = value(msMassAnalyzer, 'value', 0);
    end
    
    % /msRun/msInstrument/msDetector
    msDetector = key(msInstrument, 'msDetector', 0);
    
    if msMassAnalyzer.getLength > 0
        data.instrument.detector = value(msDetector, 'value', 0);
    end
    
    % /msRun/msInstrument/msResolution
    msResolution = key(msInstrument, 'msResolution', 0);
    
    if msResolution.getLength > 0
        data.instrument.resolution = value(msResolution, 'value', 0);
    end
    
    % /msRun/msInstrument/software
    software = key(msInstrument, 'software', 0);
    
    if software.getLength > 0
        data.instrument.software_name = value(software, 'name', 0);
        data.instrument.software_version = value(software, 'version', 0);
    end
    
    % /msRun/msInstrument/operator
    operator = key(msInstrument, 'operator', 0);
    
    if operator.getLength > 0
        %data.instrument.operator_first = value(operator, 'first', 0);
        data.instrument.operator_last = value(operator, 'last', 0);
        %data.instrument.operator_phone = value(operator, 'phone', 0);
        %data.instrument.operator_email = value(operator, 'email', 0);
        %data.instrument.operator_URI = value(operator, 'URI', 0);
    end
end
end


%
% Data Processing Information
%
function [file, data] = ProcessingInfo(file, data)

% Anonymous functions
key = file.key;
value = file.value;

% /msRun/dataProcessing
dataProcessing = key(file.msRun, 'dataProcessing', 0);

if dataProcessing.getLength > 0
    
    % /msRun/dataProcessing/intensityCutoff
    intensityCutoff = value(dataProcessing, 'intensityCutoff', 0);
    
    if ~isempty(intensityCutoff)
        data.processing.intensityCutoff = intensityCutoff;
    end
    
    % /msRun/dataProcessing/centroided
    centroided = value(dataProcessing, 'centroided', 0);
    
    if ~isempty(centroided)
        data.processing.centroided = centroided;
    end
    
    % /msRun/dataProcessing/deisotoped
    deisotoped = value(dataProcessing, 'deisotoped', 0);
    
    if ~isempty(deisotoped)
        data.processing.deisotoped = deisotoped;
    end
    
    % /msRun/dataProcessing/chargeDeconvoluted
    chargeDeconvoluted = value(dataProcessing, 'chargeDeconvoluted', 0);
    
    if ~isempty(chargeDeconvoluted)
        data.processing.chargeDeconvoluted = chargeDeconvoluted;
    end
    
    % /msRun/dataProcessing/spotIntegration
    spotIntegration = value(dataProcessing, 'spotIntegration', 0);
    
    if ~isempty(spotIntegration)
        data.processing.spotIntegration = spotIntegration;
    end
    
    % /msRun/dataProcessing/software
    software = key(dataProcessing, 'software', 0);
    
    if software.getLength > 0
        data.processing.software_type = value(software, 'type', 0);
        data.processing.software_name = value(software, 'name', 0);
        data.processing.software_version = value(software, 'version', 0);
    end
end
end


%
% Scan Information
%
function [file, data] = ScanInfo(file, data)

% Anonymous functions
value = file.value;
element = file.element;

% /msRun/scan
file.scan = element(file.mzxml, 'scan');

if file.scan.getLength > 0
    
    % Display number of scans
    disp(['Indexing ', num2str(file.scan.getLength), ' scans...']);
    tic;
    
    % Index scans
    for i = 1:file.scan.getLength
        data.index(i).id = i-1;
        
        % /msRun/scan/num
        data.index(i).num = str2double(value(file.scan, 'num', i-1));
        
        % /msRun/scan/msLevel
        data.index(i).msLevel = str2double(value(file.scan, 'msLevel', i-1));
        
        % /msRun/scan/peaksCount
        data.index(i).peaksCount = str2double(value(file.scan, 'peaksCount', i-1));
    end
    
    % Display number of scans
    disp(['Indexing complete... (', num2str(toc, '% 10.2f'), ' sec)']);
end
end


%
% Total Ion Chromatograms (TIC)
%
function [file, data] = ReadTIC(file, data)

% Anonymous functions
value = file.value;

% Pre-allocate memory
data.time{file.scan.getLength} = [];
data.tic{file.scan.getLength} = [];

if file.scan.getLength > 0
    
    % Display progress
    disp(['Importing ', num2str(file.scan.getLength), ' total intensity values...']);
    tic;
    
    % Read time, total intensity values
    for i = 1:file.scan.getLength
        
        % /msRun/scan/retentionTime
        data.time{i} = value(file.scan, 'retentionTime', i-1);
        
        % /msRun/scan/totIonCurrent
        data.tic{i} = value(file.scan, 'totIonCurrent', i-1);
    end
    
    % Parse time values
    expression = '[0-9].+[0-9]';
    units = data.time{1}(end);
    
    % Convert time values to doubles
    data.time = cellfun(@(x) str2double(regexp(x, expression, 'match')), data.time)';
    
    % Convert time values to minutes
    if strcmpi(units, 's')
        data.time = data.time / 60;
    elseif strcmpi(units, 'h')
        data.time = data.time * 60;
    end
    
    % Convert total intensity values to doubles
    data.tic = cellfun(@(x) str2double(x), data.tic)';
    
    % Replace NaN values with 0
    data.time(isnan(data.time)) = 0;
    data.tic(isnan(data.tic)) = 0;
    
    % Display progress
    disp(['Import complete... (', num2str(toc, '% 10.2f'), ' sec)']);
end
end


%
% Peak Information
%
function [file, data] = PeakInfo(file, data)

% Anonymous functions
value = file.value;
element = file.element;

% /msRun/peaks
file.peaks = element(file.mzxml, 'peaks');

if file.peaks.getLength > 0
    
    % Display progress
    disp(['Indexing ', num2str(sum([data.index.peaksCount])), ' peaks...']);
    tic;
    
    for i = 1:length(data.index)
        
        % /msRun/peaks/precision
        precision = value(file.peaks, 'precision', i-1);
        
        if ~isempty(precision) && strcmpi(precision, '32')
            data.peaks(i).precision = 'single';
        elseif ~isempty(precision) && strcmpi(precision, '64')
            data.peaks(i).precision = 'double';
        end
        
        % /msRun/peaks/byteOrder
        byteOrder = value(file.peaks, 'byteOrder', i-1);
        
        if ~isempty(byteOrder)
            data.peaks(i).byteOrder = byteOrder;
        end
        
        % /msRun/peaks/contentType
        contentType = value(file.peaks, 'contentType', i-1);
        
        if ~isempty(contentType)
            data.peaks(i).contentType = contentType;
        end
        
        % /msRun/peaks/compressionType
        compressionType = value(file.peaks, 'compressionType', i-1);
        
        if ~isempty(compressionType)
            data.peaks(i).compressionType = compressionType;
        end
        
        % /msRun/peaks/compressedLen
        compressedLen = value(file.peaks, 'compressedLen', i-1);
        
        if ~isempty(compressedLen)
            data.peaks(i).compressedLen = str2double(compressedLen);
        end
    end
    
    % Display progress
    disp(['Indexing complete... (', num2str(toc, '% 10.2f'), ' sec)']);
end
end


%
% Extracted Ion Chromatograms (XIC, MS1)
%
function [file, data] = ReadXIC(file, data)

% Anonymous functions
read = file.read;

% Read MS1 scans locations
id = [data.index.id];
index = id([data.index.msLevel] == 1);

% Read MS1 data
if ~isempty(index)
    
    % Display progress
    disp(['Importing ', num2str(length(index)), ' scans of intensity values...']);
    tic;
    
    for i = 1:length(index)
        
        % Check for peaks
        if data.index(i).peaksCount ~= 0
            
            % /msRun/peaks/
            peaks{i} = read(file.peaks, index(i));
        end
    end
    
    % Display progress
    disp(['Import complete... (', num2str(toc, '% 10.2f'), ' sec)']);
    
    % Display progress
    disp('Decoding values...');
    tic;
    
    % Decode peak values
    data = Decoder(data, peaks, index, 1);
    
    % Display progress
    disp(['Decoding complete... (', num2str(toc, '% 10.2f'), ' sec)']);
end
end


%
% Base64 Decoder
%
function data = Decoder(data, peaks, index, level)

% Check endianness
[~, ~, endian] = computer;

% Decoder functions
base64 = org.apache.commons.codec.binary.Base64( );

if strcmpi(endian, 'l')
    decoder = @(x,n) swapbytes(typecast(x,n));
else
    decoder = @(x,n) typecast(x,n);
end

% Find empty values
filter = cellfun(@isempty, peaks);
index(filter) = [];
peaks(filter) = [];

% Inialize variables
mz{length(peaks)} = [];
xic{length(peaks)} = [];

% Parse peak data
expression = '([A-Za-z0-9/\+=])*';
peaks = cellfun(@(x) regexp(char(x), expression, 'match'), peaks);

% Convert to bytes
peaks = cellfun(@(x) uint8(x), peaks, 'uniformoutput', false);

% Check compression type
if ~isfield(data.index, 'compressionType') || ~strcmpi(data.index(1).compressionType, 'zlib')
    
    for i = 1:length(peaks)
        
        % Decode Base64
        peaks{i} = base64.decode(peaks{i});
        
        % Convert to 32 or 64 bit values
        precision = data.peaks(index(i)).precision;
        
        if any(strcmpi(precision, {'single', 'double'}))
            peaks{i} = decoder(peaks{i}, precision);
        else
            peaks{i} = decoder(peaks{i}, 'single');
        end
        
        % Check data format
        if ~isfield(data.index, 'contentType')
            contentType = 'm/z-int';
        else
            contentType = data.index(index(i)).contentType;
        end
        
        % Parse data
        switch contentType
            
            case 'm/z-int'
                mz{i} = peaks{i}(1:2:end-1);
                xic{i} = peaks{i}(2:2:end);
                
            case {'m/z', 'm/z ruler'}
                mz{i} = peaks{i};
                xic{i} = [];
                
            case {'intensity', 'TOF', 'S/N', 'charge'}
                mz{i} = [];
                xic{i} = peaks{i};
                
            otherwise
                mz{i} = peaks{i}(1:2:end-1);
                xic{i} = peaks{i}(2:2:end);
        end
    end
    
    % Reshape data
    if ~isempty(xic) && ~isempty(mz)
        
        % Index scan size
        index.end = cumsum(cellfun(@length, xic)');
        index.start = circshift(index.end,[1,0]);
        index.start = index.start + 1;
        index.start(1,1) = 1;
        
        % Pre-allocate memory
        data.mz = zeros(max(index.end), length(mz));
        data.xic = zeros(max(index.end), length(xic));
        
        % Expand cells
        for i = 1:length(mz)
            
            % Remove zeros from m/z values
            filter = mz{i} == 0;
            mz{i}(filter) = [];
            xic{i}(filter) = [];
            
            % Expand cell in column
            data.mz(1:length(mz{i}),i) = mz{i};
            data.xic(1:length(xic{i}),i) = xic{i};
        end
        
        % Reshape values
        data.mz = reshape(data.mz, 1, []);
        data.xic = reshape(data.xic, 1, []);
        
        % Remove zeros
        filter = data.mz == 0;
        data.mz(filter) = [];
        data.xic(filter) = [];
        
        % Clear xic from memory
        clear xic;
        
        % Non-zero elements
        points = length(data.mz);
        
        % Determine precision of mass values
        z = round(data.mz .* (10^3)) ./ (10^3);
        data.mz = unique(z, 'sorted');
        
        % Determine column index for reshaping
        [~, column_index] = ismember(z, data.mz);
        
        % Clear m/z from memory
        clear z
        
        % Pre-allocate memory
        if length(index.end) * length(data.mz) > 6.25E6
            xic = spalloc(length(index.end), length(data.mz), points);
        else
            xic = zeros(length(index.end), length(data.mz));
        end
        
        for i = 1:length(index.start)
            
            % Variables
            m = index.start(i);
            n = index.end(i);
            
            % Reshape instensity values
            xic(i, column_index(m:n)) = data.xic(m:n);
        end
        
        % Format output
        data.xic = xic;
        data.xic(:,data.mz == 0) = [];
        data.mz(:,data.mz == 0) = [];
    end
    
    % Assign outputs
    switch level
        
        case 1
            data.xic = xic;
            data.mz = mz;
            
        case 2
            data.ms2.xic = xic;
            data.ms2.mz = mz;
    end
end
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
[~, ~, extension] = fileparts(file);

if ~strcmpi(extension, '.mzxml')
    varargout{2} = [];
    return
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

varargout{1} = file;
varargout{2} = [];
varargout{3} = options;
end