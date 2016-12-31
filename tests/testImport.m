function results = testImport()

% ---------------------------------------
% Variables
% ---------------------------------------
results.name = 'import';
results.pass = 0;
results.fail = 0;

srcPath  = fileparts(fileparts(mfilename('fullpath')));
dataPath = [srcPath, filesep, 'examples', filesep, 'data'];

% ---------------------------------------
% Files
% ---------------------------------------
agilentPath = [dataPath, filesep, 'agilent'];

agilentData = {...
    '002-GC-MS.D',...
    '002-LC-MS.D',...
    '008-GC-FID.D',...
    '081-GC-FID.D',...
    '179-GC-FID.D',...
    '181-GC-FID.D',...
    '030-LC-DAD.D',...
    '031-LC-DAD.D',...
    '130-LC-DAD.D',...
    '131-LC-DAD.D',...
    '030-LC-FLD.D',....
    '130-LC-FLD.D',...
    '030-LC-ADC.D',...
    '030-LC-RID.D',...
    '030-LC-VWD.D',...
    '130-LC-ELSD.D'...
};

% ---------------------------------------
% Intro
% ---------------------------------------
fprintf(['\n', repmat('-',1,50), '\n']);
fprintf('Import Functions');
fprintf(['\n', repmat('-',1,50), '\n']);

% ---------------------------------------
% Functions
% ---------------------------------------
fprintf(['\n', 'Function: ImportAgilent', '\n']);
results = testAgilentData(agilentData, agilentPath, results);

% ---------------------------------------
% Summary
% ---------------------------------------
fprintf(['\n', '--------------', '\n']);
fprintf(['  <strong>PASS</strong> = ', num2str(results.pass), '\n']);
fprintf(2,'  FAIL ');
fprintf(['= ', num2str(results.fail)]);
fprintf(['\n', '--------------', '\n\n']);

end

function results = testAgilentData(filename, filepath, results)

% ---------------------------------------
% Test
% ---------------------------------------
for i = 1:length(filename)
    
    file = [filepath, filesep, filename{i}];
    data = ImportAgilent('file', {file}, 'verbose', 'off');
    
    filecode = filename{i}(1:3);
    filetype = [filename{i}(5:6), '/', filename{i}(8:end-2)];
    
    if ~isempty(data.time) && ~isempty(data.intensity)
        fprintf('  <strong>PASS</strong>  ');
        fprintf([filecode, ' ', filetype, '\n']);
        results.pass = results.pass + 1;
    else
        fprintf(2,'  FAIL  ');
        fprintf([filecode, ' ', filetype, '\n']);
        results.fail = results.fail + 1;
    end
    
end

end