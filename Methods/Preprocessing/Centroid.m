% Method: Centroid
%  -Centroid raw mass spectrometer data
%
% Syntax
%   [x,y] = Centroid(x,y)
%
% Input
%   x : array
%   y : matrix
%
% Description
%   x : array containing mass values
%   y : matrix with intensity values
%
% Examples
%   [x,y] = Centroid(x,y)

function varargout = Centroid(varargin)

% Check input
[x, y] = parse(varargin);

% Initialize variables
counter = 1;

while counter ~= 0

    % Calculate centroid data
    for i = 2:length(y(1,:))-1
    
        % Find zeros in current column
        middle = y(:, i) == 0;
    
        % Find zeros in surrounding columns
        upper = y(:, i+1) == 0;
        lower = y(:, i-1) == 0;
    
        % Proceed if next column has more zeros
        if sum(middle) < sum(upper)
        
            % Index zeros adjacent to nonzeros
            index = xor(middle, upper);
        
            % Place all nonzeros from adjacent column in current column
            y(index, i) = y(index, i) + y(index, i+1);
            y(index, i+1) = 0;
        end
    
        % Proceed if previous column has more zeros
        if sum(middle) < sum(lower)
    
            % Index zeros adjacent to nonzeros
            index = xor(middle, lower);
    
            % Place all nonzeros from adjacent column in current column
            y(index, i) = y(index, i) + y(index, i-1);
            y(index, i-1) = 0;
        end
    end

    % Update counter with total number of columns
    counter = length(y(1,:));
    
    % Remove columns with all zeros
    x(:,sum(y~=0)==0) = [];
    y(:,sum(y~=0)==0) = [];

    % Update counter with number of columns removed
    counter = counter - length(y(1,:));
end

% Remove columns with only one nonzero value
x(:, sum(y~=0)==1)=[];
y(:, sum(y~=0)==1)=[];

varargout{1} = x;
varargout{2} = y;
end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments');
end

% Check data
if isnumeric(varargin{1})
    x = varargin{1};
else
    error('Undefined input arguments of type ''x''');
end
if isnumeric(varargin{2})
    y = varargin{2};
else
    error('Undefined input arguments of type ''y''');
end

% Check data precision
if ~isa(x, 'double')
    x = double(x);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check data orientation
if size(x) > 1
    error('Input dimensions must aggree');
end
if size(y) <= 1
    error('Input dimensions must aggree');
end
if length(x(:,1)) == length(y(1,:))
    x = x';
end
if length(x(1,:)) ~= length(y(1,:))
    error('Input dimensions must aggree');
end
    
% Return input
varargout{1} = x;
varargout{2} = y;
end