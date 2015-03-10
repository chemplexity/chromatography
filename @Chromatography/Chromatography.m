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
        Data
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
            obj.Defaults.smoothing.smoothness = 5;
            obj.Defaults.smoothing.asymmetry = 0.5;
            
            % Integration
            obj.Defaults.integrate.model = 'exponential gaussian hybrid';
            
            % Visualization
            obj.Defaults.visualize.position = [0.25, 0.25, 0.5, 0.5];
            
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
            obj.Diagnostics.system_os = computer;
            obj.Diagnostics.matlab_version = version('-release');
            obj.Diagnostics.toolbox_version = '0.1.4';
        end
        
        
        % Core data structure
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
                'mz'};
            
            % Sub-level fields
            file = {...
                'name',...
                'type'};
            
            sample = {...
                'name'};
            
            method = {...
                'name',...
                'instrument',...
                'date',...
                'time'};
            
            tic = {...
                'values',...
                'baseline',...
                'peaks',...
                'backup'};
            
            xic = {...
                'values',...
                'baseline',...
                'peaks',...
                'backup'};
            
            peaks = {...
                'time',...
                'height',...
                'width',...
                'area',...
                'fit',...
                'error'};
            
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