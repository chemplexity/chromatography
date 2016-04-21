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
    
    
    % ---------------------------------------
    % Properties
    % ---------------------------------------
    properties (Constant = true)
        
        url = 'https://github.com/chemplexity/chromatography';
        version = '0.1.51';

    end
    
    properties
        
        defaults
        options
        
    end
    
    
    % ---------------------------------------
    % Methods
    % ---------------------------------------
    methods
        
        
        % ---------------------------------------
        % Initialization
        % ---------------------------------------
        function obj = Chromatography()
            
            source = fileparts(which('Chromatography'));
            source = regexp(source, '.+(?=[@])', 'match');            
            
            % ---------------------------------------
            % Path
            % ---------------------------------------
            addpath(source{1});
            addpath(genpath([source{1}, 'Methods']));
            addpath(genpath([source{1}, 'Development']));
            addpath(genpath([source{1}, 'Examples']));
            
            % ---------------------------------------
            % Defaults
            % ---------------------------------------
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
            
            % ---------------------------------------
            % Options
            % ---------------------------------------
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D',   'Agilent (*.D)';
                '.MS',  'Agilent (*.MS)';
                '.RAW', 'Thermo (*.RAW)'};
            
            obj.options.export = {...
                '.CSV', '(*.CSV)'};
        end
        
        
        % ---------------------------------------
        % Reset
        % ---------------------------------------
        function data = reset(~, data, varargin)
            
            fprintf('\n\n[RESET]\n\n');
            
            if ~isstruct(data)
                fprintf('[ERROR] Input data must be of type ''struct''\n');
                return
            end
            
            % ---------------------------------------
            % Parse input
            % ---------------------------------------
            input = @(x) find(strcmpi(varargin, x),1);

            % Option: 'samples'
            if ~isempty(input('samples'))
                samples = varargin{input('samples')+1};
                
                % Input: 'default', 'all'
                if any(strcmpi(samples, {'default', 'all'}))
                    samples = 1:length(data);
                    
                % Input: numeric
                elseif ~isnumeric(samples)
                    samples = str2double(samples);
                    
                    % Check for numeric input
                    if ~any(isnan(samples))
                        samples = round(samples);
                    else
                        samples = 1:length(data);
                    end
                    
                    % Check input limits
                    samples = samples(samples <= length(data));
                    samples = samples(samples >= 1);
                end
                
            else    

                % Default: 'all'
                samples = 1:length(data);
            end
            
            % ---------------------------------------
            % Restore data to original values
            % ---------------------------------------
            fprintf(['Resetting ' num2str(numel(samples)), ' files...\n']);
            
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
                'description',...
                'sequence',...
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
            
            % ---------------------------------------
            % Parse input
            % ---------------------------------------
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
                
                data = check(data, basic);
                
                for i = 1:length(data)
                    
                    % Metadata
                    data(i).file = check(data(i).file, file);
                    data(i).sample = check(data(i).sample, sample);
                    data(i).method = check(data(i).method, method);
                    
                    % Instrument data
                    data(i).tic = check(data(i).tic, tic);
                    data(i).tic.peaks = check(data(i).tic.peaks, peaks);
                    
                    data(i).xic = check(data(i).xic, xic);
                    data(i).xic.peaks = check(data(i).xic.peaks, peaks);
                    
                    % Supplemental data
                    data(i).backup = check(data(i).backup, backup);
                    data(i).status = check(data(i).status, status);
                end
                
                % Extended data
                if ~isempty(find(strcmpi(varargin, 'extra'),1))
                    extra = varargin{find(strcmpi(varargin, 'extra'),1)+1};
                    
                    % Add MS^2 field
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

        % ---------------------------------------
        % Update
        % ---------------------------------------
        function update(varargin)
            
            fprintf('\n\n[UPDATE]\n\n');
            
            source = fileparts(which('Chromatography'));
            source = regexp(source, '.+(?=[@])', 'match');
            
            % ---------------------------------------
            % Path
            % ---------------------------------------
            if ~isempty(source)
                fprintf('Updating Chromatography Toolbox.... \n');
                cd(source{1});
            else
                fprintf('Chromatography Toolbox not on search path...\n\n');
                fprintf('[EXIT]\n');
                return
            end
            
            % ---------------------------------------
            % Windows
            % ---------------------------------------
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
                    
                    % Error: git.exe not foun
                    if status
                        fprintf('Unable to update without ''git.exe'' \n');
                        fprintf('[ABORT] \n');
                        return
                    end
                    
                    git = regexp(output,'(?i)(?!of)C:\\(\\|\w)*', 'match');
                    git = [git{1}, '\git.exe'];
                end
                
                % Update folder access
                [~, ~] = system(['icacls "', source{1}, '\" /grant Users:(OI)(CI)F']);
                
            % ---------------------------------------
            % Unix
            % ---------------------------------------
            elseif isunix
                
                % Check system for git
                [status, output] = system('which git');
                
                if ~status
                    git = regexp(output,'(?i)([/]|\w)+git', 'match');
                    git = git{1};
                
                % Error: git command not on path
                elseif status
                    fprintf('Unable to update without ''git''... \n');
                    fprintf('[ABORT] \n');
                    return
                end
                
            end
                    
            % ---------------------------------------
            % Check system git
            % ---------------------------------------
            fprintf(['Using ''', '%s', '''... \n'], git);
            [status, ~] = system([git, ' --version']);
                    
            % Error: git.exe does not work
            if status
                fprintf('Error executing ''git --version''... \n');
                fprintf('[ABORT] \n');
                return
            end
            
            % ---------------------------------------
            % Check git repository
            % ---------------------------------------
            [status, ~] = system([git, ' status']);
            
            if status
                fprintf('Initializing git repository... \n');
                
                % Initialize git repository
                [~,~] = system([git, ' init']);
                [~,~] = system([git, ' remote add origin ', Chromatography.url, '.git']);
            end
            
            % ---------------------------------------
            % Fetch latest updates
            % ---------------------------------------
            fprintf('Fetching updates from ''%s''... \n\n', Chromatography.url);
            system([git, ' fetch -v']);
               
            if status
                [~,~] = system([git, ' checkout -f master']);
            end
            
            % ---------------------------------------
            % Checkout branch
            % ---------------------------------------
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
            
            fprintf('\nUpdate complete... \n\n');
            fprintf(['Version: ', Chromatography.version, '\n\n']);
            fprintf('[COMPLETE] \n');
        end
    end
end