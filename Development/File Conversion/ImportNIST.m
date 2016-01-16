% ------------------------------------------------------------------------
% Method      : ImportNIST [EXPERIMENTAL]
% Description : Import mass spectrometry data from NIST (*.msp) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportNIST()
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportNIST()
%

function data = ImportNIST(varargin)

% ---------------------------------------
% Variables
% ---------------------------------------
parse = @(f,x) regexp(f, ['(?:', x, '[:]\s*)(\S[ ]|\S+)+(?:(\r|[;]))'], 'tokens', 'once');
data = [];

% ---------------------------------------
% File selection
% ---------------------------------------
filelist = FileUI();

% ---------------------------------------
% Parse files
% ---------------------------------------
for i = 1:length(filelist)
    
    MSP.Path =      filelist(i).Name;
    [~, MSP.File] = fileparts(filelist(i).Name);
    
    disp([num2str(i),'/',num2str(length(filelist)), ' | ', MSP.File]);
    
    f = fileread(filelist(i).Name);

    MSP.Name =      parse(f,'Name');
    MSP.Formula =   parse(f,'Formula');
    MSP.MW =        parse(f,'MW');
    MSP.CAS =       parse(f,'CAS[#]');
    MSP.NIST =      parse(f,'NIST[#]');
    MSP.DB =        parse(f,'DB[#]');
    MSP.Comments =  parse(f,'Comments');
    MSP.Peaks =     parse(f,'Peaks');
    
    MSP.fields = fields(MSP);
    
    for j = 1:length(MSP.fields)
        
        if isempty(MSP.(MSP.fields{j}))
            continue
        end
        
        if iscell(MSP.(MSP.fields{j}))
            MSP.(MSP.fields{j}) = MSP.(MSP.fields{j}){1};
        end
        
    end
    
    % Column 1: mz; Column 2: intensity
    MSP.Data = regexp(f, '(\d+ \d+)', 'match');
    MSP.Data = cellfun(@(x) strsplit(x,' '), MSP.Data, 'uniformoutput', 0);
    MSP.Data = reshape(str2double([MSP.Data{:}]), 2, [])';
    
    data = [data; MSP];
    
    clear MSP
end

data = rmfield(data, {'fields'});

end

% ---------------------------------------
% File UI
% ---------------------------------------
function filelist = FileUI()

    filelist = [];
    
    % ---------------------------------------
    % JFileChooser (Java)
    % ---------------------------------------
    fc = javax.swing.JFileChooser(java.io.File(pwd));
    
    % Selection options
    fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
    fc.setMultiSelectionEnabled(true);
    fc.setFileFilter(com.mathworks.hg.util.dFilter);
    
    % Filter options
    fc.getFileFilter.setDescription('NIST (*.MSP)');
    fc.getFileFilter.addExtension('msp');
    
    % ---------------------------------------
    % Initialize UI
    % ---------------------------------------
    status = fc.showOpenDialog(fc);
    
    if status == fc.APPROVE_OPTION
        
        % Get file selection
        fs = fc.getSelectedFiles();
        
        for i = 1:size(fs, 1)
        
            % Get file information
            [~, fattrib] = fileattrib(char(fs(i).getAbsolutePath));
            
            % Append to file list
            if isstruct(fattrib)
                filelist = [filelist; fattrib];
            end
        end
    end
end
