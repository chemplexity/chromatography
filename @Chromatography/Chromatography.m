% Class: Chromatography
%  -Data processing methods for liquid and gas chromatography
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
%       data = obj.baseline(data, 'OptionName', optionvalue...)
%       data = obj.smooth(data, 'OptionName', optionvalue...)
%
%   Integration
%       data = obj.integrate(data, 'OptionName', optionvalue...)
%
%   Visualization
%       fig = obj.visualize(data, 'OptionName', optionvalue...)

classdef Chromatography
    
    properties (SetAccess = private)
        options
    end
    
    methods
        
        % Constructor method
        function obj = Chromatography()
            
            % General informations
            obj.options.system_os = computer;
            obj.options.matlab_version = version('-release');
            obj.options.toolbox_version = '0.1.4';
            
            % Import options
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D',   'Agilent (*.D)';
                '.MS',  'Agilent (*.MS)';
                '.RAW', 'Thermo (*.RAW)'};
            
            % Export options
            obj.options.export = {...
                '.CSV', '(*.CSV)'};
            
            % Baseline options
            obj.options.baseline.smoothness = 1E6;
            obj.options.baseline.asymmetry = 1E-4;
            
            % Smoothing options
            obj.options.smoothing.smoothness = 5;
            obj.options.smoothing.asymmetry = 0.5;
            
            % Integration options
            obj.options.integration.model = 'exponential gaussian hybrid';
            
            % Visualization options
            obj.options.visualization.position = [0.25, 0.25, 0.5, 0.5];
        end
        
        function data = format(varargin)
            
            % Field names
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
                
                % Clear first line
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