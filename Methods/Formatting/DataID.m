% Method: DataID
% Description: Apply names from DataLibrary to available ions
%
% Syntax:
%   data = DataID(data, names)
%
%       data: structure 
%       names: {name1, mz1; name2, mz2...}, library, DataLibrary
%
% Examples:
%   data = DataID(data, {'C18:1', 311; 'C18:2', 309})
%   data = DataID(data, library)
%   data = DataID(data, DataLibrary)
%   data = DataID(data, DataLibrary('Class')

function varargout = DataID(data, varargin)

% Check number of inputs
if nargin < 2
    return
end

% Check data for correct fields
if isstruct(data)
    data = DataStructure('Validate', data);
else
    disp('[Error] Invalid input (Data)');
    return
end

% Check for empty values
if ~isempty(varargin{1})
    id = varargin{1};
else
    disp('[Error] Invalid input (IDs)');
    return
end

% Check if input is library structure
if isstruct(id) && isfield(id, 'compound') && isfield(id, 'mz')
    
    % Extract values
    id_values(:,1) = {id.compound};
    id_values(:,2) = {id.mz};
    
elseif iscell(id)
    % Check if input is user defined cell
    id_values = id;
else
    disp('[Error] Invalid format (IDs)');
    return
end

% Check values are correctly formatted
if ~isnumeric([id_values{:,2}])
    disp('[Error] Invalid format (m/z values)');
    return
end

for i = 1:length(data)
    
    % Check for empty ID fields
    if length(data(i).mass_values) > length(data(i).mass_values_id)
        data(i).mass_values_id{length(data(i).mass_values)} = '';
        
        % Check for excess ID fields
    elseif length(data(i).mass_values) < length(data(i).mass_values_id)
        data(i).mass_values_id = [];
        data(i).mass_values_id{length(data(i).mass_values)} = '';
    end
    
    % Find column index of input
    [data_index, id_index] = ismember(data(i).mass_values, [id_values{:,2}]);
    
    % Update ion names
    data(i).mass_values_id(data_index) = id_values(id_index(id_index>0),1);
end

varargout{1} = data;
end