% Method: listboxes
%  -Update user interface listboxes
%
% Commands
%   'initialize.samples' : initialize sample listbox with available file names
%   'initialize.ions'    : initialize ion listbox with available ion chromatograms
%   'update.samples'     : index selected samples
%   'update.ions'        : index selected ions

function obj = listbox(varargin)

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
            
    % Initialize samples listbox
    case 'initialize.samples'
        
        % Variables
        table = get(obj.figure.tables.files, 'data');
        samples = cell2mat(table(:,1))';
        sample_values = table(:,3);
        
        % Initialize listbox selections
        if ~isfield(obj.axes.index, 'samples')
            obj.axes.index.samples.current = samples;
            obj.axes.index.samples.previous = [];
            selected = samples;
        else
            selected = get(obj.figure.listbox.samples, 'value');
        end
        
        % Update listbox text
        set(obj.figure.listbox.samples,...
            'string', sample_values,...
            'min', 0,...
            'max', length(samples),...
            'value', selected);
        
        drawnow;
        
    % Initialize ions listbox
    case 'initialize.ions'
        
        % Variables
        samples = get(obj.figure.listbox.samples, 'value');
        ions{length(samples)} = 0;
        
        % Determine available ions from selected samples
        for i = 1:length(samples)
            ions{i} = obj.data(samples(i)).mass_values;
        end
        
        % Filter and sort ions
        ions = sort(unique(cell2mat(ions)));
        
        % Initialize listbox selections
        if ~isfield(obj.axes.index, 'ions')
            obj.axes.index.ions.current = ions(1);
            obj.axes.index.ions.previous = [];
            selected = 1;
        else
            selected = get(obj.figure.listbox.ions, 'value');
        end
        
        % Update listbox text
        set(obj.figure.listbox.ions,...
            'string', num2cell(ions),...
            'min', 0,...
            'max', length(ions),...
            'value', selected);
        
        drawnow;
        
    % Update index values of selected samples
    case 'update.samples'
        
        % Retreive index values
        previous = obj.axes.index.samples.current;
        current = get(obj.figure.listbox.samples, 'value');
        
        % Update index values
        obj.axes.index.samples.previous = previous;
        obj.axes.index.samples.current = current;
        
        % Determine data to remove, keep, add
        remove = ~ismember(previous, current);
        keep = ismember(current, previous);
        add = ~ismember(current, previous);
        
        % Initial data selection
        if isempty(obj.axes.data)
            add = ~add;
            keep = ~keep;
        end
        
        % Remove deselected data
        if ~isempty(previous(remove))
            obj.axes.data(remove) = [];
        end
        
        % Reindex selected data
        if ~isempty(current(keep))
            obj.axes.data(keep) = obj.axes.data;
        end
        
        % Add newly selected data
        if ~isempty(current(add))
            
            % Retreive TIC values
            samples = current(add);
            time = {obj.data(samples).time_values};
            tic = {obj.data(samples).total_intensity_values};
            
            % Determine selected ions
            ions = obj.axes.index.ions.current;
            xic{length(samples)} = 0;
            mz{length(samples)} = 0;
            
            % Retrieve XIC values
            for i = 1:length(samples)
                
                % Check XIC values
                mass = ismember(obj.data(samples(i)).mass_values, ions);
        
                % Assign XIC values
                if sum(mass) >= 1
                    xic{i} = obj.data(samples(i)).intensity_values(:, mass);
                    mz{i} = obj.data(samples(i)).mass_values(mass);
                else
                    xic{i} = [];
                    mz{i} = [];
                end
            end
                
            % Add new data
            if isempty(obj.axes.data)
                obj.axes.data = struct('time', time, 'tic', tic, 'xic', xic, 'mz', mz);
            else
                obj.axes.data(add) = struct('time', time, 'tic', tic, 'xic', xic, 'mz', mz);
            end
        end
        
    % Update values of selected ions
    case 'update.ions'
        
        % Retreive previous index values
        previous = obj.axes.index.ions.current;
        
        % Retreive current index values
        current_index = get(obj.figure.listbox.ions, 'value');
        current_values = str2double(get(obj.figure.listbox.ions, 'string'))';
        current = current_values(current_index);
        
        % Update index values
        obj.axes.index.ions.previous = previous;
        obj.axes.index.ions.current = current;
        
        % Determine data to remove, keep, add
        remove = ~ismember(previous, current);
        keep = ismember(current, previous);
        add = ~ismember(current, previous);
        
        % Check for any changes 
        if ~sum(remove) && ~sum(add)
            return
        end
        
        % Update XIC values
        for i = 1:length(obj.axes.data)
            
            % Remove deselected data
            if ~isempty(previous(remove))
               obj.axes.data(i).xic(:,remove) = [];
               obj.axes.data(i).mz(remove) = [];
            end
        
            % Reindex selected data
            if ~isempty(current(keep))
                obj.axes.data(i).xic(:, keep) = obj.axes.data(i).xic;
                obj.axes.data(i).xic(:, ~keep) = zeros(length(obj.axes.data(i).xic(:,1)), sum(~keep));
                
                obj.axes.data(i).mz(:, keep) = obj.axes.data(i).mz;
                obj.axes.data(i).mz(:, ~keep) = zeros(1, sum(~keep));
            end
        
            % Add newly selected data
            if ~isempty(current(add))
                
                % Check XIC values
                samples = obj.axes.index.samples.current(i);
                mass = ismember(obj.data(samples).mass_values, current(add));

                % Assign XIC values
                if sum(mass) >= 1
                    xic = obj.data(samples).intensity_values(:, mass);
                    mz = obj.data(samples).mass_values(1, mass);
                else
                    xic = [];
                    mz = [];
                end
                
                % Add new data
                obj.axes.data(i).xic(:, add) = xic;
                obj.axes.data(i).mz(1, add) = mz;
            end
        end
        
        % Update plot
        obj = obj.plots('update.sim');
 
    otherwise
        return
end
end