classdef Chromatography
    % ---------------------------------------------------------------------
    % Class       : Chromatography
    % Description : Functions for chromatography and mass spectrometry data
    %
    % Version     : v0.1.6-dev
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
    %   obj.update
    %       Description : updates toolbox to latest version
    %       Syntax      : obj.update
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    properties (Constant = true)
        
        name        = 'Chromatography Toolbox';
        url         = 'https://github.com/chemplexity/chromatography';
        version     = 'v0.1.6.20170303';
        
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
            %   'gitpath' -- path to git executable
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
            %
            %   'reset' -- hard reset to match online repository
            %       false (default) | true
            %
            
            % ---------------------------------------
            % Defaults
            % ---------------------------------------
            default.gitpath = [];
            default.branch  = [];
            default.force   = false;
            default.verbose = true;
            default.reset   = false;
            
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
            
            addParameter(p, 'gitpath', default.gitpath, @ischar);
            addParameter(p, 'branch',  default.branch,  @ischar);
            addParameter(p, 'force',   default.force);
            addParameter(p, 'verbose', default.verbose);
            addParameter(p, 'reset',   default.reset);
            
            parse(p, varargin{:});
            
            % ---------------------------------------
            % Options
            % ---------------------------------------
            option.git     = p.Results.gitpath;
            option.branch  = p.Results.branch;
            option.force   = p.Results.force;
            option.verbose = p.Results.verbose;
            option.reset   = p.Results.reset;
            
            % ---------------------------------------
            % Validate
            % ---------------------------------------

            % Parameter: 'git'
            option.git = obj.validateFile(option.git);
            
            if ~isempty(option.git)
                
                [~, gitExe] = fileparts(option.git);
                
                if isempty(regexp(gitExe, 'git', 'match'))
                    option.git = 'git';
                end
                
            else
                option.git = 'git';
            end
            
            % Parameter: 'branch'
            validBranch = {'master', 'dev'};
            
            if ~isempty(option.branch) && ~any(strcmpi(option.branch, validBranch))
                option.branch = default.branch;
            end
            
            % Parameter: 'force'
            option.force = obj.validateLogical(option.force, default.force);
            
            % Parameter: 'verbose'
            obj.verbose = obj.validateLogical(option.verbose, default.verbose);
             
            % Parameter: 'reset'
            option.reset = obj.validateLogical(option.reset, default.reset);
            
            % ---------------------------------------
            % Project Path
            % ---------------------------------------
            obj.dispMsg('header', 'UPDATE');
            obj.dispMsg('version');
            obj.dispMsg('newline');
            obj.dispMsg('status', 'Checking online for updates...');
            
            sourceFile = fileparts(mfilename('fullpath'));
            [sourcePath, sourceFile] = fileparts(sourceFile);
            
            if ~strcmpi(sourceFile, '@Chromatography')
                sourcePath = [sourcePath, filesep, sourceFile];
            end
            
            userPath = pwd;
            cd(sourcePath);
            
            [gitStatus, ~] = system([option.git, ' --version']);
            
            if gitStatus
                option.git = [];
            end
            
            % ---------------------------------------
            % Windows
            % ---------------------------------------
            if ispc && isempty(option.git)
                
                [gitStatus, gitPath] = system('where git');
                
                if gitStatus
                    
                    obj.dispMsg('status', 'Searching system for ''git.exe''...');
                    
                    windowsGit = {...
                        '"C:\Program Files\Git\*git.exe"',...
                        '"C:\Program Files (x86)\Git\*git.exe"',...
                        '"C:\Users\*git.exe"'};
                    
                    for i = 1:length(windowsGit)
                        
                        [gitStatus, gitPath] = system(['dir ', windowsGit{i}, ' /S']);
                        
                        if ~gitStatus
                            option.git = gitPath;
                            break
                        end
                        
                    end
                    
                    if isempty(option.git)
                        
                        msg = ['Visit ', link.windows, ' to install Git for Windows...'];
                        
                        obj.dispMsg('status', 'Unable to find ''git.exe''...');
                        obj.dispMsg('status', msg);
                        obj.dispMsg('header', 'EXIT');
                        
                        cd(userPath);
                        return
                        
                    end
                    
                    gitPath = regexp(gitPath,'(?i)(?!of)\S[:]\\(\\|\w)*', 'match');
                    gitPath = [gitPath{1}, filesep, 'git.exe'];
                    
                end
                
                option.git = deblank(strtrim(gitPath));
                                
            % ---------------------------------------
            % Mac / Linux
            % ---------------------------------------
            elseif isunix && isempty(option.git)

                [gitStatus, gitPath] = system('which git');
                
                if gitStatus
                    
                    if ismac
                        msg = ['Visit ', link.mac, ' to install Git for OSX...'];
                    else
                        msg = ['Visit ', link.linux, ' to install Git for Linux...'];
                    end
                    
                    obj.dispMsg('status', 'Unable to find ''git'' executable...');
                    obj.dispMsg('status', msg);
                    obj.dispMsg('header', 'EXIT');
                    
                    cd(userPath);
                    return
                    
                end
                
                option.git = deblank(strtrim(gitPath));
                
            end
            
            if isempty(option.git)
                
                obj.dispMsg('status', 'Unable to find ''git'' executable...');
                obj.dispMsg('header', 'EXIT');
                
                cd(userPath);
                return
                
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
                
                cd(userPath);
                return
                
            end
            
            % ---------------------------------------
            % Check git repository
            % ---------------------------------------
            [gitInit, ~] = system(['"', option.git, '" status']);
            
            if gitInit
                
                obj.dispMsg('status', 'Initializing git repository...');

                [~,~] = system(['"', option.git, '" init']);
                [gitStatus,~] = system(['"', option.git, '" remote add origin ', obj.url, '.git']);
                
                if gitStatus
                    
                    try
                        rmdir('.git', 's');
                    catch
                    end
                    
                    obj.dispMsg('error', 'Unable to connect to online repository...');
                    obj.dispMsg('header', 'EXIT');
                    
                    cd(userPath);
                    return
                    
                end
                
                if option.force
                    [~,~] = system(['"', option.git, '" reset --hard origin/master']);
                else
                    [~,~] = system(['"', option.git, '" checkout master']);
                end
                
            end
            
            % ---------------------------------------
            % Fetch latest updates
            % ---------------------------------------
            obj.dispMsg('status', ['Fetching latest updates from ', obj.url]);

            [~,~] = system(['"', option.git, '" fetch origin']);
            
            [gitTest, gitBranch] = system(['"', option.git, '" rev-parse --abbrev-ref HEAD']);

            if ~gitTest && ischar(gitBranch)
                gitBranch = deblank(strtrim(gitBranch));
            end
            
            if ~isempty(gitBranch) && ~isempty(option.branch)
                if ~strcmpi(option.branch, gitBranch) && option.force
                    [~,~] = system(['"', option.git, '" checkout -f ', option.branch]);
                    
                elseif ~strcmpi(option.branch, gitBranch) && ~option.force
                    [~,~] = system(['"', option.git, '" checkout ', option.branch]);
                end
            end
            
            if option.reset
                [gitStatus,~] = system(['"', option.git, '" reset --hard @{upstream}']);
            elseif ~isempty(option.branch)
                [gitStatus,~] = system(['"', option.git, '" pull --rebase origin ', option.branch]);
            else
                [gitStatus,~] = system(['"', option.git, '" pull --rebase origin']);
            end
            
            pause(0.5);
            cd(userPath);
            
            if gitStatus
                obj.dispMsg('error', 'Error updating toolbox...');
                obj.dispMsg('header', 'EXIT');
                return
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