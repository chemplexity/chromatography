% Class: Chromatography
%  -Graphical user interface for processing chromatography data
%
% Initialize
%   GUI();

classdef GUI < handle

    properties
        axes
        data
    end
    
    properties (SetAccess = private)
        figure
        menu
        functions
        options
    end

    methods
       
        % Constructor method
        function obj = GUI()

            % Data
            obj.data = [];
            
            % Functions
            obj.functions = Chromatography;
            
            % Options
            obj = settings(obj);

            % GUI
            obj = setup(obj);
            obj = callbacks(obj);
            
            % Update
            obj = tables(obj);
        end
        
        % Load data       
        function obj = load(obj, varargin)
            
            % Determine filetype
            filetype = get(varargin{1,1}, 'label');
            
            % Import data
            obj.data = obj.functions.import(filetype, obj.data, 'progress', 'off');
            
            % Update user interface
            obj = tables(obj, 'update.files');
            obj = listbox(obj, 'update.samples');
            obj = listbox(obj, 'update.ions');
        end
    end
    
    methods (Access = private)
        
        % Set GUI callbacks
        function obj = callbacks(obj, varargin)
        
            % File --> Load --> Agilent
            set(obj.menu.agilent{1,2}, 'callback', @obj.load);
            set(obj.menu.agilent{1,3}, 'callback', @obj.load);
            
            % File --> Load --> netCDF
            set(obj.menu.netcdf{1,2}, 'callback', @obj.load);      
            
        end
    end
end
