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

% WARNING: UNFINISHED METHOD 
disp('UNFINISHED METHOD: CANNOT PROCEED')
varargout{1} = [];
return

warning off all

% Check input
[file, data, options] = parse(varargin);

% Check file name
if isempty(file)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Open document
document = xmlread(file);

% Read document elements
file.mzxml = document.getDocumentElement;

% Header fields
[file] = FileHeader(file);

if isempty(file.version)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Information fields
[file, data] = FileInfo(file, data);
[file, data] = InstrumentInfo(file, data);
[file, data] = ProcessingInfo(file, data);

varargout{1} = data;
end


%
% File Header
%
function [file, options] = FileHeader(file, options)

% Base URL
url = 'http://sashimi.sourceforge.net/schema_revision/mzXML_';

% mzXML Version
switch char(file.mzxml.getAttribute('xmlns'))
    
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

% Read mandatory fields
file.msRun = file.mzxml.getElementsByTagName('msRun').item(0);
file.index = file.mzxml.getElementsByTagName('index').item(0);
file.indexOffset = file.mzxml.getElementsByTagName('indexOffset').item(0);
file.sha1 = file.mzxml.getElementsByTagName('sha1').item(0);
end


%
% File Information
% 
function [file, data] = FileInfo(file, data)

% /msRun/parentFile
parentFile = file.msRun.getElementsByTagName('parentFile');

if parentFile.getLength > 0
    file.parentFile = parentFile.item(0);
else
    return
end

% /msRun/parentFile/fileName
data.file.name = char(file.parentFile.getAttribute('fileName'));

% /msRun/parentFile/fileType
data.file.type = char(file.parentFile.getAttribute('fileType'));
end


%
% Instrument Information
%
function [file, data] = InstrumentInfo(file, data)

% /msRun/msInstrument
msInstrument = file.msRun.getElementsByTagName('msInstrument');

if msInstrument.getLength > 0
    file.msInstrument = msInstrument.item(0);
else
    return
end

% /msRun/msInstrument/msManufacturer
msManufacturer = file.msInstrument.getElementsByTagName('msManufacturer');

if msManufacturer.getLength > 0
    file.msManufacturer = msManufacturer.item(0);
    data.instrument.vendor = char(file.msManufacturer.getAttribute('value'));
end

% /msRun/msInstrument/msModel
msModel = file.msInstrument.getElementsByTagName('msModel');

if msModel.getLength > 0
    file.msModel = msModel.item(0);
    data.instrument.model = char(file.msModel.getAttribute('value'));
end

% /msRun/msInstrument/msIonisation
msIonisation = file.msInstrument.getElementsByTagName('msIonisation');

if msIonisation.getLength > 0
    file.msIonisation = msIonisation.item(0);
    data.instrument.ionisation = char(file.msIonisation.getAttribute('value'));
end

% /msRun/msInstrument/msMassAnalyzer
msMassAnalyzer = file.msInstrument.getElementsByTagName('msMassAnalyzer');

if msMassAnalyzer.getLength > 0
    file.msMassAnalyzer = msMassAnalyzer.item(0);
    data.instrument.analyzer = char(file.msMassAnalyzer.getAttribute('value'));
end

% /msRun/msInstrument/msDetector
msDetector = file.msInstrument.getElementsByTagName('msDetector');

if msMassAnalyzer.getLength > 0
    file.msDetector = msDetector.item(0);
    data.instrument.detector = char(file.msDetector.getAttribute('value'));
end

% /msRun/msInstrument/msResolution
msResolution = file.msInstrument.getElementsByTagName('msResolution');

if msResolution.getLength > 0
    file.msResolution = msResolution.item(0);
    data.instrument.resolution = char(file.msResolution.getAttribute('value'));
end

% /msRun/msInstrument/software
software = file.msInstrument.getElementsByTagName('software');
software_version = file.msInstrument.getElementsByTagName('software');

if software.getLength > 0
    file.software = software.item(0);
    data.instrument.software = char(file.software.getAttribute('name'));
end    

if software_version.getLength > 0
    file.software_version = software_version.item(0);
    data.instrument.software_version = char(file.software_version.getAttribute('version'));
end
end


%
% Data Processing Information
%
function [file, data] = ProcessingInfo(file, data)

% /msRun/dataProcessing
dataProcessing = file.msRun.getElementsByTagName('dataProcessing');

if dataProcessing.getLength > 0
    file.dataProcessing = dataProcessing.item(0);
else
    return
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