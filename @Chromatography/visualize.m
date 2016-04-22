% ------------------------------------------------------------------------
% Method      : Chromatography.visualize
% Description : Plot chromatograms and customize style
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   fig = obj.visualize(data)
%   fig = obj.visualize(data, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   data (required)
%       Description : chromatography data
%       Type        : structure
%
%   ----------------------------------------------------------------------
%   Plot Options
%   ----------------------------------------------------------------------
%   Data
%     'samples'   : index | 'all'
%     'ions'      : index | 'all', 'tic'
%     'baseline'  : 'on', 'off', 'corrected'
%   
%   Arrangement
%     'layout'    : 'stacked', 'overlaid'
%     'scale'     : 'relative', 'absolute'
%     'scope'     : 'local', 'global'
%     'offset'    : -1.0 to 1.0
%
%   Axes
%     'padding'   : 0.0 to 1.0
%     'xlim'      : [xmin, xmax] | 'auto'
%     'ylim'      : [ymax, ymin] | 'auto'
%   
%   Style
%     'linewidth' : > 0.0
%     'legend'    : 'on', 'off'
%     'color'     : [R, G, B]
%     'colormap'  : MATLAB colormap
%   
%   Export
%     'export'    : {'name', '-dFORMAT', '-rDPI} | 'on', 'off'
%
%   ----------------------------------------------------------------------
%   Plot Data
%   ----------------------------------------------------------------------
%   'samples' (optional)
%       Description : index of samples in data structure
%       Type        : number | 'all'
%       Default     : 'all'
%
%   'ions' (optional)
%       Description : index of ions in data
%       Type        : number | 'all', 'tic'
%       Default     : 'tic'
%
%   'baseline' (optional)
%       Description : show baseline or baseline corrected values
%       Type        : 'on', 'off', 'corrected'
%       Default     : 'off'
%
%   ----------------------------------------------------------------------
%   Plot Position
%   ----------------------------------------------------------------------
%   'layout' (optional)
%       Description : arrange plots in stacked or overlaid format
%       Type        : 'stacked', 'overlaid'
%       Default     : 'stacked'
%
%   'scale' (optional)
%       Description : plot relative or absolute values
%       Type        : 'relative', 'absolute'
%       Default     : 'relative'
%
%   'scope' (optional)
%       Description : adjust y-values to sample maximum or global maximum
%       Type        : 'local', 'global'
%       Default     : 'local'
%
%   'offset' (optional)
%       Description : sequential y-offset applied to each sample
%       Type        : number
%       Default     : 0.0
%
%   ----------------------------------------------------------------------
%   Plot Axes
%   ----------------------------------------------------------------------
%   'padding' (optional)
%       Description : white space between axes and plot lines
%       Type        : number
%       Default     : 0.05
%       Range       : 0.0 to 1.0
%
%   'xlim' (optional)
%       Description : x-axis limits
%       Type        : [number, number] | 'auto'
%       Default     : 'auto'
%
%   'ylim' (optional)
%       Description : y-axis limits
%       Type        : [number, number] | 'auto'
%       Default     : 'auto'
%
%   ----------------------------------------------------------------------
%   Plot Style
%   ----------------------------------------------------------------------
%   'linewidth' (optional)
%       Description : linewidth of plot line
%       Type        : number
%       Default     : 1.0
%       Range       : > 0.0
%
%   'legend' (optional)
%       Description : show legend with plot name
%       Type        : 'on', 'off'
%       Default     : 'off'
%
%   'color' (optional)
%       Description : RGB value of plot line
%       Type        : [number, number, number]
%       Default     : use colormap
%
%   'colormap' (optional)
%       Description : colormap to apply to plot lines
%       Type        : 'parula', 'jet', 'hsv', 'hot', 'cool', 'spring',...
%                     'spring', 'summer', 'autumn', 'winter', 'gray',...
%                     'bone', 'copper', 'pink'
%       Default     : 'parula'
%
%   ----------------------------------------------------------------------
%   Plot Export
%   ----------------------------------------------------------------------
%   'export' (optional)
%       Description : export figure to image (see MATLAB 'print' options)
%       Type        : cell | 'on', 'off'
%       Default     : 'off'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   fig = obj.visualize(data, 'samples', [1:4], 'ions', 'tic')
%   fig = obj.visualize(data, 'layout', 'stacked', 'ions', 'all')
%   fig = obj.visualize(data, 'scale', 'normalized', 'legend', 'on')
%   fig = obj.visualize(data, 'samples', 1, 'xlim', [3, 27])
%   fig = obj.visualize(data, 'export', {'SampleTIC', '-dtiff', '-r300'}
%

function varargout = visualize(obj, varargin)

% ---------------------------------------
% Parse input
% ---------------------------------------
[data, options] = parse(obj, varargin);

% ---------------------------------------
% Variables
% ---------------------------------------
samples = options.samples;
ions = options.ions;
target = options.ions;

% ---------------------------------------
% Validate attributes
% ---------------------------------------
if isempty(samples)
    disp('[ERROR] No samples match input criteria...');
    return
end

if isnumeric(target)
    target = 'xic';
end

% ---------------------------------------
% Initialize plots
% ---------------------------------------
options = plot_axes(options, data);
options = plot_legend(options, data);

for i = 1:length(samples)
    
    % ---------------------------------------
    % Variables
    % ---------------------------------------
    index = samples(i);
    baseline = [];
    
    options.i = i;
    
    % ---------------------------------------
    % Select data
    % ---------------------------------------
    x = data(index).time;
    z = data(index).mz;
    
    switch target
        
        case 'tic'
            y = data(index).tic.values;
        case 'all'            
            y = data(index).xic.values;            
        case 'xic'
            y = data(index).xic.values(:, ions); 
    end
    
    if isempty(y)
        continue
    end
    
    % ---------------------------------------
    % Select baseline
    % ---------------------------------------
    if any(strcmpi(options.baseline, {'on', 'corrected'}))
        
        switch target
            
            case 'tic'
                baseline = data(index).tic.baseline;    
            case 'all'
                baseline = data(index).xic.baseline;
            case 'xic'
                baseline = data(index).xic.baseline(:, ions);     
        end
        
        if nnz(baseline) == 0
            baseline = [];
        end
        
    end
               
    % ---------------------------------------
    % Select display names
    % ---------------------------------------
    if strcmpi(options.legend, 'on')
    
        switch target
        
            case 'tic'
                names = options.name(i);     
            case 'all'
                names(length(z)) = {''};
                mz = z(:);
            case 'xic'
                names(length(z)) = {''};
                mz = z(ions(ions <= length(z)));
        end
        
        if ~isempty(names) && any(strcmpi(ions, {'all','xic'}))
            
            [keys, index] = ismember(mz, options.keys);
            
            if any(keys)
                names(index(keys)) = options.name(keys);
            end
            
        end
        
    else
        names{length(y(1,:))} = '';
    end
    
    % ---------------------------------------
    % Data validation
    % ---------------------------------------
    if issparse(y)
        y = full(y);
    end
    
    if ~isempty(baseline) && strcmpi(options.baseline, 'corrected');
        y = y - baseline;
    end
    
    if isempty(baseline)
        options.baseline = 'off';
    end
    
    % ---------------------------------------
    % Plot layout
    % ---------------------------------------
    [x, options] = plot_xlim(x, options);
    [y, options] = plot_scale(y, options);
    [y, options] = plot_layout(y, options);
    [y, options] = plot_ylim(x, y, options);
    
    % ---------------------------------------
    % Plot data
    % ---------------------------------------
    if verLessThan('matlab', 'R2014b')
        
        plot(x, y,...
            'parent', options.axes,...
            'linewidth', options.linewidth,...
            'linesmoothing', 'on',...
            'displayname', [names{:}]);
    else
        
        plot(x, y,...
            'parent', options.axes, ...
            'linewidth', options.linewidth, ...
            'displayname', [names{:}]);
    end
    
    % ---------------------------------------
    % Plot baseline
    % ---------------------------------------
    if strcmpi(options.baseline, 'on')
        
        [baseline, options] = plot_scale(baseline, options, 1);
        
        if strcmpi(options.scale, 'normalized')
            baseline = baseline ./ 100;
        end
        
        [baseline, options] = plot_layout(baseline, options);
        
        plot(x, baseline, ...
            'parent', options.axes, ...
            'linewidth', options.linewidth, ...
            'color', [0.99,0.1,0.23]);
    end
    
end

% ---------------------------------------
% Display figure
% ---------------------------------------
plot_update(options);
set(options.empty, 'position', get(options.axes, 'position'));

% ---------------------------------------
% Export figure
% ---------------------------------------
if ~isempty(options.export)
    
    try
        disp('Rendering image, please wait...');
        print(options.figure, options.export{:});
        disp('Rendering complete!');
        
    catch
        disp('-Error reading print options, rendering image with default options...');
        print(options.figure, options.filename, '-dpng', '-r300');
        disp('Rendering complete!');
    end
    
end

varargout{1} = options;

end


% ------------------------------------------------------------------------
% Legend
% ------------------------------------------------------------------------
function options = plot_legend(options, data)

% ---------------------------------------
% Variables
% ---------------------------------------
samples = [data(options.samples).sample];
mz = [];

if isnumeric(options.ions)
    target = 'xic';
else
    target = options.ions;
end

% ---------------------------------------
% Display names
% ---------------------------------------
if strcmpi(target, 'tic')
    options.name = {samples.name};
    options.keys = 1:length(options.samples);
        
else
    
    for i = 1:length(samples)
        
        if isempty(data(i).mz)
            continue
            
        elseif strcmpi(target, 'all')
            mz = [mz, data(i).mz];
            
        elseif strcmpi(target, 'xic')
            index = options.ions(options.ions <= length(data(i).mz));
            mz = [mz, data(i).mz(index)];
        end 
        
    end
    
    mz = round(mz * 1E4) ./ 1E4;
    mz = unique(mz, 'stable');
    
    names = arrayfun(@num2str, mz, 'uniformoutput', false);
    names = cellfun(@(x) strcat(x, ' m/z'), names, 'uniformoutput', false);
            
    options.name = names;
    options.keys = mz; 
end

end

% Scale options
function varargout = plot_scale(varargin)

% Input
y = varargin{1};
options = varargin{2};

if nargin == 3
    extra = varargin{3};
else
    extra = 0;
end

xmin = options.xmin.index(options.i);
xmax = options.xmax.index(options.i);

% Normalized scale
if strcmpi(options.scale, 'normalized')
    
    % Normalization factor
    switch options.scope
        
        case 'local'
            ymin = min(y(xmin:xmax,:));
            ymax = max(y(xmin:xmax,:));

        case 'global'
            ymin = min(min(y(xmin:xmax,:)));
            ymax = max(max(y(xmin:xmax,:)));
    end
    
    y = bsxfun(@rdivide,...
        bsxfun(@minus, y, ymin), (ymax - ymin));
    
    y = y .* 100;
    
elseif strcmpi(options.scale, 'full') && strcmpi(options.layout, 'stacked')
    
    % Full scale + stacked layout
    switch options.scope
        
        case 'local'
            ymin = min(min(y(xmin:xmax,:)));
            ymax = max(max(y(xmin:xmax,:)));
            
            if options.i == 1 && extra == 0
                options.scaling_factor(1) = ymin;
                options.scaling_factor(2) = ymax;
                
            elseif ymax > options.scaling_factor(2)
                options.scaling_factor(2) = ymax;
                
            else
                ymin = options.scaling_factor(1);
                ymax = options.scaling_factor(2);
            end
            
            y = bsxfun(@rdivide,...
                bsxfun(@minus, y, ymin), (ymax - ymin));
    end
end

% Output
varargout{1} = y;
varargout{2} = options;

end

% Check layout options
function [y, options] = plot_layout(y, options)

% Axes: Y-Limits
if isempty(options.ylimits)
    options.ylimits(1) = min(min(y));
    options.ylimits(2) = max(max(y));
end

% Layout: N/A
if length(options.samples) == 1
    offset = 0;

% Layout: Stacked
elseif strcmpi(options.layout, 'stacked')
    
    switch options.scale
    
        % Scale: Normalized
        case 'normalized'
            offset = ...
                (options.i - 1) * 100 * ...
                (1 + options.offset); 
        
        % Scale: Full
        case 'full'
            offset = ...
                (options.i - 1) * ...
                (options.ylimits(2) + ...
                (options.ylimits(2) * options.offset));
    end
    
% Layout: Overlaid
elseif strcmpi(options.layout, 'overlaid')
    
    switch options.scale
    
        % Scale: Normalized
        case 'normalized'
            offset = ...
                (options.ylimits(2) * options.offset);
            
        % Scale: Full
        case 'full'
            offset = ... 
                (options.i - 1) * ...
                (options.ylimits(2) * options.offset);
    end
    
else
    offset = 0;
end

% Plot: Y-Values
y = y - offset;
            
end

% Check x-limits options
function [x, options] = plot_xlim(x, options)

% Determine min/max
xmin = min(min(x));
xmax = max(max(x));

% Automatic x-limits
if isempty(options.xlimits)
    options.xlimits = [xmin, xmax];
    
elseif strcmpi(options.xpermission, 'write')
    
    if xmin < options.xlimits(1)
        options.xlimits(1) = xmin;
    end
    
    if xmax > options.xlimits(2)
        options.xlimits(2) = xmax;
    end
end

% Determine x-limit indices
if xmin < options.xlimits(1)
    options.xmin.index(options.i) = find(x >= options.xlimits(1),1);
else
    options.xmin.index(options.i) = 1;
end

if xmax > options.xlimits(2)
    options.xmax.index(options.i) = find(x >= options.xlimits(2),1);
else
    options.xmax.index(options.i) = length(x);
end

end

% Check y-limits options
function [y, options] = plot_ylim(x, y, options)

% Axes: X-Limits
if options.xlimits(1) >= min(x)
    xmin = find(x >= options.xlimits(1), 1);
else
    xmin = 1;
end

if options.xlimits(2) <= max(x)
    xmax = find(x >= options.xlimits(2), 1);
else
    xmax = length(x);
end

ymin = min(min(y(xmin:xmax,:)));
ymax = max(max(y(xmin:xmax,:)));

% Axes: Y-Limits (auto)
if isempty(options.ylimits)
    options.ylimits = [ymin, ymax];
    
elseif strcmpi(options.ypermission, 'write')
    
    if ymin < options.ylimits(1)
        options.ylimits(1) = ymin;
    end
    
    if ymax > options.ylimits(2) && ~strcmpi(options.layout, 'stacked')
        options.ylimits(2) = ymax;
    end
    
end
end

function plot_update(options)

if ~isempty(options.xlimits)
    padding.x = (options.xlimits(2) - options.xlimits(1)) * options.padding;
    set(options.axes, 'xlim', [options.xlimits(1)-padding.x, options.xlimits(2)+padding.x]);
end

if ~isempty(options.ylimits)
    padding.y = (options.ylimits(2) - options.ylimits(1)) * options.padding;
    set(options.axes, 'ylim', [options.ylimits(1)-padding.y, options.ylimits(2)+padding.y]);
end

if strcmpi(options.legend, 'off')
   legend(options.axes, 'hide');
   
elseif length(options.name) > 100
    legend(options.axes, 'hide');
    
elseif strcmpi(options.legend, 'on')
    legend(options.axes, 'show', 'string', options.name, 'interpreter', 'none');
end

end


% Initialize axes
function options = plot_axes(options, data)

% Axes properties
options.font.name = options.fontname;
options.font.size = 14;
options.line.color = [0.23,0.23,0.23];
options.line.width = 1.25;
options.ticks.size = [0.007, 0.0075];

% Initialize figure
options.figure = figure(...
    'color', 'white',...
    'numbertitle', 'off',...
    'name', 'Chromatography Toolbox',...
    'units', options.position_units,....
    'position', options.position,...
    'visible', 'on',...
    'paperpositionmode', 'auto');

% Check color options
if isempty(options.colormap) && ~isempty(options.color)
    
    if iscell(options.color)
        options.colormap = options.color{1};
    else
        options.colormap = options.color;
    end
    
end

% Determine color order
if ischar(options.colormap)
    
    try
        colors = colormap(options.colormap);
    catch
        options.colormap = 'parula';
        colors = colormap('parula');
    end
    
else
    colors = options.colormap;
end

% Check color group
if ~any(strcmpi(options.ions, {'tic', 'all'}))
    n = length(options.ions);
    
elseif strcmpi(options.ions, 'all')
    n = length(data(options.samples(1)).mz);
    
else
    n = length(options.samples);
end

% Check amount of colors
if n < length(colors(:,1))
    
    % Use limited amount of colors
    c = round(length(colors)/n);
    options.colors = colors(1:c:end,:);
    
    if length(options.colors(:,1)) ~= n
        options.colors(1:length(options.colors) - n,:) = [];
    end
    
else
    options.colors = colors;
end

% Initialize main axes
options.axes = axes(...
    'parent', options.figure,...
    'looseinset', [0.08, 0.1, 0.05, 0.05],...
    'fontsize', options.font.size-1,...
    'fontname', options.font.name,...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'box', 'off',...
    'colororder', options.colors,...
    'color', 'none',...
    'linewidth', options.line.width,...
    'tickdir', 'out',...
    'ticklength', options.ticks.size);

hold all;

% Set x-axis label
options.xlabel = xlabel(...
    options.axes,...
    'Time (min)',...
    'fontsize', options.font.size,...
    'fontname', options.font.name);

% Overlaid y-axis label
if strcmpi(options.scale, 'normalized')
    options.ylabel = 'Intensity (%)';
else
    options.ylabel = 'Intensity';
end

% Stacked y-axis label
if strcmpi(options.layout, 'stacked') || options.offset ~= 0
    options.ylabel = [];
    
    set(options.axes,...
        'ytick', [],...
        'looseinset', [0.05, 0.1, 0.05, 0.05]);
end

% Set y-axis label
options.ylabel = ylabel(...
    options.axes,...
    options.ylabel,...
    'fontsize', options.font.size,...
    'fontname', options.font.name);

% Initialize empty axes
options.empty = axes(...
    'parent', options.figure,...
    'box','on',...
    'linewidth', options.line.width,...
    'color', 'none',...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'xtick', [],...
    'ytick', [],...
    'selectionhighlight', 'off',...
    'position', get(options.axes, 'position'),...
    'nextplot', 'add');

box(options.empty, 'on');
box(options.axes, 'off');

% Link axes to allow zooming
linkaxes([options.axes, options.empty]);

try
    set(zoom(options.figure),...
        'actionpostcallback', @(varargin) set(options.empty,...
        'position', get(options.axes, 'position')));
catch
end

% Version specific options
if verLessThan('matlab', 'R2014b')
    
    try
        % Resize callback
        set(options.figure,...
            'resizefcn', @(varargin) set(options.empty,...
            'position', get(options.axes, 'position')));
    catch
    end
    
else
    
    % Resize callback
    set(options.figure,...
        'sizechangedfcn', @(varargin) set(options.empty,...
        'position', get(options.axes, 'position')));
    
    % Axes overlap
    set(get(get(options.axes, 'yruler'), 'axle'), 'visible', 'off');
    set(get(get(options.axes, 'xruler'), 'axle'), 'visible', 'off');
    set(get(get(options.axes, 'ybaseline'), 'axle'), 'visible', 'off');  
end

end


% Parse user input
function varargout = parse(obj, varargin)

if length(varargin{1}) < 1
    error('Not enough input arguments.');
end

% ---------------------------------------
% Variables
% ---------------------------------------
varargin = varargin{1};

if isstruct(varargin{1})
    data = obj.format('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''.');
end

% ---------------------------------------
% Functions
% ---------------------------------------
input = @(x) find(strcmpi(varargin, x),1);

% ---------------------------------------
% Defaults
% ---------------------------------------
options.samples = 1:length(data);
options.ions = 'tic';
options.baseline = 'off';

options.layout = 'stacked';
options.scale = 'full';
options.scope = 'local';

options.xlimits = [];
options.ylimits = [];
options.xpermission = 'write';
options.ypermission = 'write';

options.padding = 0.05;
options.offset = 0.0;
options.linewidth = 1.0;

options.name = {};
options.legend = 'off';

options.color = [0.15,0.15,0.15];
options.colormap = obj.defaults.plot_colormap;

options.fontname = 'avenir';

options.position = obj.defaults.plot_position;
options.position_units = 'normalized';

options.filename = [datestr(datetime, 'yyyymmdd_HHMM'), '_chromatography_figure'];
options.export = [];

% ---------------------------------------
% Option: 'samples'
% ---------------------------------------
if ~isempty(input('samples'))
    samples = varargin{input('samples')+1};
    
    samples_all = {...
        'default',...
        'all'};
    
    % Check input
    if any(strcmpi(samples, samples_all))
        options.samples = 1:length(data);
                
    elseif isnumeric(samples)
        options.samples = samples(samples >= 1 & samples <= length(data));
        options.samples = round(options.samples);
    end
end

% ---------------------------------------
% Option: 'ions'
% ---------------------------------------
if ~isempty(input('ions'))
    ions = varargin{input('ions')+1};
    
    ions_tic = {...
        'default',...
        'tic',...
        'tics',...
        'total_ion'};
    
    ions_all = {...
        'all',...
        'xic',...
        'xics',...
        'eic',...
        'eics',...
        'extracted_ion'};
    
    % Check input
    if any(strcmpi(ions, ions_tic))
        options.ions = 'tic';
        
    elseif any(strcmpi(ions, ions_all))
        options.ions = 'all';
        
    elseif isnumeric(ions)
        options.ions = ions;
    end
    
    % Validate selection
    if ~ischar(options.ions) && ~strcmpi(options.ions, 'tic')
        options.samples(cellfun(@isempty, {data(options.samples).mz})) = [];
    end
    
    if isnumeric(options.ions)
        options.ions = options.ions(options.ions <= min(cellfun(@length, {data(options.samples).mz})));
        options.ions = options.ions(options.ions >= 1);
        options.ions = unique(options.ions, 'stable');
    end
end

% ---------------------------------------
% Option: 'baseline'
% ---------------------------------------
if ~isempty(input('baseline'))
    baseline = varargin{input('baseline')+1};
    
    baseline_on = {...
        'on',...
        'show',...
        'display'};
    
    baseline_off = {...
        'default',...
        'off',...
        'hide'};
    
    baseline_corrected = {...
        'corrected',...
        'correct',...
        'subtract',...
        'subtracted'};
    
    % Check input
    if any(strcmpi(baseline, baseline_off))
        options.baseline = 'off';
        
    elseif any(strcmpi(baseline, baseline_on))
        options.baseline = 'on';
        
    elseif any(strcmpi(baseline, baseline_corrected))
        options.baseline = 'corrected';
    end    
end

% ---------------------------------------
% Option: 'layout'
% ---------------------------------------
if ~isempty(input('layout'))
    layout = varargin{input('layout')+1};
    
    layout_stacked = {...
        'default',...
        'stacked',...
        'stack',...
        'separate',...
        'separated'};
    
    layout_overlaid = {...
        'overlaid',...
        'overlay',...
        'overlap'};
    
    % Check input
    if any(strcmpi(layout, layout_stacked))
        options.layout = 'stacked';
        
    elseif any(strcmpi(layout, layout_overlaid))
        options.layout = 'overlaid';
    end
end

% ---------------------------------------
% Option: 'scale'
% ---------------------------------------
if ~isempty(input('scale'))
    scale = varargin{input('scale')+1};
    
    scale_normalize = {...
        'default',...
        'normalize',...
        'normalized',...
        'relative'};
    
    scale_full = {...
        'absolute',...
        'full',...
        'original'};
    
    % Check input
    if any(strcmpi(scale, scale_normalize))
        options.scale = 'normalized';
        
    elseif any(strcmpi(scale, scale_full))
        options.scale = 'full';
    end
end

% ---------------------------------------
% Option: 'scope'
% ---------------------------------------
if ~isempty(input('scope'))
    scope = varargin{input('scope')+1};
    
    scope_local = {...
        'default',...
        'local',...
        'sample',...
        'individual'};
    
    scope_global = {...
        'global',...
        'all',...
        'samples',...
        'group'};
    
    % Check input
    if any(strcmpi(scope, scope_local))
        options.scope = 'local';
        
    elseif any(strcmpi(scope, scope_global))
        options.scope = 'global';
    end
end

% ---------------------------------------
% Option: 'xlim'
% ---------------------------------------
if ~isempty(input('xlim'))
    xlimits = varargin{input('xlim')+1};
    
    % Check input
    if ~isnumeric(xlimits) || any(strcmpi(xlimits, {'default', 'auto'}))
        options.xlimits = [];
        options.xpermission = 'write';
        
    elseif xlimits(2) < xlimits(1) || length(xlimits) ~= 2;
        options.xlimits = [];
        options.xpermission = 'write';
        
    elseif isnumeric(xlimits)
        options.xlimits = xlimits;
        options.xpermission = 'read';
    end
end

% ---------------------------------------
% Option: 'ylim'
% ---------------------------------------
if ~isempty(input('ylim'))
    ylimits = varargin{input('ylim')+1};
    
    % Check input
    if ~isnumeric(ylimits) || any(strcmpi(ylimits, {'default', 'auto'}))
        options.ylimits = [];
        options.ypermission = 'write';
        
    elseif ylimits(2) < ylimits(1) || length(ylimits) ~= 2
        options.ylimits = [];
        options.ypermission = 'write';
        
    elseif isnumeric(ylimits)
        options.ylimits = ylimits;
        options.ypermission = 'read';
    end
end

% ---------------------------------------
% Option: 'padding'
% ---------------------------------------
if ~isempty(input('padding'))
    padding = varargin{input('padding')+1};
    
    % Check input
    if any(strcmpi(padding, {'default', 'on'}))
        options.padding = 0.05;
        
    elseif any(strcmpi(padding, {'off', 'none'}))
        options.padding = 0.0;
        
    elseif padding(1) < 0 || padding(1) > 1
        options.padding = 0.05;
        
    elseif isnumeric(padding)
        options.padding = padding(1);
    end
end

% ---------------------------------------
% Option: 'offset'
% ---------------------------------------
if ~isempty(input('offset'))
    offset = varargin{input('offset')+1};
    
    % Check input
    if any(strcmpi(offset, {'on'}))
        options.offset = 0.05;
        
    elseif any(strcmpi(offset, {'default', 'off', 'none'}))
        options.offset = 0.0;
        
    elseif isnumeric(offset)
        options.offset = offset(1);
    end
end

% ---------------------------------------
% Option: 'linewidth'
% ---------------------------------------
if ~isempty(input('linewidth'))
    linewidth = varargin{input('linewidth')+1};
    
    % Check input
    if strcmpi(linewidth, 'default') || ischar(linewidth)
        options.linewidth = 1.0;
        
    elseif linewidth <= 0
        options.linewidth = 1.0;
        
    elseif isnumeric(linewidth)
        options.linewidth = linewidth(1);
    end
end

% ---------------------------------------
% Option: 'legend'
% ---------------------------------------
if ~isempty(input('legend'))
    legend = varargin{input('legend')+1};
    
    legend_on = {...
        'on',...
        'show',...
        'display'};
    
    legend_off = {...
        'default',...
        'off',...
        'hide'};
    
    % Check input
    if any(strcmpi(legend, legend_off))
        options.legend = 'off';
        
    elseif any(strcmpi(legend, legend_on))
        options.legend = 'on';
    end
end

% ---------------------------------------
% Option: 'color'
% ---------------------------------------
if ~isempty(input('color'))
    color = varargin{input('color')+1};
    
    color_name = {...
        'red',   [0.85, 0.25, 0.20];......
        'green', [0.00, 0.76, 0.23];......
        'blue',  [0.14, 0.35, 0.55];......
        'black', [0.15, 0.15, 0.15];......
        'gray',  [0.50, 0.50, 0.50]};
    
    % Check input
    if iscell(color)
        color = color{1};
    end
    
    if ischar(color)
        color_selection = strcmpi(color, color_name(:,1));
        
        if any(color_selection)
            options.color = color_name(color_selection,2);
        end
        
    elseif isnumeric(color)
        
        if min(color) > 1 && max(color) <= 255
            color = color / 255;
        else
            color(color > 255) = 1;
            color(color < 0) = 0;    
        end
        
        if length(color) == 1
            options.color(1:3) = color;
        
        elseif length(color) == 2
            options.color(1:2) = color;
            options.color(3) = mean(color);
                
        else
            options.color = color(1:3);
        end
        
    end
end

% ---------------------------------------
% Option: 'colormap'
% ---------------------------------------
if ~isempty(input('colormap'))
    colormap = varargin{input('colormap')+1};
    
    colormap_list = {...
        'parula',...
        'jet',...
        'hsv',...
        'hot',...
        'cool',...
        'spring',...
        'summer',...
        'autumn',...
        'winter',...
        'gray',...
        'bone',...
        'copper',...
        'pink',...
        'lines'};
        
    % Check input
    if any(strcmpi(colormap, colormap_list))
        options.colormap = colormap;
    end
    
    if isempty(input('color'))
        options.color = [];
    else
        options.colormap = [];
    end
    
elseif ~isempty(input('color')) || numel(options.samples) > 20
    options.colormap = [];
end


% ---------------------------------------
% Option: 'fontname'
% ---------------------------------------
if ~isempty(input('fontname'))
    fontname = varargin{input('fontname')+1};
    
    if ischar(fontname) && any(strcmpi(fontname, listfonts))
        options.fontname = fontname;
    end
    
else    
    if ~any(strcmpi(options.fontname, listfonts))
        options.fontname = 'arial';
    end
end

% ---------------------------------------
% Option: 'position'
% ---------------------------------------
if ~isempty(input('position'))
    position = varargin{input('position')+1};
    
    if isnumeric(position) && length(position) == 4
        options.position = position;
    end
end

% ---------------------------------------
% Option: 'position_units'
% ---------------------------------------
if ~isempty(input('position_units'))
    units = varargin{input('position_units')+1};
    
    units_default = {...
        'default',...
        'normalized'};
    
    units_other = {...
        'pixels',...
        'inches',...
        'centimeters',...
        'points',...
        'characters'};
    
    if any(strcmpi(units, units_default))
        options.position_units = 'normalized';
        
    elseif any(strcmpi(units, units_other))
        options.position_units = units;
    end
end

% ---------------------------------------
% Option: 'filename'
% ---------------------------------------
if ~isempty(input('filename'))
    filename = varargin{input('filename')+1};
    
    if ischar(filename) 
        options.filename = filename;
    end
end 

% ---------------------------------------
% Option: 'export'
% ---------------------------------------
if ~isempty(input('export'))
    export = varargin{input('export')+1};
    
    % Check input
    if strcmpi(export, 'on')
        
        options.export = {...
            options.filename,...
            '-dpng',...
            '-r300'};
        
    elseif iscell(export)
        options.export = export;
        
    elseif any(strcmpi(export, {'default', 'off'}))
        options.export = [];
    end
end

% Return input
varargout{1} = data;
varargout{2} = options;

end
