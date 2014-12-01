% Method: ImportThermo
%  -Extract LC/MS data from Thermo (.RAW) files
%
% Syntax:
%   data = ImportThermo(file)
%
% Description:
%   file: name of data file with valid extension (.RAW)
%
% Examples:
%   data = ImportThermo('MyData.RAW')

file = 'Alkenone.RAW';

% Open file
file = fopen(file);

% Read signature
fseek(file, 2, 'bof');
data.signature = deblank(transpose(fread(file, 9, 'uint16=>char', 0, 'l')));

% Read version
fseek(file, 36, 'bof');
data.version = fread(file, 1, 'ulong', 0, 'l');

% Read tag
fseek(file, 328, 'bof');
data.tag = deblank(transpose(fread(file, 514, 'uint16=>char', 0, 'l')));

% Read version
fseek(file, 1702, 'bof');
data.scan = fread(file, 100, 'uint32', 0, 'l');
