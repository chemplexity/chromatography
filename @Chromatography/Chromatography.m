% Class: Chromatography
%  -Data processing methods for liquid and gas chromatography
%
% Initialize
%   obj = Chromatography
%
% Import
%   obj.import(filetype, 'OptionName', OptionValue...)
%   
% Baseline
%   obj.baseline(data, 'OptionName', OptionValue...)
%
% Integration
%   obj.integrate(data, 'OptionName', OptionValue...)
%
% Visualize
%   obj.visualize(data, 'OptionName', OptionValue...)

classdef Chromatography

    properties (SetAccess = private)
        options
    end
    
    methods
        
        % Constructor method
        function obj = Chromatography()
           
            % Import options
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D', 'Agilent (*.D)';
                '.MS', 'Agilent (*.MS)'};
            
            % Baseline options
            obj.options.baseline.smoothness = 10^6;
            obj.options.baseline.asymmetry = 10^-6;
            
            % Integration options
            obj.options.integration.type = 'exponential gaussian';
            
            % Visualization options
            obj.options.visualization.position = [0.1, 0.4, 0.4, 0.4];
        end

        % Import method
        data = import(obj, varargin);
        
        % Baseline method
        data = baseline(obj, varargin);
        
        % Integration method
        data = integrate(obj, varargin);
        
        % Visualize method
        visualize(obj, varargin);
    end
end