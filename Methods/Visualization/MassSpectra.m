% Method: MassSpectra 
%  -Plot a mass spectra histogram
%
% Syntax
%   MassSpectra(mz, y, 'OptionName', optionvalue...)
%
% Input
%   mz          : array
%   y           : array or matrix
%
% Options
%   'labels'    : 'on', 'off'
%   'fontsize'  : value
%   'scale'     : 'relative', 'full'
%   'xlim'      : 'auto', [xmin, xmax]
%   'ylim'      : 'auto', [ymin, ymax]
%   'barwidth'  : value
%   'export'    : see MATLAB documentation on print functions
%
% Description
%   mz          : m/z values
%   y           : intensity values
%   'labels'    : show labels over m/z values (default = 'on')
%   'fontsize'  : font size of text labels (default = 7.5)
%   'scale'     : display relative or total intensity (default = 'relative')
%   'xlim'      : x-axis limits (default = 'auto')
%   'ylim'      : y-axis limits (default = 'auto')
%   'barwidth'  : width of individual bars (default = 7)
%   'export'    : cell array passed to the MATLAB print function (default = none)
%
% Examples
%   MassSpectra(mz, y)
%   MassSpectra(mz, y, 'labels', 'off', 'scale', 'full')
%   MassSpectra(mz, y 'export', {'myfig', '-dtiff', '-r300'})

function varargout = MassSpectra(varargin)

% Check input
[mz, y, options] = parse(varargin);
    
% Check for normalization
if strcmpi(options.scale, 'relative')
    
    % Check for negative values
    y(y < 0) = 0;
    
    % Normalize values
    y = (y - min(min(y))) ./ (max(max(y)) - min(min(y)));
    y = y * 100;
    
    % Set y-axis label
    options.ylabel = 'Abundance (%)';
else
    
    % Check y-axis limits
    if ~isempty(options.ylimits) && options.ylimits(2) <= 1
        options.ylimits(2) = options.ylimits(2) * max(max(y));
    end
    if ~isempty(options.ylimits) && options.ylimits(1) <= 1
        options.ylimits(1) = options.ylimits(1) * max(max(y));
    end
    
    % Set y-axis label
    options.ylabel = 'Intensity';
end

% Set figure options
options.font.name = 'Avenir Next';
options.font.size = 13.5;
options.line.color = [0.22,0.22,0.22];
options.line.width = 1.25;
options.bar.color = [0,0,0];
options.ticks.size = [0.007, 0.0075];

if options.bar.width >= 10
    options.line.style = '-';
else
    options.line.style = 'none';
end

% Initialize figure
options.figure = figure(...
    'units', 'normalized',...
    'position', [(1-0.4)/2, 0.2, 0.38, 0.4],...%'position', [(1-0.6)/2, 0.2, 0.625, 0.56],...
    'color', 'white',...
    'paperpositionmode', 'auto',...
    'papertype', 'usletter',...
    'visible','off');

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
    'selectionhighlight', 'off',...
    'nextplot', 'replacechildren');

% Set x-label
options.xlabel = xlabel(...
    'Mass (m/z)',...
    'fontname', options.font.name,...
    'fontsize', options.font.size,...
    'units', 'normalized');

% Set y-label
options.ylabel = ylabel(...
    options.ylabel,...
    'fontname', options.font.name,...
    'fontsize', options.font.size,...
    'units', 'normalized');

% Initialize bar plot
options.plot = bar(mz, y,...
    'parent', options.axes,...
    'barwidth', options.bar.width, ...
    'linestyle', options.line.style,...
    'edgecolor', options.bar.color, ...
    'facecolor', options.bar.color);

% Determine x-axis limits
if isempty(options.xlimits)
    options.xlimits = [floor(min(mz) - min(mz) * 0.15), floor(max(mz) + max(mz) * 0.05)];
end

% Determine window for y-axis scaling
window = mz >= options.xlimits(1) & mz <= options.xlimits(2);
    
if isempty(options.ylimits)
    options.ylimits = [0 - (max(y(window)) * 0.003), max(y(window)) + (0.05 * max(y(window)))];
end

% Set axis limits
set(options.axes, 'xlim', options.xlimits);
set(options.axes, 'ylim', options.ylimits);

% Check label options
if strcmpi(options.labels, 'on')

    % Index downward points: y(n) > y(n+1)
    dy = y(1,:) > circshift(y(1,:), [0,-1]);
    
    % Index upward points: y(n) > y(n-1) 
    dy(2,:) = y(1,:) > circshift(y(1,:), [0, 1]);
    
    % Index local maxima: y(n-1) < y(n) > y(n+1)
    dy(3,:) = dy(1,:) & dy(2,:);

    % Extract local maxima ions
    xlocal = mz(dy(3,:));
    ylocal = y(dy(3,:));
    
    % Determine noise
    dy = ylocal(1,:) > circshift(ylocal, [0,-1]);
    dy(2,:) = ylocal(1,:) > circshift(ylocal, [0, 1]);
    dy(3,:) = dy(1,:) & dy(2,:);

    % Filter noise
    xlocal = xlocal(dy(3,:));
    ylocal = ylocal(dy(3,:));
    
    % Filter values below height threshold
    xlocal(ylocal < max(y(window)) * options.threshold) = [];
    ylocal(ylocal < max(y(window)) * options.threshold) = [];
    
    % Filter values outside window
    ylocal(:, xlocal < options.xlimits(1) | xlocal > options.xlimits(2)) = [];
    xlocal(:, xlocal < options.xlimits(1) | xlocal > options.xlimits(2)) = [];
   
    % Variables
    counter = 1;
    padding = 0.01 * (max(mz) - min(mz));
    
    % Filter values within noise
    while counter ~= 0 && ~isempty(ylocal)
    
        % Determine m/z between peaks
        xlocal(2,:) = circshift(xlocal(1,:), [0,-1]) - xlocal(1,:);
        xlocal(2,end) = padding;
        
        xlocal(3,:) = xlocal(1,:) - circshift(xlocal(1,:), [0,1]);
        xlocal(3,1) = padding;
        
        % Determine height between peaks
        ylocal(2,:) = ylocal(1,:) - circshift(ylocal(1,:), [0,-1]);
        ylocal(2,end) = 1;
        
        ylocal(3,:) = ylocal(1,:) - circshift(ylocal(1,:), [0,1]);
        ylocal(3,1) = 1;
        
        % Determine relative change in height between peaks
        ylocal(4,:) = ylocal(2,:) ./ ylocal(1,:);
        ylocal(5,:) = ylocal(3,:) ./ ylocal(1,:);
        
        % Remove peaks with large height differnce and small m/z difference
        remove = xlocal(2,:) < padding & ylocal(4,:) < -0.5;
        remove(2,:) = xlocal(3,:) < padding & ylocal(5,:) < -0.5;
        remove = remove(1,:) | remove(2,:);
        
        xlocal(:,remove) = [];
        ylocal(:,remove) = [];
        
        % Set counter to number of peaks removed
        counter = sum(remove);
    end
    
    % Check for labels 
    if ~isempty(ylocal)
        
        % Initialize labels
        for i = 1:length(ylocal(1,:))
            
            % Add labels
            options.text{i} = text(...
                xlocal(1,i), ylocal(1,i), num2str(xlocal(1,i), '%10.1f'),...
                'parent', options.axes,...
                'horizontalalignment', 'center',...
                'verticalalignment', 'bottom',...
                'clipping', 'on',...
                'fontsize', options.label.fontsize,...
                'fontname', options.font.name);
            
            % Set position units to characters
            set(options.text{i}, 'units', 'characters');
        end
        
        % Variables
        counter = 1;
        shift = 1;
        
        % Remove overlapping labels
        while counter ~=0 && ~isempty(options.text)
            
            % Determine text position
            position = cellfun(@(x) {get(x, 'extent')}, options.text);
            
            % Determine left/right text positions: left(n); right(n+1)
            xtext = cellfun(@(x) x(1), position);
            xtext(2,:) = cellfun(@(x) x(1)+x(3), position);
            xtext(2,:) = circshift(xtext(2,:), [0,shift]);
            
            % Check for left/right text overlap: left(n+1) < right(n)
            xtext(3,:) = xtext(1,:) < xtext(2,:);
            
            % Determine top/bottom text positions: bottom(n); top(n); bottom(n+1); top(n+1)
            ytext = cellfun(@(x) x(2), position);
            ytext(2,:) = cellfun(@(x) x(2)+x(4), position);
            ytext(3,:) = circshift(ytext(1,:), [0,shift]);
            ytext(4,:) = circshift(ytext(2,:), [0,shift]);
            
            % Check for top text overlap: top(n) > top(n+1) > bottom(n)
            ytext(5,:) = ytext(2,:) > ytext(4,:) & ytext(4,:) > ytext(1,:);
            
            % Check for bottom text overlap: top(n) > bottom(n+1) > bottom(n)
            ytext(6,:) = ytext(2,:) > ytext(3,:) & ytext(3,:) > ytext(1,:);
            
            % Check for overlapping xy positions
            overlap = (xtext(3,:) & ytext(5,:)) | (xtext(3,:) & ytext(6,:));
            overlap(1:shift) = 0;
            
            % Set counter to number of overlapping labels
            counter = sum(overlap);
            
            % Remove overlapping labels
            if counter > 0
                
                % Retreive overlapping labels
                ytext(7,:) = ytext(6,:) & overlap;
                ytext(8,:) = circshift(ytext(5,:) & overlap, [0, -shift]);
                
                % Determine labels to remove
                remove = ytext(8,:) | ytext(7,:);
                
                % Temporarily hide labels
                cellfun(@(x) set(x, 'visible', 'off'), options.text);
                
                % Remove labels
                options.text(remove) = [];
                
                % Display labels
                cellfun(@(x) set(x, 'visible', 'on'), options.text);
                
                % Check label distance
            elseif counter == 0
                
                % Check label overlap from distant columns
                if shift <= 5
                    
                    % Increment shift
                    shift = shift + 1;
                    
                    % Reset counter
                    counter = 1;
                end
            end
        end
        
        % Reset position units
        cellfun(@(x) {set(x, 'units', 'data')}, options.text);
        
        % Determine text position
        position = cellfun(@(x) {get(x, 'extent')}, options.text);
        
        % Determine left/right text positions: left(n); right(n)
        xtext = cellfun(@(x) x(1), position);
        xtext(2,:) = cellfun(@(x) x(1)+x(3), position);
        
        % Determine top/bottom text positions: bottom(n); top(n);
        ytext = cellfun(@(x) x(2), position);
        ytext(2,:) = cellfun(@(x) x(2)+x(4), position);
        
        % Find text outside axes
        remove = xtext(1,:) < options.xlimits(1);
        remove(2,:) = xtext(2,:) > options.xlimits(2);
        remove(3,:) = ytext(1,:) < options.ylimits(1);
        remove(4,:) = ytext(2,:) > options.ylimits(2);
        remove = remove(1,:) | remove(2,:) | remove(3,:) | remove(4,:);
        
        % Remove text outside axes
        if sum(remove) > 0
            
            % Temporarily hide labels
            cellfun(@(x) set(x, 'visible', 'off'), options.text);
                
            % Remove labels
            options.text(remove) = [];
                
            % Display labels
            cellfun(@(x) set(x, 'visible', 'on'), options.text);
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
    'layer', 'bottom',...
    'selectionhighlight', 'off',...
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

% Display figure
set(options.figure, 'visible', 'on');

% Set output
varargout{1} = options;
end

% Parse user input
function [mz, y, options] = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin <= 1
    error('Not enough input arguments.');
end

% Check data
if isnumeric(varargin{1})
    mz = varargin{1};
else
    error('Undefined input arguments of type ''mz''.');
end
if isnumeric(varargin{2})
    y = varargin{2};
else
    error('Undefined input arguments of type ''y''.');
end

% Check input length
if length(mz(:,1)) > length(mz(1,:))
    mz = mz';
end
if length(y(:,1)) == length(mz(1,:)) && length(y(:,1)) ~= length(y(1,:))
    y = y';
end
if ~any(size(y) == 1)
    y = sum(y);
end
if length(mz(1,:)) ~= length(y(1,:))
    disp('Index exceeds matrix dimensions.');
    return
end
    
% Check input precision
if ~isa(mz, 'double')
    mz = double(mz);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check for negative m/z values
y(mz < 0) = [];
mz(mz < 0) = [];

% Check for negative intensity values
y(y < 0) = 0;

if isempty(mz)
    disp('Input arguments of type ''mz'' must be positive.'); 
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Label options
if ~isempty(input('labels'))
    options.labels = varargin{input('labels')+1};
                    
    % Check for valid input
    if any(strcmpi(options.labels, {'default', 'on', 'show', 'display'}))
        options.labels = 'on';
    elseif any(strcmpi(options.labels, {'off', 'hide'}))
        options.labels = 'off';
    else
        options.labels = 'on';
    end
else
    options.labels = 'on';
end


% Label size options
if ~isempty(input('labelsize'))
    fontsize = varargin{input('labelsize')+1};
elseif ~isempty(input('fontsize'))
    fontsize = varargin{input('fontsize')+1};
else
    fontsize = [];
end

% Check for valid input
if ~isempty(fontsize)
    if any(strcmpi(fontsize, {'default'})) || ~isnumeric(fontsize)
        options.label.fontsize = 7.5;
    elseif fontsize >= 30 || fontsize <= 1
        options.label.fontsize = 7.5;
    else
        options.label.fontsize = fontsize;
    end
else
    options.label.fontsize = 7.5;
end


% Scale options
if ~isempty(input('scale'))
    options.scale = varargin{input('scale')+1};
                    
    % Check for valid input
    if any(strcmpi(options.scale, {'default', 'relative', 'normalize', 'normalized'}))
        options.scale = 'relative';
    elseif any(strcmpi(options.scale, {'full', 'separate'}))
        options.scale = 'full';
    else
        options.scale = 'relative';
    end
else
    options.scale = 'relative';
end


% Export options
if ~isempty(input('export'))
    options.export = varargin{input('export')+1};
      
    % Check for valid input
    if strcmpi(options.export, 'on')
        options.export = {'spectra', '-dpng', '-r300'};
    elseif ~iscell(options.export)
        options.export = 'off';
    end
else
    options.export = 'off';
end


% X-limits options
if ~isempty(input('xlim'))
    xlimits = varargin{input('xlim')+1};
    
    % Check for valid input
    if ~isnumeric(xlimits) || any(strcmpi(xlimits, {'default', 'auto'}))
        options.xlimits = [];
    elseif xlimits(2) < xlimits(1) || length(xlimits) ~= 2;
        options.xlimits = [];
    else
        options.xlimits = xlimits;
    end

else
    options.xlimits = [];
end


% Y-limits options
if ~isempty(input('ylim'))
    ylimits = varargin{input('ylim')+1};
    
    % Check user input
    if ~isnumeric(ylimits) || any(strcmpi(ylimits, {'default', 'auto'}))
        options.ylimits = [];
    elseif ylimits(2) < ylimits(1) || length(ylimits) ~= 2
        options.ylimits = [];
    else 
        options.ylimits = ylimits;
    end    
else
    options.ylimits = [];
end


% Barwidth options
if ~isempty(input('barwidth'))
    options.bar.width = varargin{input('barwidth')+1};
                   
    if ~isnumeric(options.bar.width)
        options.bar.width = 7;
    elseif options.bar.width <= 0 || options.bar.width > 999
        options.bar.width = 7;
    else
        options.bar.width = options.bar.width(1);
    end 
else
    options.bar.width = 7;
end


% Threshold options (experimental)
if ~isempty(input('threshold'))
    options.threshold = varargin{input('threshold')+1};
                   
    if ~isnumeric(opitons.threshold)
        options.threshold = 0.015;
    elseif options.threshold <= 0 || options.threshold > 1
        options.threshold = 0.015;
    else
        options.threshold = options.threshold(1);
    end 
else
    options.threshold = 0.015;
end
end
