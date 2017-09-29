function results = testHelp()

% ---------------------------------------
% Variables
% ---------------------------------------
results.name = 'help';
results.pass = 0;
results.fail = 0;

% ---------------------------------------
% Classes
% ---------------------------------------
classHelp = {...
    'Chromatography',...
    'Chromatography.import',...
    'Chromatography.baseline',...
    'Chromatography.smooth',...
    'Chromatography.centroid',...
    'Chromatography.integrate',...
    'Chromatography.visualize'
};

% ---------------------------------------
% Functions
% ---------------------------------------
fileHelp = {...
    'ImportAgilent',...
    'ImportCDF',...
    'ImportMZXML',...
    'ImportNIST',...
    'ImportThermo',...
    'ImportMAT',...
    'ExportCSV',...
    'ExportMAT'...
};

preprocessingHelp = {...
    'Align',...
    'Baseline',...
    'Centroid',...
    'Derivative',...
    'Filter',...
    'Normalize',...
    'Smooth'...
};

integrationHelp = {...
    'ExponentialGaussian',...
    'PeakDetection'...
};
    
visualizationHelp = {...
    'MassSpectra'...
};

utilityHelp = {...
    'MD5'...
};

% ---------------------------------------
% Intro
% ---------------------------------------
fprintf(['\n', repmat('-',1,50), '\n']);
fprintf('Help Functions');
fprintf(['\n', repmat('-',1,50), '\n\n']);

% ---------------------------------------
% Classes
% ---------------------------------------
fprintf(['Class: Chromatography', '\n']);
results = runTest(classHelp, results);

% ---------------------------------------
% Functions
% ---------------------------------------
fprintf(['\n', 'Functions: File I/O', '\n']);
results = runTest(fileHelp, results);

fprintf(['\n', 'Functions: Preprocessing', '\n']);
results = runTest(preprocessingHelp, results);

fprintf(['\n', 'Functions: Integration', '\n']);
results = runTest(integrationHelp, results);

fprintf(['\n', 'Functions: Visualization', '\n']);
results = runTest(visualizationHelp, results);

fprintf(['\n', 'Functions: Utility', '\n']);
results = runTest(utilityHelp, results);

% ---------------------------------------
% Summary
% ---------------------------------------
fprintf(['\n', '--------------', '\n']);
fprintf(['  <strong>PASS</strong> = ', num2str(results.pass), '\n']);
fprintf(2,'  FAIL ');
fprintf(['= ', num2str(results.fail)]);
fprintf(['\n', '--------------', '\n\n']);

end

function results = runTest(x, results)

% ---------------------------------------
% Test
% ---------------------------------------
msg = cellfun(@help, x, 'uniformoutput', 0);

for i = 1:length(msg)
    
    if isempty(msg{i})
        fprintf(2,'  FAIL  ');
        fprintf(['help(''', x{i}, ''')', '\n']);
    else
        fprintf('  <strong>PASS</strong>  ');
        fprintf(['help(''', x{i}, ''')', '\n']);
    end
    
end

% ---------------------------------------
% Results
% ---------------------------------------
results.pass = results.pass + length(x) - sum(cellfun(@isempty, msg));
results.fail = results.fail + sum(cellfun(@isempty, msg));

end