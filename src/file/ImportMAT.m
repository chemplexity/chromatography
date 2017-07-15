function [data, fileName] = ImportMAT(varargin)
% ------------------------------------------------------------------------
% Method      : ImportMAT
% Description : Load MATLAB data files (.MAT)
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportMAT(data)
%   data = ImportMAT( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'file' -- name of file
%       empty (default) | char | cell array of strings

% ---------------------------------------
% Defaults
% ---------------------------------------
fileName = [];
data = [];

default.path = [];

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addParameter(p, 'file', fileName);
addParameter(p, 'path', default.path);

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
fileName = p.Results.file;
filePath = p.Results.path;

userPath = pwd;

% ---------------------------------------
% Validate
% ---------------------------------------
if ~isempty(filePath) && ischar(filePath)
    try
        cd(filePath)
    catch
    end
end

if ischar(fileName)
    
    [isFile, fileInfo] = fileattrib(fileName);
    
    if isFile && isstruct(fileInfo) && isfield(fileInfo, 'Name')
        fileName = fileInfo.Name;
    else
        fileName = [];
    end

else
    
    [fileName, filePath] = uigetfile('*.mat', 'Open');
    
    if ischar(fileName) && ischar(filePath)
        fileName = [filePath, fileName];
    else
        fileName = [];
    end
        
end

% ---------------------------------------
% Load
% ---------------------------------------
if ~isempty(fileName)
    data = load(fileName);
end

cd(userPath);

end
