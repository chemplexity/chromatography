% ------------------------------------------------------------------------
% Method      : ExportCSV
% Description : Export data as comma separated values (.CSV) file
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = ExportCSV(y)
%   data = ExportCSV(x, y, Name, Value)
%   data = ExportCSV(x, y, z, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   x (optional)
%       Description : time values (row vector)
%       Type        : array
%
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   z (optional)
%       Description : mass values (column vector) 
%       Type        : array
%
%   'file' (optional)
%       Description : name of file
%       Type        : string
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   ExportCSV(y)
%   ExportCSV(x, y, 'file', '001-03.csv')
%   ExportCSV(x, y, z, 'file', '004-01.csv')
%

function ExportCSV(varargin)

% Check input
[data, options] = parse(varargin);

% Export data
dlmwrite(options.file, data);

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif nargin <= 3
    values = sum(cellfun(@isnumeric, varargin));
    
elseif nargin > 3
    values = sum(cellfun(@isnumeric, varargin(1:3)));
end

% Check for any data
if values == 0
    error('Incorrect input arguments of type ''y''.');
end

% Check input data
switch values
    case 1
        x = [];
        y = varargin{1};
        z = [];
    case 2
        x = varargin{1};
        y = varargin{2};
        z = [];
    case 3
        x = varargin{1};
        y = varargin{2};
        z = varargin{3};
end

% Check precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end
if ~isa(z, 'double')
    z = double(z);
end

% Check x data
if ~isempty(x)
    
    % Check x for rows
    if length(x(1,:)) == length(y(:,1))
        x = x';
    elseif length(x(:,1)) ~= length(y(:,1))
        x = [];
    end
    
    % Check x for matric
    if length(x(:,1)) == length(y(:,1)) && length(x(1,:)) > 1
        x = x(:,1);
    end
end

if ~isempty(z)
    
    % Check z for rows
    if length(z(:,1)) == length(y(1,:))
        z = z';
    elseif length(z(:,1)) == length(y(1,:)) + 1
        z = z';
    elseif length(z(1,:)) ~= length(y(1,:)) && length(z(1,:)) ~= length(y(1,:)) + 1
        z = [];
    end
    
    % Check z for matrix
    if length(z(:,1)) > 1
        z = z(1,:);
    end
    
    % Check z for columns
    if length(z(1,:)) == length(y(1,:))
        z = [0, z];
    end
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Name options
if ~isempty(input('filename'))
    file = varargin{input('filename')+1};
    
    % Check for string input
    if ischar(file)
        
        % Check input length
        if length(file) <= 20
            options.file = deblank(file);
        elseif length(file) > 20
            options.file = deblank(file(1:20));
        end
        
        % Check for cell input
    elseif iscell(file) && ischar(file{1})
        
        % Check input length
        if length(file{1}) <= 20
            options.file = deblank(file{1});
        elseif length(file{1}) > 20
            options.file = deblank(file{1}(1:20));
        end
        
    else
        options.file = 'data.CSV';
    end
    
    % Remove file extension
    [~, options.file] = fileparts(options.file);
    
    % Add '.CSV' extension
    options.file = strcat(options.file, '.CSV');
else
    options.file = 'data.CSV';
end


% Check data
if ~isempty(x) && isempty(z)
    data = [x,y];
elseif ~isempty(x) && ~isempty(z)
    data = [z; x,y];
else
    data = y;
end

% Return input
varargout{1} = data;
varargout{2} = options;

end
