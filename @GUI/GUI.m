% Class: Chromatography
%  -Graphical user interface for processing chromatography data
%
% Initialize
%   GUI();

classdef GUI < handle

    properties
        
        % Frontend
        figure
        menu
        axes
        
        % Backend
        functions
        data
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
        end
        
        % Load data       
        function obj = load(obj, varargin)
            
            % Determine filetype
            filetype = get(varargin{1,1}, 'label');
            
            % Import data
            obj.data = obj.functions.import(filetype, obj.data, 'progress', 'off');
            
            % Initialize GUI data
            if ~isfield(obj.axes, 'data')
                obj.axes.data = [];
                obj.axes.index = [];
                obj.axes.options = [];
            end
            
            % Initialize GUI components
            obj = obj.tables('initialize.files');
            obj = obj.listbox('initialize.samples');
            obj = obj.listbox('initialize.ions');
            
            % Initialize GUI plots
            obj = obj.plots('initialize.all');
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
            
            % Listbox - Select Data
            set(obj.figure.listbox.samples, 'callback', {@obj.listbox, 'update.samples'});
            set(obj.figure.listbox.ions, 'callback', {@obj.listbox, 'update.ions'});
            
            % Checkbox - View Options
            set(obj.figure.checkbox.stacked, 'callback', {@obj.plots, 'options.stacked'});
            set(obj.figure.checkbox.normalized, 'callback', {@obj.plots, 'options.normalized'});
        end
    end
end
