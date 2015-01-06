% Class: Chromatography
%  -Graphical user interface for processing chromatography data
%
% Initialize
%   GUI();

classdef GUI < handle

    properties
        figure
        menu
        axes
    end
    
    properties (SetAccess = private)
        functions
        options
    end

    methods
       
        % Constructor method
        function obj = GUI()

            % Functions
            obj.functions = Chromatography;
            
            % Options
            obj = settings(obj);

            % User interface
            obj = setup(obj);
        end
    end
    
    methods (Access = private)
        
    end
end
