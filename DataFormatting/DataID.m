% Method: DataID
% Description: Create a database of ion names
%
% Syntax:
%   data = DataID(data, 'OptionName', optionvalue...)
%
%   Options:
%       ID : {name1, mz1; name2, mz2...}
%
% Examples:
%   data = DataStructure(data, 'ID', {'C18:1', 311; 'C18:2', 309})

function data = DataID(data, varargin)

% Check number of inputs
if nargin < 2
    return
    
elseif nargin >= 2
    
    % Check input
    id_index = find(strcmp(varargin, 'ID'));
    
    % Check for empty values
    if ~isempty(id_index)
        id = varargin{id_index + 1};
    else
        return
    end
    
    % Check values are correctly formatted
    if ~isnumeric([id{:,2}])
        sprintf('Illegal formatting')
        return
    end
    
    for i = 1:length(data)
        
        % Check for empty ID field
        if length(data(i).mass_values) > length(data(i).mass_values_id)
            data(i).mass_values_id{length(data(i).mass_values)} = '';        
        elseif length(data(i).mass_values) < length(data(i).mass_values_id)
            data(i).mass_values_id = [];
            data(i).mass_values_id{length(data(i).mass_values)} = '';
        end
        
        % Find column index of input
        [data_index, id_index] = ismember(data(i).mass_values, [id{:,2}]);
                
        % Update ion names
        data(i).mass_values_id(data_index) = id(id_index(id_index>0),1);    
    end
end