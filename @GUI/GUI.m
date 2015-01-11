% Class: Chromatography
%  -Graphical user interface for processing chromatography data
%
% Initialize
%   GUI();

classdef GUI < handle

    properties
        data
    end
    
    properties (SetAccess = private)
        
        % Frontend
        figure
        axes
        menu
        
        % Backend
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
            obj = listbox(obj);
        end
        
        % Load data       
        function obj = load(obj, varargin)
            
            % Determine filetype
            filetype = get(varargin{1,1}, 'label');
            
            % Import data
            obj.data = obj.functions.import(filetype, obj.data, 'progress', 'off');
            
            % Update GUI components
            obj = tables(obj, 'update.files');
            obj = listbox(obj, 'update.samples');
            obj = listbox(obj, 'update.ions');
            
            % Initialize GUI plots
            if ~isfield(obj.axes, 'data')
                obj.axes.data = [];
                obj.axes.options = [];
                obj.plots(obj, 'initialize.all');
            end
        end
    end
    
    methods (Access = private)
        
        % Set GUI callbacks
        function obj = callbacks(obj, varargin)
        
            % Menu - File --> Load --> Agilent
            set(obj.menu.agilent{1,2}, 'callback', @obj.load);
            set(obj.menu.agilent{1,3}, 'callback', @obj.load);
            
            % Menu - File --> Load --> netCDF
            set(obj.menu.netcdf{1,2}, 'callback', @obj.load); 
            
            % Checkbox - View Options
            set(obj.figure.checkbox.stacked, 'callback', {@obj.plots, 'options.stacked'});
            set(obj.figure.checkbox.normalized, 'callback', {@obj.plots, 'options.normalized'});
        end
    end
end
