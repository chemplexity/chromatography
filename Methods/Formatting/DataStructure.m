% Method: DataStructure
%  -Create or validate a chromatography data structure 
%
% Syntax
%   data = DataStructure('OptionName', optionvalue...)
%
% Options
%   'validate' : structure
%
% Description
%   'validate' : check data structure for missing fields
% 
% Examples
%   data = DataStructure()
%   data = DataStructure('validate', data)

function data = DataStructure(varargin)

% Field names
basic = {...
    'id',...
    'name',...
    'file',...
    'sample',...
    'method',...
    'time',...
    'tic',...
    'xic',...
    'mz'};

file = {...
    'name',...
    'type'};

sample = {...
    'name'};

method = {...
    'name',...
    'instrument',...
    'date',...
    'time'};

tic = {...
    'values',...
    'baseline',...
    'peaks',...
    'backup'};

xic = {...
    'values',...
    'baseline',...
    'peaks',...
    'backup'};

peaks = {...
    'time',...
    'height',...
    'width',...
    'area',...
    'fit',...
    'error'};

ms2 = {...
    'time',...
    'xic',...
    'mz'};

% Check number of inputs
if nargin < 2
    
    % Create an empty data structure
    data = cell2struct(cell(1,length(basic)), basic, 2);
    
    % Clear first line
    data(1) = [];

elseif nargin >= 2
    
    % Check for validate options
    if ~isempty(find(strcmpi(varargin, 'validate'),1))
        data = varargin{find(strcmpi(varargin, 'validate'),1)+1};
    else
        return
    end
    
    % Check basic fields
    data = check(data, basic);
    
    % Check nested fields
    for i = 1:length(data)

        % General information
        data(i).file = check(data(i).file, file);
        data(i).sample = check(data(i).sample, sample);
        data(i).method = check(data(i).method, method);
        
        % Total ion chromatograms
        data(i).tic = check(data(i).tic, tic);
        data(i).tic.peaks = check(data(i).tic.peaks, peaks);
        
        % Extracted ion chromatograms
        data(i).xic = check(data(i).xic, xic);
        data(i).xic.peaks = check(data(i).xic.peaks, peaks);
    end
    
    % Check for extra fields
    if ~isempty(find(strcmpi(varargin, 'extra'),1))
        extra = varargin{find(strcmpi(varargin, 'extra'),1)+1};
        
        % Add MS2 field
        if strcmpi(extra, 'ms2')
            data = check(data, {'ms2'});
        end
    end
end
end

% Validate structure
function structure = check(structure, fields)

% Check structure input
if ~isstruct(structure)
    structure = [];
end

% Check fields input
if ~iscell(fields)
    return
end

% Check for empty structure
if isempty(structure)
    structure = cell2struct(cell(1,length(fields)), fields, 2);
    
% Check for missing fields
elseif ~isempty(~isfield(structure, fields))
    missing = fields(~isfield(structure, fields));
            
    % Add missing peak fields to structure
    if ~isempty(missing)
        for i = 1:length(missing)
            structure = setfield(structure, {1}, missing{i}, []);
        end
    end
end
end