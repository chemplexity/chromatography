% Method: visualize
%  -Plot chromatograms, baselines, and curve fitting results
%
% Syntax
%   visualize(data)
%   visualize(data, 'OptionName', optionvalue...)
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
%
% Description
%   data       : an existing data structure     
%   'samples'  : row index of samples in data structure -- (default: all)
%   'ions'     : column index of ions in data structure -- (default: 'tic')
%   'baseline' : display baseline/baseline corrected spectra -- (default: 'off')
%   'peaks'    : display curve fitting results for available peaks -- (default: 'off')
%   'layout'   : plot spectra in a stacked or overlaid format -- (default: 'stacked')
%   'scale'    : display spectra on a normalized scale or full scale -- (default: 'full')
%   'xlim'     : x-axis limits -- (default: 'auto')
%   'ylim'     : y-axis limits -- (default: 'auto')
%   'legend'   : add legend to plot -- (default: 'on')
%
% Examples
% obj.visualize(data, 'samples', [1:4], 'ions', 'tic', 'baseline', 'on')
% obj.visualize(data, 'layout', 'stacked', 'scale', 'normalized')
% obj.visualize(data, 'peaks', 'residuals', 'baseline', 'on')
% obj.visualize(data, 'scale', 'normalized', 'baseline', 'corrected')
% obj.visualize(data, 'samples', 1, 'peaks', 'on', 'baseline', 'on')

function visualize(obj, varargin)

% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
end
  
% Check data structure
if isstruct(varargin{1})
    data = DataStructure('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''');
end

% Anonymous function to parse input
check_key = @(arg) find(strcmpi(varargin, arg),1);

% Check sample options
if ~isempty(find(strcmpi(varargin, 'samples'),1))
    options.samples = varargin{find(strcmpi(varargin, 'samples'),1) + 1};
                    
    % Check user input
    if strcmpi(options.samples, 'all')
        options.samples = 1:length(varargin{1});
    elseif ~isnumeric(options.samples)
        error('Undefined input arguments of type ''samples''');
    elseif max(options.samples) > length(data) || min(options.samples) < 1
        error('Index exceeds matrix dimensions')
    end
        
else
    % Default samples options
    options.samples = 1:length(varargin{1});
end

% Check ion options
if ~isempty(find(strcmpi(varargin, 'ions'),1))
    options.ions = varargin{find(strcmpi(varargin, 'ions'),1) + 1};
else
    % Default ions options
    options.ions = 'tic';
end

% Check baseline options
if ~isempty(find(strcmpi(varargin, 'baseline'),1))
    options.baseline = varargin{find(strcmpi(varargin, 'baseline'),1) + 1};
    
    % Check user input
    if ~strcmpi(options.baseline, 'on') && ~strcmpi(options.baseline, 'off') && ~strcmpi(options.baseline, 'corrected')        
        error('Undefined input arguments of type ''baseline''');
    end
else
    % Default baselines options
    options.baseline = 'off';
end

% Check peak options
if ~isempty(find(strcmpi(varargin, 'peaks'),1))
    options.peaks = varargin{find(strcmpi(varargin, 'peaks'),1) + 1};
    
    % Check user input
    if ~strcmpi(options.peaks, 'on') && ~strcmpi(options.peaks, 'off') && ~strcmpi(options.peaks, 'residuals')        
        error('Undefined input arguments of type ''peaks''');
    end
else
    % Default peak options
    options.peaks = 'off';
end

% Check layout options
if ~isempty(find(strcmpi(varargin, 'layout'),1))
    options.layout = varargin{find(strcmpi(varargin, 'layout'),1) + 1};
    
    % Check user input
    if strcmpi(options.layout, 'overlay') || strcmpi(options.layout, 'overlap')
        options.layout = 'overlaid';
    elseif strcmpi(options.layout, 'stack')
        options.layout = 'stacked';
    elseif ~strcmpi(options.layout, 'stacked') && ~strcmpi(options.layout, 'overlaid')        
        error('Undefined input arguments of type ''layout''');
    end
else
    % Default peak options
    options.layout = 'stacked';
end

% Check scale options
if ~isempty(find(strcmpi(varargin, 'scale'),1))
    options.scale = varargin{find(strcmpi(varargin, 'scale'),1) + 1};
    
    % Check user input
    if strcmpi(options.scale, 'normalize')
        options.scale = 'normalized';
    elseif ~strcmpi(options.scale, 'normalized') && ~strcmpi(options.scale, 'full')
        error('Undefined input arguments of type ''scale''');
    end
else
    % Default scale options
    options.scale = 'full';
end

% Check xlim options
if ~isempty(find(strcmpi(varargin, 'xlim'),1))
    options.x = varargin{find(strcmpi(varargin, 'xlim'),1) + 1};
    options.x_permission = 'read';
    
    % Check user input
    if length(options.x) > 2 || length(options.x) < 2
        error('Incorrect number of input arguments of type ''xlim''');
    elseif ~isnumeric(options.x) || strcmp(options.x, 'auto') || options.x(2) < options.x(1)
        options.x = [];
        options.x_permission = 'write';
    end
else
    % Default xlim options
    options.x = [];
    options.x_permission = 'write';
end

% Check ylim options
if ~isempty(find(strcmpi(varargin, 'ylim'),1))
    options.y = varargin{find(strcmpi(varargin, 'ylim'),1) + 1};
    options.y_permission = 'read';
    
    % Check user input
    if ~isnumeric(options.y) || strcmp(options.y, 'auto')
        options.y = [];
        options.y_permission = 'write';
    elseif length(options.y) > 2 || length(options.y) < 2
        error('Incorrect number of input arguments of type ''ylim''');
    end
else
    % Default ylim options
    options.y = [];
    options.y_permission = 'write';
end

% Check legend options
if ~isempty(find(strcmpi(varargin, 'legend'),1))
    options.legend = varargin{find(strcmpi(varargin, 'legend'),1) + 1};
    
    % Check user input
    if ~strcmpi(options.legend, 'on') && ~strcmpi(options.legend, 'off')
        if strcmpi(ions, 'tic') 
            options.legend = 'on';
        else
            options.legend = 'off';
        end
    end
else
    % Default legend options
    if strcmpi(options.ions, 'tic') 
        options.legend = 'on';
    else
        options.legend = 'off';
    end
end

% Initialize axes
options = plot_axes(obj, options);

% Determine y-limits
for i = 1:length(options.samples)
    if strcmpi(options.ions, 'tic')
        y = data(options.samples(i)).total_intensity_values;
    elseif strcmp(options.ions, 'all')
        y = data(options.samples(i)).intensity_values;
    else
        y = data(options.samples(i)).intensity_values(:,options.ions);
    end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    % Update options
    options.i = i;
    y = plot_scale(y, options);
    y = plot_layout(y, options);
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
           if ~isempty(data(options.samples(i)).intensity_values_peaks.peak_fit)
               peaks = data(options.samples(i)).intensity_values_peaks.peak_fit(1,options.ions);
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
        
        % Set legend name
        for j = 1:length(options.ions)
            options.name{j} = strcat(num2str(data(options.samples(i)).mass_values(options.ions(j))), ' - m/z');
        end
        
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
                    peaks = data(options.samples(i)).total_intensity_values_peaks.peak_fit(1,1);
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
                
                % Set legend name
                options.name{1} = strcat(num2str(i), ' - TIC');
                
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
                    peaks = data(options.samples(i)).intensity_values_peaks.peak_fit(1,:);
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
                
                % Set legend name
                for j = 1:length(y(1,:))
                    options.name{j} = strcat(num2str(data(options.samples(i)).mass_values(j)), ' - m/z');
                end
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
            'color', [0.05, 0.25, 0.50]);
    end
    
    % Apply user input
    y = plot_scale(y, options);
    y = plot_layout(y, options);
    
    options = plot_xlim(x, options);
    options = plot_ylim(y, options);
        
    for j = 1:length(y(1,:))
        
        % Plot data
        plot(x, y(:,j), ...
            'parent', options.axes, ...
            'linewidth', 1.5, ...
            'displayname', options.name{j});
    end
end

% Update plot properties
plot_update(options);

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
        legend('show');
    elseif strcmpi(options.legend, 'off')
        legend('hide');
    end
end

% Update plot zoom on scroll
function plot_scroll(~, varargin)
    scroll_count = varargin{1,1}.VerticalScrollCount;
    scroll_amount = varargin{1,1}.VerticalScrollAmount;
end

% Initialize axes
function options = plot_axes(obj, options)

% Visualization options
options.figure = figure(...
    'color', 'white',...
    'numbertitle', 'off',...
    'name', 'Chromatography Toolbox',...
    'units', 'normalized',....
    'position', obj.options.visualization.position,...
    'WindowScrollWheelFcn', @plot_scroll,...
    'visible', 'on');

options.axes = axes(...
    'parent', options.figure,...
    'looseinset', [0.05,0.1,0.05,0.05],...
    'fontsize', 14,...
    'fontname', 'lucidasans',...
    'xcolor', 'black',...
    'ycolor', 'black',...
    'box', 'on',...
    'linewidth', 1.5,...
    'tickdir', 'in',...
    'nextplot', 'add',...
    'ticklength', [0.005, 0.001]);

xlabel(options.axes,...
    'Time (min)',...
    'fontsize', 15,...
    'fontname', 'lucidasans');
end

