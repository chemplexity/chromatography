% Method: plots
%  -Update user interface plots
%
% Commands
%   'initialize.all'     : initialize all plots
%   'update.all'         : redraw all plots
%   'update.tic'         : redraw total ion chromatograms
%   'update.sim'         : redraw ion chromatograms
%   'options.stacked'    : update plot stacking options
%   'options.normalized' : update plot scale options

function obj = plots(obj, varargin)

% Check input
if isempty(varargin)
    return
end

% Determine function to perform
switch varargin{1}
    
    % Initialize total ion chromatograms
    case 'initialize.all'

        % Set variables
        index = 1:length(obj.data);
        
        % Assign TIC data
        for i = 1:length(index)
            obj.axes.data(i).time = obj.data(index(i)).time_values;
            obj.axes.data(i).tic = obj.data(index(i)).total_intensity_values;
        end
        
        % Assign SIM data
        index = get(obj.figure.listbox.ions, 'value');
        values = get(obj.figure.listbox.ions,'string');
        ions = str2double(values{index}); 
        
    % Update all plots
    case 'update.all'
        
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
        
        % Update plot options
        obj.axes.options.normalized = get(checkbox, 'value') == get(checkbox, 'max');
        
    otherwise
        return
end
end