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
varargout{1} = [];
return

% Check input
[file, data, options] = parse(varargin);

% Check file name
if isempty(file)
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Open file
file = xmlread(file);

% Read document elements
mzxml = file.getDocumentElement;

% Read primary data
file.msRun = mzxml.getElementsByTagName('msRun');

% Check primary data
if file.msRun.getLength > 0
    file.msRun = msRun.item(0);
else
    varargout{1} = [];
    disp('Error: Input file invalid.');
    return
end

% Read data
[file, data] = FileInfo(file, data);
[file, data] = InstrumentInfo(file, data);
[file, data] = ProcessingInfo(file, data);
end

function [file, data] = FileInfo(file, data)

% Read file information
file.parentFile = file.msRun.getElementsByTagName('parentFile').item(0);

end


function [file, data] = InstrumentInfo(file, data)

% Read instrument information
file.msInstrument = msRun.getElementsByTagName('msInstrument').item(0);

end


function [file, data] = ProcessingInfo(file, data)

% Read data processing information
file.dataProcessing = msRun.getElementsByTagName('parentFile').item(0);

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