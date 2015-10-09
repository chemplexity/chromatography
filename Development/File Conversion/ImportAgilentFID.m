% Method      : ImportAgilentFID (EXPERIMENTAL)
% Description : Read Agilent data files (.D, .CH)
%
% Syntax
%   data = ImportAgilent()
%   data = ImportAgilent(files)
%
% Examples
%   Options: GUI, Files, Folders, Files/Folders

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

file = [];
fstruct = structure();

data = [];
%    'id', [],...
%     'file', [],...
%    'sample', [],...
%    'method', [],...
%    'instrument', [],...
%    'time', [],...
%    'intensity', [],...
%    'units', [],...
%    'checksum', []...
%    );

% Input: none
if nargin == 0
   
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
            [~, fa] = fileattrib(char(fs(i).getAbsolutePath));
            
            % Append file list
            if isstruct(fa)
                file = [file; fa];
            end
        end
    end
    
% Input: files/folders
elseif nargin > 0
    
    for i = 1:length(varargin)
        
        % Check input name
        if ischar(varargin{i})
            [~, fa] = fileattrib(varargin{i});
            
            % Append file list
            if isstruct(fa)
                file = [file; fa];
            end
        end
    end
end

% Search function
fsearch = @(x) regexp(x, '(?i)[.](D|MS|CH)', 'match');

% Validate selection
for i = 1:length(file)
    
    % Search directory
    if file(i).directory
        fdir = dir(file(i).Name);
        
        % Get file extensions
        fext = cellfun(@(x) fsearch(x), {fdir.name}, 'uniformoutput', 0);
        fdir(cellfun(@isempty, fext)) = [];
        
        for j = 1:length(fdir)
        
            % Get absolute path
            fpath = fullfile(file(i).Name, filesep, fdir(j).name);
        
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
                        data(end+1).file = fa.Name;
                    end
                end
                
            % Case: '.CH', '.MS'
            elseif ~fdir(j).isdir
                [~, fa] = fileattrib(fpath);
        
                % Append data structure
                if isstruct(fa)
                    data(end+1).file = fa.Name;
                end
            end
        end
        
    % Search file
    else
        fname = file(i).Name;
        
        % Append data structure
        if ~isempty(fsearch(fname))
            data(end+1).file = fname;
        end
    end
end

% Display start message
if ~isempty(data)
    fprintf(['\nInitializing file import...\n\n',...
             'Files: ', num2str(length(data)), '\n']);
end

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';
ftime = 0;

% Import data
for i = 1:length(data)
    
    tic;
    % Get MD5 checksum
    %data(i).checksum = MD5(data(i).file.name);
  
    fprintf(['\n(', num2str(i), '/', num2str(length(data)), ') ']);
    
    % Get format code
    f = fopen(data(i).file, 'r');
    ftype = fread(f, fread(f, 1, 'uint8'), 'uint8=>char')';
    
    fseek(f, 0, 'eof');
    fsize = ftell(f);
    
    fref = fstruct([fstruct.id]==str2double(ftype));
    
    for j = 1:length(fref)
        
        fseek(f, fref(j).offset, 'bof');
        
        if ~strcmpi(fref(j).type, 'pascal') 
            data(i).(fref(j).name) = fread(f, 1, fref(j).type, fref(j).endian);
        elseif str2double(ftype) < 100
            data(i).(fref(j).name) = fpascal(f, 'uint8');
        elseif str2double(ftype) > 100
            data(i).(fref(j).name) = fpascal(f, 'uint16');
        end
    end
    
    switch ftype
        
        case '181'
            signal = [];
            buffer = zeros(1,3);
            
            fseek(f, (data(i).DataOffset-1)*512, 'bof');
            
            while ftell(f) < fsize
                
                buffer(3) = fread(f, 1, 'int16', 'b');
                
                if buffer(3) ~= 32767
                    buffer(2) = buffer(2) + buffer(3);
                    buffer(1) = buffer(1) + buffer(2);
                else
                    buffer(1) = fread(f, 1, 'int16', 'b') * 4294967296;
                    buffer(1) = fread(f, 1, 'int32', 'b') + buffer(1);
                    buffer(2) = 0;
                end
                
                signal(end+1, 1) = buffer(1);
            end
                        
            data(i).Signal = (signal * data(i).Slope) + data(i).Intercept;

            data(i).Time(:,1) = linspace(data(i).StartTime, data(i).EndTime, length(signal));
            data(i).Time = data(i).Time / 60000;
    end
    
    fclose(f);
    
    ftime = ftime + toc;
    
    fprintf([sprintf('%.3f', ftime), ' s']);
    % Read data
    %switch data(i).file.type
     %   case '30'
      %      data(i) = LC30(data(i));
       % case '8'
        %    data(i) = GC8(data(i));    
        %case '81'
         %   data(i) = GC81(data(i));
        %case '179'
         %   data(i) = GC179(data(i));
        %case '181'
         %   data(i) = GC181(data(i));
    %end
end

varargout{1} = data;
end

% MD5 checksum
function checksum = MD5(filename)

md5 = java.security.MessageDigest.getInstance('MD5');

if ischar(filename)

    fstream = java.io.FileInputStream(java.io.File(filename));
    dstream = java.security.DigestInputStream(fstream, md5);

    while(dstream.read() ~= -1)
    end

    checksum = reshape(dec2hex(typecast(md5.digest(),'uint8'))', 1, []);
else
    checksum = '00000000000000000000000000000000';
end
end

function varargout = LC30(varargin)

keys = {'id', 'offset', 'type', 'endian', 'name'};

values = {...
    30,   4,     'pascal',   'l',  'File';
    30,   24,    'pascal',   'l',  'SampleName';
    30,   86,    'pascal',   'l',  'Barcode';
    30,   48,    'pascal',   'l',  'Operator';
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


% |  526   | int32   |   b    | Max             |
% |  530   | int32   |   b    | BunchPower      |
% |  534   | float64 |   b    | PeakWidth       |
% |  542   | int32   |   b    | Version         |
% |  580   | pascal  |   l    | Units           |
% |  596   | pascal  |   l    | SigDesc         |
% |  636   | float64 |   b    | Intercept       |
% |  644   | float64 |   b    | Slope           |
% |  784   | int16   |   b    | SignalDataType  |
% |                                             |
% | Signal : delta compression                  |

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

data = varargin{1};

f = fopen(data.file.name, 'r');

fseek(f, 0, 'eof');
data.file.size = ftell(f);

fseek(f, 4, 'bof');
data.file.id = fpascal(f, 'uint8');

fseek(f, 24, 'bof');
data.sample.name = fpascal(f, 'uint8');

% Barcode
fseek(f, 86, 'bof');
data.sample.id = fpascal(f, 'uint8');

fseek(f, 148, 'bof');
data.sample.operator = fpascal(f, 'uint8');

fseek(f, 178, 'bof');
data.sample.date = fpascal(f, 'uint8');

fseek(f, 208, 'bof');
data.instrument.model = fpascal(f, 'uint8');

fseek(f, 218, 'bof');
data.instrument.inlet = fpascal(f, 'uint8');

fseek(f, 228, 'bof');
data.method.name = fpascal(f, 'uint8');

fseek(f, 248, 'bof');
data.file.type = fread(f, 1, 'int32', 'b');
data.sample.sequence_id = fread(f, 1, 'int16', 'b');
data.sample.vial_id = fread(f, 1, 'int16', 'b');
data.sample.replicate_id = fread(f, 1, 'int16', 'b');

% DirEntType
fseek(f, 258, 'bof');
DirEntType = fread(f, 1, 'int16', 'b');
DirOffset = fread(f, 1, 'int32', 'b');
data.file.data_offset = (fread(f, 1, 'int32', 'b') - 1) * 512;
data.RunTableOffset = fread(f, 1, 'int32', 'b');
data.NormOffset = fread(f, 1, 'int32', 'b');
data.NumRecords = fread(f, 1, 'int16', 'b');
data.ExtraRecords = fread(f, 1, 'int32', 'b');
data.StartTime = fread(f, 1, 'int32', 'b') / 60000;

% EndTime
fseek(f, 286, 'bof');
data.EndTime = fread(f, 1, 'int32', 'b') / 60000;

% MaxSignal
fseek(f, 290, 'bof');
data.MaxSignal = fread(f, 1, 'int32', 'b');

% MinSignal
fseek(f, 294, 'bof');
data.MinSignal = fread(f, 1, 'int32', 'b');

% MaxY
fseek(f, 298, 'bof');
data.MaxY = fread(f, 1, 'int32', 'b');

% MinY
fseek(f, 302, 'bof');
data.MinY = fread(f, 1, 'int32', 'b');

% Mode
fseek(f, 314, 'bof');
data.Mode = fread(f, 1, 'int32', 'b');

if data.Mode == 1
    
    % GlpFlag
    fseek(f, 318, 'bof');
    data.GlpFlag = fread(f, 1, 'int32', 'b');

    % SoftwareName
    fseek(f, 322, 'bof');
    data.SoftwareName = fpascal(f, 'uint8');

    % FirmwareRev
    fseek(f, 355, 'bof');
    data.FirmwareRev = fpascal(f, 'uint8');

    % SoftwareRev
    fseek(f, 405, 'bof');
    data.SoftwareRev = fpascal(f, 'uint8');
end

% Detector
fseek(f, 514, 'bof');
data.Detector = fread(f, 1, 'int16', 'b');

% Method
fseek(f, 516, 'bof');
data.Method = fread(f, 1, 'int16', 'b');

% Zero
fseek(f, 518, 'bof');
data.Zero = fread(f, 1, 'int32', 'b');

% Min
fseek(f, 522, 'bof');
data.Min = fread(f, 1, 'int32', 'b');

% Max
fseek(f, 526, 'bof');
data.Max = fread(f, 1, 'int32', 'b');

% BunchPower
fseek(f, 530, 'bof');
data.BunchPower = fread(f, 1, 'int32', 'b');

% PeakWidth
fseek(f, 534, 'bof');
data.PeakWidth = fread(f, 1, 'double', 'b');

% Version
fseek(f, 542, 'bof');
data.Version = fread(f, 1, 'int32', 'b');

% Units
fseek(f, 580, 'bof');
data.Units = fpascal(f, 'uint8');

% SigDesc
fseek(f, 596, 'bof');
data.SigDesc = fpascal(f, 'uint8');

if data.Version == 1
    
    % Intercept
    data.Intercept = 0;

    % Slope
    data.Slope = 1;
    
elseif data.Version == 2
    
    % Intercept
    data.Intercept = 0;
    
    % Slope
    data.Slope = 0.00240841663372301;
else
    % Intercept
    fseek(f, 636, 'bof');
    data.Intercept = fread(f, 1, 'double', 'b');

    % Slope
    fseek(f, 644, 'bof');
    data.Slope = fread(f, 1, 'double', 'b');
end

% SignalDataType
fseek(f, 784, 'bof');
data.SignalDataType = fread(f, 1, 'int16', 'b');

% Signal (delta decompression)
signal = data.Zero;
buffer = zeros(1,8);

fseek(f, data.DataOffset, 'bof');

while ftell(f) < data.FileSize
    
    buffer(1) = fread(f, 1, 'int16', 'b');
    buffer(2) = bitshift(buffer(1), 12, 'int16');
    buffer(3) = buffer(8);
    buffer(4) = bitand(buffer(1), 4095, 'int16');
    
    for i = 1:buffer(4)
        
        buffer(5) = fread(f, 1, 'int16', 'b');
        
        if buffer(5) ~= -32768
            buffer(3) = buffer(3) + buffer(5);
        else
            buffer(3) = fread(f, 1, 'int32', 'b');
        end
        
        buffer(6) = buffer(3);
        buffer(7) = buffer(6);
        buffer(8) = buffer(6);
        signal(end+1, 1) = buffer(7);
    end
end

fclose(f);

% Signal
if data.Slope ~= 0
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Time
if data.StartTime < data.EndTime
    data.Time(:,1) = linspace(data.StartTime, data.EndTime, length(signal));
else
    data.Time(:,1) = 1:length(signal);
end

varargout{1} = data;
end


function varargout = GC8(varargin)

% |             File Header 8                   |
% |                                             |
% | Offset |  Type   | Endian |      Name       |
% |  4     | pascal  |   l    | File            |
% |  24    | pascal  |   l    | SampleName      |
% |  86    | pascal  |   l    | Barcode         |
% |  148   | pascal  |   l    | Operator        |
% |  178   | pascal  |   l    | DateTime        |
% |  208   | pascal  |   l    | InstModel       |
% |  218   | pascal  |   l    | Inlet           |
% |  228   | pascal  |   l    | MethodName      |
% |  248   | int32   |   b    | FileType        |
% |  252   | int16   |   b    | SeqIndex        |
% |  254   | int16   |   b    | AlsBottle       |
% |  256   | int16   |   b    | Replicate       |
% |  258   | int16   |   b    | DirEntType      |
% |  260   | int32   |   b    | DirOffset       |
% |  264   | int32   |   b    | DataOffset      |
% |  268   | int32   |   b    | RunTableOffset  |
% |  272   | int32   |   b    | NormOffset      |
% |  276   | int16   |   b    | ExtraRecords    |
% |  278   | int32   |   b    | NumRecords      |
% |  282   | int32   |   b    | StartTime       |
% |  286   | int32   |   b    | EndTime         |
% |  290   | int32   |   b    | MaxSignal       |
% |  294   | int32   |   b    | MinSignal       |
% |  298   | int32   |   b    | MaxY            |
% |  302   | int32   |   b    | MinY            |
% |  314   | int32   |   b    | Mode            |
% |  514   | int16   |   b    | Detector        |
% |  516   | int16   |   b    | Method          |
% |  518   | int32   |   b    | Zero            |
% |  522   | int32   |   b    | Min             |
% |  526   | int32   |   b    | Max             |
% |  530   | int32   |   b    | BunchPower      |
% |  534   | float64 |   b    | PeakWidth       |
% |  542   | int32   |   b    | Version         |
% |  580   | pascal  |   l    | Units           |
% |  596   | pascal  |   l    | SigDesc         |
% |  636   | float64 |   b    | Intercept       |
% |  644   | float64 |   b    | Slope           |
% |  784   | int16   |   b    | SignalDataType  |
% |                                             |
% | Signal : delta compression                  |

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

% Open
file = fopen(varargin{1}, 'r');

% FileName
data.FileName = varargin{1};

% FileSize
fseek(file, 0, 'eof');
data.FileSize = ftell(file);

if data.FileSize < 1028
    varargout{1} = data;
    return
end

% File
fseek(file, 4, 'bof');
data.File = fpascal(file, 'uint8');

% SampleName
fseek(file, 24, 'bof');
data.SampleName = fpascal(file, 'uint8');

% Barcode
fseek(file, 86, 'bof');
data.Barcode = fpascal(file, 'uint8');

% Operator
fseek(file, 148, 'bof');
data.Operator = fpascal(file, 'uint8');

% DateTime
fseek(file, 178, 'bof');
data.DateTime = fpascal(file, 'uint8');

% InstModel
fseek(file, 208, 'bof');
data.InstModel = fpascal(file, 'uint8');

% Inlet
fseek(file, 218, 'bof');
data.Inlet = fpascal(file, 'uint8');

% MethodName
fseek(file, 228, 'bof');
data.MethodName = fpascal(file, 'uint8');

% FileType
fseek(file, 248, 'bof');
data.FileType = fread(file, 1, 'int32', 'b');

% SeqIndex
fseek(file, 252, 'bof');
data.SeqIndex = fread(file, 1, 'int16', 'b');

% AlsBottle
fseek(file, 254, 'bof');
data.AlsBottle = fread(file, 1, 'int16', 'b');

% Replicate
fseek(file, 256, 'bof');
data.Replicate = fread(file, 1, 'int16', 'b');

% DirEntType
fseek(file, 258, 'bof');
data.DirEntType = fread(file, 1, 'int16', 'b');

% DirOffset
fseek(file, 260, 'bof');
data.DirOffset = fread(file, 1, 'int32', 'b');

% DataOffset
fseek(file, 264, 'bof');
data.DataOffset = (fread(file, 1, 'int32', 'b') - 1) * 512;

% RunTableOffset
fseek(file, 268, 'bof');
data.RunTableOffset = fread(file, 1, 'int32', 'b');

% NormOffset
fseek(file, 272, 'bof');
data.NormOffset = fread(file, 1, 'int32', 'b');

% ExtraRecords
fseek(file, 276, 'bof');
data.NumRecords = fread(file, 1, 'int16', 'b');

% NumRecords
fseek(file, 278, 'bof');
data.NumRecords = fread(file, 1, 'int32', 'b');

% StartTime
fseek(file, 282, 'bof');
data.StartTime = fread(file, 1, 'int32', 'b') / 60000;

% EndTime
fseek(file, 286, 'bof');
data.EndTime = fread(file, 1, 'int32', 'b') / 60000;

% MaxSignal
fseek(file, 290, 'bof');
data.MaxSignal = fread(file, 1, 'int32', 'b');

% MinSignal
fseek(file, 294, 'bof');
data.MinSignal = fread(file, 1, 'int32', 'b');

% MaxY
fseek(file, 298, 'bof');
data.MaxY = fread(file, 1, 'int32', 'b');

% MinY
fseek(file, 302, 'bof');
data.MinY = fread(file, 1, 'int32', 'b');

% Mode
fseek(file, 314, 'bof');
data.Mode = fread(file, 1, 'int32', 'b');

% Detector
fseek(file, 514, 'bof');
data.Detector = fread(file, 1, 'int16', 'b');

% Method
fseek(file, 516, 'bof');
data.Method = fread(file, 1, 'int16', 'b');

% Zero
fseek(file, 518, 'bof');
data.Zero = fread(file, 1, 'int32', 'b');

% Min
fseek(file, 522, 'bof');
data.Min = fread(file, 1, 'int32', 'b');

% Max
fseek(file, 526, 'bof');
data.Max = fread(file, 1, 'int32', 'b');

% BunchPower
fseek(file, 530, 'bof');
data.BunchPower = fread(file, 1, 'int32', 'b');

% PeakWidth
fseek(file, 534, 'bof');
data.PeakWidth = fread(file, 1, 'double', 'b');

% Version
fseek(file, 542, 'bof');
data.Version = fread(file, 1, 'int32', 'b');

% Units
fseek(file, 580, 'bof');
data.Units = fpascal(file, 'uint8');

% SigDesc
fseek(file, 596, 'bof');
data.SigDesc = fpascal(file, 'uint8');

if any(data.Version == [1,2,3])
    
    % Intercept
    data.Intercept = 0;

    % Slope
    data.Slope = 1.33321110047553;    
else
    % Intercept
    fseek(file, 636, 'bof');
    data.Intercept = fread(file, 1, 'double', 'b');

    % Slope
    fseek(file, 644, 'bof');
    data.Slope = fread(file, 1, 'double', 'b');
end

% SignalDataType
fseek(file, 784, 'bof');
data.SignalDataType = fread(file, 1, 'int16', 'b');

% Signal (delta decompression)
signal = data.Zero;
buffer = zeros(1,8);

fseek(file, data.DataOffset, 'bof');

while ftell(file) < data.FileSize
    
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

fclose(file);

% Signal
if data.Slope ~= 0
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Time
if data.StartTime < data.EndTime
    data.Time(:,1) = linspace(data.StartTime, data.EndTime, length(signal));
else
    data.Time(:,1) = 1:length(signal);
end

varargout{1} = data;
end


function varargout = GC81(varargin)

% |             File Header 81                  |
% |                                             |
% | Offset |  Type   | Endian |      Name       |
% |  4     | pascal  |   l    | File            |
% |  24    | pascal  |   l    | SampleName      |
% |  86    | pascal  |   l    | Barcode         |
% |  148   | pascal  |   l    | Operator        |
% |  178   | pascal  |   l    | DateTime        |
% |  208   | pascal  |   l    | InstModel       |
% |  218   | pascal  |   l    | Inlet           |
% |  228   | pascal  |   l    | MethodName      |
% |  248   | int32   |   b    | FileType        |
% |  252   | int16   |   b    | SeqIndex        |
% |  254   | int16   |   b    | AlsBottle       |
% |  256   | int16   |   b    | Replicate       |
% |  258   | int16   |   b    | DirEntType      |
% |  260   | int32   |   b    | DirOffset       |
% |  264   | int32   |   b    | DataOffset      |
% |  268   | int32   |   b    | RunTableOffset  |
% |  272   | int32   |   b    | NormOffset      |
% |  276   | int16   |   b    | ExtraRecords    |
% |  278   | int32   |   b    | NumRecords      |
% |  282   | float32 |   b    | StartTime       |
% |  286   | float32 |   b    | EndTime         |
% |  290   | float32 |   b    | MaxSignal       |
% |  294   | float32 |   b    | MinSignal       |
% |  298   | float32 |   b    | MaxY            |
% |  302   | float32 |   b    | MinY            |
% |  314   | int32   |   b    | Mode            |
% |  514   | int16   |   b    | Detector        |
% |  516   | int16   |   b    | Method          |
% |  518   | float32 |   b    | Zero            |
% |  522   | float32 |   b    | Min             |
% |  526   | float32 |   b    | Max             |
% |  530   | int32   |   b    | BunchPower      |
% |  534   | float64 |   b    | PeakWidth       |
% |  542   | int32   |   b    | Version         |
% |  580   | pascal  |   l    | Units           |
% |  596   | pascal  |   l    | SigDesc         |
% |  636   | float64 |   b    | Intercept       |
% |  644   | float64 |   b    | Slope           |
% |  784   | int16   |   b    | SignalDataType  |
% |                                             |
% | Signal : double delta compression           |

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

% Open
file = fopen(varargin{1}, 'r');

% FileName
data.FileName = varargin{1};

% FileSize
fseek(file, 0, 'eof');
data.FileSize = ftell(file);

if data.FileSize < 1028
    varargout{1} = data;
    return
end

% File
fseek(file, 4, 'bof');
data.File = fpascal(file, 'uint8');

% SampleName
fseek(file, 24, 'bof');
data.SampleName = fpascal(file, 'uint8');

% Barcode
fseek(file, 86, 'bof');
data.Barcode = fpascal(file, 'uint8');

% Operator
fseek(file, 148, 'bof');
data.Operator = fpascal(file, 'uint8');

% DateTime
fseek(file, 178, 'bof');
data.DateTime = fpascal(file, 'uint8');

% InstModel
fseek(file, 208, 'bof');
data.InstModel = fpascal(file, 'uint8');

% Inlet
fseek(file, 218, 'bof');
data.Inlet = fpascal(file, 'uint8');

% MethodName
fseek(file, 228, 'bof');
data.MethodName = fpascal(file, 'uint8');

% FileType
fseek(file, 248, 'bof');
data.FileType = fread(file, 1, 'int32', 'b');

% SeqIndex
fseek(file, 252, 'bof');
data.SeqIndex = fread(file, 1, 'int16', 'b');

% AlsBottle
fseek(file, 254, 'bof');
data.AlsBottle = fread(file, 1, 'int16', 'b');

% Replicate
fseek(file, 256, 'bof');
data.Replicate = fread(file, 1, 'int16', 'b');

% DirEntType
fseek(file, 258, 'bof');
data.DirEntType = fread(file, 1, 'int16', 'b');

% DirOffset
fseek(file, 260, 'bof');
data.DirOffset = fread(file, 1, 'int32', 'b');

% DataOffset
fseek(file, 264, 'bof');
data.DataOffset = (fread(file, 1, 'int32', 'b') - 1) * 512;

% RunTableOffset
fseek(file, 268, 'bof');
data.RunTableOffset = fread(file, 1, 'int32', 'b');

% NormOffset
fseek(file, 272, 'bof');
data.NormOffset = fread(file, 1, 'int32', 'b');

% ExtraRecords
fseek(file, 276, 'bof');
data.NumRecords = fread(file, 1, 'int16', 'b');

% NumRecords
fseek(file, 278, 'bof');
data.NumRecords = fread(file, 1, 'int32', 'b');

% StartTime
fseek(file, 282, 'bof');
data.StartTime = fread(file, 1, 'float32', 'b') / 60000;

% EndTime
fseek(file, 286, 'bof');
data.EndTime = fread(file, 1, 'float32', 'b') / 60000;

% MaxSignal
fseek(file, 290, 'bof');
data.MaxSignal = fread(file, 1, 'float32', 'b');

% MinSignal
fseek(file, 294, 'bof');
data.MinSignal = fread(file, 1, 'float32', 'b');

% MaxY
fseek(file, 298, 'bof');
data.MaxY = fread(file, 1, 'float32', 'b');

% MinY
fseek(file, 302, 'bof');
data.MinY = fread(file, 1, 'float32', 'b');

% Mode
fseek(file, 314, 'bof');
data.Mode = fread(file, 1, 'int32', 'b');

% Detector
fseek(file, 514, 'bof');
data.Detector = fread(file, 1, 'int16', 'b');

% Method
fseek(file, 516, 'bof');
data.Method = fread(file, 1, 'int16', 'b');

% Zero
fseek(file, 518, 'bof');
data.Zero = fread(file, 1, 'float32', 'b');

% Min
fseek(file, 522, 'bof');
data.Min = fread(file, 1, 'float32', 'b');

% Max
fseek(file, 526, 'bof');
data.Max = fread(file, 1, 'float32', 'b');

% BunchPower
fseek(file, 530, 'bof');
data.BunchPower = fread(file, 1, 'int32', 'b');

% PeakWidth
fseek(file, 534, 'bof');
data.PeakWidth = fread(file, 1, 'float64', 'b');

% Version
fseek(file, 542, 'bof');
data.Version = fread(file, 1, 'int32', 'b');

% Units
fseek(file, 580, 'bof');
data.Units = fpascal(file, 'uint8');

% SigDesc
fseek(file, 596, 'bof');
data.SigDesc = fpascal(file, 'uint8');

% Intercept
fseek(file, 636, 'bof');
data.Intercept = fread(file, 1, 'float64', 'b');

% Slope
fseek(file, 644, 'bof');
data.Slope = fread(file, 1, 'float64', 'b');

% SignalDataType
fseek(file, 784, 'bof');
data.SignalDataType = fread(file, 1, 'int16', 'b');

% Signal (double delta decompression)
signal = [];
buffer = zeros(1,3);

fseek(file, data.DataOffset, 'bof');

while ftell(file) < data.FileSize
    
    buffer(3) = fread(file, 1, 'int16', 'b');
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(file, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(file, 1, 'int32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    signal(end+1, 1) = buffer(1);
end

fclose(file);

% Signal
if data.Slope ~= 0
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Time
if data.StartTime < data.EndTime
    data.Time(:,1) = linspace(data.StartTime, data.EndTime, length(signal));
else
    data.Time(:,1) = 1:length(signal);
end

varargout{1} = data;
end


function varargout = GC179(varargin)

% |             File Header 179                 |
% |                                             |
% | Offset |  Type   | Endian |      Name       |
% |  248   | int32   |   b    | FileType        |
% |  252   | int16   |   b    | SeqIndex        |
% |  254   | int16   |   b    | AlsBottle       |
% |  256   | int16   |   b    | Replicate       |
% |  258   | int16   |   b    | DirEntType      |
% |  260   | int32   |   b    | DirOffset       |
% |  264   | int32   |   b    | DataOffset      |
% |  268   | int32   |   b    | RunTableOffset  |
% |  272   | int32   |   b    | NormOffset      |
% |  276   | int16   |   b    | ExtraRecords    |
% |  278   | int32   |   b    | NumRecords      |
% |  282   | float32 |   b    | StartTime       |
% |  286   | float32 |   b    | EndTime         |
% |  290   | float32 |   b    | MaxSignal       |
% |  294   | float32 |   b    | MinSignal       |
% |  298   | float32 |   b    | MaxY            |
% |  302   | float32 |   b    | MinY            |
% |  314   | int32   |   b    | Mode            |
% |  347   | pascal  |   l    | File            |
% |  858   | pascal  |   l    | SampleName      |
% |  1369  | pascal  |   l    | Barcode         |
% |  1880  | pascal  |   l    | Operator        |
% |  2391  | pascal  |   l    | DateTime        |
% |  2492  | pascal  |   l    | InstModel       |
% |  2533  | pascal  |   l    | Inlet           |
% |  2574  | pascal  |   l    | MethodName      |
% |  3089  | pascal  |   l    | SoftwareName    |
% |  3601  | pascal  |   l    | FirmwareRev     |
% |  3802  | pascal  |   l    | SoftwareRev     |
% |  4106  | int16   |   b    | Detector        |
% |  4108  | int16   |   b    | Method          |
% |  4110  | float32 |   b    | Zero            |
% |  4114  | float32 |   b    | Min             |
% |  4118  | float32 |   b    | Max             |
% |  4122  | int32   |   b    | BunchPower      |
% |  4126  | float64 |   b    | PeakWidth       |
% |  4134  | int32   |   b    | Version         |
% |  4172  | pascal  |   l    | Units           |
% |  4213  | pascal  |   l    | SigDesc         |
% |  4724  | float64 |   b    | Intercept       |
% |  4732  | float64 |   b    | Slope           |
% |  5524  | int16   |   b    | SignalDataType  |
% |                                             |
% | Signal : double array                       |

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

% Open
file = fopen(varargin{1}, 'r');

% FileName
data.FileName = varargin{1};

% FileSize
fseek(file, 0, 'eof');
data.FileSize = ftell(file);

if data.FileSize < 4092
    varargout{1} = [];
    return
end

% FileType
fseek(file, 248, 'bof');
data.FileType = fread(file, 1, 'int32', 'b');

% SeqIndex
fseek(file, 252, 'bof');
data.SeqIndex = fread(file, 1, 'int16', 'b');

% AlsBottle
fseek(file, 254, 'bof');
data.AlsBottle = fread(file, 1, 'int16', 'b');

% Replicate
fseek(file, 256, 'bof');
data.Replicate = fread(file, 1, 'int16', 'b');

% DirEntType
fseek(file, 258, 'bof');
data.DirEntType = fread(file, 1, 'int16', 'b');

% DirOffset
fseek(file, 260, 'bof');
data.DirOffset = fread(file, 1, 'int32', 'b');

% DataOffset
fseek(file, 264, 'bof');
data.DataOffset = (fread(file, 1, 'int32', 'b') - 1) * 512;

% RunTableOffset
fseek(file, 268, 'bof');
data.RunTableOffset = fread(file, 1, 'int32', 'b');

% NormOffset
fseek(file, 272, 'bof');
data.NormOffset = fread(file, 1, 'int32', 'b');

% ExtraRecords
fseek(file, 276, 'bof');
data.NumRecords = fread(file, 1, 'int16', 'b');

% NumRecords
fseek(file, 278, 'bof');
data.NumRecords = fread(file, 1, 'int32', 'b');

% StartTime
fseek(file, 282, 'bof');
data.StartTime = fread(file, 1, 'float32', 'b') / 60000;

% EndTime
fseek(file, 286, 'bof');
data.EndTime = fread(file, 1, 'float32', 'b') / 60000;

% MaxSignal
fseek(file, 290, 'bof');
data.MaxSignal = fread(file, 1, 'float32', 'b');

% MinSignal
fseek(file, 294, 'bof');
data.MinSignal = fread(file, 1, 'float32', 'b');

% MaxY
fseek(file, 298, 'bof');
data.MaxY = fread(file, 1, 'float32', 'b');

% MinY
fseek(file, 302, 'bof');
data.MinY = fread(file, 1, 'float32', 'b');

% Mode
fseek(file, 314, 'bof');
data.Mode = fread(file, 1, 'int32', 'b');

% File
fseek(file, 347, 'bof');
data.File = fpascal(file, 'uint16');

% SampleName
fseek(file, 858, 'bof');
data.SampleName = fpascal(file, 'uint16');

% Barcode
fseek(file, 1369, 'bof');
data.Barcode = fpascal(file, 'uint16');

% Operator
fseek(file, 1880, 'bof');
data.Operator = fpascal(file, 'uint16');

% DateTime
fseek(file, 2391, 'bof');
data.DateTime = fpascal(file, 'uint16');

% InstModel
fseek(file, 2492, 'bof');
data.InstModel = fpascal(file, 'uint16');

% Inlet
fseek(file, 2533, 'bof');
data.Inlet = fpascal(file, 'uint16');

% MethodName
fseek(file, 2574, 'bof');
data.MethodName = fpascal(file, 'uint16');

% SoftwareName
fseek(file, 3089, 'bof');
data.SoftwareName = fpascal(file, 'uint16');

% FirmwareRev
fseek(file, 3601, 'bof');
data.FirmwareRev = fpascal(file, 'uint16');

% SoftwareRev
fseek(file, 3802, 'bof');
data.SoftwareRev = fpascal(file, 'uint16');

% Detector
fseek(file, 4106, 'bof');
data.Detector = fread(file, 1, 'int16', 'b');

% Method
fseek(file, 4108, 'bof');
data.Method = fread(file, 1, 'int16', 'b');

% Zero
fseek(file, 4110, 'bof');
data.Zero = fread(file, 1, 'float32', 'b');

% Min
fseek(file, 4114, 'bof');
data.Min = fread(file, 1, 'float32', 'b');

% Max
fseek(file, 4118, 'bof');
data.Max = fread(file, 1, 'float32', 'b');

% BunchPower
fseek(file, 4122, 'bof');
data.BunchPower = fread(file, 1, 'int32', 'b');

% PeakWidth
fseek(file, 4126, 'bof');
data.PeakWidth = fread(file, 1, 'float64', 'b');

% Version
fseek(file, 4134, 'bof');
data.Version = fread(file, 1, 'int32', 'b');

% Units
fseek(file, 4172, 'bof');
data.Units = fpascal(file, 'uint16');

% SigDesc
fseek(file, 4213, 'bof');
data.SigDesc = fpascal(file, 'uint16');

% Intercept
fseek(file, 4724, 'bof');
data.Intercept = fread(file, 1, 'float64', 'b');

% Slope
fseek(file, 4732, 'bof');
data.Slope = fread(file, 1, 'float64', 'b');

% SignalDataType
fseek(file, 5524, 'bof');
data.SignalDataType = fread(file, 1, 'int16', 'b');

% Signal (double array)
fseek(file, data.DataOffset, 'bof');
signal = fread(file, (data.FileSize - data.DataOffset) / 8, 'double', 'l');

fclose(file);

% Signal
if data.Slope ~= 0
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Time
if data.StartTime < data.EndTime
    data.Time(:,1) = linspace(data.StartTime, data.EndTime, length(signal));
else
    data.Time(:,1) = 1:length(signal);
end

varargout{1} = data;
end


function varargout = GC181(varargin)

% |             File Header 181                 |
% |                                             |
% | Offset |  Type   | Endian |      Name       |
% |  248   | int32   |   b    | FileType        |
% |  252   | int16   |   b    | SeqIndex        |
% |  254   | int16   |   b    | AlsBottle       |
% |  256   | int16   |   b    | Replicate       |
% |  258   | int16   |   b    | DirEntType      |
% |  260   | int32   |   b    | DirOffset       |
% |  264   | int32   |   b    | DataOffset      |
% |  268   | int32   |   b    | RunTableOffset  |
% |  272   | int32   |   b    | NormOffset      |
% |  276   | int16   |   b    | ExtraRecords    |
% |  278   | int32   |   b    | NumRecords      |
% |  282   | float32 |   b    | StartTime       |
% |  286   | float32 |   b    | EndTime         |
% |  290   | float32 |   b    | MaxSignal       |
% |  294   | float32 |   b    | MinSignal       |
% |  298   | float32 |   b    | MaxY            |
% |  302   | float32 |   b    | MinY            |
% |  314   | int32   |   b    | Mode            |
% |  347   | pascal  |   l    | File            |
% |  858   | pascal  |   l    | SampleName      |
% |  1369  | pascal  |   l    | Barcode         |
% |  1880  | pascal  |   l    | Operator        |
% |  2391  | pascal  |   l    | DateTime        |
% |  2492  | pascal  |   l    | InstModel       |
% |  2533  | pascal  |   l    | Inlet           |
% |  2574  | pascal  |   l    | MethodName      |
% |  4106  | int16   |   b    | Detector        |
% |  4108  | int16   |   b    | Method          |
% |  4110  | float32 |   b    | Zero            |
% |  4114  | float32 |   b    | Min             |
% |  4118  | float32 |   b    | Max             |
% |  4122  | int32   |   b    | BunchPower      |
% |  4126  | float64 |   b    | PeakWidth       |
% |  4134  | int32   |   b    | Version         |
% |  4172  | pascal  |   l    | Units           |
% |  4213  | pascal  |   l    | SigDesc         |
% |  4724  | float64 |   b    | Intercept       |
% |  4732  | float64 |   b    | Slope           |
% |  5524  | int16   |   b    | SignalDataType  |
% |                                             |
% | Signal : double delta compression           |

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

% Open
file = fopen(varargin{1}, 'r');

% FileName
data.FileName = varargin{1};

% FileSize
fseek(file, 0, 'eof');
data.FileSize = ftell(file);

if data.FileSize < 4096
    varargout{1} = [];
    return
end

% FileType
fseek(file, 248, 'bof');
data.FileType = fread(file, 1, 'int32', 'b');

% SeqIndex
fseek(file, 252, 'bof');
data.SeqIndex = fread(file, 1, 'int16', 'b');

% AlsBottle
fseek(file, 254, 'bof');
data.AlsBottle = fread(file, 1, 'int16', 'b');

% Replicate
fseek(file, 256, 'bof');
data.Replicate = fread(file, 1, 'int16', 'b');

% DirEntType
fseek(file, 258, 'bof');
data.DirEntType = fread(file, 1, 'int16', 'b');

% DirOffset
fseek(file, 260, 'bof');
data.DirOffset = fread(file, 1, 'int32', 'b');

% DataOffset
fseek(file, 264, 'bof');
data.DataOffset = (fread(file, 1, 'int32', 'b') - 1) * 512;

% RunTableOffset
fseek(file, 268, 'bof');
data.RunTableOffset = fread(file, 1, 'int32', 'b');

% NormOffset
fseek(file, 272, 'bof');
data.NormOffset = fread(file, 1, 'int32', 'b');

% ExtraRecords
fseek(file, 276, 'bof');
data.NumRecords = fread(file, 1, 'int16', 'b');

% NumRecords
fseek(file, 278, 'bof');
data.NumRecords = fread(file, 1, 'int32', 'b');

% StartTime
fseek(file, 282, 'bof');
data.StartTime = fread(file, 1, 'float32', 'b') / 60000;

% EndTime
fseek(file, 286, 'bof');
data.EndTime = fread(file, 1, 'float32', 'b') / 60000;

% MaxSignal
fseek(file, 290, 'bof');
data.MaxSignal = fread(file, 1, 'float32', 'b');

% MinSignal
fseek(file, 294, 'bof');
data.MinSignal = fread(file, 1, 'float32', 'b');

% MaxY
fseek(file, 298, 'bof');
data.MaxY = fread(file, 1, 'float32', 'b');

% MinY
fseek(file, 302, 'bof');
data.MinY = fread(file, 1, 'float32', 'b');

% Mode
fseek(file, 314, 'bof');
data.Mode = fread(file, 1, 'int32', 'b');

% File
fseek(file, 347, 'bof');
data.File = fpascal(file, 'uint16');

% SampleName
fseek(file, 858, 'bof');
data.SampleName = fpascal(file, 'uint16');

% Barcode
fseek(file, 1369, 'bof');
data.Barcode = fpascal(file, 'uint16');

% Operator
fseek(file, 1880, 'bof');
data.Operator = fpascal(file, 'uint16');

% DateTime
fseek(file, 2391, 'bof');
data.DateTime = fpascal(file, 'uint16');

% InstModel
fseek(file, 2492, 'bof');
data.InstModel = fpascal(file, 'uint16');

% Inlet
fseek(file, 2533, 'bof');
data.Inlet = fpascal(file, 'uint16');

% MethodName
fseek(file, 2574, 'bof');
data.MethodName = fpascal(file, 'uint16');

% Detector
fseek(file, 4106, 'bof');
data.Detector = fread(file, 1, 'int16', 'b');

% Method
fseek(file, 4108, 'bof');
data.Method = fread(file, 1, 'int16', 'b');

% Zero
fseek(file, 4110, 'bof');
data.Zero = fread(file, 1, 'float32', 'b');

% Min
fseek(file, 4114, 'bof');
data.Min = fread(file, 1, 'float32', 'b');

% Max
fseek(file, 4118, 'bof');
data.Max = fread(file, 1, 'float32', 'b');

% BunchPower
fseek(file, 4122, 'bof');
data.BunchPower = fread(file, 1, 'int32', 'b');

% PeakWidth
fseek(file, 4126, 'bof');
data.PeakWidth = fread(file, 1, 'float64', 'b');

% Version
fseek(file, 4134, 'bof');
data.Version = fread(file, 1, 'int32', 'b');

% Units
fseek(file, 4172, 'bof');
data.Units = fpascal(file, 'uint16');

% SigDesc
fseek(file, 4213, 'bof');
data.SigDesc = fpascal(file, 'uint16');

% Intercept
fseek(file, 4724, 'bof');
data.Intercept = fread(file, 1, 'float64', 'b');

% Slope
fseek(file, 4732, 'bof');
data.Slope = fread(file, 1, 'float64', 'b');

% SignalDataType
fseek(file, 5524, 'bof');
data.SignalDataType = fread(file, 1, 'int16', 'b');

% Signal (double delta decompression)
signal = [];
buffer = zeros(1,3);

fseek(file, data.DataOffset, 'bof');

while ftell(file) < data.FileSize
    
    buffer(3) = fread(file, 1, 'int16', 'b');
    
    if buffer(3) ~= 32767
        buffer(2) = buffer(2) + buffer(3);
        buffer(1) = buffer(1) + buffer(2);
    else
        buffer(1) = fread(file, 1, 'int16', 'b') * 4294967296;
        buffer(1) = fread(file, 1, 'int32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    signal(end+1, 1) = buffer(1);
end

fclose(file);

% Signal
if data.Slope ~= 0
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Time
if data.StartTime < data.EndTime
    data.Time(:,1) = linspace(data.StartTime, data.EndTime, length(signal));
else
    data.Time(:,1) = 1:length(signal);
end

varargout{1} = data;
end

function varargout = structure()

FHEADER = {'id', 'offset', 'type', 'endian', 'name'};

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

varargout{1} = cell2struct([F8; F30; F81; F179; F181], FHEADER, 2);
end