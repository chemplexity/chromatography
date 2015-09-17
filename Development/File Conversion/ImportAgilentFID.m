% Method      : ImportAgilentFID (EXPERIMENTAL)
% Description : Read Agilent data files (.D, .CH)
%
% Syntax
%   data = ImportAgilent()
%   data = ImportAgilent(file)
%   data = ImportAgilent(folder)
%
% Compatibility
%   
%   GC-FID
%       5890 Series
%       6890 Series
%       7890 Series

function varargout = ImportAgilentFID(varargin)

fpascal = @(f, type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

if ischar(varargin{1}) && exist(varargin{1}, 'file')
    
    filecheck = fopen(which(varargin{1}), 'r');
    filetype = fpascal(filecheck, 'uint8');
    fclose(filecheck);
    
    disp([varargin{1}, ': ', num2str(filetype)]);
    
    switch filetype
        
        case '8'
            varargout{1} = GC8(varargin{1});
            
        case '81'
            varargout{1} = GC81(varargin{1});
            
        case '179'
            varargout{1} = GC179(varargin{1});
            
        case '181'
            varargout{1} = GC181(varargin{1});
            
        otherwise
            varargout{1} = [];
    end
end
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

% Data (delta decompression)
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
% |  Data  : double delta compression           |

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

% Data (double delta decompression)
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
% |  3601  | pascal  |   l    | FirmwareVersion |
% |  3802  | pascal  |   l    | SoftwareVersion |
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
% |  Data  : double array                       |

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

% FirmwareVersion
fseek(file, 3601, 'bof');
data.FirmwareVersion = fpascal(file, 'uint16');

% SoftwareVersion
fseek(file, 3802, 'bof');
data.SoftwareVersion = fpascal(file, 'uint16');

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

% Data (double array)
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
% |  Data  : double delta compression           |

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

% Data (double delta decompression)
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