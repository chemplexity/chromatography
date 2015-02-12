% Method: ExportCSV
%  -Export data as comma separated value (.CSV) file
%
% Syntax:
%   ExportCSV(y, 'OptionName', optionvalue,...)
%   ExportCSV(x, y, 'OptionName', optionvalue,...)
%
% Input
%   x        : array
%   y        : array or matrix
%
% Options   
%   'file'   : string
%   'header' : array
%
% Description
%   x        : time values
%   y        : intensity values
%   'file'   : desired file name (default = 'data.csv')
%   'header' : column names (default = 1:length(columns))
%
% Examples:
%   ExportCSV(y)
%   ExportCSV(x, y, 'file', '001-03.csv')
%   ExportCSV(x, y, 'file', '004-01.csv', 'header', mz)

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
    error('Not enough input arguments');
elseif nargin == 1 && isnumeric(varargin{1})
    x = [];
    y = varargin{1};
elseif nargin >= 2 && isnumeric(varargin{1}) && isnumeric(varargin{2})
    x = varargin{1};
    y = varargin{2};
elseif nargin >= 2 && isnumeric(varargin{1}) && ~isnumeric(varargin{2})
    x = [];
    y = varargin{1};
else 
    error('Undefined input arguments of type ''y''');
end

% Check precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check x data
if ~isempty(x)

    % Check x for rows
    if length(x(:,1)) ~= length(y(:,1))
        x = [];
    
    % Check x for columns
    elseif length(x(:,1)) == length(y(:,1)) && length(x(1,:)) > 1
        x = x(:,1);
    end
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Name options
if ~isempty(input('file'))
    file = varargin{input('file')+1};
    
    % Check for string input
    if ischar(file) 
        
        % Check input length
        if length(file) <= 20
            options.file = file;
        elseif ischar(file) && length(file) > 20
            options.file = file(1:20);
        end
        
    % Check for cell input
    elseif iscell(file) && ischar(file{1})
        
        % Check input length
        if length(file{1}) <= 20
            options.file = file{1};
        elseif length(file{1}) > 20
            options.file = file{1}(1:20);
        end
        
    else
        options.file = 'data.csv';
    end
    
    % Check file type
    if length(options.file) >= 4;
        
        % Check for '.CSV' extension
        if ~strcmpi(options.file(end-3:end), '.csv');
            options.file = options.file(options.file ~= '.');
            options.file = strcat(options.file, '.csv');
        end
    end
    
else
    options.filename = 'data.csv';
end

% Header options
if ~isempty(input('header'))
    header = varargin{input('header')+1};
    
    % Check for string input
    if isnumeric(header) 
        
        % Check input length
        if length(header(1,:)) == length(y(1,:)) && ~isempty(x)
            options.header = [0, header(1,:)];
            
        elseif length(header(1,:)) == length(y(1,:)) && isempty(x)
            options.header = header(1,:);
        end
        
    else
        
        % Check input data
        if isempty(x)
            options.header = 1:length(y(1,:));
        else
            options.header = 0:length(y(1,:));
        end
    end
    
else
    
    % Check input data
    if isempty(x)
        options.header = 1:length(y(1,:));
    else
        options.header = 0:length(y(1,:));
    end
end

% Check header precision
if ~isa(options.header, 'double')
    options.header = double(options.header);
end

% Check data
if ~isempty(x)
    data = [x,y]; 
else
    data = y;
end

% Check header length
if length(options.header(1,:)) == length(data(1,:))
    data = [options.header; data];
end

% Return input
varargout{1} = data;
varargout{2} = options;
end
