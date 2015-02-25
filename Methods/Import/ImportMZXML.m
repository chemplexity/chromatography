% Method: ImportMZXML
%  -Extract raw data from mzXML (.mzXML) files
%
% Syntax
%   data = ImportMZXML(file)
%   data = ImportMZXML(file, 'OptionName', optionvalue)
%
% Input
%   file        : string
%
% Options
%   'precision' : integer
%
% Description
%   file        : file name with valid extension (.mzXML)
%   'precision' : number of decimal places allowed for m/z values (default = 3)
%
% Examples
%   data = ImportMZXML('31a-051c.mzXML')
%   data = ImportMZXML('43f-trial1.mzxml', 'precision', 2)

function varargout = ImportMZXML(varargin)

warning off all

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
[~, data] = ReadTIC(file, data);

varargout{1} = data;
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
    data.file.name = value(parentFile, 'fileName', 0);

    % /msRun/parentFile/fileType
    data.file.type = value(parentFile, 'fileType', 0);

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
        data.instrument.vendor = value(msManufacturer, 'value', 0);
    end
    
    % /msRun/msInstrument/msModel
    msModel = key(msInstrument, 'msModel', 0);
    
    if msModel.getLength > 0
        data.instrument.model = value(msModel, 'value', 0);
    end
    
    % /msRun/msInstrument/msIonisation
    msIonisation = key(msInstrument, 'msIonisation', 0);
    
    if msIonisation.getLength > 0
        data.instrument.ionisation = value(msIonisation, 'value', 0);
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
        data.instrument.software = value(software, 'name', 0);
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
    cutoff = value(dataProcessing, 'intensityCutoff', 0);
    
    if ~isempty(cutoff)
        data.processing.cutoff = cutoff;
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
        data.processing.charge_deconvoluted = chargeDeconvoluted;
    end
    
    % /msRun/dataProcessing/spotIntegration
    spotIntegration = value(dataProcessing, 'spotIntegration', 0);
    
    if ~isempty(spotIntegration)
        data.processing.spot_integration = spotIntegration;
    end
    
    % /msRun/dataProcessing/software
    software = key(dataProcessing, 'software', 0);
    
    if software.getLength > 0
        data.processing.type = value(software, 'type', 0);
        data.processing.name = value(software, 'name', 0);
        data.processing.version = value(software, 'version', 0);
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
    disp(['Reading ', file.scan.getLength, ' scans']);
    
    % Index scans
    for i = 1:file.scan.getLength
        
        % /msRun/scan/num
        data.index(i).scan = str2double(value(file.scan, 'num', i-1));
        
        % /msRun/scan/msLevel
        data.index(i).level = str2double(value(file.scan, 'msLevel', i-1));
        
        % /msRun/scan/peaksCount
        data.index(i).peaks = str2double(value(file.scan, 'peaksCount', i-1));
    end
end
end


%
% Total Intensity Values
%
function [file, data] = ReadTIC(file, data)

% Anonymous functions
value = file.value;

% Pre-allocate memory
data.time{file.scan.getLength} = [];
data.tic{file.scan.getLength} = [];

if file.scan.getLength > 0

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