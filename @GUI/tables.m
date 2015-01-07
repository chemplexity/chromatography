% Method: tables
%  -Update user interface tables

function obj = tables(obj, varargin)

% Check input
if isempty(varargin)
    return
end

% Determine function to perform
switch varargin{1}
            
    % Update files table
    case 'update.files'
        
        % Variables
        table = get(obj.figure.tables.files, 'data');
        
        % Set table units
        set(obj.figure.tables.files, 'units', 'pixels');
        
        % Get table width
        position = get(obj.figure.tables.files, 'position');
        
        % Column width
        col{1} = position(3) * 0.2;
        col{2} = position(3) * 0.4;
        col{3} = position(3) * 0.4;
        
        % Check for empty table
        if isempty(table)
            
            set(obj.figure.tables.files, ...
                'ColumnName', {'ID', 'File', 'Name'},...
                'ColumnFormat', {'char', 'char', 'char'},...
                'ColumnEditable', [true, false, true],...
                'ColumnWidth', {col{1}, col{2}, col{3}});
            
            start = 1;
        else
            start = length(table(1,:)) + 1;
        end
        
        % Update table data
        for i = start:length(obj.data)
            
            % Set first column to 'ID'
            table{i,1} = i;
            
            % Set second column to 'File'
            file = obj.data(i).file_name;
            type = obj.data(i).file_type;
            
            % Remove file extension
            table{i,2} = file(1:end - length(type));
            
            % Set third column to 'Name'
            table{i,3} = strcat(table{i,2}, '_', num2str(i));
        end
        
        % Update table data
        set(obj.figure.tables.files, 'data', table);
        
    otherwise
        return
end
end