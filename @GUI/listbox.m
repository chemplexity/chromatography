% Method: listboxes
%  -Update user interface listboxes
%
% Commands
%   'update.samples' : update listbox with available file names
%   'update.ions'    : update listbox with available ion chromatograms

function obj = listbox(obj, varargin)

% Check input
if isempty(varargin)
    return
end

% Determine function to perform
switch varargin{1}
            
    % Update samples listbox
    case 'update.samples'
        
        % Variables
        table = get(obj.figure.tables.files, 'data');
        samples = table(:,3);
        
        % Update listbox
        set(obj.figure.listbox.samples,...
            'String', samples,...
            'Min', 0,...
            'Max', length(samples));
            
        drawnow;
      
    % Update ions listbox
    case 'update.ions'
        
        % Variables
        samples = get(obj.figure.listbox.samples, 'value');
        
        % Get ions from selected samples
        for i = 1:length(samples)
            ions{i} = obj.data(samples(i)).mass_values;
        end
        
        % Restructure ions
        ions = sort(unique(cell2mat(ions)));
        
        % Update listbox
        set(obj.figure.listbox.ions,...
            'String', num2cell(ions),...
            'Min', 0,...
            'Max', length(ions));
            
    otherwise
        return
end
end