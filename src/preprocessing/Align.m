function varargout = Align(varargin)
% ------------------------------------------------------------------------
% Method      : Align
% Description : Batch signal alignment with parametric time warping
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   [xindex, yindex] = Align(y0, y1)
%   [xindex, yindex] = Align( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   y0 -- calibration signal used for alignment
%       array | cell
%
%   y1 -- intensity values
%       array | matrix | cell array
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
% Examples
% ------------------------------------------------------------------------
%   [xi, yi] = Align(y0, y1)
%   [xi, yi] = Align(y0, y1, 'iterations', 75)
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

addRequired(p, 'y0', @ismatrix);
addRequired(p, 'y1', @ismatrix);

addParameter(p, 'iterations',  default.iterations,  @isscalar);
addParameter(p, 'convergence', default.convergence, @isscalar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
y0          = p.Results.y0;
y1          = p.Results.y1;
iterations  = p.Results.iterations;
convergence = p.Results.convergence;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: y
if ~iscell(y1)
    y1 = mat2cell(y1, size(y1,1), ones(size(y1,2), 1));
end

% Input: reference
if ~iscell(y0)
    y0 = {y0};
end

% Parameter: 'iterations'
if iterations < 1
    iterations = 1;
end

% ---------------------------------------
% Variables
% ---------------------------------------
m = max([cellfun(@length, y1), length(y0{1})]);
n = length(y1);

% ---------------------------------------
% Alignment
% ---------------------------------------
for i = 1:n

    e = [0; 0];
    c = [0; 1; 0];
    
    B = [ones(m,1), (1:m)', ((1:m)'/m).^2];

    for j = 1:iterations
    
        w = B * c;
        
        yi = find(1 < w & w < length(y0{1}));
        xi = floor(w(yi));
        
        dy = y0{1}(xi+1,1) - y0{1}(xi,1);
        yy = y0{1}(xi,1) + (w(yi) - xi) .* dy;
        
        yi = yi(yi <= length(y1{i})); 
        xi = xi(xi <= length(y1{i}));
        
        r = y1{i}(yi) - yy(1:length(y1{i}(yi)));
    
        e(1) = sqrt(r' * r / m);

        if abs((e(1)-e(2))/(e(1)+1E-10)) < convergence
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