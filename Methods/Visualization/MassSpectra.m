% Method: MassSpectra 
%  -Plot a mass spectra histogram
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
%   MassSpectra(x, y 'export', {'myspectra', '-dtiff', '-r300'})

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
elseif length(x(:,1)) == length(y(1,:)) && length(x(1,:)) == length(y(:,1))
    x = x';
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

% Check input dimension
if length(x(:,1)) > length(x(1,:))
    x = x';
    y = y';
end

% Check for matrix
if length(y(:,1)) > 1 && length(y(1,:)) > 1
    
    % Sum intensity values across the m/z dimension
    if length(x(:,1)) > length(x(1,:))
        y = sum(y,2);
    elseif length(x(:,1)) < length(x(1,:))
        y = sum(y,1);
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
options.font.name = 'Avenir Next';
options.font.size = 13.5;
options.line.color = [0.22,0.22,0.22];
options.line.width = 1.25;
options.bar.width = 7;
options.bar.color = [0.0,0.0,0.0];
options.ticks.size = [0.007, 0.0075];

% Initialize figure
options.figure = figure(...
    'units', 'normalized',...
    'position', [(1-0.4)/2, 0.2, 0.325, 0.36],...
    'position', [(1-0.6)/2, 0.2, 0.625, 0.56],...
    'color', 'white',...
    'paperpositionmode', 'auto',...
    'papertype', 'usletter');

% Initialize axes
options.axes = axes(...
    'parent', options.figure,...
    'units', 'normalized',...
    'color', 'none',...
    'fontname', options.font.name,...
    'fontsize', options.font.size-1,...
    'tickdir', 'out',...
    'ticklength', options.ticks.size,...
    'box', 'off',...
    'xminortick', 'on',...
    'layer', 'top',...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'linewidth', options.line.width,...
    'looseinset', [0.075,0.12,0.05,0.05],...
    'nextplot', 'replacechildren');

% Set labels
options.xlabel = xlabel(...
    'Mass (m/z)',...
    'fontname', options.font.name,...
    'fontsize', options.font.size,...
    'units', 'normalized');

options.ylabel = ylabel(...
    options.ylabel,...
    'fontname', options.font.name,...
    'fontsize', options.font.size,...
    'units', 'normalized');

% Initialize bar plot
options.plot = bar(x, y,...
    'parent', options.axes,...
    'barwidth', options.bar.width, ...
    'linestyle', 'none',...
    'edgecolor', [0,0,0], ...
    'facecolor', options.bar.color);

% Set axis limits
set(options.axes, 'xlim', [floor(min(x) - min(x) * 0.15), floor(max(x) + max(x) * 0.05)]);
set(options.axes, 'ylim', [0 - (max(y) * 0.003), max(y) + (0.05 * max(y))]);

% Check label options
if strcmpi(options.labels, 'on')

    % Index downward points: y(n) > y(n+1)
    dy = y(1,:) > circshift(y, [0,-1]);
    
    % Index upward points: y(n) > y(n-1) 
    dy(2,:) = y(1,:) > circshift(y, [0, 1]);
    
    % Index local maxima: y(n-1) < y(n) > y(n+1)
    dy(3,:) = dy(1,:) & dy(2,:);

    % Extract local maxima
    xlocal = x(dy(3,:));
    ylocal = y(dy(3,:));
    
    % Determine noise
    dy = ylocal(1,:) > circshift(ylocal, [0,-1]);
    dy(2,:) = ylocal(1,:) > circshift(ylocal, [0, 1]);
    dy(3,:) = dy(1,:) & dy(2,:);

    % Filter noise
    xlocal = xlocal(dy(3,:));
    ylocal = ylocal(dy(3,:));

    % Set minimum label height
    threshold = 0.05;
    
    % Filter values below height threshold
    xlocal(ylocal < max(y) * threshold) = [];
    ylocal(ylocal < max(y) * threshold) = [];
    
    % Initialize labels
    for i = 1:length(ylocal)
    
        % Add labels
        options.text{i} = text(...
            xlocal(i), ylocal(i), num2str(xlocal(i), '%10.1f'),...
            'parent', options.axes,...
            'horizontalalignment', 'center',...
            'verticalalignment', 'bottom',...
            'fontsize', options.font.size-6,...
            'fontname', options.font.name);
            
        % Set position units to characters
        set(options.text{i}, 'units', 'characters');
    end
    
    % Determine text position
    position = cellfun(@(x) {get(x, 'extent')}, options.text);
    
    % Determine left/right text positions: left(n); right(n)
    xtext(1,:) = cellfun(@(x) x(1), position);
    xtext(2,:) = cellfun(@(x) x(1)+x(3), position);
    
    % Shift second row forward: left(n+1); right(n) 
    xtext(2,:) = circshift(xtext(2,:), [0,1]);
    
    % Check for left/right text overlap: left(n+1) < right(n)
    xtext(3,:) = xtext(1,:) < xtext(2,:);
    
    % Determine top/bottom text positions: bottom(n); top(n); bottom(n); top(n)
    ytext(1,:) = cellfun(@(x) x(2), position);
    ytext(2,:) = cellfun(@(x) x(2)+x(4), position);
    ytext(3,:) = ytext(1,:);
    ytext(4,:) = ytext(2,:);
    
    % Shift second/third rows forward: bottom(n); top(n); bottom(n+1); top(n+1)
    ytext(3,:) = circshift(ytext(3,:), [0,1]);
    ytext(4,:) = circshift(ytext(4,:), [0,1]);
    
    % Check for top/bottom text overlap: top(n) > top(n+1) > bottom(n)
    ytext(5,:) = ytext(2,:) > ytext(4,:) & ytext(4,:) > ytext(1,:);
    
    % Check for top/bottom text overlap: top(n) > bottom(n+1) > bottom(n)
    ytext(6,:) = ytext(2,:) > ytext(3,:) & ytext(3,:) > ytext(1,:);
    
    % Check for overlapping conditions
    overlap = (xtext(3,:) & ytext(5,:)) | (xtext(3,:) & ytext(6,:));
    overlap(1) = 0;

    % Reset position units
    cellfun(@(x) {set(x, 'units', 'data')}, options.text);
    
    % Hide overlapping text
    if sum(overlap) < 0
    
        % Determine text to hide
        labels = options.text(overlap);

        % Hide labels
        for i = 1:length(labels)
            set(labels{i}, 'visible', 'off')
        end
        
        % Delete labels
        for i = 1:length(labels)
            labels(i) = [];
        end
    end
end

% Initialize empty axes
options.empty = axes(...
    'parent', options.figure,...
    'box','on',...
    'units', 'normalized',...
    'fontname', options.font.name,...
    'fontsize', options.font.size-1,...
    'tickdir', 'out',...
    'ticklength', options.ticks.size,...
    'linewidth', options.line.width,...
    'color', 'none',...
    'layer', 'bottom',...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'looseinset', [0.075,0.12,0.05,0.05],...
    'xtick', [],...
    'ytick', [],...
    'position', get(options.axes,'position')+[-0.003,-0.0038,0,0]);

% Link axes to allow zooming
axes(options.axes);
linkaxes([options.axes, options.empty]);

box(options.axes, 'off');

% Align axes edges
align([options.axes,options.empty],'VerticalAlignment','bottom');
align([options.axes,options.empty],'HorizontalAlignment','left');

% Set version specific properties
switch version('-release')
    
    case '2014b'
        
        % Resize callback
        set(options.figure, 'sizechangedfcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
        
        % Prevent axes overlap
        set(get(get(options.axes, 'yruler'),'axle'), 'visible', 'off');
        set(get(get(options.axes, 'xruler'),'axle'), 'visible', 'off');
        set(get(get(options.axes, 'ybaseline'),'axle'), 'visible', 'off');
        
    case {'2014a', '2013b', '2013a', '2012b', '2012a'}
        
        % Resize callback
        set(options.figure, 'resizefcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
        
    otherwise
        try
            % Resize callback
            set(options.figure, 'resizefcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
        catch       
        end
end

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
