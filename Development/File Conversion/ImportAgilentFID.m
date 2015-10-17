% Method      : ImportAgilentFID (EXPERIMENTAL)
% Description : Read Agilent data files (.D, .CH)
%
% Syntax
%   data = ImportAgilent()
%   data = ImportAgilent(files)
%
% Examples
%   Options: GUI, Files, Folders, Files/Folders
%
%   1) UI
%       data = ImportAgilent()
%
%   2) Files
%       data = ImportAgilent('002B0201.D')
%       data = ImportAgilent('/Users/Admin/Data/084B051.D')
%       data = ImportAgilent('C:\Users\Admin\Data\FID2B.CH')
%       data = ImportAgilent('005-0101.D', 'DAD1A.CH', 'FID1A.CH')
%
%   3) Folders
%       data = ImportAgilent('/Users/Admin/Data/20150101_SEQUENCE/')
%       data = ImportAgilent('C:\Users\Admin\Data\2015_OCT_SAMPLES\')
%       data = ImportAgilent('TRIAL1_SEQ', 'TRIAL2_SEQ')
%
%   4) Files/Folders
%       data = ImportAgilent('DAD1A.CH', '/Users/Admin/Data/TRIAL1043/')
%       data = ImportAgilent('SAMPLES_100_300', '001STANDARD.D')
%

function data = ImportAgilentFID(varargin)

filename = parseInput(varargin);
filepath = getFilePath(filename);

data = getFileInfo(filepath);

end

function filename = parseInput(varargin)

filename = [];

% Input: none
if nargin-1 == 0
    
    % Initialize JFileChooser
    fc = javax.swing.JFileChooser(java.io.File(pwd));
    
    % Selection options
    fc.setFileSelectionMode(fc.FILES_AND_DIRECTORIES);
    fc.setMultiSelectionEnabled(true);
    fc.setFileFilter(com.mathworks.hg.util.dFilter);
    
    % Filter options
    fc.getFileFilter.setDescription('Agilent (*.D, *.MS, *.CH)');
    fc.getFileFilter.addExtension('d');
    fc.getFileFilter.addExtension('ms');
    fc.getFileFilter.addExtension('ch');
    
    % Open JFileChooser
    status = fc.showOpenDialog(fc);
    
    % Check selection status
    if status == fc.APPROVE_OPTION
        
        % Get file selection
        fs = fc.getSelectedFiles();
        
        % java.io.File to char
        for i = 1:size(fs, 1)
            [~, fattrib] = fileattrib(char(fs(i).getAbsolutePath));
            
            % Append file list
            if isstruct(fattrib)
                filename = [filename; fattrib];
            end
        end
    end
    
% Input: files or folders
elseif nargin-1 > 0
    
    for i = 1:length(varargin)
        
        % Check input name
        if ischar(varargin{i})
            [~, fattrib] = fileattrib(varargin{i});
            
            % Append file list
            if isstruct(fattrib)
                filename = [filename; fattrib];
            end
        end
    end
end
end
   

function filepath = getFilePath(filename)

filepath = [];

% Search function
fsearch = @(x) regexp(x, '(?i)[.](D|MS|CH)', 'match');

% Validate selection
for i = 1:length(filename)
    
    % Search directory
    if filename(i).directory
        fdir = dir(filename(i).Name);
        
        % Get file extensions
        fext = cellfun(@(x) fsearch(x), {fdir.name}, 'uniformoutput', 0);
        fdir(cellfun(@isempty, fext)) = [];
        
        for j = 1:length(fdir)
            
            % Get absolute path
            fpath = fullfile(filename(i).Name, filesep, fdir(j).name);
            
            % Case: '.D'
            if fdir(j).isdir
                
                % Search sub-directory
                fsub = dir(fpath);
                fsub([fsub.isdir]) = [];
                
                % Get file extensions
                fext = cellfun(@(x) fsearch(x), {fsub.name}, 'uniformoutput', 0);
                fsub(cellfun(@isempty, fext)) = [];
                
                for k = 1:length(fsub)
                    
                    % Get absolute path
                    fpath = fullfile(fpath, filesep, fsub(k).name);
                    [~, fa] = fileattrib(fpath);
                    
                    % Append file list
                    if isstruct(fa)
                        filepath(end+1).filepath = fa.Name;
                    end
                end
                
                % Case: '.CH', '.MS'
            elseif ~fdir(j).isdir
                [~, fa] = fileattrib(fpath);
                
                % Append file list
                if isstruct(fa)
                    filepath(end+1).filepath = fa.Name;
                end
            end
        end
        
        % Search file
    else
        fname = filename(i).Name;
        
        % Append file list
        if ~isempty(fsearch(fname))
            filepath(end+1).filepath = fname;
        end
    end
end
end


function data = getFileInfo(filepath)

data = [];
reference = AgilentFileStructure();

fpascal = @(f,type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';
fmessage = @(a,b) fprintf(['Loading file (', a, '/', b, ')\n']);

fprintf('\nInitializing file import...\n');
fprintf(['\nFiles: ', num2str(length(filepath)), '\n\n']);

for i = 1:length(filepath)
    
    fmessage(num2str(i), num2str(length(filepath)));
    data(i).filepath = filepath(i).filepath;
    
    % Get file code
    file = fopen(data(i).filepath, 'r');
    ftype = fread(file, fread(file, 1, 'uint8'), 'uint8=>char')';
    
    % Load file structure
    finfo = reference([reference.id]==str2double(ftype));
    
    % Import file info
    for j = 1:length(finfo)
        
        fseek(file, finfo(j).offset, 'bof');
        
        % integer/float
        if ~strcmpi(finfo(j).type, 'pascal') 
            data(i).(finfo(j).name) = fread(file, 1, finfo(j).type, finfo(j).endian);
        
        % pascal string (UTF-8)
        elseif str2double(ftype) < 100
            data(i).(finfo(j).name) = fpascal(file, 'uint8');
        
        % pascal string (UTF-16)
        elseif str2double(ftype) > 100
            data(i).(finfo(j).name) = fpascal(file, 'uint16');
        end
        
    end
    
    % Validate file info
    if ~isfield(data, 'Version') || isempty(data(i).Version)
        data(i).Version = 0;
    end
    
    if isfield(data, 'StartTime')
        data(i).StartTime = data(i).StartTime / 60000;
    end
    
    if isfield(data, 'EndTime')
        data(i).EndTime = data(i).EndTime / 60000;
    end
    
    if isfield(data, 'DataOffset')
        data(i).DataOffset = (data(i).DataOffset - 1) * 512;
    else
        continue
    end
    
    data(i).Time = [];
    data(i).Signal = [];
       
    % Import signal
    switch ftype
        
        % GC (UTF-8)
        case '8'
            switch data(i).Version
                case {1,2,3}
                    data(i).Intercept = 0;
                    data(i).Slope = 1.33321110047553;
            end
            
            data(i) = DeltaCompression(file, data(i));
            
        % LC (UTF-8)
        case '30'
            switch data(i).Version
                case 1
                    data(i).Intercept = 0;
                    data(i).Slope = 1;
                case 2
                    data(i).Intercept = 0;
                    data(i).Slope = 0.00240841663372301;
            end
            
            data(i) = DeltaCompression(file, data(i));
            
        % GC (UTF-8)
        case '81'
            data(i) = DoubleDeltaCompression(file, data(i));
            
        % LC (UTF-16)
        case '130'
            data(i) = DeltaCompression(file, data(i));
            
        % GC (UTF-16)
        case '179'
            data(i) = DoubleArray(file, data(i));
            
        % GC (UTF-16)
        case '181'
            data(i) = DoubleDeltaCompression(file, data(i));
            
    end
    
    % Close file
    fclose(file);
end

if isfield(data, 'Signal')
    data(cellfun(@isempty, {data.Signal})) = [];
end
end

function varargout = parsedate(input, format)

    format{1} = 'dd mmm yy HH:MM PM';
    format{2} = 'mm/dd/yy HH:MM:SS PM';
    format{3} = 'dd-mmm-yy, HH:MM:SS';

    
end

%
% Method      : DeltaCompression
% Description : Decode delta compressed signal
%
function data = DeltaCompression(file, data)

% File validation
if isnumeric(file)
    fseek(file, 0, 'eof');
    fsize = ftell(file);
else
    return
end

% Set signal zero
if isfield(data, 'Zero')
    signal = data.Zero;
else
    signal = [];
end

% Read data
fseek(file, data.DataOffset, 'bof');
buffer = zeros(1,8);

while ftell(file) < fsize
    
    buffer(1) = fread(file, 1, 'int16', 'b');
    buffer(2) = bitshift(buffer(1), 12, 'int16');
    buffer(3) = buffer(8);
    buffer(4) = bitand(buffer(1), 4095, 'int16');
    
    for i = 1:buffer(4)
        
        buffer(5) = fread(file, 1, 'int16', 'b');
        
        if buffer(5) ~= -32768
            buffer(3) = buffer(3) + buffer(5);
        else
            buffer(3) = fread(file, 1, 'int32', 'b');
        end
        
        buffer(6) = buffer(3);
        buffer(7) = buffer(6);
        buffer(8) = buffer(6);
        signal(end+1, 1) = buffer(7);
    end
end

% Adjust signal
if isfield(data, 'Slope') && isfield(data, 'Intercept')
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Calculate time values
if isfield(data, 'StartTime') && isfield(data, 'EndTime')
    data.Time = linspace(data.StartTime, data.EndTime, length(signal))';
else
    data.Time = 1:length(signal);
end
end


%
% Method      : DoubleDeltaCompression
% Description : Decode double delta compressed signal
%
function data = DoubleDeltaCompression(file, data)

% File validation
if isnumeric(file)
    fseek(file, 0, 'eof');
    fsize = ftell(file);
else
    return
end
        
% Read data
fseek(file, data.DataOffset, 'bof');

signal = zeros(fsize/2, 1);

if isfield(data, 'Zero')
    signal(1) = data.Zero;
end

count = 1;
buffer = zeros(1,3);

while ftell(file) < fsize
    
    buffer(3) = fread(file, 1, 'int16', 'b');
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(file, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(file, 1, 'int32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    signal(count, 1) = buffer(1);
    count = count + 1;
end

signal(count+1:end,:) = [];

% Adjust signal
if isfield(data, 'Slope') && isfield(data, 'Intercept')
    data.Signal = (signal .* data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Calculate time values
if isfield(data, 'StartTime') && isfield(data, 'EndTime')
    data.Time = linspace(data.StartTime, data.EndTime, length(signal))';
else
    data.Time = 1:length(signal);
end
end


%
% Method      : DoubleArray
% Description : Load signal from double array
%
function data = DoubleArray(file, data)

% File validation
if isnumeric(file)
    fseek(file, 0, 'eof');
    fsize = ftell(file);
else
    return
end

% Read data
fseek(file, data.DataOffset, 'bof');
data.Signal = fread(file, (fsize - data.DataOffset) / 8, 'double', 'l');

% Set signal zero
if isfield(data, 'Zero')
    data.Signal(1) = data.Zero;
end

% Calculate time values
if isfield(data, 'StartTime') && isfield(data, 'EndTime')
    data.Time = linspace(data.StartTime, data.EndTime, length(data.Signal))';
else
    data.Time = 1:length(data.Signal);
end
end


%
% Method      : AgilentFileStructure
% Description : Binary file layout
%
function varargout = AgilentFileStructure(varargin)

fields = {'id', 'offset', 'type', 'endian', 'name'};

F8 = {...
    8,    4,     'pascal',   'l',  'File';
    8,    24,    'pascal',   'l',  'SampleName';
    8,    86,    'pascal',   'l',  'Barcode';
    8,    148,   'pascal',   'l',  'Operator';
    8,    178,   'pascal',   'l',  'DateTime';
    8,    208,   'pascal',   'l',  'InstModel';
    8,    218,   'pascal',   'l',  'Inlet';
    8,    228,   'pascal',   'l',  'MethodName';
    8,    248,   'int32',    'b',  'FileType';
    8,    252,   'int16',    'b',  'SeqIndex';
    8,    254,   'int16',    'b',  'AlsBottle';
    8,    256,   'int16',    'b',  'Replicate';
    8,    258,   'int16',    'b',  'DirEntType';
    8,    260,   'int32',    'b',  'DirOffset';
    8,    264,   'int32',    'b',  'DataOffset';
    8,    268,   'int32',    'b',  'RunTableOffset';
    8,    272,   'int32',    'b',  'NormOffset';
    8,    276,   'int16',    'b',  'ExtraRecords';
    8,    278,   'int32',    'b',  'NumRecords';
    8,    282,   'int32',    'b',  'StartTime';
    8,    286,   'int32',    'b',  'EndTime';
    8,    290,   'int32',    'b',  'MaxSignal';
    8,    294,   'int32',    'b',  'MinSignal';
    8,    298,   'int32',    'b',  'MaxY';
    8,    302,   'int32',    'b',  'MinY';
    8,    314,   'int32',    'b',  'Mode';
    8,    514,   'int16',    'b',  'Detector';
    8,    516,   'int16',    'b',  'Method';
    8,    518,   'int32',    'b',  'Zero';
    8,    522,   'int32',    'b',  'Min';
    8,    526,   'int32',    'b',  'Max';
    8,    530,   'int32',    'b',  'BunchPower';
    8,    534,   'float64',  'b',  'PeakWidth';
    8,    542,   'int32',    'b',  'Version';
    8,    580,   'pascal',   'l',  'Units';
    8,    596,   'pascal',   'l',  'SigDesc';
    8,    636,   'float64',  'b',  'Intercept';
    8,    644,   'float64',  'b',  'Slope';
    8,    784,   'int16',    'b',  'SignalDataType';
    };

F30 = {...
    30,   4,     'pascal',   'l',  'File';
    30,   24,    'pascal',   'l',  'SampleName';
    30,   86,    'pascal',   'l',  'Barcode';
    30,   148,   'pascal',   'l',  'Operator';
    30,   178,   'pascal',   'l',  'DateTime';
    30,   208,   'pascal',   'l',  'InstModel';
    30,   218,   'pascal',   'l',  'Inlet';
    30,   228,   'pascal',   'l',  'MethodName';
    30,   248,   'int32',    'b',  'FileType';
    30,   252,   'int16',    'b',  'SeqIndex';
    30,   254,   'int16',    'b',  'AlsBottle';
    30,   256,   'int16',    'b',  'Replicate';
    30,   258,   'int16',    'b',  'DirEntType';
    30,   260,   'int32',    'b',  'DirOffset';
    30,   264,   'int32',    'b',  'DataOffset';
    30,   268,   'int32',    'b',  'RunTableOffset';
    30,   272,   'int32',    'b',  'NormOffset';
    30,   276,   'int16',    'b',  'ExtraRecords';
    30,   278,   'int32',    'b',  'NumRecords';
    30,   282,   'int32',    'b',  'StartTime';
    30,   286,   'int32',    'b',  'EndTime';
    30,   290,   'int32',    'b',  'MaxSignal';
    30,   294,   'int32',    'b',  'MinSignal';
    30,   298,   'int32',    'b',  'MaxY';
    30,   302,   'int32',    'b',  'MinY';
    30,   314,   'int32',    'b',  'Mode';
    30,   318,   'int32',    'b',  'GlpFlag';
    30,   322,   'pascal',   'l',  'SoftwareName';
    30,   355,   'pascal',   'l',  'FirmwareRev';
    30,   405,   'pascal',   'l',  'SoftwareRev';
    30,   514,   'int16',    'b',  'Detector';
    30,   516,   'int16',    'b',  'Method';
    30,   518,   'int32',    'b',  'Zero';
    30,   522,   'int32',    'b',  'Min';
    30,   526,   'int32',    'b',  'Max';
    30,   530,   'int32',    'b',  'BunchPower';
    30,   534,   'float64',  'b',  'PeakWidth';
    30,   542,   'int32',    'b',  'Version';
    30,   580,   'pascal',   'l',  'Units';
    30,   596,   'pascal',   'l',  'SigDesc';
    30,   636,   'float64',  'b',  'Intercept';
    30,   644,   'float64',  'b',  'Slope';
    30,   784,   'int16',    'b',  'SignalDataType';
    };

F81 = {...
    81,   4,     'pascal',   'l',  'File';
    81,   24,    'pascal',   'l',  'SampleName';
    81,   86,    'pascal',   'l',  'Barcode';
    81,   148,   'pascal',   'l',  'Operator';
    81,   178,   'pascal',   'l',  'DateTime';
    81,   208,   'pascal',   'l',  'InstModel';
    81,   218,   'pascal',   'l',  'Inlet';
    81,   228,   'pascal',   'l',  'MethodName';
    81,   248,   'int32',    'b',  'FileType';
    81,   252,   'int16',    'b',  'SeqIndex';
    81,   254,   'int16',    'b',  'AlsBottle';
    81,   256,   'int16',    'b',  'Replicate';
    81,   258,   'int16',    'b',  'DirEntType';
    81,   260,   'int32',    'b',  'DirOffset';
    81,   264,   'int32',    'b',  'DataOffset';
    81,   268,   'int32',    'b',  'RunTableOffset';
    81,   272,   'int32',    'b',  'NormOffset';
    81,   276,   'int16',    'b',  'ExtraRecords';
    81,   278,   'int32',    'b',  'NumRecords';
    81,   282,   'float32',  'b',  'StartTime';
    81,   286,   'float32',  'b',  'EndTime';
    81,   290,   'float32',  'b',  'MaxSignal';
    81,   294,   'float32',  'b',  'MinSignal';
    81,   298,   'float32',  'b',  'MaxY';
    81,   302,   'float32',  'b',  'MinY';
    81,   314,   'int32',    'b',  'Mode';
    81,   514,   'int16',    'b',  'Detector';
    81,   516,   'int16',    'b',  'Method';
    81,   518,   'float32',  'b',  'Zero';
    81,   522,   'float32',  'b',  'Min';
    81,   526,   'float32',  'b',  'Max';
    81,   530,   'int32',    'b',  'BunchPower';
    81,   534,   'float64',  'b',  'PeakWidth';
    81,   542,   'int32',    'b',  'Version';
    81,   580,   'pascal',   'l',  'Units';
    81,   596,   'pascal',   'l',  'SigDesc';
    81,   636,   'float64',  'b',  'Intercept';
    81,   644,   'float64',  'b',  'Slope';
    81,   784,   'int16',    'b',  'SignalDataType';
    };

F130 = {...
    130,  248,   'int32',    'b',  'FileType';
    130,  252,   'int16',    'b',  'SeqIndex';
    130,  254,   'int16',    'b',  'AlsBottle';
    130,  256,   'int16',    'b',  'Replicate';
    130,  258,   'int16',    'b',  'DirEntType';
    130,  260,   'int32',    'b',  'DirOffset';
    130,  264,   'int32',    'b',  'DataOffset';
    130,  268,   'int32',    'b',  'RunTableOffset';
    130,  272,   'int32',    'b',  'NormOffset';
    130,  276,   'int16',    'b',  'ExtraRecords';
    130,  278,   'int32',    'b',  'NumRecords';
    130,  282,   'int32',    'b',  'StartTime';
    130,  286,   'int32',    'b',  'EndTime';
    130,  290,   'int32',    'b',  'MaxSignal';
    130,  294,   'int32',    'b',  'MinSignal';
    130,  298,   'int32',    'b',  'MaxY';
    130,  302,   'int32',    'b',  'MinY';
    130,  314,   'int32',    'b',  'Mode';
    130,  347,   'pascal',   'l',  'File';
    130,  858,   'pascal',   'l',  'SampleName';
    130,  1369,  'pascal',   'l',  'Barcode';
    130,  1880,  'pascal',   'l',  'Operator';
    130,  2391,  'pascal',   'l',  'DateTime';
    130,  2492,  'pascal',   'l',  'InstModel';
    130,  2533,  'pascal',   'l',  'Inlet';
    130,  2574,  'pascal',   'l',  'MethodName';    
    130,  3089,  'pascal',   'l',  'SoftwareName';
    130,  3601,  'pascal',   'l',  'FirmwareRev';
    130,  3802,  'pascal',   'l',  'SoftwareRev';
    130,  4106,  'int16',    'b',  'Detector';
    130,  4108,  'int16',    'b',  'Method';
    130,  4110,  'int32',    'b',  'Zero';
    130,  4114,  'int32',    'b',  'Min';
    130,  4118,  'int32',    'b',  'Max';
    130,  4122,  'int32',    'b',  'BunchPower';
    130,  4126,  'float64',  'b',  'PeakWidth';
    130,  4134,  'int32',    'b',  'Version';
    130,  4172,  'pascal',   'l',  'Units';
    130,  4213,  'pascal',   'l',  'SigDesc';
    130,  4724,  'float64',  'b',  'Intercept';
    130,  4732,  'float64',  'b',  'Slope';
    130,  5524,  'int16',    'b',  'SignalDataType';
    };

F179 = {...
    179,  248,   'int32',    'b',  'FileType';
    179,  252,   'int16',    'b',  'SeqIndex';
    179,  254,   'int16',    'b',  'AlsBottle';
    179,  256,   'int16',    'b',  'Replicate';
    179,  258,   'int16',    'b',  'DirEntType';
    179,  260,   'int32',    'b',  'DirOffset';
    179,  264,   'int32',    'b',  'DataOffset';
    179,  268,   'int32',    'b',  'RunTableOffset';
    179,  272,   'int32',    'b',  'NormOffset';
    179,  276,   'int16',    'b',  'ExtraRecords';
    179,  278,   'int32',    'b',  'NumRecords';
    179,  282,   'float32',  'b',  'StartTime';
    179,  286,   'float32',  'b',  'EndTime';
    179,  290,   'float32',  'b',  'MaxSignal';
    179,  294,   'float32',  'b',  'MinSignal';
    179,  298,   'float32',  'b',  'MaxY';
    179,  302,   'float32',  'b',  'MinY';
    179,  314,   'int32',    'b',  'Mode';
    179,  347,   'pascal',   'l',  'File';
    179,  858,   'pascal',   'l',  'SampleName';
    179,  1369,  'pascal',   'l',  'Barcode';
    179,  1880,  'pascal',   'l',  'Operator';
    179,  2391,  'pascal',   'l',  'DateTime';
    179,  2492,  'pascal',   'l',  'InstModel';
    179,  2533,  'pascal',   'l',  'Inlet';
    179,  2574,  'pascal',   'l',  'MethodName';    
    179,  3089,  'pascal',   'l',  'SoftwareName';
    179,  3601,  'pascal',   'l',  'FirmwareRev';
    179,  3802,  'pascal',   'l',  'SoftwareRev';
    179,  4106,  'int16',    'b',  'Detector';
    179,  4108,  'int16',    'b',  'Method';
    179,  4110,  'float32',  'b',  'Zero';
    179,  4114,  'float32',  'b',  'Min';
    179,  4118,  'float32',  'b',  'Max';
    179,  4122,  'int32',    'b',  'BunchPower';
    179,  4126,  'float64',  'b',  'PeakWidth';
    179,  4134,  'int32',    'b',  'Version';
    179,  4172,  'pascal',   'l',  'Units';
    179,  4213,  'pascal',   'l',  'SigDesc';
    179,  4724,  'float64',  'b',  'Intercept';
    179,  4732,  'float64',  'b',  'Slope';
    179,  5524,  'int16',    'b',  'SignalDataType';
    };

F181 = {...
    181,  248,   'int32',    'b',  'FileType';
    181,  252,   'int16',    'b',  'SeqIndex';
    181,  254,   'int16',    'b',  'AlsBottle';
    181,  256,   'int16',    'b',  'Replicate';
    181,  258,   'int16',    'b',  'DirEntType';
    181,  260,   'int32',    'b',  'DirOffset';
    181,  264,   'int32',    'b',  'DataOffset';
    181,  268,   'int32',    'b',  'RunTableOffset';
    181,  272,   'int32',    'b',  'NormOffset';
    181,  276,   'int16',    'b',  'ExtraRecords';
    181,  278,   'int32',    'b',  'NumRecords';
    181,  282,   'float32',  'b',  'StartTime';
    181,  286,   'float32',  'b',  'EndTime';
    181,  290,   'float32',  'b',  'MaxSignal';
    181,  294,   'float32',  'b',  'MinSignal';
    181,  298,   'float32',  'b',  'MaxY';
    181,  302,   'float32',  'b',  'MinY';
    181,  314,   'int32',    'b',  'Mode';
    181,  347,   'pascal',   'l',  'File';
    181,  858,   'pascal',   'l',  'SampleName';
    181,  1369,  'pascal',   'l',  'Barcode';
    181,  1880,  'pascal',   'l',  'Operator';
    181,  2391,  'pascal',   'l',  'DateTime';
    181,  2492,  'pascal',   'l',  'InstModel';
    181,  2533,  'pascal',   'l',  'Inlet';
    181,  2574,  'pascal',   'l',  'MethodName';
    181,  4106,  'int16',    'b',  'Detector';
    181,  4108,  'int16',    'b',  'Method';
    181,  4110,  'float32',  'b',  'Zero';
    181,  4114,  'float32',  'b',  'Min';
    181,  4118,  'float32',  'b',  'Max';
    181,  4122,  'int32',    'b',  'BunchPower';
    181,  4126,  'float64',  'b',  'PeakWidth';
    181,  4134,  'int32',    'b',  'Version';
    181,  4172,  'pascal',   'l',  'Units';
    181,  4213,  'pascal',   'l',  'SigDesc';
    181,  4724,  'float64',  'b',  'Intercept';
    181,  4732,  'float64',  'b',  'Slope';
    181,  5524,  'int16',    'b',  'SignalDataType';
    };

units = {
    'mAU';
    'LU';
    'nRIU';
    'kV';
    'uV';
    '°C';
    'mbar';
    'mW';
    'pA'
    'uA'
};

varargout{1} = cell2struct([F8; F30; F81; F130; F179; F181], fields, 2);
end