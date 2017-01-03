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
y          = p.Results.y;
z          = p.Results.mz;
iterations = p.Results.iterations;
blocksize  = p.Results.blocksize;

varargout{1} = [];
varargout{2} = [];

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: mz
if size(z,2) ~= size(y,2)
    return
end

if size(z,2) == 1 || size(y,1) == 1
    return
end

% Parameter: 'iterations' 
if iterations <= 0
    iterations = 1;
end

% Parameter: 'blocksize'
if blocksize <= 1E3
    blocksize = 1E3;
end

% ---------------------------------------
% Variables
% ---------------------------------------
[m,n] = size(y);

if isa(y,'double')
    ii = 1:floor(blocksize/(m*8)):n;
else
    ii = 1:floor(blocksize/(m*4)):n;
end
    
if ii(end) ~= n
    ii(end+1) = n+1;
end
    
% ---------------------------------------
% Centroid
% ---------------------------------------
for i = 1:numel(ii)-1

    z0 = z(1, ii(i):ii(i+1)-1);
    y0 = y(:, ii(i):ii(i+1)-1);
    
    if issparse(y)
        [z0, y0] = centroid(z0, full(y0), iterations);
        varargout = {[varargout{1}, z0], varargout{2}, sparse(y0)};
    else
        [z0, y0] = centroid(z0, y0, iterations);
        varargout = {[varargout{1}, z0], [varargout{2}, y0]};
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
% Centroid algorithm
% ---------------------------------------
while gradient ~= 0 && counter < iterations
    
    n = size(y,2);
    
    for i = 2:n-1
        
        % Index zeros in column
        y1 = ~y(:, i);
        
        % Index zeros in adjacent columns
        y2 = ~y(:, i+1);
        y0 = ~y(:, i-1);
        
        % Shift values from y(i+1) to y(i)
        if nnz(y1) < nnz(y2)
            
            % Index nonzeros adjacent to zeros
            ii = xor(y1, y2);
            
            % Shift values from y(i+1) to y(i)
            y(ii, i) = y(ii, i) + y(ii, i+1);
            y(ii, i+1) = 0;
            
        end
        
        % Shift values from y(i-1) to y(i)
        if nnz(y1) < nnz(y0)
            
            % Index nonzeros adjacent to zeros
            ii = xor(y1, y0);
            
            % Shift values from y(i-1) to y(i)
            y(ii, i) = y(ii, i) + y(ii, i-1);
            y(ii, i-1) = 0;
            
        end
    end
    
    % Remove columns with all zeros
    ii = all(~y);
    
    x(:, ii) = [];
    y(:, ii) = [];
    
    % Update values
    gradient = n - size(y,2);
    counter  = counter + 1;
    
end

end