% Class: Chromatography
%  -Data processing methods for liquid and gas chromatography
%
% Initialize
%   obj = Chromatography
%
% Methods
%   Import
%       data = obj.import(filetype, 'OptionName', OptionValue...)
%   
%   Baseline
%       data = obj.baseline(data, 'OptionName', OptionValue...)
%
%   Integration
%       data = obj.integrate(data, 'OptionName', OptionValue...)
%
%   Visualize
%       obj.visualize(data, 'OptionName', OptionValue...)

classdef Chromatography

    properties (SetAccess = private)
        options
    end
    
    methods
        
        % Constructor method
        function obj = Chromatography()
           
            % General informations
            obj.options.system_os = computer;
            obj.options.matlab_version = version;
            obj.options.toolbox_version = '1.0';
            
            % Import options
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D', 'Agilent (*.D)';
                '.MS', 'Agilent (*.MS)'};
            
            % Baseline options
            obj.options.baseline.smoothness = 10^6;
            obj.options.baseline.asymmetry = 10^-6;
            
            % Integration options
            obj.options.integration.model = 'exponential gaussian hybrid';
            
            % Visualization options
            obj.options.visualization.position = [0.1, 0.4, 0.4, 0.4];
        end
    end
end