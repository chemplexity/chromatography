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
%   'xlim'     : [xmin, xmax], 'auto'
%   'ylim'     : [ymin, ymax], 'auto'
%
% Description
%   data       : an existing data structure     
%   'samples'  : row index of samples in data structure -- (default: all)
%   'ions'     : column index of ions in data structure -- (default: 'tic')
%   'baseline' : display baseline/baseline corrected spectra -- (default: 'off')
%   'peaks'    : display curve fitting results for available peaks -- (default: 'off')
%   'layout'   : plot spectra in a stacked or overlaid format -- (default: 'overlaid')
%   'scale'    : display spectra on a normalized scale or full scale -- (default: 'full')
%   'xlim'     : x-axis limits -- (default: 'auto')
%   'ylim'     : y-axis limits -- (default: 'auto')
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

% Check sample options
if ~isempty(find(strcmpi(varargin, 'samples'),1))
    samples = varargin{find(strcmpi(varargin, 'samples'),1) + 1};
                    
    % Check user input
    if strcmpi(samples, 'all')
        samples = 1:length(varargin{1});
    elseif ~isnumeric(samples)
        error('Undefined input arguments of type ''samples''');
    elseif max(samples) > length(data) || min(samples) < 1
        error('Index exceeds matrix dimensions')
    end
        
else
    % Default samples options
    samples = 1:length(varargin{1});
end

% Check ion options
if ~isempty(find(strcmpi(varargin, 'ions'),1))
    ions = varargin{find(strcmpi(varargin, 'ions'),1) + 1};
else
    % Default ions options
    ions = 'tic';
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
    options.layout = 'overlaid';
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
    if ~isnumeric(options.x) || strcmp(options.x, 'auto')
        options.x = [];
        options.x_permission = 'write';
    elseif length(options.x) > 2 || length(options.x) < 2
        error('Incorrect number of input arguments of type ''xlim''');
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

% Initialize axes
options = plot_axes(obj, options);

% Plot chromatograms
for i = 1:length(samples)
    
    % Counter
    options.i = i;
    
    % Determine x-values
    x = data(samples(i)).time_values;
    
    % Check ion options
    if ~ischar(ions)
        
        % Check user input
        if max(ions) > length(data(samples(i)).mass_values)
            error('Index exceeds matrix dimensions');
        end
        
        % Set y values
        y = data(samples(i)).intensity_values(:, ions);
        
        % Check baseline
        if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
            baseline = data(samples(i)).intensity_values_baseline(:,ions);
        else
            baseline = [];
        end
        
        % Check peaks
        if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
            peaks = data(samples(i)).intensity_values_peaks.peak_fit(1,ions);
        else
            peaks = [];
        end
        
        % Check baseline correction
        if strcmpi(options.baseline, 'corrected')
            y = y - baseline;
        end
        
        % Set legend name
        options.name = strcat(num2str(i), ' - SIM');
    else
        switch ions
            
            % Use total ion chromatograms
            case 'tic'
                
                % Set y values
                y = data(samples(i)).total_intensity_values;
                
                % Check baseline
                if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
                    baseline = data(samples(i)).total_intensity_values_baseline(:,ions);
                else
                    baseline = [];
                end
        
                % Check peaks
                if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
                    peaks = data(samples(i)).total_intensity_values_peaks.peak_fit(1,1);
                else
                    peaks = [];
                end
                
                % Check baseline correction
                if strcmpi(options.baseline, 'corrected')
                    y = y - baseline;
                end
                
                % Set legend name
                options.name = strcat(num2str(i), ' - TIC');
            
            % Use all ion chromatograms
            case 'all'
                
                % Set y values
                y = data(samples(i)).intensity_values;
                
                % Check baseline
                if strcmpi(options.baseline, 'on') || strcmpi(options.baseline, 'corrected')
                    baseline = data(samples(i)).intensity_values_baseline;
                else
                    baseline = [];
                end
        
                % Check peaks
                if strcmpi(options.peaks, 'on') || strcmpi(options.peaks, 'residuals')
                    peaks = data(samples(i)).intensity_values_peaks.peak_fit(1,:);
                else
                    peaks = [];
                end
                
                % Check baseline correction
                if strcmpi(options.baseline, 'corrected')
                    y = y - baseline;
                end
                
                % Set legend name
                options.name = strcat(num2str(i), ' - SIM');
        end
    end
    
    % Apply user input
    y = plot_scale(y, options);
    y = plot_layout(y, options);
    
    options = plot_xlim(x, options);
    options = plot_ylim(y, options);
    
    % Plot data
    plot(x, y, ...
        'parent', options.axes, ...
        'linewidth', 1.5, ...
        'displayname', options.name);
end

% Update axes limits
plot_update(options);

legend('show');

end

% Check scale options
function y = plot_scale(y, options)
    if strcmpi(options.scale, 'normalized')
        y = Normalize(y);
    end
end

% Check layout options
function y = plot_layout(y, options)
    if strcmpi(options.layout, 'stacked')
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

% Update axes limits
function plot_update(options)
    padding.x = (options.x(2) - options.x(1)) * 0.05;
    padding.y = (options.y(2) - options.y(1)) * 0.05;
    set(options.axes, 'xlim', [options.x(1)-padding.x, options.x(2)+padding.x]);
    set(options.axes, 'ylim', [options.y(1)-padding.y, options.y(2)+padding.y]);
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
    'yticklabel', [],...
    'ticklength', [0.005, 0.001]);

xlabel(options.axes,...
    'Time (min)',...
    'fontsize', 15,...
    'fontname', 'lucidasans');
end

