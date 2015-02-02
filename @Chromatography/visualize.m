% Method: visualize
%  -Plot chromatograms, baselines, and curve fitting results
%
% Syntax
%   fig = visualize(data)
%   fig = visualize(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'  : 'all', [sampleindex]
%   'ions'     : 'all', 'tic', [ionindex]
%   'baseline' : 'on', 'off', 'corrected'
%   'peaks'    : 'on', 'off', 'residuals'
%   'layout'   : 'stacked', 'overlaid'
%   'scale'    : 'normalized', 'full'
%   'xlim'     : 'auto', [xmin, xmax]
%   'ylim'     : 'auto', [ymin, ymax]
%   'legend'   : 'on', 'off'
%   'export'   : see MATLAB documentation on print functions
%   'colormap' : 'parula', 'jet', 'hsv', 'hot', 'cool', 'spring', 'summer', 
%                'autumn', 'winter', 'jet' 'gray', 'bone', 'copper', 'pink'
%
% Description
%   data       : an existing data structure     
%   'samples'  : row index of samples in data structure -- (default: 'all')
%   'ions'     : column index of ions in data structure -- (default: 'tic')
%   'baseline' : display baseline/baseline corrected spectra -- (default: 'off')
%   'peaks'    : display curve fitting results for available peaks -- (default: 'off')
%   'layout'   : plot spectra in a stacked or overlaid format -- (default: 'overlaid')
%   'scale'    : display spectra on a normalized scale or full scale -- (default: 'full')
%   'xlim'     : x-axis limits -- (default: 'auto')
%   'ylim'     : y-axis limits -- (default: 'auto')
%   'legend'   : add legend to plot -- (default: 'off')
%   'export'   : cell array passed to the MATLAB print function -- (default: none)
%   'colormap' : select colormap to use for plotting -- (default: 'parula')
%
% Examples
%   fig = obj.visualize(data, 'samples', [1:4], 'ions', 'tic', 'baseline', 'on')
%   fig = obj.visualize(data, 'layout', 'stacked', 'scale', 'normalized')
%   fig = obj.visualize(data, 'peaks', 'residuals', 'baseline', 'on')
%   fig = obj.visualize(data, 'scale', 'normalized', 'baseline', 'corrected')
%   fig = obj.visualize(data, 'samples', 1, 'peaks', 'on', 'baseline', 'on')
%   fig = obj.visualize(data, 'ions', 'all', 'colormap', 'jet', 'export', 'export', {'mydata', '-dtiff', '-r300'}

function varargout = visualize(obj, varargin)

% Check input
if nargin < 2
    error('Not enough input arguments');
elseif isstruct(varargin{1})
    data = DataStructure('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check sample options
if ~isempty(input('samples'))
    options.samples = varargin{input('samples')+1};
                    
    % Check for valid input
    if strcmpi(options.samples, 'all')
        options.samples = 1:length(varargin{1});
    elseif ~isnumeric(options.samples)
        error('Undefined input arguments of type ''samples''');
    elseif length(options.samples(:,1)) > 1 && length(options.samples(1,:)) > 1
        error('Undefined input arguments of type ''samples''');
    elseif max(options.samples) > length(data) || min(options.samples) < 1
        error('Index exceeds matrix dimensions')
    end 
else
    % Default samples options
    options.samples = 1:length(varargin{1});
end

% Check ion options
if ~isempty(input('ions'))
    options.ions = varargin{input('ions')+1};
    
    % Check for valid input
    if isnumeric(options.ions)
        if min(options.ions) <= 0
            options.ions = 'tic';
        elseif max(options.ions) > max(cellfun(@length, {data.mass_values}))
            options.ions = 'tic';
        end
    elseif ~strcmpi(options.ions, 'all') && ~strcmpi(options.ions, 'tic')
        options.ions = 'tic';
    end 
else
    % Default ions options
    options.ions = 'tic';
end

% Check baseline options
if ~isempty(input('baseline'))
    options.baseline = varargin{input('baseline')+1};
    
    % Check for valid input
    if ~strcmpi(options.baseline, 'on') && ~strcmpi(options.baseline, 'off') && ~strcmpi(options.baseline, 'corrected')        
        error('Undefined input arguments of type ''baseline''');
    end
else
    % Default baselines options
    options.baseline = 'off';
end

% Check peak options
if ~isempty(input('peaks'))
    options.peaks = varargin{input('peaks')+1};
    
    % Check for valid input
    if ~strcmpi(options.peaks, 'on') && ~strcmpi(options.peaks, 'off') && ~strcmpi(options.peaks, 'residuals')        
        error('Undefined input arguments of type ''peaks''');
    end
else
    % Default peak options
    options.peaks = 'off';
end

% Check layout options
if ~isempty(input('layout'))
    options.layout = varargin{input('layout')+1};
    
    % Check for valid input
    if strcmpi(options.layout, 'overlay') || strcmpi(options.layout, 'overlap')
        options.layout = 'overlaid';
    elseif strcmpi(options.layout, 'stack')
        options.layout = 'stacked';
    elseif ~strcmpi(options.layout, 'stacked') && ~strcmpi(options.layout, 'overlaid')        
        options.layout = 'overlaid';
    end
else
    % Default peak options
    options.layout = 'overlaid';
end

% Check scale options
if ~isempty(input('scale'))
    options.scale = varargin{input('scale')+1};
    
    % Check for valid input
    if strcmpi(options.scale, 'normalize') || strcmpi(options.scale, 'separate')
        options.scale = 'normalized';
    elseif ~strcmpi(options.scale, 'normalized') && ~strcmpi(options.scale, 'full')
        options.scale = 'full';
    end
else
    % Default scale options
    options.scale = 'full';
end

% Check xlim options
if ~isempty(input('xlim'))
    options.x = varargin{input('xlim')+1};
    options.x_permission = 'read';
    
    % Check for valid input
    if ~isnumeric(options.x) || strcmp(options.x, 'auto') || options.x(2) < options.x(1)
        options.x = [];
        options.x_permission = 'write';
    end
else
    % Default xlim options
    options.x = [];
    options.x_permission = 'write';
end

% Check ylim options
if ~isempty(input('ylim'))
    options.y = varargin{input('ylim')+1};
    options.y_permission = 'read';
    
    % Check user input
    if ~isnumeric(options.y) || strcmp(options.y, 'auto')
        options.y = [];
        options.y_permission = 'write';
    elseif length(options.y) > 2 || length(options.y) < 2
        error('Incorrect number of input arguments of type ''ylim''');
    end
else
    % Default for valid input
    options.y = [];
    options.y_permission = 'write';
end

% Check legend options
if ~isempty(input('legend'))
    options.legend = varargin{input('legend')+1};
    
    % Check for valid input
    if ~strcmpi(options.legend, 'on') && ~strcmpi(options.legend, 'off')
        if strcmpi(options.ions, 'tic') 
            options.legend = 'off';
        else
            options.legend = 'off';
        end
    end
else
    % Default legend options
    if strcmpi(options.ions, 'tic')
        options.legend = 'off';
    else
        options.legend = 'off';
    end
end

% Check colormap options
if ~isempty(input('colormap'))
    options.colormap = varargin{input('colormap')+1};
    
    % Check for valid input
    if ~ischar(options.colormap)
        options.colormap = 'parula';
    end
else
    % Default colormap options
    options.colormap = 'parula';
end

% Check export options
if ~isempty(input('export'))
    options.export = varargin{input('export')+1};
      
    % Check for valid input
    if ischar(options.export) && strcmpi(options.export, 'on')
        options.export = {'spectra', '-dpng', '-r300'};
    elseif ~iscell(options.export) && ~strcmpi(options.export, 'on')
        options.export = [];
    end
else
    options.export = [];
end

% Determine scaling factor
if strcmpi(options.layout, 'stacked') && strcmpi(options.scale, 'normalized')
    
    % Find max value in structure
    ymax = @(ydata) max(cellfun(@(y) max(max(y)), ydata));
    
    if strcmpi(options.ions, 'tic')
        options.yfactor = ymax({data(options.samples).total_intensity_values});
    elseif strcmpi(options.ions, 'all')
        options.yfactor = ymax({data(options.samples).intensity_values});
    else
        options.yfactor = ymax({data(options.samples).intensity_values});
    end
else
    options.yfactor = 0;
end

% Initialize axes
options = plot_axes(obj, options, data);

% Plot data
for i = 1:length(options.samples)
    
    % Set y data
    if strcmpi(options.ions, 'tic')
        y = data(options.samples(i)).total_intensity_values;
    elseif strcmp(options.ions, 'all')
        y = data(options.samples(i)).intensity_values;
    else
        y = data(options.samples(i)).intensity_values(:,options.ions);
    end                   
    
    % Set variables
    options.i = i;
    options.name = {};
    
    % Preprocess data
    y = plot_scale(y, options);
    y = plot_layout(y, options);
    
    % Plot data
    options = plot_ylim(y, options);
    y = [];
end

% Plot chromatograms
for i = 1:length(options.samples)
    
    % Counter
    options.i = i;
    
    % Determine x-values
    x = data(options.samples(i)).time_values;
    
    % Check ion options
    if ~ischar(options.ions)
        
        % Check user input
        if max(options.ions) > length(data(options.samples(i)).mass_values)
            error('Index exceeds matrix dimensions');
        end
        
        % Set y values
        y = data(options.samples(i)).intensity_values(:, options.ions);
        
        % Check baseline
        if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
            if ~isempty(data(options.samples(i)).intensity_values_baseline)
                baseline = data(options.samples(i)).intensity_values_baseline(:,options.ions);
            else
                options.baseline = 'off';
            end
        else
            baseline = [];
        end
        
        % Check peaks
        if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
           if ~isempty(data(options.samples(i)).intensity_values_peaks.fit)
               peaks = data(options.samples(i)).intensity_values_peaks.fit(1,options.ions);
           end
            if isempty(peaks)
                options.peaks = 'off';
            end
        else
            peaks = [];
        end
        
        % Check baseline correction
        if strcmpi(options.baseline, 'corrected')
            y = y - baseline;
        end
        
        % Determine display names
        for j = 1:length(options.ions)
            options.name{j} = strcat(num2str(data(options.samples(i)).mass_values(options.ions(j))), ' m/z');
        end
        
        % Filter duplicate names
        options.name = (unique(options.name, 'stable'));
        
    else
        switch options.ions
            
            % Use total ion chromatograms
            case 'tic'
                
                % Set y values
                y = data(options.samples(i)).total_intensity_values;
                
                % Check baseline
                if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
                    baseline = data(options.samples(i)).total_intensity_values_baseline;
                    if isempty(baseline)
                        options.baseline = 'off';
                    end
                else
                    baseline = [];
                end
        
                % Check peaks
                if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
                    peaks = data(options.samples(i)).total_intensity_values_peaks.fit{1,1};
                    if isempty(peaks)
                        options.peaks = 'off';
                    end
                else
                    peaks = [];
                end
                
                % Check baseline correction
                if strcmpi(options.baseline, 'corrected')
                    y = y - baseline;
                end
                
                % Determine display names
                options.name(end+1) = {data(options.samples(i)).file_name};
                options.name = (unique(options.name, 'stable'));
                
            % Use all ion chromatograms
            case 'all'
                
                % Set y values
                y = data(options.samples(i)).intensity_values;
                
                % Check baseline
                if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
                    baseline = data(options.samples(i)).intensity_values_baseline;
                    if isempty(baseline)
                        options.baseline = 'off';
                    end
                else
                    baseline = [];
                end
        
                % Check peaks
                if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
                    peaks = data(options.samples(i)).intensity_values_peaks.fit(1,:);
                    if isempty(peaks)
                        options.peaks = 'off';
                    end
                else
                    peaks = [];
                end
                
                % Check baseline correction
                if strcmpi(options.baseline, 'corrected')
                    y = y - baseline;
                end
                
                % Determine display names
                for j = 1:length(y(1,:))
                    options.name{j} = strcat(num2str(data(options.samples(i)).mass_values(j)), ' m/z');
                end
                
                % Filter duplicate names
                options.name = (unique(options.name, 'stable'));
        end
    end
    
    % Apply user input
    y = plot_scale(y, options);
    y = plot_layout(y, options);
    
    options = plot_xlim(x, options);
    options = plot_ylim(y, options);
    
    % Plot data
    switch version('-release')
    
        case '2014b'
            
            for j = 1:length(y(1,:))
                plot(x, y(:,j), ...
                    'parent', options.axes, ...
                    'linewidth', 1.5, ...
                    'displayname', options.name{j});
            end
            
        otherwise
            
            for j = 1:length(y(1,:))
                plot(x, y(:,j), ...
                    'parent', options.axes, ...
                    'linewidth', 1.5, ...
                    'linesmoothing', 'on',...
                    'displayname', options.name{j});
            end
    end
        
    % Check baseline options
    if strcmpi(options.baseline, 'on')
        
        if strcmpi(options.scale, 'normalized')
            baseline = (baseline-min(min(y))) / (max(max(y))-min(min(y)));
        end
        
        baseline = plot_layout(baseline, options);
        
        % Plot baseline
        plot(x, baseline, ...
            'parent', options.axes, ...
            'linewidth', 1.5, ...
            'color', [0.99,0.25,0.23]);
    end
end

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

% Display figure
set(options.figure, 'visible', 'on');

% Output
varargout{1} = options;

end

% Check scale options
function y = plot_scale(y, options)
    if strcmpi(options.scale, 'normalized')
        y = Normalize(y);
    end
end

% Check layout options
function y = plot_layout(y, options)
    if strcmpi(options.layout, 'stacked') && length(options.samples) > 1
        if strcmpi(options.scale, 'normalized')
            y = y - (options.i * 1.05);
        else
            if isempty(options.y)
                options.y(2) = max(max(y));
            end
            y = y - (options.i * (options.y(2)+(options.y(2)*0.05)));
        end
    end
end

% Check xlim options
function options = plot_xlim(x, options)

    % Determine y-limits
    xmin = min(min(x));
    xmax = max(max(x));
    
    if isempty(options.x)
        options.x = [xmin, xmax];
    elseif strcmpi(options.x_permission, 'write')        
        if options.x(1) > xmin
            options.x(1) = xmin;
        end
        if options.x(2) < xmax
            options.x(2) = xmax;
        end
    end
end

% Check ylim options
function options = plot_ylim(y, options)

    % Determine y-limits
    ymin = min(min(y));
    ymax = max(max(y));
    
    if isempty(options.y)
        options.y = [ymin, ymax];
    elseif strcmpi(options.y_permission, 'write')        
        if options.y(1) > ymin
            options.y(1) = ymin;
        end
        if options.y(2) < ymax
            options.y(2) = ymax;
        end
    end
end

% Update plot properties
function plot_update(options)
    
    % Axes limits
    padding.x = (options.x(2) - options.x(1)) * 0.05;
    padding.y = (options.y(2) - options.y(1)) * 0.05;
    set(options.axes, 'xlim', [options.x(1)-padding.x, options.x(2)+padding.x]);
    set(options.axes, 'ylim', [options.y(1)-padding.y, options.y(2)+padding.y]);
    
    % Legend
    if strcmpi(options.legend, 'on')
        legend('show', 'string', options.name);
    elseif strcmpi(options.legend, 'off')
        legend('hide');
    end
end

% Initialize axes
function options = plot_axes(obj, options, data)

% Set general options
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
    'position', obj.options.visualization.position,...
    'visible', 'off',...
    'paperpositionmode', 'auto');

% Determine color order
try
    colors = colormap(options.colormap);
catch
    colors = colormap('parula');
    options.colormap = 'parula';
end

% Check colors
if ~strcmpi(options.ions, 'tic') && ~strcmpi(options.ions, 'all')
    n = length(options.ions);
elseif strcmpi(options.ions, 'all')
    n = length(data(options.samples(1)).mass_values);
else
    n = length(options.samples);
end

% Reduce colors
if n < length(colors(:,1))
    c = round(length(colors)/n);
    options.colors = colors(1:c:end,:);
else
    options.colors = colors;
end

% Initialize main axes
options.axes = axes(...
    'parent', options.figure,...
    'looseinset', [0.08,0.1,0.05,0.05],...
    'fontsize', options.font.size-1,...
    'fontname', options.font.name,...
    'xcolor', options.line.color,...
    'ycolor', options.line.color,...
    'box', 'on',...
    'colororder', options.colors,...
    'color', 'none',...
    'linewidth', options.line.width,...
    'tickdir', 'out',...
    'ticklength', options.ticks.size,...
    'nextplot', 'add');

% Set x-axis label
options.xlabel = xlabel(...
    options.axes,...
    'Time (min)',...
    'fontsize', options.font.size,...
    'fontname', options.font.name);

% Determine y-axis label
if strcmpi(options.scale, 'normalized')
    options.ylabel = 'Intensity (%)';
else
    options.ylabel = 'Intensity';
end
if strcmpi(options.layout, 'stacked')
    options.ylabel = [];
    set(options.axes, 'ytick', [], 'looseinset', [0.05,0.1,0.05,0.05]);
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
    'position', get(options.axes, 'position'),...
    'nextplot', 'add');

box(options.empty, 'on');
box(options.axes, 'off');

% Link axes to allow zooming
axes(options.axes);
linkaxes([options.axes, options.empty]);

% Set zoom callback
set(zoom(options.figure), 'actionpostcallback', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));

% Set resize callback
switch version('-release')
    
    case '2014b'
        set(options.figure, 'sizechangedfcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
    case {'2014a', '2013b', '2013a', '2012b', '2012a'}
        set(options.figure, 'resizefcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
    otherwise
        try
            set(options.figure, 'resizefcn', @(varargin) set(options.empty, 'position', get(options.axes, 'position')));
        catch       
        end
end
end