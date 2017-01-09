classdef Chromatography
    % ------------------------------------------------------------------------
    % Class       : Chromatography
    % Description : Functions for chromatography and mass spectrometry data
    %
    % Version     : 0.1.6-dev
    % Website     : https://github.com/chemplexity/chromatography
    %------------------------------------------------------------------------
    %
    % ------------------------------------------------------------------------
    % Syntax
    % ------------------------------------------------------------------------
    %   obj = Chromatography;
    %
    % ------------------------------------------------------------------------
    % Methods
    % ------------------------------------------------------------------------
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
    %   obj.update
    %       Description : updates toolbox to latest version
    %       Syntax      : obj.update
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    properties (Constant = true)
        
        url     = 'https://github.com/chemplexity/chromatography';
        version = '0.1.6-dev';
        
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
            source = fileparts(mfilename('fullpath'));
            source = regexp(source, '.+(?=[@])', 'match');
            
            addpath(source{1});
            addpath(genpath([source{1}, 'examples']));
            addpath(genpath([source{1}, 'src']));
            addpath(genpath([source{1}, 'tests']));
            
            % ---------------------------------------
            % Defaults
            % --------------------------------------
            obj.defaults.baseline_smoothness  = 1E6;
            obj.defaults.baseline_asymmetry   = 1E-4;
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
                '.CDF', 'netCDF (*.CDF)';
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
        
        function update(obj, varargin)
            % ------------------------------------------------------------
            % Method      : Chromatography.update
            % Description : Update toolbox to latest version
            % ------------------------------------------------------------
            %
            % ------------------------------------------------------------
            % Syntax
            % ------------------------------------------------------------
            %    Chromatography.update()
            %    Chromatography.update(Name, Value)
            %
            % ------------------------------------------------------------
            % Input (Name, Value)
            % ------------------------------------------------------------
            %   'git' -- path to git executable
            %       empty (default) | string
            %
            %   'branch' -- select branch to checkout
            %       empty (default) | 'master' | 'dev'
            %
            %   'force' -- force update and throwaway local changes
            %       false (default) | true
            %
            %   'verbose' -- show progress in command window
            %       true (default) | false
            
            % ---------------------------------------
            % Defaults
            % ---------------------------------------
            default.git     = [];
            default.branch  = [];
            default.force   = false;
            default.verbose = true;
            
            % ---------------------------------------
            % Variables
            % ---------------------------------------
            link.windows = 'https://git-scm.com/download/windows';
            link.mac     = 'https://git-scm.com/download/mac';
            link.linux   = 'https://git-scm.com/download/linux';
            
            % ---------------------------------------
            % Input
            % ---------------------------------------
            p = inputParser;
            
            addParameter(p, 'git',     default.git,    @ischar);
            addParameter(p, 'branch',  default.branch, @ischar);
            addParameter(p, 'force',   default.force);
            addParameter(p, 'verbose', default.verbose);
            
            parse(p, varargin{:});
            
            % ---------------------------------------
            % Options
            % ---------------------------------------
            option.git     = p.Results.git;
            option.branch  = p.Results.branch;
            option.force   = p.Results.force;
            option.verbose = p.Results.verbose;
            
            % ---------------------------------------
            % Validate
            % ---------------------------------------

            % Parameter: 'git'
            option.git = Chromatography.validateFile(option.git);
            
            % Parameter: 'branch'
            validBranch = {'master', 'dev'};
            
            if ~isempty(option.branch) && ~any(strcmpi(option.branch, validBranch))
                option.branch = [];
            end
            
            % Parameter: 'force'
            option.force = Chromatography.validateLogical(option.force, default.force);
            
            % Parameter: 'verbose'
            obj.verbose = Chromatography.validateLogical(option.verbose, default.verbose);
             
            % ---------------------------------------
            % Path
            % ---------------------------------------
            obj.dispMsg('header', 'UPDATE');
            obj.dispMsg('version');
            obj.dispMsg('newline');
            obj.dispMsg('status', 'Checking online for updates...');
            
            sourcePath = fileparts(mfilename('fullpath'));
            sourcePath = regexp(sourcePath, '.+(?=[@])', 'match');
            
            cd(sourcePath{1});
            
            % ---------------------------------------
            % Windows
            % ---------------------------------------
            if ispc && isempty(option.git)
                
                [gitStatus, gitPath] = system('where git');
                
                if gitStatus

                    obj.dispMsg('status', 'Searching system for ''git.exe''...');
                    
                    [gitStatus, gitPath] = system('dir C:\Users\*git.exe /s');
                    
                    if gitStatus
                        
                        msg = ['Visit ', link.windows, ' to and install Git for Windows...'];
                        
                        obj.dispMsg('status', 'Unable to find ''git.exe''...');
                        obj.dispMsg('status', msg);
                        obj.dispMsg('header', 'EXIT');
                        
                        return
                        
                    end
                    
                    gitPath = regexp(gitPath,'(?i)(?!of)\S[:]\\(\\|\w)*', 'match');
                    gitPath = [gitPath{1}, filesep, 'git.exe'];
                    
                end
                
                option.git = deblank(strtrim(gitPath));
                                
            % ---------------------------------------
            % Unix
            % ---------------------------------------
            elseif isunix && isempty(option.git)

                [gitStatus, gitPath] = system('which git');
                
                if gitStatus
                    
                    if ismac
                        msg = ['Visit ', link.mac, ' to and install Git for OSX...'];
                    else
                        msg = ['Visit ', link.linux, ' to and install Git for Linux...'];
                    end
                    
                    obj.dispMsg('status', 'Unable to find ''git'' executable...');
                    obj.dispMsg('status', msg);
                    obj.dispMsg('header', 'EXIT');
                    
                    return
                    
                end
                
                option.git = deblank(strtrim(gitPath));
                
            end
            
            obj.dispMsg('status', ['Using ', option.git, '...']);
            
            % ---------------------------------------
            % Check permissions
            % ---------------------------------------
            if ispc
                [~, ~] = system(['icacls "', option.git, '\" /grant Users:(OI)(CI)F']);
            end
            
            % ---------------------------------------
            % Check system git
            % ---------------------------------------
            [gitTest, ~] = system(['"', option.git, '" --version']);
            
            if gitTest
                
                obj.dispMsg('error', 'Error executing ''git --version''...');
                obj.dispMsg('header', 'EXIT');
                
                return
                
            end
            
            % ---------------------------------------
            % Check git repository
            % ---------------------------------------
            [gitTest, ~] = system(['"', option.git, '" status']);
            
            if gitTest
                
                obj.dispMsg('status', 'Initializing git repository...');

                [~,~] = system(['"', git, '" init']);
                [~,~] = system(['"', git, '" remote add origin ', obj.url, '.git']);
                
            end
            
            % ---------------------------------------
            % Fetch latest updates
            % ---------------------------------------
            obj.dispMsg('status', ['Fetching latest updates from ', obj.url]);

            [~,~] = system(['"', option.git, '" pull']);
            
            if gitTest

                if option.force
                    gitCmd = '" checkout -f master';
                else
                    gitCmd = '" checkout master';
                end
                
                [~,~] = system(['"', option.git, gitCmd]);
                
            end
            
            % ---------------------------------------
            % Checkout branch
            % ---------------------------------------
            if ~isempty(option.branch)
                
                if option.force
                    gitCmd = ['" checkout -f ', option.branch];
                else
                    gitCmd = ['" checkout ', option.branch];
                end
                
                [~,~] = system(['"', option.git, gitCmd]);
                
            end
        
            % ---------------------------------------
            % Status
            % ---------------------------------------
            obj.dispMsg('status', 'Update complete!');
            obj.dispMsg('newline');
            obj.dispMsg('version');
            obj.dispMsg('header', 'EXIT');
            
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
                    fprintf(2, '\n ERROR  ');
                    fprintf('%s \n\n', varargin{2});
                    
                case 'version'
                    fprintf(' Chromatography Toolbox v');
                    fprintf('%s \n', obj.version);
                    
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
            
            if ismac()
                x = 'mac';
            elseif isunix()
                x = 'linux';
            elseif ispc()
                x = 'windows';
            else
                x = 'unknown';
            end
            
        end
        
        function x = getEnvironment()
            
            if ~isempty(ver('MATLAB'))
                x = 'matlab';
            elseif ~isempty(ver('OCTAVE'))
                x = 'octave';
            else
                x = 'unknown';
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
        
    end
    
end