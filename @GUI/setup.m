% Method: setup
%  -Constructs the basic components of the user interface

function obj = setup(obj, varargin)

    % Figure
    function obj = set_figure(obj, varargin)
        
        % Variables
        screensize = obj.options.screensize;

        % Calculate figure position
        figure_position(3) = 0.9 * (screensize(3) - (screensize(3) - (1.618 * screensize(4))));
        figure_position(4) = 0.75 * screensize(4);
        figure_position(1) = (screensize(3) - figure_position(3)) / 2;
        figure_position(2) = (screensize(4) - figure_position(4)) / 2;
 
        % Create figure
        obj.figure.figure = figure('Name', '', 'Position', figure_position);
    end


    % Menus
    function obj = set_menu(obj, varargin)
 
        % File
        obj.menu.file = uimenu(obj.figure.figure, 'Label', 'File');
            
        % File --> Load
        obj.menu.load = uimenu(obj.menu.file, 'Label', 'Load');
            
        % File --> Load --> Agilent 
        obj.menu.agilent{1} = uimenu(obj.menu.load, 'Label', 'Agilent');
        obj.menu.agilent{2} = uimenu(obj.menu.agilent{1}, 'Label', '.D');
        obj.menu.agilent{3} = uimenu(obj.menu.agilent{1}, 'Label', '.MS');

        % File --> Load --> netCDF
        obj.menu.netcdf{1} = uimenu(obj.menu.load, 'Label', 'netCDF');
        obj.menu.netcdf{2} = uimenu(obj.menu.netcdf{1}, 'Label', '.CDF');
    end


    % Panels
    function obj = set_panels(obj, varargin)

        % Create panels
        obj.figure.panels{1} = uipanel(obj.figure.figure, 'Position', [0.01,0.61,0.37,0.37]);
        obj.figure.panels{2} = uipanel(obj.figure.figure, 'Position', [0.01,0.02,0.37,0.57]);
        obj.figure.panels{3} = uipanel(obj.figure.figure, 'Position', [0.39,0.02,0.60,0.96]);
    end
    

    % Tabs
    function obj = set_tabs(obj, varargin)
    
        % Main tabs
        obj.figure.tabs.main{1} = uitabgroup(obj.figure.panels{1});
        obj.figure.tabs.main{2} = uitab(obj.figure.tabs.main{1}, 'Title', 'File');
        obj.figure.tabs.main{3} = uitab(obj.figure.tabs.main{1}, 'Title', 'Options');

        % Option tabs
        obj.figure.tabs.options{1} = uitabgroup(obj.figure.panels{2});
        obj.figure.tabs.options{2} = uitab(obj.figure.tabs.options{1}, 'Title', 'Display');
        obj.figure.tabs.options{3} = uitab(obj.figure.tabs.options{1}, 'Title', 'Baseline');
        obj.figure.tabs.options{4} = uitab(obj.figure.tabs.options{1}, 'Title', 'Integration');

        % Axes tabs
        obj.figure.tabs.axes{1} = uitabgroup(obj.figure.panels{3});
        obj.figure.tabs.axes{2} = uitab(obj.figure.tabs.axes{1}, 'Title', 'TIC');
        obj.figure.tabs.axes{3} = uitab(obj.figure.tabs.axes{1}, 'Title', 'SIM');
    end


    % Tables
    function obj = set_tables(obj, varargin)

        % Create tables
        obj.figure.tables.files = uitable(obj.figure.tabs.main{2}, 'Position', [0.02,0.02, 0.96, 0.96]);
    end
     

    % Listboxes
    function obj = set_listboxes(obj, varargin)

        % Create listboxes
        obj.figure.listbox.samples = uicontrol(obj.figure.tabs.options{2}, 'Style', 'List', 'Position', [0.02, 0.45, 0.47, 0.53]);
        obj.figure.listbox.ions = uicontrol(obj.figure.tabs.options{2}, 'Style', 'List', 'Position', [0.51, 0.45, 0.47, 0.53]);
    end
      

    % Axes
    function obj = set_axes(obj, varargin)
    
        % Create axes
        obj.axes.tic = axes('Parent', obj.figure.tabs.axes{2}, 'Position', [0.05, 0.09, 0.9, 0.875]);
        obj.axes.sim = axes('Parent', obj.figure.tabs.axes{3}, 'Position', [0.05, 0.09, 0.9, 0.875]);
        
        % X-Axis
        set(get(obj.axes.tic, 'XLabel'), 'String', 'Time (min)', 'FontSize', 11);
        set(get(obj.axes.sim, 'XLabel'), 'String', 'Time (min)', 'FontSize', 11);
    end


% Construct user interface
obj = set_figure(obj);
obj = set_menu(obj);
obj = set_panels(obj);
obj = set_tabs(obj);
obj = set_tables(obj);
obj = set_listboxes(obj);
obj = set_axes(obj);

% Create button containers
%obj.uifigure.panels{4} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.02, 0.02, 0.3066, 0.41], 'Title', 'X-Axis');
%obj.uifigure.panels{5} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.3466, 0.02, 0.3066, 0.41], 'Title', 'Y-Axis');
%obj.uifigure.panels{6} = uipanel(obj.uifigure.tabs{2,2}, 'Position', [0.6732, 0.02, 0.3066, 0.41], 'Title', 'Offset');
            
% Create sliders
%obj.uifigure.slider{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);
%obj.uifigure.slider{2} = uicontrol(obj.uifigure.panels{5}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);
%obj.uifigure.slider{3} = uicontrol(obj.uifigure.panels{5}, 'Style', 'slider', 'Units', 'Pixels', 'BackgroundColor', [0.99, 0.99, 0.99]);

% Determine slider positions
%set(obj.uifigure.panels{4}, 'Units', 'pixels');
%position = get(obj.uifigure.panels{4}, 'position');
%set(obj.uifigure.panels{4}, 'Units', 'normalized');

%slider_position = @(x,y,z) set(x, 'Position', [y(3)*z(1), y(4)*z(2), y(3)*z(3), y(4)*z(4)]);
%slider_position(obj.uifigure.slider{1}, position, [0.06,0.03,0.85,0.1]);
%slider_position(obj.uifigure.slider{2}, position, [0.78,0.17,0.11,0.7]);
%slider_position(obj.uifigure.slider{3}, position, [0.62,0.17,0.11,0.7]);

% Create checkboxes
%obj.uifigure.checkbox{1} = uicontrol(obj.uifigure.panels{4}, 'Style', 'checkbox', 'Position', [0.05, 0.775, 0.7, 0.125], 'String', 'Overlay', 'FontSize', 9, 'Value', 0);
%obj.uifigure.checkbox{2} = uicontrol(obj.uifigure.panels{5}, 'Style', 'checkbox', 'Position', [0.05, 0.775, 0.7, 0.125], 'String', 'Normalize', 'FontSize', 9, 'Value', 1);
%obj.uifigure.checkbox{3} = uicontrol(obj.uifigure.panels{5}, 'Style', 'checkbox', 'Position', [0.05, 0.61, 0.7, 0.125], 'String', 'Overlay', 'FontSize', 9, 'Value', 0);

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

end
