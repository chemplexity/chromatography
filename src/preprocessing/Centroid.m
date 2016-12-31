function varargout = Centroid(varargin)
% ------------------------------------------------------------------------
% Method      : Centroid
% Description : Centroid mass spectrometer data
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   [mz, y] = Centroid(mz, y)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   mz -- mass values
%       array (size = 1 x n)
%
%   y -- intensity values
%       array | matrix (size = m x n)
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'iterations' -- number of iterations to perform centroiding
%       10 (default) | number
%
%   'blocksize' -- maximum number of bytes to process at a single time
%       10E6 (default) | number
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   [mz, y] = Centroid(mz, y)

% ---------------------------------------
% Defaults
% ---------------------------------------
default.iterations = 10;
default.blocksize  = 10E6;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'mz', @ismatrix);
addRequired(p, 'y',  @ismatrix);

addParameter(p, 'iterations', default.iterations, @isscalar);
addParameter(p, 'blocksize',  default.blocksize,  @isscalar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
mz = p.Results.mz;
y  = p.Results.y;

iterations = p.Results.iterations;
blocksize  = p.Results.blocksize;

varargout{1} = [];
varargout{2} = [];

% ---------------------------------------
% Validate
% ---------------------------------------
if length(mz(1,:)) ~= length(y(1,:))
    return
end

if iterations <= 0
    iterations = 1;
end

if blocksize <= 1E3
    blocksize = 1E3;
end

% ---------------------------------------
% Variables
% ---------------------------------------
[m, n] = size(y);

if isa(y, 'double')
    index = 1:floor(blocksize/(m*8)):n;
else
    index = 1:floor(blocksize/(m*4)):n;
end
    
if index(end) ~= n
    index(end+1) = n + 1;
end
    
% ---------------------------------------
% Centroid
% ---------------------------------------
for i = 1:length(index)-1

    block.mz = mz(index(i):index(i+1)-1);
    block.y  = y(:, index(i):index(i+1)-1);
    
    if issparse(y)
        [block.mz, block.y] = centroid(block.mz, full(block.y), iterations);
        varargout{1} = [varargout{1}, block.mz];
        varargout{2} = [varargout{2}, sparse(block.y)];
    else
        [block.mz, block.y] = centroid(block.mz, block.y, iterations);
        varargout{1} = [varargout{1}, block.mz];
        varargout{2} = [varargout{2}, block.y];
    end

end

end

function [x, y] = centroid(x, y, iterations)

% ---------------------------------------
% Variables
% ---------------------------------------
gradient = 1;
counter  = 0;

% ---------------------------------------
% Centroid
% ---------------------------------------
while gradient ~= 0 && counter < iterations
    
    n = length(y(1,:));
    
    for i = 2:n-1
        
        % Find zeros in column
        middle = ~y(:, i);
        
        % Find zeros in adjacent columns
        upper = ~y(:, i+1);
        lower = ~y(:, i-1);
        
        % Consolidate if next column has more zeros
        if nnz(middle) < nnz(upper)
            
            % Find zeros adjacent to nonzeros
            index = xor(middle, upper);
            
            % Shift nonzeros in adjacent column to middle column
            y(index, i) = y(index, i) + y(index, i+1);
            y(index, i+1) = 0;
            
        end
        
        % Consolidate if previous column has more zero elements
        if nnz(middle) < nnz(lower)
            
            % Find zeros adjacent to nonzeros
            index = xor(middle, lower);
            
            % Shift nonzeros in adjacent column to middle column
            y(index, i) = y(index, i) + y(index, i-1);
            y(index, i-1) = 0;
            
        end
    end
    
    % Remove columns with all zeros
    ii = all(~y);
    
    x(:, ii) = [];
    y(:, ii) = [];
    
    % Update values
    gradient = n - length(y(1,:));
    counter  = counter + 1;
    
end

end