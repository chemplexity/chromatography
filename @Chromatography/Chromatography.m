% Class: Chromatography
%  -Data processing methods for liquid and gas chromatography
%
% Initialize
%   obj = Chromatography
%
% Methods
%   Import
%       data = obj.import(filetype, 'OptionName', optionvalue...)
%   
%   Baseline
%       data = obj.baseline(data, 'OptionName', optionvalue...)
%
%   Smooth
%       data = obj.smooth(data, 'OptionName', optionvalue...)
%
%   Integration
%       data = obj.integrate(data, 'OptionName', optionvalue...)
%
%   Visualize
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
            obj.options.toolbox_version = '0.1.2';

            % Import options
            obj.options.import = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D', 'Agilent (*.D)';
                '.MS', 'Agilent (*.MS)';
                '.RAW', 'Thermo (*.RAW)'};

            % Baseline options
            obj.options.baseline.smoothness = 10^6;
            obj.options.baseline.asymmetry = 10^-4;

            % Smoothing options
            obj.options.smoothing.smoothness = 50;
            obj.options.smoothing.asymmetry = 0.5;

            % Integration options
            obj.options.integration.model = 'exponential gaussian hybrid';

            % Visualization options
            obj.options.visualization.position = [0.25, 0.25, 0.5, 0.5];
        end
    end
end