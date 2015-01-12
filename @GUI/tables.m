% Method: tables
%  -Update user interface tables
%
% Commands
%   'initialize.files' : initialize table with file information

function obj = tables(varargin)

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
            
    % Initialize table with file information
    case 'initialize.files'
        
        % Variables
        table = get(obj.figure.tables.files, 'data');
        
        % Set table units
        set(obj.figure.tables.files, 'units', 'pixels');
        
        % Get table width
        position = get(obj.figure.tables.files, 'position');
        
        % Set column width
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
        
        % Determine table data
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
        
        % Set table data
        set(obj.figure.tables.files, 'data', table);
        
    otherwise
        return
end
end