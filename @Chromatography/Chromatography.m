classdef Chromatography
    % ---------------------------------------------------------------------
    % Class       : Chromatography
    % Description : Functions for chromatography and mass spectrometry data
    %
    % Version     : v0.1.6-20170928
    % Website     : https://github.com/chemplexity/chromatography
    %----------------------------------------------------------------------
    %
    % ---------------------------------------------------------------------
    % Syntax
    % ---------------------------------------------------------------------
    %   obj = Chromatography;
    %
    % ---------------------------------------------------------------------
    % Methods
    % ---------------------------------------------------------------------
    %   obj.import
    %       Description : import instrument data files
    %       Syntax      : data = obj.import(Name, Value)
    %
    %   obj.centroid
    %       Description : centroid mass values
    %       Syntax      : data = obj.centroid(data, Name, Value)
    %
    %   obj.baseline
    %       Description : calculate baseline for chromatogram
    %       Syntax      : data = obj.baseline(data, Name, Value)
    %
    %   obj.smooth
    %       Description : smooth chromatogram
    %       Syntax      : data = obj.smooth(data, Name, Value)
    %
    %   obj.integrate
    %       Description : find and integrate peaks in chromatogram
    %       Syntax      : data = obj.integrate(data, Name, Value)
    %
    %   obj.visualize
    %       Description : plot chromatogram or mass spectra
    %       Syntax      : fig = obj.visualize(data, Name, Value)
    %
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    properties (Constant = true)
        
        name        = 'Chromatography Toolbox';
        url         = 'https://github.com/chemplexity/chromatography';
        version     = 'v0.1.6.20170928';
        
        platform    = Chromatography.getPlatform();
        environment = Chromatography.getEnvironment();
        
    end
    
    properties
        
        defaults
        options
        
    end
    
    properties (Access = private)
        
        verbose = true;
        
    end
    
    % ---------------------------------------
    % Methods
    % ---------------------------------------
    methods
        
        % ---------------------------------------
        % Initialization
        % ---------------------------------------
        function obj = Chromatography()
            
            % ---------------------------------------
            % Path
            % ---------------------------------------
            sourceFile = fileparts(mfilename('fullpath'));
            [sourcePath, sourceFile] = fileparts(sourceFile);
            
            if ~strcmpi(sourceFile, '@Chromatography')
                sourcePath = [sourcePath, filesep, sourceFile];
            end
            
            addpath(sourcePath);
            addpath(genpath([sourcePath, filesep, 'examples']));
            addpath(genpath([sourcePath, filesep, 'src']));
            addpath(genpath([sourcePath, filesep, 'tests']));
            
            % ---------------------------------------
            % Defaults
            % --------------------------------------
            obj.defaults.smoothing_smoothness = 0.5;
            obj.defaults.smoothing_asymmetry  = 0.5;
            obj.defaults.integrate_model      = 'emg';
            obj.defaults.plot_position        = [0.25, 0.25, 0.5, 0.5];
            
            if verLessThan('matlab', 'R2014b')
                obj.defaults.plot_colormap = 'jet';
            else
                obj.defaults.plot_colormap = 'parula';
            end
            
            % ---------------------------------------
            % Options
            % ---------------------------------------
            obj.options.import = {...
                '.D',   'Agilent (*.D)';
                '.MS',  'Agilent (*.MS)';
                '.CH',  'Agilent (*.CH)';
                '.CDF', 'netCDF (*.CDF, *.NC)';
                '.MSP', 'NIST (*.MSP)';
                '.RAW', 'Thermo (*.RAW)'};
            
            obj.options.export = {...
                '.CSV', '(*.CSV)'};
            
        end
        
        % ---------------------------------------
        % Schema
        % ---------------------------------------
        function data = format(varargin)
            
            basic = {...
                'id',...
                'name',...
                'file',...
                'sample',...
                'method',...
                'time',...
                'tic',...
                'xic',...
                'mz',...
                'backup',...
                'status'};
            
            file = {...
                'path',...
                'name',...
                'bytes'};
            
            sample = {...
                'name',...
                'info',...
                'sequence',...
                'vial',...
                'replicate'};
            
            method = {...
                'name',...
                'operator',...
                'instrument',...
                'datetime'};
            
            tic = {...
                'values',...
                'baseline',...
                'peaks'};
            
            xic = {...
                'values',...
                'baseline',...
                'peaks'};
            
            peaks = {...
                'time',...
                'height',...
                'width',...
                'area',...
                'fit',...
                'error'};
            
            backup = {...
                'time',...
                'tic',...
                'xic',...
                'mz'};
            
            status = {...
                'version',...
                'centroid',...
                'baseline',...
                'smoothed',...
                'integrate'};
            
            % ---------------------------------------
            % Parse input
            % ---------------------------------------
            if nargin < 2
                
                data = cell2struct(cell(1,length(basic)), basic, 2);
                data(1) = [];
                
            elseif nargin >= 2
                
                if ~isempty(find(strcmpi(varargin, 'validate'),1))
                    data = varargin{find(strcmpi(varargin, 'validate'),1)+1};
                else
                    return
                end
                
                data = check(data, basic);
                
                for i = 1:length(data)
                    data(i).file      = check(data(i).file, file);
                    data(i).sample    = check(data(i).sample, sample);
                    data(i).method    = check(data(i).method, method);
                    data(i).tic       = check(data(i).tic, tic);
                    data(i).tic.peaks = check(data(i).tic.peaks, peaks);
                    data(i).xic       = check(data(i).xic, xic);
                    data(i).xic.peaks = check(data(i).xic.peaks, peaks);
                    data(i).backup    = check(data(i).backup, backup);
                    data(i).status    = check(data(i).status, status);
                end
                
                if ~isempty(find(strcmpi(varargin, 'extra'),1))
                    
                    extra = varargin{find(strcmpi(varargin, 'extra'),1)+1};
                    
                    if strcmpi(extra, 'ms2')
                        data = check(data, {'ms2'});
                    end
                    
                end
            end
            
            % ---------------------------------------
            % Check data structure
            % ---------------------------------------
            function structure = check(structure, fields)
                
                % Check input types
                if ~isstruct(structure)
                    structure = [];
                end
                
                if ~iscell(fields)
                    return
                end
                
                % Check input values
                if isempty(structure)
                    structure = cell2struct(cell(1,length(fields)), fields, 2);
                    
                elseif ~isempty(~isfield(structure, fields))
                    
                    % Check for missing fields
                    missing = fields(~isfield(structure, fields));
                    
                    % Add missing field to structure
                    if ~isempty(missing)
                        
                        for j = 1:length(missing)
                            structure = setfield(structure, {1}, missing{j}, []);
                        end
                        
                    end
                end
            end
        end
        
    end
    
    % ---------------------------------------
    % Methods (private)
    % ---------------------------------------
    methods (Access = private)
        
        function dispMsg(obj, varargin)
            
            if ~obj.verbose
                return
            end
            
            switch varargin{1}
                
                case 'header'
                    fprintf(['\n', repmat('-',1,50), '\n']);
                    fprintf(' %s', varargin{2});
                    fprintf(['\n', repmat('-',1,50), '\n\n']);
                    
                case 'counter'
                    m = num2str(varargin{2});
                    n = num2str(varargin{3});
                    m = [repmat('0', 1, length(n)-length(m)), m];
                    fprintf([' [', m, '/', n, ']']);
                    
                case 'status'
                    fprintf(' STATUS  %s \n', varargin{2});
                    
                case 'error'
                    fprintf(2, ' ERROR  ');
                    fprintf('%s \n', varargin{2});
                    
                case 'sample'
                    fprintf([' Sample #', num2str(varargin{2})]);
                    
                case 'channel'
                    if varargin{3} == 1
                        n = '1 channel';
                    else
                        n = [num2str(varargin{3}), ' channels'];
                    end
                    fprintf([', ', upper(varargin{2}), ' (', n, ')\n']);
                    
                case 'version'
                    fprintf(' Chromatography Toolbox v');
                    fprintf('%s \n', Chromatography.version);
                    
                case 'newline'
                    fprintf('\n');
                    
                case 'string'
                    fprintf('%s', varargin{2});
                    
                case 'bytes'
                    fprintf('%s', Chromatography.parseFileSize(varargin{2}));
                    
                case 'time'
                    fprintf('%s', Chromatography.parseElapsedTime(varargin{2}));
                    
            end
            
        end
        
    end
    
    % ---------------------------------------
    % Methods (static)
    % ---------------------------------------
    methods (Static = true)
        
        
        function x = getPlatform()
            x = computer;
        end
        
        function x = getEnvironment()
            
            if ~isempty(ver('MATLAB'))
                x = ver('MATLAB');
                x = ['MATLAB ', x.Release];
            elseif ~isempty(ver('OCTAVE'))
                x = 'OCTAVE';
            else
                x = 'UNKNOWN';
            end
            
        end
        
        function x = parseFileSize(x)
            
            if x > 1E9
                x = [num2str(x/1E9, '%.1f'), ' GB'];
            elseif x > 1E6
                x = [num2str(x/1E6, '%.1f'), ' MB'];
            elseif x > 1E3
                x = [num2str(x/1E3, '%.1f'), ' KB'];
            else
                x = [num2str(x/1E3, '%.3f'), ' KB'];
            end
            
        end
        
        function x = parseElapsedTime(x)
            
            if x > 60
                x = [num2str(x/60, '%.1f'), ' min'];
            else
                x = [num2str(x, '%.1f'), ' sec'];
            end
            
        end
        
        function x = validateFile(x)
            
            if isempty(x) || ~ischar(x)
                x = [];
                return
            else
                [~, x] = fileattrib(x);
            end
            
            if isstruct(x)
                x = x.Name;
            else
                x = [];
            end
            
        end
        
        function x = validateLogical(x, default)
            
            isTrue  = {'on',  't', 'true',  'y', 'yes', '1'};
            isFalse = {'off', 'f', 'false', 'n', 'no',  '0'};
            
            if ischar(x) && any(strcmpi(x, isTrue))
                x = true;
            elseif ischar(x) && any(strcmpi(x, isFalse))
                x = false;
            elseif isnumeric(x) && x == 1
                x = true;
            elseif isnumeric(x) && x == 0
                x = false;
            elseif ~islogical(x)
                x = default;
            end
            
        end
        
        function x = validateSample(x, n)
            
            if n == 0
                return
            end
            
            if ischar(x) && strcmpi(x, 'all')
                x = 1:n;
            elseif ischar(x)
                x = str2double(x);
            end
            
            if isnumeric(x)
                x = unique(round(x));
                x(x > n | x < 1 | isnan(x)) = [];
            end
            
        end
        
        function x = validateChannel(x, n)
            
            if n == 0
                x = 0;
            end
            
            if ischar(x) && strcmpi(x, 'tic')
                x = repmat({1}, length(n), 1);
            elseif ischar(x) && strcmpi(x, 'all')
                x = arrayfun(@(x) repmat({1:x}, 1, 1), n);
            end
            
            if isnumeric(x)
                x = unique(round(x));
                x = repmat({x}, length(n), 1);
            end
            
            for i = 1:length(n)
                x{i}(x{i} > n(i) | x{i} < 1 | isnan(x{i})) = [];
            end
            
        end
        
    end
    
end