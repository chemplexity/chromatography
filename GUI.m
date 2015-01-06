classdef GUI < handle

    properties
        uifigure
        uiaxes
    end
    
    properties (SetAccess = private)
        functions
        options
        diagnostics
    end

    methods
       
        % Constructor method
        function obj = GUI()
            
            % User interface
            obj.uifigure = [];
            obj.uiaxes = [];
            
            % Functions
            obj.functions = Chromatography;
            
            % Options
            obj.options = [];
            obj.diagnostics = []; 
            
            % Initialize GUI
            obj = SetUIProperties(obj);
            obj = ConstructUIFigure(obj);
        end
        
        % Construct user interface
        function obj = SetUIProperties(obj, varargin)
            
            % Determine system information
            obj.diagnostics.os = computer;
            obj.diagnostics.matlab_version = version('-release');
            obj.diagnostics.gui_version = 1.0;
            
            % Determine screen information
            obj.diagnostics.screensize = get(0, 'ScreenSize');
            obj.diagnostics.screenresolution = get(0, 'ScreenPixelsPerInch');
            
            % Add class folders to the current path
            path([fileparts(which('GUI.m')), filesep, '@Chromatography'], path);
            
            % Temporary options
            backgroundcolor = [0.96, 0.96, 0.96];
            fontsize = 10;
            
            % Set figure defaults
            set(0, ...
                'DefaultFigureColor', [0.99, 0.99, 0.99],...
                'DefaultFigureDockControls', 'off',...
                'DefaultFigureMenuBar', 'none',...
                'DefaultFigureNumberTitle', 'off',...
                'DefaultFigureRenderer', 'opengl',...
                'DefaultFigureResize', 'on',...
                'DefaultFigureUnits', 'pixels');
            
            % Set table defaults
            set(0, ...
                'DefaultUITableBackgroundColor', [0.98, 0.98, 0.98; 0.92, 0.92, 0.92],...
                'DefaultUITableFontName', 'SansSerif',...
                'DefaultUITableFontSize', fontsize,...
                'DefaultUITableFontUnits', 'points',...
                'DefaultUITableFontWeight', 'light',...
                'DefaultUITableForegroundColor', [0.0, 0.0, 0.0],...
                'DefaultUITableRearrangeableColumns', 'off',...
                'DefaultUITableRowName', [],...
                'DefaultUITableRowStriping', 'on',...
                'DefaultUITableUnits', 'normalized');
            
            % Set axes defaults
            set(0, ...
                'DefaultAxesBox', 'on',...
                'DefaultAxesColor', [1.0, 1.0, 1.0],...
                'DefaultAxesDrawMode', 'fast',...
                'DefaultAxesFontName', 'Helvetica',...
                'DefaultAxesFontSize', fontsize,...
                'DefaultAxesFontUnits', 'points',...
                'DefaultAxesFontWeight', 'normal',...
                'DefaultAxesLayer', 'top',...
                'DefaultAxesLineWidth', 2.5,...
                'DefaultAxesNextPlot', 'add',...
                'DefaultAxesTickDir', 'out',...
                'DefaultAxesTickLength', [0.0015, 0.0005],...
                'DefaultAxesUnits', 'normalized',...
                'DefaultAxesXColor', [0.1, 0.1, 0.1],...
                'DefaultAxesYColor', [0.1, 0.1, 0.1],...
                'DefaultAxesZColor', [0.6, 0.6, 0.6],...
                'DefaultAxesXGrid', 'off',...
                'DefaultAxesXLimMode', 'manual',...
                'DefaultAxesYLimMode', 'manual',...
                'DefaultAxesZLimMode', 'manual',...
                'DefaultAxesXTickMode', 'auto',...
                'DefaultAxesXTickLabelMode', 'auto',...
                'DefaultAxesYTick', [],...
                'DefaultAxesYTickLabel', [],...
                'DefaultAxesYTickLabelMode', 'manual',...
                'DefaultAxesZTick', [],...
                'DefaultAxesZTickLabel', [],...
                'DefaultAxesZTickLabelMode', 'manual');
                
            % Set control defaults
            set(0, ...
                'DefaultUIControlBackgroundColor', backgroundcolor,...
                'DefaultUIControlFontName', 'SansSerif',...
                'DefaultUIControlFontSize', fontsize,...
                'DefaultUIControlFontUnits', 'points',...
                'DefaultUIControlFontWeight', 'light',...
                'DefaultUIControlForegroundColor', [0.0, 0.0, 0.0],...
                'DefaultUIControlHorizontalAlignment', 'center',...
                'DefaultUIControlUnits', 'normalized');
            
            % Set panel defaults
            set(0, ...
                'DefaultUIPanelBackgroundColor', backgroundcolor,...
                'DefaultUIPanelBorderType', 'line',...
                'DefaultUIPanelBorderWidth', 2.5,...
                'DefaultUIPanelFontName', 'SansSerif',...
                'DefaultUIPanelFontSize', fontsize,...
                'DefaultUIPanelFontUnits', 'points',...
                'DefaultUIPanelFontWeight', 'normal',...
                'DefaultUIPanelForegroundColor', [0.0, 0.0, 0.0],...
                'DefaultUIPanelHighlightColor', [0.0, 0.0, 0.0],...
                'DefaultUIPanelUnits', 'normalized');
            
            warning off all
        end
        
        % Construct figure
        function obj = ConstructUIFigure(obj, varargin)
 
            % Create anonymous functions
            set_position = @(x,y) set(x, 'Position', y);
        
            % Calculate figure position
            figure_width = 0.8 * (obj.diagnostics.screensize(3) - (obj.diagnostics.screensize(3) - (1.618 * obj.diagnostics.screensize(4))));
            figure_height = 0.8 * obj.diagnostics.screensize(4);
            figure_left = (obj.diagnostics.screensize(3) - figure_width) / 2;
            figure_bottom = (obj.diagnostics.screensize(4) - figure_height) / 2;
            figure_position = [figure_left, figure_bottom, figure_width, figure_height];

            % Create figure
            obj.uifigure.figure = figure('Name', 'TEXPRESS Toolbox v1.0', 'Position', figure_position);
            
            % Create menus
            obj.uifigure.menu{1,1} = uimenu(obj.uifigure.figure, 'Label', 'File');
            obj.uifigure.menu{1,2} = uimenu(obj.uifigure.menu{1,1}, 'Label', 'Load');
            obj.uifigure.menu{2,2} = uimenu(obj.uifigure.menu{1,2}, 'Label', '.D', 'Callback', @obj.ImportData);
            obj.uifigure.menu{3,2} = uimenu(obj.uifigure.menu{1,2}, 'Label', '.MS', 'Callback', @obj.ImportData);
            obj.uifigure.menu{4,2} = uimenu(obj.uifigure.menu{1,2}, 'Label', '.CDF', 'Callback', @obj.ImportData);
            
            % Create panels
            obj.uifigure.panels{1} = uipanel(obj.uifigure.figure);%, 'Position', [0.01, 0.61, 0.37, 0.37]);
            obj.uifigure.panels{2} = uipanel(obj.uifigure.figure);%, 'Position', [0.01, 0.02, 0.37, 0.57]);
            obj.uifigure.panels{3} = uipanel(obj.uifigure.figure);%, 'Position', [0.39, 0.02, 0.6, 0.96]); 
            
            set_position(obj.uifigure.panels{1}, [0.01,0.61,0.37,0.37]);
            set_position(obj.uifigure.panels{2}, [0.01,0.02,0.37,0.57]);
            set_position(obj.uifigure.panels{3}, [0.39,0.02,0.6,0.96]);
            
            % Create tabs
            obj.uifigure.tabs{1,1} = uitabgroup(obj.uifigure.panels{1});
            obj.uifigure.tabs{2,1} = uitab(obj.uifigure.tabs{1,1}, 'Title', 'Files');
            obj.uifigure.tabs{3,1} = uitab(obj.uifigure.tabs{1,1}, 'Title', 'Options');
            obj.uifigure.tabs{1,2} = uitabgroup(obj.uifigure.panels{2});
            obj.uifigure.tabs{2,2} = uitab(obj.uifigure.tabs{1,2}, 'Title', 'View');
            obj.uifigure.tabs{1,3} = uitabgroup(obj.uifigure.panels{3});
            obj.uifigure.tabs{2,3} = uitab(obj.uifigure.tabs{1,3}, 'Title', 'TIC');
            obj.uifigure.tabs{3,3} = uitab(obj.uifigure.tabs{1,3}, 'Title', 'SIM');
            
            % Create tables
            obj.uifigure.table{1} = uitable(obj.uifigure.tabs{2,1}, 'Position', [0.02,0.02, 0.96, 0.96], 'CellEditCallback', @obj.EditTable);
            
            % Create listboxes
            obj.uifigure.listbox{1} = uicontrol(obj.uifigure.tabs{2,2}, 'Style', 'List', 'Position', [0.02, 0.45, 0.47, 0.53], 'Callback', @obj.EditListbox);
            obj.uifigure.listbox{2} = uicontrol(obj.uifigure.tabs{2,2}, 'Style', 'List', 'Position', [0.51, 0.45, 0.47, 0.53], 'Callback', @obj.EditListbox);
        
            % Create axes
            obj.uiaxes.axes{1} = axes('Parent', obj.uifigure.tabs{2,3}, 'Position', [0.05, 0.09, 0.9, 0.875]);
            obj.uiaxes.axes{2} = axes('Parent', obj.uifigure.tabs{3,3}, 'Position', [0.05, 0.09, 0.9, 0.875]);
            
            set(get(obj.uiaxes.axes{1}, 'XLabel'), 'String', 'Time (min)', 'FontSize', 11);
            set(get(obj.uiaxes.axes{2}, 'XLabel'), 'String', 'Time (min)', 'FontSize', 11);
            
            % Create button containers
            obj.uifigure.panels{4} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.02, 0.02, 0.3066, 0.41], 'Title', 'X-Axis');
            obj.uifigure.panels{5} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.3466, 0.02, 0.3066, 0.41], 'Title', 'Y-Axis');
            %obj.uifigure.panels{6} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.6732, 0.02, 0.3066, 0.41], 'Title', 'Offset');
            
            % Create sliders
            obj.uifigure.slider{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);
            obj.uifigure.slider{2} = uicontrol(obj.uifigure.panels{5}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);
            obj.uifigure.slider{3} = uicontrol(obj.uifigure.panels{5}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);
            
            % Determine slider positions
            set(obj.uifigure.panels{4}, 'Units', 'pixels');
            position = get(obj.uifigure.panels{4}, 'position');
            set(obj.uifigure.panels{4}, 'Units', 'normalized');
            
            slider_position = @(x,y,z) set(x, 'Position', [y(3)*z(1), y(4)*z(2), y(3)*z(3), y(4)*z(4)]);
            slider_position(obj.uifigure.slider{1}, position, [0.06,0.03,0.85,0.1]);
            slider_position(obj.uifigure.slider{2}, position, [0.78,0.17,0.11,0.7]);
            slider_position(obj.uifigure.slider{3}, position, [0.62,0.17,0.11,0.7]);
            
            % Create checkboxes
            obj.uifigure.checkbox{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'checkbox', 'Position', [0.05, 0.775, 0.7, 0.125], 'String', 'Overlay', 'FontSize', 9, 'Value', 0);
            obj.uifigure.checkbox{2} = uicontrol(obj.uifigure.panels{5}, 'Style', 'checkbox', 'Position', [0.05, 0.775, 0.7, 0.125], 'String', 'Normalize', 'FontSize', 9, 'Value', 1);
            obj.uifigure.checkbox{3} = uicontrol(obj.uifigure.panels{5}, 'Style', 'checkbox', 'Position', [0.05, 0.61, 0.7, 0.125], 'String', 'Overlay', 'FontSize', 9, 'Value', 0);

            % Create static text
            %obj.uifigure.text{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'text', 'Position', [0.02, 0.05, 0.6, 0.1], 'String', 'Zoom:', 'FontSize', 9);
            %obj.uifigure.text{2} = uicontrol(obj.uifigure.panels{6}, 'Style', 'text', 'Position', [0.02, 0.05, 0.6, 0.1], 'String', 'Offset:', 'FontSize', 9);
            
            % Create textbox
            %obj.uifigure.edittext{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'edit', 'Position', [0.73, 0.02, 0.23, 0.13], 'String', '100', 'FontSize', 9);
            %obj.uifigure.edittext{2} = uicontrol(obj.uifigure.panels{6}, 'Style', 'edit', 'Position', [0.73, 0.02, 0.23, 0.13], 'String', '100', 'FontSize', 9);
            %obj.uifigure.edittext{3} = uicontrol(obj.uifigure.panels{5}, 'Style', 'edit', 'Position', [0.65, 0.58, 0.23, 0.13], 'FontSize', 9);
            %obj.uifigure.edittext{4} = uicontrol(obj.uifigure.panels{5}, 'Style', 'edit', 'Position', [0.65, 0.4, 0.23, 0.13], 'FontSize', 9);
            %obj.uifigure.edittext{5} = uicontrol(obj.uifigure.panels{5}, 'Style', 'edit', 'Position', [0.65, 0.22, 0.23, 0.13], 'FontSize', 9);
            
            % Align objects
            %align([obj.uifigure.text{1}, obj.uifigure.edittext{1}, obj.uifigure.text{3}], 'None', 'Middle');
            %align([obj.uifigure.text{2}, obj.uifigure.edittext{2}, obj.uifigure.text{4}], 'None', 'Middle');
            
            %Set resize callback
            set(obj.uifigure.figure, 'ResizeFcn', @obj.ResizeFigure);
        end
    end
end
