% Method: plots
%  -Update user interface plots
%
% Commands
%   'initialize.all'     : initialize first instance of all plots
%   'update.all'         : redraw all plots
%   'update.tic'         : redraw total ion chromatograms (TIC)
%   'update.xic'         : redraw extracted ion chromatograms (XIC)
%   'options.stacked'    : update plot stacking options
%   'options.normalized' : update plot scale options

function obj = plots(varargin)

% Functions
normalize = @(y) (y - min(min(y))) ./ (max(max(y)) - min(min(y)));
        
% Check for any input
if isempty(varargin)
    return
end

% Check for valid input
if isobject(varargin{1})
    obj = varargin{1};
else
    return
end

% Check inputs
switch length(varargin)
    
    % Command line input
    case 2
        if ischar(varargin{2})
            options = varargin{2};
        end
        
    % Callback input
    case 4
        if ischar(varargin{4})
            options = varargin{4};
        end
        
    % Invalid input
    otherwise
        return
end

% Determine function to perform
switch options
    
    % Initialize all plots
    case 'initialize.all'

        % Initialize plot data
        obj = obj.listbox('update.samples');
        obj = obj.listbox('update.ions');

        % Initialize plots
        obj = obj.plots('update.all');
        
    % Update all plots
    case 'update.all'
        
        % Initialize plot options
        obj = obj.plots('options.stacked');
        obj = obj.plots('options.normalized');
        
        % Retrieve data
        tic = get(obj.axes.tic, 'userdata');
        xic = get(obj.axes.xic, 'userdata');
        
        cla
        
        % Set plot data
        for i = 1:length(obj.axes.data)
            plot(tic.x{i}, tic.y{i}, 'parent', obj.axes.tic, 'linewidth', 2, 'color', [1,1,1/i]);
            plot(xic.x{i}, xic.y{i}, 'parent', obj.axes.xic, 'linewidth', 2, 'color', [1,1,1/i]);
            hold all
        end
        
    % Update total ion chromatograms
    case 'update.tic'
        
    % Update ion chromatograms
    case 'update.sim'
        
    % Set plot positioning option
    case 'options.stacked'
        
        % Variables
        checkbox = obj.figure.checkbox.stacked;
        
        % Update plot options
        obj.axes.options.stacked = get(checkbox, 'value') == get(checkbox, 'max');
        
    % Set plot scale option
    case 'options.normalized'
        
        % Variables
        checkbox = obj.figure.checkbox.normalized;
        
        % Determine checkbox state
        obj.axes.options.normalized = get(checkbox, 'value') == get(checkbox, 'max');
        
        % Process data
        if obj.axes.options.normalized && ~isempty(obj.axes.data)
            
            % Normalize data
            tic.y = cellfun(@(y) normalize(y), {obj.axes.data.tic}, 'uniformoutput', false);
            xic.y = cellfun(@(y) normalize(y), {obj.axes.data.xic}, 'uniformoutput', false);
        else
            % Raw data
            tic.y = {obj.axes.data.tic};
            xic.y = {obj.axes.data.xic};
        end
        
        % Time data
        tic.x = {obj.axes.data.time};
        xic.x = {obj.axes.data.time};
        
        % Update data
        set(obj.axes.tic, 'userdata', tic);
        set(obj.axes.xic, 'userdata', xic);
        
    otherwise
        return
end
end