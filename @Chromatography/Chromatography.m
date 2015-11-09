% Class: Chromatography
%  -Methods for processing chromatography and mass spectrometry data
%
% Initialize
%   obj = Chromatography
%
% Methods
%
%   Import
%       data = obj.import(filetype, 'OptionName', optionvalue...)
%
%   Preprocessing
%       data = obj.centroid(data, 'OptionName', optionvalue...)
%       data = obj.baseline(data, 'OptionName', optionvalue...)
%       data = obj.smooth(data, 'OptionName', optionvalue...)
%
%   Integration
%       data = obj.integrate(data, 'OptionName', optionvalue...)
%
%   Visualization
%       fig = obj.visualize(data, 'OptionName', optionvalue...)
%

classdef Chromatography
    
    properties
        Defaults
    end
    
    properties (SetAccess = private)
        Options
        Diagnostics
    end
    
    methods
        
        % Initialize class
        function obj = Chromatography()

            % Initialize properties
            obj = defaults(obj);
            obj = options(obj);
            obj = diagnostics(obj);            
        end
        
        % Initialize default options
        function obj = defaults(obj, varargin)
           
            % Baseline
            obj.Defaults.baseline.smoothness = 1E6;
            obj.Defaults.baseline.asymmetry = 1E-4;
            
            % Smoothing
            obj.Defaults.smoothing.smoothness = 0.8;
            obj.Defaults.smoothing.asymmetry = 0.5;
            
            % Integration
            obj.Defaults.integrate.model = 'exponential gaussian hybrid';
            
            % Visualization
            obj.Defaults.visualize.position = [0.25, 0.25, 0.5, 0.5];
            obj.Defaults.visualize.colormap = 'parula';
            
        end
        
        % Initialize fixed options
        function obj = options(obj, varargin)
           
            % Import
            obj.Options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D',   'Agilent (*.D)';
                '.MS',  'Agilent (*.MS)';
                '.RAW', 'Thermo (*.RAW)'};
            
            % Export
            obj.Options.export = {...
                '.CSV', '(*.CSV)'};
        end
        
        % Initialize diagnostic information
        function obj = diagnostics(obj, varargin)
            
            % Diagnostics
            obj.Diagnostics.date = date;
            obj.Diagnostics.system_os = computer;
            obj.Diagnostics.matlab_version = version('-release');
            obj.Diagnostics.toolbox_version = '0.1.4';
        end
        
        % Restore data from backup values
        function data = reset(~, data, varargin)
           
            fprintf('\n[RESET]\n');
            
            if ~isstruct(data)
                fprintf('[ERROR] Input data must be of type ''struct''\n');
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
        
        % Restore data from backup values
        function data = remove(~, data, varargin)
           
            fprintf('\n[RESET]\n');
            
            if ~isstruct(data)
                fprintf('[ERROR] Input data must be of type ''struct''\n');
            end
            
            fprintf(['\nRemoving sample ''' num2str(numel(samples)), ''' from data...\n']);
            
            fprintf('\n[COMPLETE]\n\n');
        end
            
        % Create data structure
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
                    
                % Check for missing fields
                elseif ~isempty(~isfield(structure, fields))
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
    end
end