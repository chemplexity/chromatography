% ---------------------------------------
% Unit Tests
% ---------------------------------------
srcPath = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(srcPath));

results = testHelp();
results = [results; testImport()];