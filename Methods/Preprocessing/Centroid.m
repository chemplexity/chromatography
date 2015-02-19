% Method: Centroid
%  -Centroid raw mass spectrometer data
%
% Syntax
%   [mz,y] = Centroid(mz,y)
%
% Input
%   mz : array
%   y  : matrix
%
% Description
%   mz : mass values
%   y  : intensity values
%
% Examples
%   [mz,y] = Centroid(mz,y)

function varargout = Centroid(varargin)

% Check input
[mz, y] = parse(varargin);

% Initialize variables
counter = 1;
iterations = 0;

while counter ~= 0 && iterations <= 10

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
    mz(:,sum(y~=0)==0) = [];
    y(:,sum(y~=0)==0) = [];

    % Update counter with number of columns removed
    counter = counter - length(y(1,:));
    
    % Update number of iterations
    iterations = iterations + 1;
end

varargout{1} = mz;
varargout{2} = y;
end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin <= 1
    error('Not enough input arguments');
end

% Check data
if isnumeric(varargin{1})
    mz = varargin{1};
else
    error('Undefined input arguments of type ''mz''');
end
if isnumeric(varargin{2})
    y = varargin{2};
else
    error('Undefined input arguments of type ''y''');
end

% Check data precision
if ~isa(mz, 'double')
    mz = double(mz);
end
if ~isa(y, 'double')
    y = double(y);
end

% Check data orientation
if size(mz) > 1
    error('Input dimensions must aggree');
end
if size(y) <= 1
    error('Input dimensions must aggree');
end
if length(mz(:,1)) == length(y(1,:))
    mz = mz';
end
if length(mz(1,:)) ~= length(y(1,:))
    error('Input dimensions must aggree');
end
    
% Return input
varargout{1} = mz;
varargout{2} = y;
end