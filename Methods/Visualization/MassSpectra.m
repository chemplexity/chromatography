% Method: MassSpectra 
%  -Plots a mass spectra bar graph
%
% Syntax
%   MassSpectra(x, y, 'OptionName', optionvalue...)
%
% Options
%   'labels' : 'on', 'off'
%   'scale'  : 'relative', 'full'
%
% Description
%   x        : m/z values
%   y        : intensity values 
%   'labels' : text placed over local maxima m/z values -- (default: on)
%   'scale'  : display y-scale as relative intensity or total intensity -- (default: relative)
%
% Examples
%   MassSpectra(x, y)
%   MassSpectra(x, y, 'labels', 'off', 'scale', 'full')

function MassSpectra(x, y, varargin)

% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
elseif ~isnumeric(x)
    error('Undefined input arguments of type ''x''');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
else
    x = double(x);
    y = double(y);
end

% Check label options
if ~isempty(find(strcmpi(varargin, 'labels'),1))
    options.labels = varargin{find(strcmpi(varargin, 'labels'),1) + 1};
                    
    % Check user input
    if ~strcmpi(options.labels, 'on') || strcmpi(options.labels, 'off')
        options.labels = 'on';
    end
else
    options.labels = 'on';
end

% Check scale options
if ~isempty(find(strcmpi(varargin, 'scale'),1))
    options.scale = varargin{find(strcmpi(varargin, 'scale'),1) + 1};
                    
    % Check user input
    if strcmpi(options.scale, 'normalize') || strcmpi(options.scale, 'normalized')
        options.scale = 'relative';
    elseif ~strcmpi(options.scale, 'relative') || ~strcmpi(options.scale, 'full')
        options.scale = 'relative';
    end
else
    options.scale = 'relative';
end

% Check for relative scale
if strcmpi(options.scale, 'relative')
    y = (y - min(min(y))) / (max(max(y)) - min(min(y)));
    y = y*100;
end

% Initialize figure
options.figure = figure();

% Set figure properties
set(options.figure,...
    'Units', 'normalized',...
    'Position', [0.1, 0.1, 0.6, 0.55],...
    'Visible', 'on',...
    'Color', 'white');

% Set axes properties
options.axes = axes(...
    'Parent', options.figure,...
    'Units', 'Normalized',...
    'Color', [1,1,1],...
    'FontName', 'Lucida-Sans',...
    'FontSize', 12,...
    'FontWeight', 'demi',...
    'TickDir', 'out',...
    'XMinorTick', 'on',...
    'XColor', 'black',...
    'YColor', 'black',...
    'TickLength', [0.0075,0.001],...
    'LineWidth', 1.5,...
    'LooseInset', [0.05,0.05,0.05,0.05],...
    'NextPlot', 'replacechildren');

% Set x-axis label
xlabel(...
    'Mass (m/z)',...
    'FontName', 'Lucida-Sans',...
    'FontSize', 12);

% Set y-axis label
ylabel(...
    'Abundance (%)',...
    'FontName', 'Lucida-Sans',...
    'FontSize', 12);

% Set plot properties
options.plot = bar(x, y,... 
    'Parent', options.axes,...
    'barwidth', 0.75,...
    'edgecolor', 'white',...
    'facecolor', 'black');

% Set y-axis limits
ylim([0 - (0.025 * max(y)), max(y) + (0.05 * max(y))]);

% Set x-axis limits
set(options.axes, 'box', 'off',...
    'XLim', [50, 605]);

% Check label options
if strcmpi(options.labels, 'on')

    % Set variables
    resolution = (max(x) - min(x)) / length(x);
    window_size = floor(12 / resolution);
    steps = floor(length(x) / window_size);
    
    % Set minimum height
    ymin = 0.015 * max(y);

    % Find local maxima to label
    for i = 1:steps
    
        % Current index
        index_min = i * window_size - window_size + 1;
        index_max = index_min + window_size;
        
        % Find max intensity value
        [ymax, yindex] = max(y(1, index_min:index_max));
        
        % Correct yindex
        yindex = yindex + index_min - 1;
        
        % Check if value is above minimum
        if ymax > ymin
            
            % Add label
            text(x(1,yindex), y(1, yindex), num2str(x(1,yindex),4),...
                'HorizontalAlignment', 'center',...
                'VerticalAlignment','bottom',...
                'FontSize', 10,...
                'FontName', 'Lucida-Sans');   
        end
    end
end

% Delete ticks on top and right axes
set(options.axes, 'box', 'off', 'color', 'none')
    
% Create empty axes
a = axes('Position', get(options.axes,'Position'),...
    'box','on', ...
    'LineWidth', 1.5,...
    'xtick',[],...
    'ytick',[]);
 
% Set active axes
axes(options.axes);

% Link axes
linkaxes([options.axes, a]);
end