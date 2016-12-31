function varargout = Align(varargin)
% ------------------------------------------------------------------------
% Method      : Align
% Description : Batch signal alignment with parametric time warping
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   [xindex, yindex] = Align(y, reference)
%   [xindex, yindex] = Align( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   y -- intensity values
%       array | matrix | cell array
%
%   reference -- calibration signal used for alignment
%       array | cell
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'iterations' -- number of iterations to perform warping optimization 
%       50 (default) | number
%
%   'convergence' -- stopping criteria
%       1E-5 (default) | number
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%    P.H.C. Eilers, Analytical Chemistry, 76 (2004) 404

% ---------------------------------------
% Defaults
% ---------------------------------------
default.iterations  = 50;
default.convergence = 1E-5;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'y',   @ismatrix);
addRequired(p, 'ref', @ismatrix);

addParameter(p, 'iterations',  default.iterations,  @isscalar);
addParameter(p, 'convergence', default.convergence, @isscalar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y = p.Results.y;
z = p.Results.ref;

iterations  = p.Results.iterations;
convergence = p.Results.convergence;

% ---------------------------------------
% Validate
% ---------------------------------------
if ~iscell(y)
    y = mat2cell(y, length(y(:,1)), ones(length(y(1,:)), 1));
end

if ~iscell(z)
    z = {z};
end

if iterations < 1
    iterations = 1;
end

% ---------------------------------------
% Variables
% ---------------------------------------
m = max([cellfun(@length, y), length(z{1})]);
n = length(y);

% ---------------------------------------
% Alignment
% ---------------------------------------
for i = 1:n

    e = [0; 0];
    c = [0; 1; 0];
    
    B = [ones(m,1), (1:m)', ((1:m)'/m).^2];

    for j = 1:iterations
    
        w = B * c;
        
        yi = find(1 < w & w < length(z{1}));
        xi = floor(w(yi));
        
        dy = z{1}(xi+1,1) - z{1}(xi,1);
        yy = z{1}(xi,1) + (w(yi) - xi) .* dy;
        
        yi = yi(yi <= length(y{i})); 
        xi = xi(xi <= length(y{i}));
        
        r = y{i}(yi) - yy(1:length(y{i}(yi)));
    
        e(1) = sqrt(r' * r / m);

        if abs((e(1) - e(2)) / (e(1) + 1E-10)) < convergence
            break
        else
            e(2) = e(1);
        end
        
        c = c + repmat(dy(1:length(r)),1,3) .* B(yi,:) \ r;

    end
    
    if length(xi) > length(yi)
        varargout{1}{i} = xi(1:length(yi));
        varargout{2}{i} = yi;
    else
        varargout{1}{i} = xi;
        varargout{2}{i} = yi(1:length(xi));
    end
    
end

end