% Method: MassSpectra 
%  -Plots a mass spectra histogram
%
% Syntax
%   MassSpectra(x, y, 'OptionName', optionvalue...)
%
% Input
%   x        : array
%   y        : array or matrix
%
% Options
%   'labels' : 'on', 'off'
%   'scale'  : 'relative', 'full'
%   'export' : see MATLAB documentation on print functions
%
% Description
%   x        : m/z values
%   y        : intensity values
%   'labels' : text placed over local maxima m/z values -- (default: on)
%   'scale'  : display y-scale as relative intensity or total intensity -- (default: relative)
%   'export' : cell array passed the MATLAB print function -- (default: none)
%
% Examples
%   MassSpectra(x, y)
%   MassSpectra(x, y, 'labels', 'off', 'scale', 'full')
%   MassSpectra(x, y 'export', {'myspectra', '-dtiffn', '-r300'})

function varargout = MassSpectra(x, y, varargin)

% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
elseif ~isnumeric(x)
    error('Undefined input arguments of type ''x''');
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''');
elseif length(x(:,1)) > 1 && length(x(1,:)) > 1
    error('Undefined input arguments of type ''x''');
elseif length(x(:,1)) ~= length(y(:,1)) && length(x(1,:)) ~= length(y(1,:))
    error('Input arguments of unequal length');
end

% Check input precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check for matrix
if length(y(:,1)) > 1 && length(y(1,:)) > 1
    
    % Sum intensity values across the m/z dimension
    if length(x(:,1)) > length(x(1,:))
        y = sum(y,2);
    elseif length(x(:,1)) < length(x(1,:))
        y = sum(y,1);
    elseif length(x(:,1)) == length(x(1,:))
        error('Undefined input arguments of type ''x''');
    end
end 

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check label options
if ~isempty(input('labels'))
    options.labels = varargin{input('labels') + 1};
                    
    % Check for valid input
    if ~ischar(options.labels) || ~strcmpi(options.labels, 'off')
        options.labels = 'on';
    end
else
    options.labels = 'on';
end

% Check scale options
if ~isempty(input('scale'))
    options.scale = varargin{input('scale') + 1};
                    
    % Check for valid input
    if ~ischar(options.scale)
        options.scale = 'relative';
    elseif strcmpi(options.scale, 'normalize') || strcmpi(options.scale, 'normalized')
        options.scale = 'relative';
    elseif ~strcmpi(options.scale, 'relative') && ~strcmpi(options.scale, 'full')
        options.scale = 'relative';
    end
else
    options.scale = 'relative';
end

% Check export options
if ~isempty(input('export'))
    options.export = varargin{input('export') + 1};
      
    % Check for valid input
    if ischar(options.export) && strcmpi(options.export, 'on')
        options.export = {'spectra', '-dpng', '-r300'};
    elseif ~iscell(options.export) && ~strcmpi(options.export, 'on')
        options.export = 'off';
    end
else
    options.export = 'off';
end
    
% Check for normalization
if strcmpi(options.scale, 'relative')
    y = (y - min(min(y))) ./ (max(max(y)) - min(min(y)));
    y = y * 100;
    
    % Set y-axis label
    options.ylabel = 'Abundance (%)';
else
    options.ylabel = 'Intensity';
end

% Set global options
options.font.name = 'Avenir';
options.font.size = 14;
options.line.color = [0.23,0.23,0.23];
options.line.width = 1.25;
options.bar.width = 5;
options.ticks.size = [0.007, 0.0075];

% Initialize figure
options.figure = figure(...
    'units', 'normalized',...
    'position', [(1-0.55)/2, 0.2, 0.6, 0.55],...
    'color', 'white',...
    'paperpositionmode', 'auto',...
    'papertype', 'a2');

% Initialize axes
options.axes = axes(...
    'parent', options.figure,...
    'units', 'normalized',...
    'color', options.line.color,...
    'fontname', options.font.name,...
    'fontsize', options.font.size-1,...
    'tickdir', 'out',...
    'xminortick', 'on',...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'ticklength', options.ticks.size,...
    'linewidth', options.line.width,...
    'looseinset', [0.075,0.12,0.05,0.05],...
    'nextplot', 'replacechildren');

% Set axis labels
options.xlabel = xlabel('Mass (m/z)');
options.ylabel = ylabel(options.ylabel);

% Set label style
set(options.xlabel, 'fontname', options.font.name, 'fontsize', options.font.size);
set(options.ylabel, 'fontname', options.font.name, 'fontsize', options.font.size);

% Initialize plot
options.plot = bar(x, y,...
    'parent', options.axes,...
    'barwidth', options.bar.width, ...
    'linestyle', 'none',...
    'edgecolor', [0,0,0.4], ...
    'facecolor', [0.05,0.05,0.05]);

% Set y-axis limits
ylim([0 - (max(y) * 0), max(y) + (0.05 * max(y))]);

% Determine x-axis limits
xmin = floor(min(x) - min(x) * 0.05);
xmax = floor(max(x) + max(x) * 0.05);

% Set x-axis limits
set(options.axes, 'box', 'on', 'xlim', [xmin, xmax]);

% Update label positions
set(options.xlabel, 'units', 'normalized');
set(options.ylabel, 'units', 'normalized');
set(options.xlabel, 'position', get(options.xlabel, 'position') - [0,0.0,0]);
set(options.ylabel, 'position', get(options.ylabel, 'position') - [0.0,0,0]);

% Check label options
if strcmpi(options.labels, 'on')

    % Set variables
    resolution = (max(x) - min(x)) / length(x);
    bin = floor(12 / resolution);
    steps = floor(length(x) / bin);
    
    % Check for valid data
    if bin < 1 || isinf(bin)
        bin = floor(length(x) / 2);
    end
    if steps < 1 || isinf(steps)
        if bin > length(x)
            steps = floor(bin/length(x));
        else
            steps = floor(length(x)/bin);
        end
    end
    
    % Set minimum height to label
    ymin = 0.015 * max(y);

    % Determine local maxima to label
    for i = 1:steps
    
        % Current index
        index_min = i * bin - bin + 1;
        index_max = index_min + bin;
        
        % Determine local maxima
        [ymax, yindex] = max(y(1, index_min:index_max));
        yindex = yindex + index_min - 1;
        
        % Check threshold
        if ymax > ymin
            
            % Add label
            text(x(1,yindex), y(1, yindex), num2str(x(1,yindex),4),...
                'horizontalalignment', 'center',...
                'verticalalignment','bottom',...
                'fontsize', options.font.size-3.5,...
                'fontname', options.font.name);   
        end
    end
end

% Create empty axes
options.box = axes('position', get(options.axes, 'position'), 'box','on', 'linewidth', options.line.width);

% Set x-axis tick labels
set(options.axes, 'box', 'off', 'color', 'none')
set(options.axes,'xticklabelmode','auto')
set(options.box, 'xtick',[], 'ytick',[]);

% Set resize callback
set(options.figure, 'sizechangedfcn', @(varargin) set(options.box, 'position', get(options.axes,'position')));

% Link axes
axes(options.axes);
linkaxes([options.axes, options.box]);

% Export figure
if iscell(options.export)
    try
        disp('Rendering image, please wait...');
        print(options.figure, options.export{:});
        disp('Rendering complete!');
    catch
        disp('-Error reading print options, rendering image with default options...');
        print(options.figure, 'spectra', '-dpng', '-r300');
        disp('Rendering complete!');
    end
end

% Set output
varargout{1} = options;

end
