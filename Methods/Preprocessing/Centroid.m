% ------------------------------------------------------------------------
% Method      : Centroid
% Description : Centroid mass values
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   [mz, y] = Centroid(mz, y)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   mz (required)
%       Description : mass values
%       Type        : array
%
%   y (required)
%       Description : intensity values
%       Type        : matrix
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   [mz, y] = Centroid(mz, y)
%

function varargout = Centroid(varargin)

varargout{1} = [];
varargout{2} = [];

% Check input
[mz, y] = parse(varargin);

% Process large input in segments
blocksize = 5000;

if length(mz) > blocksize
    
    % Calculate block index
    n(:,2) = (1:floor(length(mz)/blocksize)) * blocksize;
    n(:,1) = circshift(n(:,2), [1,0]) + 1;
    n(1,1) = 1;
    
    for i = 1:length(n(:,1))
        
        if i == length(n(:,1))
            index = n(i,1):length(mz);
        else
            index = n(i,1):n(i,2);
        end
        
        % Centroid data block
        [mz_segment, y_segment] = centroid(mz(index), full(y(:,index)));
        
        % Reassemble data
        varargout{1} = [varargout{1}, mz_segment];
        
        if issparse(y)
            varargout{2} = [varargout{2}, sparse(y_segment)];
        else
            varargout{2} = [varargout{2}, y_segment];
        end
    end
    
else
    
    % Centroid data
    [varargout{1}, varargout{2}] = centroid(mz, y);
end

end

function [mz,y] = centroid(mz,y)

% Initialize variables
counter = 1;
iterations = 0;

while counter ~= 0 && iterations <= 10
    
    % Centroid data
    for i = 2:length(y(1,:))-1
        
        % Check data
        if all(~y(:,i))
            continue
        end
        
        % Find zeros in column
        middle = ~y(:,i);
        
        % Find zeros in adjacent columns
        upper = ~y(:,i+1);
        lower = ~y(:,i-1);
        
        % Consolidate if next column has more zeros
        if nnz(middle) < nnz(upper)
            
            % Find zeros adjacent to nonzeros
            index = xor(middle, upper);
            
            % Shift nonzeros in adjacent column to middle column
            y(index,i) = y(index,i) + y(index,i+1);
            y(index,i+1) = 0;
        end
        
        % Consolidate if previous column has more zero elements
        if nnz(middle) < nnz(lower)
            
            % Find zeros adjacent to nonzeros
            index = xor(middle, lower);
            
            % Shift nonzeros in adjacent column to middle column
            y(index,i) = y(index,i) + y(index,i-1);
            y(index,i-1) = 0;
        end
    end
    
    % Update counter with number of columns
    counter = length(y(1,:));
    
    % Remove columns with all zeros
    remove = all(~y);
    
    mz(:,remove) = [];
    y(:,remove) = [];
    
    % Update counter with number of columns removed
    counter = counter - length(y(1,:));
    
    % Update number of iterations
    iterations = iterations + 1;
end

end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin <= 1
    error('Not enough input arguments.');
end

% Check data
if isnumeric(varargin{1})
    mz = varargin{1};
else
    error('Undefined input arguments of type ''mz''.');
end

if isnumeric(varargin{2})
    y = varargin{2};
else
    error('Undefined input arguments of type ''y''.');
end

% Incorrect 'mz' orientation
if length(mz(:,1)) == length(y(1,:))
    mz = mz(:,1)';
end

% Incorrect 'mz' and 'y' orientation
if length(mz(:,1)) == length(y(:,1)) && length(y(:,1)) ~= length(y(1,:))
    mz = mz(:,1)';
    y = y';
end

% Incorrect 'y' orientation
if length(mz(1,:)) == length(y(:,1)) && length(y(:,1)) ~= length(y(1,:))
    y = y';
end

if length(mz(1,:)) ~= length(y(1,:))
    error('Input dimensions must aggree.');
end

% Return input
varargout{1} = mz;
varargout{2} = y;

end