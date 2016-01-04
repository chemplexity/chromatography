% ------------------------------------------------------------------------
% Method      : ImportAgilentFID [EXPERIMENTAL]
% Description : Import data stored in Agilent(.D, .CH) files
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ImportAgilentFID()
%   data = ImportAgilentFID(path)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   path (optional)
%       Description : relative or absolute path of file/folder
%       Type        : string
%       Default     : opens file selection UI
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = ImportAgilentFID()
%   data = ImportAgilentFID('002B0201.D')
%   data = ImportAgilentFID('/Users/Admin/Data/084B051.D')
%   data = ImportAgilentFID('C:\Users\Admin\Data\FID2B.CH')
%   data = ImportAgilentFID('005-0101.D', 'DAD1A.CH', 'FID1A.CH')
%   data = ImportAgilentFID('/Users/Admin/Data/20150101_SEQUENCE/')
%   data = ImportAgilentFID('C:\Users\Admin\Data\2015_OCT_SAMPLES\')
%   data = ImportAgilentFID('TRIAL1_SEQ', 'TRIAL2_SEQ')
%   data = ImportAgilentFID('DAD1A.CH', '/Users/Admin/Data/TRIAL1043/')
%   data = ImportAgilentFID('SAMPLES_100_300', '001STANDARD.D')
%

function data = ImportAgilentFID(varargin)

filename = parseInput(varargin);
filelist = getFilePath(filename);

data = getFileInfo(filelist);

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

function filelist = getFilePath(filename)

filelist = [];

% Search filter
filter = @(x) regexp(x, '(?i)[.](D|MS|CH|UV)', 'match');

% Validate selection
for i = 1:length(filename)
    
    % Search directory
    if filename(i).directory
        fdir = dir(filename(i).Name);
        
        % Get file extensions
        fext = cellfun(@(x) filter(x), {fdir.name}, 'uniformoutput', 0);
        fdir(cellfun(@isempty, fext)) = [];
        
        for j = 1:length(fdir)
            
            % Get absolute path
            fpath = fullfile(filename(i).Name, filesep, fdir(j).name);
            
            if fdir(j).isdir
                
                % Case: '.D'
                fsub = dir(fpath);
                fsub([fsub.isdir]) = [];
                
                % Get '.D' contents
                fext = cellfun(@(x) filter(x), {fsub.name}, 'uniformoutput', 0);
                fsub(cellfun(@isempty, fext)) = [];
                
                for k = 1:length(fsub)
                    
                    % Get absolute path
                    fpath = fullfile(...
                        filename(i).Name, filesep,...
                        fdir(j).name, filesep,...
                        fsub(k).name);
                    
                    [~, fattrib] = fileattrib(fpath);
                    fname = fattrib.Name;
                    
                    % Append file list
                    if isstruct(fattrib)
                        filelist(end+1).filepath = fname;
                        filelist(end).filename = regexp(fname, '(?i)\w+[.]D', 'match');
                        
                        if isempty(filelist(end).filename)
                            filelist(end).filename = regexp(fname, '(?i)\w+[.](MS|CH|UV)', 'match');
                            filelist(end).filename = filelist(end).filename{1};
                        else
                            filelist(end).filename = filelist(end).filename{1};
                        end
                        
                        filelist(end).date = fsub(k).datenum;
                        filelist(end).size = fsub(k).bytes;
                    end
                end
                
            elseif ~fdir(j).isdir
                
                % Case: '.CH', '.MS', '.UV'
                [~, fattrib] = fileattrib(fpath);
                
                fname = fattrib.Name;
                finfo = dir(fname);
                
                % Append file list
                if isstruct(fattrib)
                    
                    filelist(end+1).filepath = fname;
                    filelist(end).filename = regexp(fname, '(?i)\w+[.]D', 'match');
                    
                    if isempty(filelist(end).filename)
                        filelist(end).filename = regexp(fname, '(?i)\w+[.](MS|CH|UV)', 'match');
                        
                        if ~isempty(filelist(end).filename)
                            filelist(end).filename = filelist(end).filename{1};
                        end
                    else
                        filelist(end).filename = filelist(end).filename{1};
                    end
                    
                    filelist(end).date = finfo.datenum;
                    filelist(end).size = finfo.bytes;
                end
            end
        end
        
    else
        
        fname = filename(i).Name;
        finfo = dir(filename(i).Name);
        
        % Append file list
        if ~isempty(filter(fname))
            filelist(end+1).filepath = fname;
            filelist(end).filename = regexp(fname, '(?i)\w+[.]D', 'match');
            
            if isempty(filelist(end).filename)
                filelist(end).filename = regexp(fname, '(?i)\w+[.](MS|CH|UV)', 'match');
                filelist(end).filename = filelist(end).filename{1};
            else
                filelist(end).filename = filelist(end).filename{1};
            end
            
            filelist(end).date = finfo.datenum;
            filelist(end).size = finfo.bytes;
        end
    end
end
end


% ---------------------------------------
% File Information
% ---------------------------------------
function data = getFileInfo(filelist)

% ---------------------------------------
% Anonymous functions
% ---------------------------------------
fpascal = @(f,type) fread(f, fread(f, 1, 'uint8'), [type,'=>char'], 'l')';

% Variables
data = [];
reference = AgilentFileStructure();

% Messages
message = [];
message.timer = 0;
message.counter = 0;

message.error.header = @(filepath,type) fprintf([...
    'error...\n',...
    '        Unsupported file type... \n',...
    '        File      : ', '%s', '\n',...
    '        Header    : ', type, '\n',...
    '        Supported : 8, 30, 81, 130, 179, 181 \n'], filepath);

message.load.summary = @(count,bytes,time,rate) fprintf([...
    '\nImport complete... \n',...
    '    Files   : ', num2str(count), '\n',...
    '    Size    : ', bytes, '\n',...
    '    Elapsed : ', time, '\n',...
    '    Rate    : ', rate, '\n\n']);

message.load.start = @(a,b) fprintf([...
    '[', num2str(a), '/', num2str(b), '] ',...
    'Loading ']);

message.load.finish = @(a,b,time,speed,progress) fprintf([...
    ' (', time, ', ', speed, ', ', progress, ')\n']);

message.info.data = @(instrument) fprintf([...
    '', instrument, ' file...']);

for i = 1:length(filelist)
    
    if i == 1
        fprintf('\nImporting Agilent data files...\n\n');
    end
    
    % Start timer
    tic;
    
    % MESSAGE / Load file
    message.load.start(i, length(filelist));
    
    % Get file info
    data(i).filepath = filelist(i).filepath;
    data(i).filename = filelist(i).filename;
    data(i).filedate = filelist(i).date;
    data(i).filesize = filelist(i).size;
    
    % Open file
    file = fopen(data(i).filepath, 'r');
    
    ftype = fread(file, fread(file, 1, 'uint8'), 'uint8=>char')';
    finfo = reference([reference.id]==str2double(ftype));
    
    % MESSAGE / Read file header
    if isempty(finfo)
        message.error.header(data(i).filepath, ftype);
        message.timer = message.timer + toc;
        continue
    end
    
    % Read file header
    for j = 1:length(finfo)
        fseek(file, finfo(j).offset, 'bof');
        
        % Integer/float
        if ~strcmpi(finfo(j).type, 'pascal')
            data(i).(finfo(j).name) = fread(file, 1, finfo(j).type, finfo(j).endian);
            
            % Pascal string (UTF-8)
        elseif str2double(ftype) < 100
            data(i).(finfo(j).name) = fpascal(file, 'uint8');
            
            % Pascal string (UTF-16)
        elseif str2double(ftype) > 100
            data(i).(finfo(j).name) = fpascal(file, 'uint16');
        end
    end
    
    % Instrument type
    if isfield(data, 'Inlet') && ~isempty(data(i).Inlet)
        instrument = regexp(data(i).Inlet, '(?i)\w+', 'match');
        
    elseif isfield(data, 'File') && ~isempty(data(i).File)
        instrument = regexp(data(i).File, '(?i)(LC|GC|CE)', 'match');
        
    else
        instrument = '';
    end
    
    detector = regexp(data(i).filepath,...
        '(?i)([A-Z]+)(?=\d?\w?[.](MS|CH|UV))', 'match');
    
    if isempty(detector)
        detector = regexp(data(i).filepath,...
            '(?i)(MS|FID|ADC|DAD|FLD|ELS|VWD|MWD|RID)(?=\w*[.])', 'match');
        
        if ~isempty(detector) && strcmpi(detector{1}, 'ELS')
            detector{1} = 'ELSD';
        end
    end
    
    if isempty(detector)
        detector = regexp(data(i).filepath,...
            '(?i)((?=CE.?)(MS|P|T|V|C|E))', 'match');
        
        if ~isempty(detector)
            detector{1} = ['CE-', detector{1}];
        end
    end
    
    if ~isempty(detector) && ~isempty(instrument)
        instrument = [instrument{1}, '/', detector{1}];
        
    elseif isempty(detector) && ~isempty(instrument)
        instrument = instrument{1};
        
    elseif ~isempty(detector) && isempty(instrument)
        instrument = detector{1};
        
    else
        instrument = 'UNKNOWN';
    end
    
    if ischar(instrument)
        instrument = upper(instrument);
    end
    
    data(i).instrument = instrument;
    
    % Validate file info
    if ~isfield(data, 'Version') || isempty(data(i).Version)
        data(i).Version = 0;
    end
    
    if isfield(data, 'StartTime') && ~isempty(data(i).StartTime);
        data(i).StartTime = data(i).StartTime / 60000;
    end
    
    if isfield(data, 'EndTime') && ~isempty(data(i).EndTime);
        data(i).EndTime = data(i).EndTime / 60000;
    end
    
    if isfield(data, 'DataOffset') && ~isempty(data(i).DataOffset);
        data(i).DataOffset = (data(i).DataOffset - 1) * 512;
    else
        data(i).DataOffset = 0;
    end
    
    % MESSAGE / Read file data
    if data(i).DataOffset <= data(i).filesize
        message.info.data(instrument);
    else
        message.timer = message.timer + toc;
        continue
    end
    
    data(i).Time = [];
    data(i).Signal = [];
    
    % Load signal
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
    
    % Parse timestamp
    if isfield(data, 'DateTime') && ~isempty(data(i).DateTime)
        datevalue = parsedate(data(i).DateTime);
        
        if ~isempty(datevalue)
            data(i).UnixTime = datevalue;
            data(i).DateTime = datestr(datevalue, 'yyyy-mm-dd HH:MM:SS');
        else
            data(i).UnixTime = [];
        end
    end
    
    % MESSAGE / Load complete
    message.timer = message.timer + toc;
    message.counter = message.counter + data(i).filesize;
    
    if (message.counter / 1E6) / message.timer > 1
        rate = [num2str((message.counter / 1E6) / message.timer, '%.2f'), ' MB/s'];
    else
        rate = [num2str((message.counter / 1E3) / message.timer, '%.1f'), ' KB/s'];
    end
    
    if message.timer >= 60
        elapsed = [num2str(message.timer / 60, '%.2f'), ' min'];
    else
        elapsed = [num2str(message.timer, '%.1f'), ' sec'];
    end
    
    totalsize = sum([filelist.size]);
    
    if totalsize > 1E6
        a = num2str(message.counter / 1E6, '%.1f');
        b = num2str(totalsize / 1E6, '%.1f');
    else
        a = num2str(message.counter / 1E3, '%.1f');
        b = num2str(totalsize / 1E3, '%.1f');
    end
    
    progress = [a, '/', b, ' MB'];
    
    message.load.finish(i, length(filelist), elapsed, rate, progress);
end

if message.timer >= 60
    elapsed = [num2str(message.timer / 60, '%.2f'), ' min'];
else
    elapsed = [num2str(message.timer, '%.1f'), ' sec'];
end

if (message.counter / 1E6) / message.timer > 1
    rate = [num2str((message.counter / 1E6) / message.timer, '%.2f'), ' MB/s'];
else
    rate = [num2str((message.counter / 1E3) / message.timer, '%.1f'), ' KB/s'];
end

% MESSAGE / Summary
if ~isempty(filelist)
    message.load.summary(length(data), units(message.counter, 'bytes'), elapsed, rate);
end

% Clear empty signal
if isfield(data, 'Signal')
    data(cellfun(@isempty, {data.Signal})) = [];
end

% Sort by date and time
if isfield(data, 'UnixTime')
    [~, index] = sort([data.UnixTime]);
    data = data(index);
end
end

function varargout = units(varargin)

switch varargin{2}
    
    case 'bytes'
        
        if varargin{1} > 1E9
            varargout{1} = [num2str(varargin{1}/1E9, '%.2f'), ' GB'];
        elseif varargin{1} > 1E6
            varargout{1} = [num2str(varargin{1}/1E6, '%.2f'), ' MB'];
        elseif varargin{1} > 1E3
            varargout{1} = [num2str(varargin{1}/1E3, '%.2f'), ' KB'];
        else
            varargout{1} = [num2str(varargin{1}/1E0, '%.2f'), ' B'];
        end
end
end

%
% Method      : parsedate
% Description : Convert timestamp to UNIX time
%
% Input       : Timestamp (string)
% Output      : UNIX time (number)
%
function varargout = parsedate(varargin)

if ischar(varargin{1})
    try
        varargout{1} = datenum(varargin{1}, 'dd mmm yy HH:MM PM');
    catch
        try
            varargout{1} = datenum(varargin{1}, 'mm/dd/yy HH:MM:SS PM');
        catch
            try
                varargout{1} = datenum(varargin{1}, 'dd-mmm-yy, HH:MM:SS');
            catch
                varargout{1} = [];
            end
        end
    end
else
    varargout{1} = [];
end
end


%
% Method      : DeltaCompression
% Description : Decode delta compressed signal
%
function data = DeltaCompression(file, data)

if ftell(file) == -1
    data.Time = [];
    data.Signal = [];
    return;
else
    fseek(file, 0, 'eof');
    stop = ftell(file);
    
    fseek(file, data.DataOffset, 'bof');
    start = ftell(file);
end

signal = zeros(round((stop-start)/2), 1);
buffer = zeros(4, 1);
index = 1;

while ftell(file) < stop
    
    buffer(1) = fread(file, 1, 'int16', 'b');
    buffer(2) = buffer(4);
    
    if bitshift(buffer(1), 12, 'int16') == 0
        signal(index:end) = [];
        break
    end
    
    for i = 1:bitand(buffer(1), 4095, 'int16');
        
        buffer(3) = fread(file, 1, 'int16', 'b');
        
        if buffer(3) ~= -32768
            buffer(2) = buffer(2) + buffer(3);
        else
            buffer(2) = fread(file, 1, 'int32', 'b');
        end
        
        signal(index) = buffer(2);
        index = index + 1;
    end
    
    buffer(4) = buffer(2);
end

% Adjust signal
if isfield(data, 'Slope') && isfield(data, 'Intercept')
    data.Signal = (signal * data.Slope) + data.Intercept;
else
    data.Signal = signal;
end

% Caclelculate time values
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
        buffer(1) = fread(file, 1, 'uint32', 'b') + buffer(1);
        buffer(2) = 0;
    end
    
    signal(count, 1) = buffer(1);
    count = count + 1;
end

signal(count:end,:) = [];

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

%units = {
%    'mAU';
%    'LU';
%    'nRIU';
%    'kV';
%  'uV';
%   '°C';
%   'mbar';
%    'mW';
%    'pA'
%    'uA'
%};

varargout{1} = cell2struct([F8; F30; F81; F130; F179; F181], fields, 2);
end