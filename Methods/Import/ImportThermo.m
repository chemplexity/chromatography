% Method: ImportThermo
%  -Extract data from Thermo (.RAW) files
%
% Syntax:
%   data = ImportThermo(file)
%
% Description:
%   file: name of data file with valid extension (.RAW)
%
% Examples:
%   data = ImportThermo('MyData.RAW')

function varargout = ImportThermo(varargin)

% Open file
file.name = fopen(varargin{1});

    % File header
    function file = FileHeader(file)
        
        % Read version
        fseek(file.name, 36, 'bof');
        version = fread(file.name, 1, 'uint32', 0, 'l');

        % Check version
        switch version
            case {62, 63}
                file.key = 32;
            case 57
                file.key = 17;
            otherwise
                file.key = 13;
        end
        
        % Skip to end
        fseek(file.name, 1356, 'bof');
    end

    file = FileHeader(file);

    % Injection data
    function file = InjectionData(file)
        
        % Skip injection data
        fseek(file.name, 64, 'cof');
    end

    file = InjectionData(file);
    
    % Sequence data
    function file = SequenceData(file)
    
        % Skip sequence data
        for i = 1:file.key
            if i == 17
                fseek(file.name, 4, 'cof');
            else
                offset = fread(file.name, 1, 'uint32');
                
                if offset > 0
                    fread(file.name, offset, 'uint16=>char', 0, 'l');
                end
            end
        end
    end
    
    file = SequenceData(file);

    % Autosampler data
    function file = AutosamplerData(file)
        
        % Skip autosampler data
        fseek(file.name, 24, 'cof');
        fseek(file.name, fread(file.name, 1, 'uint32'), 'cof');
    end

    file = AutosamplerData(file);
    
    % File preamble
    function file = FilePreamble(file)
        
        % Read date/time
        fseek(file.name, 4, 'cof');
        x = fread(file.name, 8, 'uint16', 0, 'l');
        x = datenum([x(1), x(2), x(4), x(5), x(6), x(7)]);

        % Format date/time
        file.date = strtrim(datestr(x, 'mm/dd/yy'));
        file.time = strtrim(datestr(x, 'HH:MM PM'));

        % Read data address
        fseek(file.name, 4, 'cof');
        file.data_address = fread(file.name, 1, 'uint32', 0, 'l');

        % Read run header address
        fseek(file.name, 16, 'cof');
        file.run_header_address = fread(file.name, 1, 'uint32', 0, 'l');
    end

    file = FilePreamble(file);
    
    % Run header
    function file = RunHeader(file)
       
        % Skip to run header
        fseek(file.name, file.run_header_address, 'bof');
        
        % Read scan range
        fseek(file.name, 8, 'cof');
        file.scan_start = fread(file.name, 1, 'uint32', 0, 'l');
        file.scan_end = fread(file.name, 1, 'uint32', 0, 'l');
        
        % Read scan index
        fseek(file.name, 12, 'cof');
        file.scan_index = fread(file.name, 1, 'uint32', 0, 'l');
        
        % Read m/z range
        fseek(file.name, 24, 'cof');
        file.mz_low = fread(file.name, 1, 'float64', 0, 'l');
        file.mz_high = fread(file.name, 1, 'float64', 0, 'l');
        
        % Read time range
        file.time_start = fread(file.name, 1, 'float64', 0, 'l');
        file.time_end = fread(file.name, 1, 'float64', 0, 'l');
        
        % Read scan trailer/parameters address
        fseek(file.name, file.run_header_address + 7368, 'bof');
        file.scan_trailer_address = fread(file.name, 1, 'uint32', 0, 'l');
        file.scan_parameters_address = fread(file.name, 1, 'uint32', 0, 'l');
    end

    file = RunHeader(file);

    % Scan information
    function data = ScanInfo(file, data)
       
        % Skip to scan index 
        fseek(file.name, file.scan_index, 'bof');
        
        for i = file.scan_start:file.scan_end
            
            % Read offset/index values
            data.offset(i) = fread(file.name, 1, 'uint32', 0, 'l');
            data.index(i) = fread(file.name, 1, 'uint32', 0, 'l');
            
            % Read time values
            fseek(file.name, 12, 'cof');
            data.size(i) = fread(file.name, 1, 'uint32', 0, 'l');

            data.time_values(i) = fread(file.name, 1, 'float64', 0, 'l');
            
            % Read TIC values
            data.total_intensity_values(i) = fread(file.name, 1, 'float64', 0, 'l');
            fseek(file.name, 32, 'cof');
        end        
    end

    % Variables
    scans = file.scan_end - file.scan_start;

    % Pre-allocate memory
    data.time_values = zeros(scans, 1);
    data.total_intensity_values = zeros(scans, 1);
    
    data.offset = zeros(scans, 1);
    data.index = zeros(scans, 1);
    data.size = zeros(scans, 1);
    
    data = ScanInfo(file, data);
    
    % Scan data
    function data = ScanData(file, data)
       
        fseek(file.name, file.data_address, 'bof');
        
        for i = 1:length(data.index)
            
            % Skip to scan data
            fseek(file.name, data.offset(i), 'cof');
            
            % Read profile size
            fseek(file.name, 4, 'cof');
            profile_size(i) = fread(file.name, 1, 'uint32', 0, 'l');
            peak_list_size(i) = fread(file.name, 1, 'uint32', 0, 'l');
            layout(i) = fread(file.name, 1, 'uint32', 0, 'l');
            descriptor_size(i) = fread(file.name, 1, 'uint32', 0, 'l');
            unknown_size(i) = fread(file.name, 1, 'uint32', 0, 'l');
            triplet_size(i) = fread(file.name, 1, 'uint32', 0, 'l');
            
            fseek(file.name, 4, 'cof');
            mlow(i) =  fread(file.name, 1, 'float32', 0, 'l');
            mhigh(i) =  fread(file.name, 1, 'float32', 0, 'l');
        end
    end
    
    data = ScanData(file, data);

    varargout{1} = data;
    
    fclose(file.name);
end