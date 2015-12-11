% ------------------------------------------------------------------------
% Class       : Chromatography
% Description : Functions for chromatography and mass spectrometry data
% ------------------------------------------------------------------------
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
%       Syntax      : data = obj.import(filetype, Name, Value)
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

classdef Chromatography
    
    properties (Constant = true)
        
        version = '0.1.5';
        
    end
    
    properties
        
        defaults
        options
        
    end
    
    methods
        
        function obj = Chromatography()
            
            % Add dependencies to user path
            source = fileparts(which('Chromatography'));
            source = regexp(source, '.+(?=[@])', 'match');
            
            addpath(source{1});
            addpath(genpath([source{1}, 'Methods']));
            addpath(genpath([source{1}, 'Development']));
            addpath(genpath([source{1}, 'Examples']));
            
            % Default parameters
            obj.defaults.baseline_smoothness = 1E6;
            obj.defaults.baseline_asymmetry = 1E-4;
            
            obj.defaults.smoothing_smoothness = 0.5;
            obj.defaults.smoothing_asymmetry = 0.5;
            
            obj.defaults.integrate_model = 'exponential gaussian hybrid';
            
            obj.defaults.plot_position = [0.25, 0.25, 0.5, 0.5];
            
            if verLessThan('matlab', 'R2014b')
                obj.defaults.plot_colormap = 'jet';
            else
                obj.defaults.plot_colormap = 'parula';
            end
            
            % Options
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D',   'Agilent (*.D)';
                '.MS',  'Agilent (*.MS)';
                '.RAW', 'Thermo (*.RAW)'};
            
            obj.options.export = {...
                '.CSV', '(*.CSV)'};
        end
        
        % Restore data to original state
        function data = reset(~, data, varargin)
            
            fprintf('\n[RESET]\n');
            
            if ~isstruct(data)
                fprintf('[ERROR] Input data must be of type ''struct''\n');
                return
            end
            
            % Check user input
            input = @(x) find(strcmpi(varargin, x),1);
            
            if ~isempty(input('samples'))
                samples = varargin{input('samples')+1};
                
                % Set keywords
                samples_all = {'default', 'all'};
                
                % Check for valid input
                if any(strcmpi(samples, samples_all))
                    samples = 1:length(data);
                    
                elseif ~isnumeric(samples)
                    
                    % Check string input
                    samples = str2double(samples);
                    
                    % Check for numeric input
                    if ~any(isnan(samples))
                        samples = round(samples);
                    else
                        samples = 1:length(data);
                    end
                end
                
                % Check maximum input value
                if max(samples) > length(data)
                    samples = samples(samples <= length(data));
                end
                
                % Check minimum input value
                if min(samples < 1)
                    samples = samples(samples >= 1);
                end
                
            else
                samples = 1:length(data);
            end
            
            fprintf(['\nRestoring backup data for ' num2str(numel(samples)), ' samples...\n']);
            
            % Restore backup data
            for i = 1:length(samples)
                
                id = samples(i);
                
                data(id).time = data(id).backup.time;
                data(id).tic.values = data(id).backup.tic;
                data(id).xic.values = data(id).backup.xic;
                data(id).mz = data(id).backup.mz;
                
                data(id).tic.baseline = [];
                data(id).xic.baseline = [];
                
                data(id).status.centroid = 'N';
                data(id).status.smoothed = 'N';
                data(id).status.baseline = 'N';
                data(id).status.integrate = 'N';
            end
            
            fprintf('\n[COMPLETE]\n\n');
        end
        
        % Data Structure
        function data = format(varargin)
            
            % Top-level fields
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
            
            % Sub-level fields
            file = {...
                'path',...
                'name',...
                'bytes'};
            
            sample = {...
                'name',...
                'description',...
                'vial',...
                'replicate'};
            
            method = {...
                'name',...
                'operator',...
                'instrument',...
                'date',...
                'time'};
            
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
            
            % Check number of inputs
            if nargin < 2
                
                % Create an empty data structure
                data = cell2struct(cell(1,length(basic)), basic, 2);
                data(1) = [];
                
            elseif nargin >= 2
                
                % Check for validate options
                if ~isempty(find(strcmpi(varargin, 'validate'),1))
                    data = varargin{find(strcmpi(varargin, 'validate'),1)+1};
                else
                    return
                end
                
                % Check basic fields
                data = check(data, basic);
                
                % Check nested fields
                for i = 1:length(data)
                    
                    % General information
                    data(i).file = check(data(i).file, file);
                    data(i).sample = check(data(i).sample, sample);
                    data(i).method = check(data(i).method, method);
                    
                    % Total ion chromatograms
                    data(i).tic = check(data(i).tic, tic);
                    data(i).tic.peaks = check(data(i).tic.peaks, peaks);
                    
                    % Extracted ion chromatograms
                    data(i).xic = check(data(i).xic, xic);
                    data(i).xic.peaks = check(data(i).xic.peaks, peaks);
                    
                    % Supporting infomation
                    data(i).backup = check(data(i).backup, backup);
                    data(i).status = check(data(i).status, status);
                end
                
                % Check for extra fields
                if ~isempty(find(strcmpi(varargin, 'extra'),1))
                    extra = varargin{find(strcmpi(varargin, 'extra'),1)+1};
                    
                    % Add MS2 field
                    if strcmpi(extra, 'ms2')
                        data = check(data, {'ms2'});
                    end
                end
            end
            
            
            % Validate structure
            function structure = check(structure, fields)
                
                % Check structure input
                if ~isstruct(structure)
                    structure = [];
                end
                
                % Check fields input
                if ~iscell(fields)
                    return
                end
                
                % Check for empty structure
                if isempty(structure)
                    structure = cell2struct(cell(1,length(fields)), fields, 2);
                    
                elseif ~isempty(~isfield(structure, fields))
                    
                    % Check for missing fields
                    missing = fields(~isfield(structure, fields));
                    
                    % Add missing peak fields to structure
                    if ~isempty(missing)
                    
                        for j = 1:length(missing)
                            structure = setfield(structure, {1}, missing{j}, []);
                        end 
                    end
                end
            end
        end

        % Update Chromatography Toolbox
        function update(varargin)
            
            url = 'https://github.com/chemplexity/chromatography';
            
            fprintf('\n\n');
            fprintf('[UPDATE] \n\n');
            
            % Root toolbox path
            source = fileparts(which('Chromatography'));
            source = regexp(source, '.+(?=[@])', 'match');
            
            % Error: toolbox not on path
            if isempty(source)
                fprintf('Unable to find Chromatography Toolbox on path... \n\n');
                fprintf('[EXIT] \n');
                return
            else
                fprintf('Updating Chromatography Toolbox.... \n');
                cd(source{1});
            end
            
            % Windows
            if ispc
                
                % Check system for git
                [status, output] = system('where git');
                
                if ~status
                    git = regexp(output,'(?i)C:\\(\\|\w)*', 'match');
                    git = [git{1}, '.exe'];
                
                % Error: git command not on path
                elseif status
                    fprintf('Unable to find ''git.exe'' on path... \n');
                    fprintf('Searching system for ''git.exe''... \n');
                    
                    % Attempt to find git.exe
                    [status, output] = system('dir C:\Users\*git.exe /s');
                    
                    % Error: git.exe not found
                    if status
                        fprintf('Unable to find ''git.exe''... \n');
                        fprintf('[ABORT] \n');
                        return
                    end
                    
                    git = regexp(output,'(?i)(?!of)C:\\(\\|\w)*', 'match');
                    git = [git{1}, '\git.exe'];
                end
                
                % Grant folder access
                [~, ~] = system(['icacls "', source{1}, '\" /grant Users:(OI)(CI)F']);
                
            % Unix
            elseif isunix
                
                % Check system for git
                [status, output] = system('which git');
                
                if ~status
                    git = regexp(output,'(?i)([/]|\w)+git', 'match');
                    git = git{1};
                
                % Error: git command not on path
                elseif status
                    fprintf('Unable to find ''git''... \n');
                    fprintf('[ABORT] \n');
                    return
                end
                
            end
                    
            % Check git --version
            fprintf(['Using ''', '%s', '''... \n'], git);
            [status, ~] = system([git, ' --version']);
                    
            % Error: git.exe does not work
            if status
                fprintf('Error executing ''git --version''... \n');
                fprintf('[ABORT] \n');
                return
            end
            
            % Check git --status
            [status, ~] = system([git, ' status']);
            
            % Download latest updates
            if ~status
                fprintf('Fetching updates from ''%s''... \n\n', url);
                system([git, ' fetch -v']);
               
            % Error: not a git repository
            elseif status
                fprintf('Initializing git repository... \n');
                
                % Initialize git repository
                [~,~] = system([git, ' init']);
                [~,~] = system([git, ' remote add origin ', url, '.git']);
                
                fprintf('Fetching updates from ''%s''... \n\n', url);
                system([git, ' fetch -v']);
                [~,~] = system([git, ' checkout -f master']);
            end
            
            % Check input
            if nargin > 0 && ischar(varargin{1})
                switch varargin{1}
                    case {'master'}
                        system([git, ' checkout -f master']);                        
                    case {'release'}
                        system([git, ' checkout -f release/v0.1.5']);
                    case {'dev', 'development'}
                        system([git, ' checkout -f dev']);
                end
            end
            
            fprintf('\n Update complete... \n\n');
            fprintf(['Version: ', Chromatography.version, '\n\n']);
            fprintf('[EXIT] \n');
        end
    end
end