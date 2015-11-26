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
%   Plot Data
%   ----------------------------------------------------------------------
%   'samples' (optional)
%       Description : index of samples in data
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
%   'peaks' (optional)
%       Description : show peaks
%       Type        : 'on', 'off'
%       Default     : 'off'
%
%   ----------------------------------------------------------------------
%   Plot Layout
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
%       Description : adjust scale to sample maximum or global maximum
%       Type        : 'local', 'global'
%       Default     : 'local'
%
%   'padding' (optional)
%       Description : white space between axes and plot lines
%       Type        : number
%       Default     : 0.05
%       Range       : 0.0 to 1.0
%
%   'offset' (optional)
%       Description : sequential y-offset applied to each sample
%       Type        : number
%       Default     : 0.0
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
%       Default     : 1.5
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

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;
ions = options.ions;

if isempty(samples)
    disp('Error: No samples match input criteria...');
    return
end

% Initialize axes
options = plot_axes(obj, options, data);

% Initialize legend
if strcmp(options.legend, 'on')
    options = plot_legend(options, data);
end

% Initialize plot
for i = 1:length(samples)
    
    % Counter
    options.i = i;
    
    % Input values
    x = data(samples(i)).time;
    
    % Check ion options
    if isnumeric(ions)
        ions = 'xic';
    end
    
    switch ions
        
        case 'tic'
            
            % Input values
            y = data(samples(i)).tic.values;
            
            % Check for sparse matrix
            if issparse(y)
                y = full(y);
            end
            
            % Check baseline
            if any(strcmpi(options.baseline, {'on', 'corrected'}))
                baseline = data(samples(i)).tic.baseline;
            else
                baseline = [];
            end
            
            % Check peaks
            if any(strcmpi(options.peaks, {'on', 'residuals'}))
                peaks = data(samples(i)).tic.peaks.fit;
            else
                peaks = [];
            end
            
            % Display names
            if strcmpi(options.legend, 'on')
                names = options.name(i);
            else
                names = {''};
            end
            
        case 'all'
            
            % Input values
            y = data(samples(i)).xic.values;
            
            % Check for sparse matrix
            if issparse(y)
                y = full(y);
            end
            
            % Check baseline
            if any(strcmpi(options.baseline, {'on', 'corrected'}))
                baseline = data(samples(i)).xic.baseline;
                
                if ~isempty(baseline)
                    
                    if sum(sum(baseline)) == 0
                        baseline = [];
                    end
                end
            else
                baseline = [];
            end
            
            % Check peaks
            if any(strcmpi(options.peaks, {'on', 'residuals'}))
                peaks = data(samples(i)).xic.peaks.fit;
            else
                peaks = [];
            end
            
            % Display names
            names(1:length(data(samples(i)).mz(options.ions))) = {''};
            
            if strcmpi(options.legend, 'on')
                mz = data(samples(i)).mz(options.ions);
                mz = round(mz * 1E4) ./ 1E4;
                
                [keys, index] = ismember(mz, options.keys);
                
                if any(keys)
                    names(index(keys)) = options.name(keys);
                end
            end
            
        case 'xic'
            
            % Input values
            y = data(samples(i)).xic.values(:, options.ions);
            
            % Check for sparse matrix
            if issparse(y)
                y = full(y);
            end
            
            % Check baseline
            if any(strcmpi(options.baseline, {'on', 'corrected'}))
                baseline = data(samples(i)).xic.baseline;
                
                if ~isempty(baseline)
                    
                    if sum(sum(baseline)) > 0
                        baseline = baseline(:, options.ions);
                    else
                        baseline = [];
                    end
                end
            else
                baseline = [];
            end
            
            % Check peaks
            if any(strcmpi(options.peaks, {'on', 'residuals'}))
                peaks = data(samples(i)).xic.peaks.fit;
                
                if ~isempty(peaks)
                    peaks = peaks(:, options.ions);
                end
            else
                peaks = [];
            end
            
            % Display names
            names(1:length(data(samples(i)).mz(options.ions))) = {''};
            
            if strcmpi(options.legend, 'on')
                mz = data(samples(i)).mz(options.ions);
                mz = round(mz * 1E4) ./ 1E4;
                
                [keys, index] = ismember(mz, options.keys);
                
                if any(keys)
                    names(index(keys)) = options.name(keys);
                end
            end
    end
    
    % Check baseline
    if ~isempty(baseline) && strcmpi(options.baseline, 'corrected');
        y = y - baseline;
    elseif isempty(baseline)
        options.baseline = 'off';
    end
    
    % Check peaks
    if isempty(peaks)
        options.peaks = 'off';
    end
    
    % Determine x-axis limits
    options = plot_xlim(x, options);
    
    % Calculate scale and layout
    [y, options] = plot_scale(y, options);
    y = plot_layout(y, options);
    
    % Determine y-axis limits
    options = plot_ylim(x, y, options);
    
    % Initialize plots
    
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
    
    % Check baseline options
    if strcmpi(options.baseline, 'on')
        
        baseline = plot_scale(baseline, options, 1);
        
        if strcmpi(options.scale, 'normalized')
            baseline = baseline ./ 100;
        end
        
        baseline = plot_layout(baseline, options);
        
        plot(x, baseline, ...
            'parent', options.axes, ...
            'linewidth', options.linewidth, ...
            'color', [0.99,0.1,0.23]);
    end
end

% Display figure
set(options.figure, 'visible', 'on');

% Update plot properties
plot_update(options);

% Update axes position
set(options.empty, 'position', get(options.axes, 'position'));

% Export figure
if ~isempty(options.export)
    
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

% Output
varargout{1} = options;

end


% Legend options
function options = plot_legend(options, data)

% Check ion options
if isnumeric(options.ions)
    ions = 'xic';
else
    ions = options.ions;
end

switch ions
    
    case 'tic'
        samples = [data(options.samples).sample];
        
        % Variables
        options.name = {samples.name};
        options.keys = 1:length(options.samples);
        
    case 'all'
        mz = [data(options.samples).mz];
        mz = round(mz * 1E4) ./ 1E4;
        mz = unique(mz, 'stable');
        
        % Convert values to strings
        names = arrayfun(@num2str, mz, 'uniformoutput', false);
        names = cellfun(@(x) strcat(x, ' m/z'), names, 'uniformoutput', false);
        
        % Variables
        options.name = names;
        options.keys = mz;
        
    case 'xic'
        
        mz = [];
        
        for i = 1:length(options.samples)
            mz = [mz, data(options.samples(i)).mz(options.ions)];
        end
        
        mz = round(mz * 1E4) ./ 1E4;
        mz = unique(mz, 'stable');
        
        % Convert values to strings
        names = arrayfun(@num2str, mz, 'uniformoutput', false);
        names = cellfun(@(x) strcat(x, ' m/z'), names, 'uniformoutput', false);
        
        % Variables
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
function y = plot_layout(y, options)

% Determine stacked layout
if strcmpi(options.layout, 'stacked') && length(options.samples) > 1
    
    % Normalized scale
    if strcmpi(options.scale, 'normalized')
        
        % Calculate offset
        y = y - (options.i * 100) * (1 + options.padding + options.offset);
        
        % Full scale
    elseif strcmpi(options.scale, 'full')
        
        % Determine y-limits
        if isempty(options.ylimits)
            options.ylimits(1) = min(min(y));
            options.ylimits(2) = max(max(y));
        end
        
        % Calculate offset
        padding = options.ylimits(2) * options.padding;
        offset = options.ylimits(2) * options.offset;
        
        y = y - (options.i-1) * (options.ylimits(2) + padding + offset);
    end
    
elseif strcmpi(options.layout, 'overlaid') && length(options.samples) > 1
    
    % Normalized scale
    if options.offset ~= 0 && strcmpi(options.scale, 'normalized')
        
        % Calculate offset
        y = y - (options.i * 100) * options.offset;
        
        % Full scale
    elseif options.offset ~= 0 && strcmpi(options.scale, 'full')
        
        % Determine y-limits
        if isempty(options.ylimits)
            options.ylimits(1) = min(min(y));
            options.ylimits(2) = max(max(y));
        end
        
        % Calculate offset
        y = y - options.i * (options.ylimits(2) * options.offset);
    end
    
end
end


% Check x-limits options
function options = plot_xlim(x, options)

% Determine min/max
xmin = min(min(x));
xmax = max(max(x));

% Automatic x-limits
if isempty(options.xlimits)
    options.xlimits = [xmin, xmax];
    
    % Manual x-limits
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
function options = plot_ylim(x, y, options)

% Find x-limits
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

% Determine y-limits
ymin = min(min(y(xmin:xmax,:)));

if strcmpi(options.layout, 'stacked') && strcmpi(options.scale, 'normalized')
    y = y + (options.i * 100) - 100;
end

ymax = max(max(y(xmin:xmax,:)));

% Automatic y-limits
if isempty(options.ylimits)
    options.ylimits = [ymin, ymax];
    
    % Manual y-limits
elseif strcmpi(options.ypermission, 'write')
    
    if ymin < options.ylimits(1)
        options.ylimits(1) = ymin;
    end
    
    if ymax > options.ylimits(2)
        options.ylimits(2) = ymax;
    end
end

end


% Update plot properties
function plot_update(options)

% Axes padding
padding.x = (options.xlimits(2) - options.xlimits(1)) * (options.padding);
padding.y = (options.ylimits(2) - options.ylimits(1)) * options.padding;

% Axes limits
set(options.axes, 'xlim', [options.xlimits(1)-padding.x, options.xlimits(2)+padding.x]);
set(options.axes, 'ylim', [options.ylimits(1)-padding.y, options.ylimits(2)+padding.y]);

% Show legend
if strcmpi(options.legend, 'on')
    
    % Check number of legend entries
    if length(options.name) > 25
        legend(options.axes, 'hide');
    else
        legend(options.axes, 'show', 'string', options.name);
    end
    
    % Hide legend
elseif strcmpi(options.legend, 'off')
    legend(options.axes, 'hide');
end

end


% Initialize axes
function options = plot_axes(obj, options, data)

% Axes properties
options.font.name = 'Avenir';
options.font.size = 14;
options.line.color = [0.23,0.23,0.23];
options.line.width = 1.25;
options.ticks.size = [0.007, 0.0075];

% Initialize figure
options.figure = figure(...
    'color', 'white',...
    'numbertitle', 'off',...
    'name', 'Chromatography Toolbox',...
    'units', 'normalized',....
    'position', obj.defaults.plot_position,...
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
    
    % Extracted ion chromatograms (selected)
    n = length(options.ions);
    
elseif strcmpi(options.ions, 'all')
    
    % Extracted ion chromatograms (all)
    n = length(data(options.samples(1)).mz);
    
else
    
    % Total ion chromatograms
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
    % Use full amount of colors
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

hold all

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
    set(options.axes, 'ytick', [], 'looseinset', [0.05, 0.1, 0.05, 0.05]);
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
        'actionpostcallback', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
catch
end

% Version specific options
if verLessThan('matlab', 'R2014b')
    
    try
        % Resize callback
        set(options.figure,...
            'resizefcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
    catch
    end
else
    
    % Resize callback
    set(options.figure,...
        'sizechangedfcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
    
    % Axes overlap
    set(get(get(options.axes, 'yruler'),'axle'), 'visible', 'off');
    set(get(get(options.axes, 'xruler'),'axle'), 'visible', 'off');
    set(get(get(options.axes, 'ybaseline'),'axle'), 'visible', 'off');
end

end


% Parse user input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif isstruct(varargin{1})
    data = obj.format('validate', varargin{1});
    
else
    error('Undefined input arguments of type ''data''.');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Sample options
if ~isempty(input('samples'))
    samples = varargin{input('samples')+1};
    
    % Set keywords
    samples_all = {'default', 'all'};
    
    % Check for valid input
    if any(strcmpi(samples, samples_all))
        samples = 1:length(data);
        
        % Check input type
    elseif ~isnumeric(samples)
        
        % Check string input
        samples = str2double(samples);
        
        % Check for numeric input
        if ~any(isnan(samples))
            samples = round(samples);
        else
            samples = 1:length(data);
        end
    end
    
    % Check maximum input value
    if max(samples) > length(data)
        samples = samples(samples <= length(data));
    end
    
    % Check minimum input value
    if min(samples < 1)
        samples = samples(samples >= 1);
    end
    
    options.samples = samples;
    
else
    options.samples = 1:length(data);
end


% Ion options
if ~isempty(input('ions'))
    ions = varargin{input('ions')+1};
    
    % Set keywords
    ions_tic = {'default', 'tic', 'tics', 'total_ion_chromatograms'};
    ions_all = {'all', 'xic', 'xics', 'eic', 'eics', 'extracted_ion_chromatograms'};
    
    % Check for valid input
    if any(strcmpi(ions, ions_tic))
        options.ions = 'tic';
        
    elseif any(strcmpi(ions, ions_all))
        options.ions = 'all';
        
    elseif ~isnumeric(ions) && ~ischar(ions)
        options.ions = 'tic';
        
    else
        options.ions = ions;
    end
    
    if ~ischar(options.ions) && ~strcmpi(options.ions, 'tic')
        
        % Remove samples without ions
        options.samples(cellfun(@isempty, {data(options.samples).mz})) = [];
    end
    
    % Check input range
    if isnumeric(options.ions)
        
        % Check maximum input value
        if any(max(options.ions) > cellfun(@length, {data(options.samples).mz}))
            options.ions = options.ions(options.ions <= min(cellfun(@length, {data(options.samples).mz})));
        end
        
        % Check minimum input value
        if min(options.ions) < 1
            options.ions = options.ions(options.ions >= 1);
        end
        
        % Filter duplicates and sort
        options.ions = unique(options.ions, 'stable');
    end
    
else
    options.ions = 'tic';
end


% Baseline options
if ~isempty(input('baseline'))
    baseline = varargin{input('baseline')+1};
    
    % Set keywords
    baseline_on = {'on', 'show', 'display'};
    baseline_off = {'default', 'off', 'hide'};
    baseline_corrected = {'corrected', 'correct', 'subtract', 'subtracted'};
    
    % Check for valid input
    if any(strcmpi(baseline, baseline_off))
        options.baseline = 'off';
        
        % Check input type
    elseif any(strcmpi(baseline, baseline_on))
        options.baseline = 'on';
        
    elseif any(strcmpi(baseline, baseline_corrected))
        options.baseline = 'corrected';
        
    else
        options.baseline = 'off';
    end
    
else
    options.baseline = 'off';
end


% Peak options
if ~isempty(input('peaks'))
    peaks = varargin{input('peaks')+1};
    
    % Set keywords
    peaks_on = {'on', 'show', 'display'};
    peaks_off = {'default', 'off', 'hide'};
    peaks_residuals = {'residuals', 'residual', 'error', 'errors'};
    
    % Check for valid input
    if any(strcmpi(peaks, peaks_off))
        options.peaks = 'off';
        
        % Check input type
    elseif any(strcmpi(peaks, peaks_on))
        options.peaks = 'on';
        
    elseif any(strcmpi(peaks, peaks_residuals))
        options.peaks = 'corrected';
        
    else
        options.peaks = 'off';
    end
    
else
    options.peaks = 'off';
end


% Layout options
if ~isempty(input('layout'))
    layout = varargin{input('layout')+1};
    
    % Set keywords
    layout_stacked = {'default', 'stacked', 'stack', 'separate', 'separated'};
    layout_overlaid = {'overlaid', 'overlay', 'overlap', 'full'};
    
    % Check for valid input
    if any(strcmpi(layout, layout_stacked))
        options.layout = 'stacked';
        
    elseif any(strcmpi(layout, layout_overlaid))
        options.layout = 'overlaid';
        
    else
        options.layout = 'stacked';
    end
    
else
    options.layout = 'stacked';
end


% Scale options
if ~isempty(input('scale'))
    scale = varargin{input('scale')+1};
    
    % Set keywords
    scale_normalize = {'default', 'normalize', 'normalized', 'relative', 'separate'};
    scale_full = {'absolute', 'full', 'all'};
    
    % Check for valid input
    if any(strcmpi(scale, scale_normalize))
        options.scale = 'normalized';
        
    elseif any(strcmpi(scale, scale_full))
        options.scale = 'full';
        
    else
        options.scale = 'normalized';
    end
    
else
    
    if strcmpi(options.ions, 'tic')
        options.scale = 'normalized';
    else
        options.scale = 'full';
    end
end


% Scaling reference options
if ~isempty(input('scope'))
    scope = varargin{input('scope')+1};
    
    % Set keywords
    scale_local = {'default', 'local', 'separated', 'separate', 'relative'};
    scale_global = {'global', 'all', 'full'};
    
    % Check for valid input
    if any(strcmpi(scope, scale_local))
        options.scope = 'local';
        
    elseif any(strcmpi(scope, scale_global))
        options.scope = 'global';
        
    else
        options.scope = 'local';
    end
    
else
    options.scope = 'local';
end


% X-limits options
if ~isempty(input('xlim'))
    xlimits = varargin{input('xlim')+1};
    
    % Check for valid input
    if ~isnumeric(xlimits) || any(strcmpi(xlimits, {'default', 'auto'}))
        
        % Automatic x-limits
        options.xlimits = [];
        options.xpermission = 'write';
        
        % Check input length
    elseif xlimits(2) < xlimits(1) || length(xlimits) ~= 2;
        
        % Automatic x-limits
        options.xlimits = [];
        options.xpermission = 'write';
        
    else
        % Manual x-limits
        options.xlimits = xlimits;
        options.xpermission = 'read';
    end
    
else
    options.xlimits = [];
    options.xpermission = 'write';
end


% Y-limits options
if ~isempty(input('ylim'))
    ylimits = varargin{input('ylim')+1};
    
    % Check user input
    if ~isnumeric(ylimits) || any(strcmpi(ylimits, {'default', 'auto'}))
        
        % Automatic y-limits
        options.ylimits = [];
        options.ypermission = 'write';
        
        % Check input length
    elseif ylimits(2) < ylimits(1) || length(ylimits) ~= 2
        
        % Automatic y-limits
        options.ylimits = [];
        options.ypermission = 'write';
        
    else
        % Manual y-limits
        options.ylimits = ylimits;
        options.ypermission = 'read';
    end
    
else
    options.ylimits = [];
    options.ypermission = 'write';
end


% Axes padding
if ~isempty(input('padding'))
    padding = varargin{input('padding')+1};
    
    % Check for valid input
    if any(strcmpi(padding, {'default', 'on'}))
        options.padding = 0.05;
        
    elseif any(strcmpi(padding, {'off', 'none'}))
        options.padding = 0;
        
        % Check input range
    elseif padding(1) < 0 || padding(1) > 0.99
        options.padding = 0.05;
    else
        options.padding = padding(1);
    end
    
else
    options.padding = 0.05;
end


% Axes offset
if ~isempty(input('offset'))
    offset = varargin{input('offset')+1};
    
    % Check for valid input
    if any(strcmpi(offset, {'on'}))
        options.offset = 0.05;
        
    elseif any(strcmpi(offset, {'default', 'off', 'none'}))
        options.offset = 0;
        
    else
        options.offset = offset(1);
    end
    
else
    options.offset = 0;
end


% Linewidth options
if ~isempty(input('linewidth'))
    linewidth = varargin{input('linewidth')+1};
    
    % Check for valid input
    if strcmpi(linewidth, 'default') || ischar(linewidth)
        options.linewidth = 1.5;
        
    elseif linewidth <= 0
        options.linewidth = 1.5;
        
    else
        options.linewidth = linewidth(1);
    end
    
else
    options.linewidth = 1.5;
end


% Legend options
if ~isempty(input('legend'))
    legend = varargin{input('legend')+1};
    
    % Check for valid input
    if any(strcmpi(legend, {'default', 'off', 'hide'}))
        options.legend = 'off';
        
    elseif any(strcmpi(legend, {'on', 'show', 'display'}))
        options.legend = 'on';
        
    else
        options.legend = 'off';
    end
    
else
    options.legend = 'off';
end


% Color options
if ~isempty(input('color'))
    
    options.color = varargin{input('color')+1};
    
    color_name = {'red', 'green', 'blue', 'black', 'gray'};
    color_value = {[0.85,0.25,0.2], [0,0.76,0.23], [0.14,0.35,0.55], [0.15,0.15,0.15], [0.5,0.5,0.5]};
    
    % Check input
    if iscell(options.color)
        options.color = options.color{1};
    end
    
    if ischar(options.color)
        color_match = strcmpi(options.color, color_name);
        
        % Check match
        if any(color_match)
            options.color = color_value(color_match);
        else
            options.color = [0.15,0.15,0.15];
        end
        
    elseif isnumeric(options.color)
        
        % Check values
        if min(options.color) > 1 && max(options.color) <= 255
            options.color = options.color / 255;
        end
        
        % Check out of range valies
        options.color(options.color > 255) = 1;
        options.color(options.color < 0) = 0;
        
        % Check length
        switch length(options.color)
            
            case 1
                options.color(2:3) = options.color(1);
            case 2
                options.color(3) = mean(options.color);
            case 3
                options.color = options.color;
                
            otherwise
                options.color = options.color(1:3);
        end
        
    else
        options.color = [];
    end
    
else
    options.color = [];
end


% Colormap options
if ~isempty(input('colormap')) && isempty(options.color)
    options.colormap = varargin{input('colormap')+1};
    
    default = obj.defaults.plot_colormap;
    
    % Check MATLAB version
    if verLessThan('matlab', 'R2014b')
        
        colormaps = {...
            'jet', 'hsv', 'hot', 'cool', 'spring', 'summer',...
            'autumn', 'winter', 'gray', 'bone', 'copper', 'pink', 'lines'};
        
    else
        colormaps = {...
            'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer',...
            'autumn', 'winter', 'gray', 'bone', 'copper', 'pink', 'lines'};
    end
    
    % Check for valid input
    if isnumeric(options.colormap)
        
        % Check for RGB array
        if length(options.colormap(1,:)) ~= 3 || any(any(options.colormap > 1)) || any(any(options.colormap < 0))
            options.colormap = default;
        end
        
        % Check for default
    elseif strcmpi(options.colormap, 'default')
        options.colormap = default;
        
        % Check for colormap name
    elseif ~any(strcmpi(options.colormap, colormaps));
        options.colormap = default;
    end
    
elseif ~isempty(options.color)
    options.colormap = [];
    
else
    options.colormap = obj.defaults.plot_colormap;
end


% Export options
if ~isempty(input('export'))
    export = varargin{input('export')+1};
    
    % Check for valid input
    if strcmpi(export, 'on')
        
        % Set default options
        options.export = {'chromatography_export', '-dpng', '-r300'};
        
    elseif iscell(export)
        options.export = export;
        
    elseif any(strcmpi(export, {'default', 'off'}))
        options.export = [];
        
    else
        options.export = [];
    end
    
else
    options.export = [];
end

% Variables
options.name = {};

% Return input
varargout{1} = data;
varargout{2} = options;

end
