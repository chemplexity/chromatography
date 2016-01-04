% ------------------------------------------------------------------------
% Method      : ParallelBaseline [EXPERIMENTAL]
% Description : Asymmetric least squares baseline with parallel computing
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Requirements
% ------------------------------------------------------------------------
%   MATLAB Parallel Computing Toolbox (Version 6.2+)
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   baseline = ParallelBaseline(y)
%   baseline = ParallelBaseline(y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   'parallel' (optional)
%       Description : parallel compute baseline data
%       Type        : 'on', 'off'
%       Default     : 'on'
%
%   'smoothness' (optional)
%       Description : smoothness parameter used for baseline calculation
%       Type        : number
%       Default     : 1E6
%       Range       : 1E3 to 1E9
%
%   'asymmetry' (optional)
%       Description : asymmetry parameter used for baseline calculation
%       Type        : number
%       Default     : 1E-4
%       Range       : 1E-3 to 1E-9
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   baseline = ParallelBaseline(y)
%   baseline = ParallelBaseline(y, 'asymmetry', 1E-2)
%   baseline = ParallelBaseline(y, 'smoothness', 1E5)
%   baseline = ParallelBaseline(y, 'parallel', 'on', 'asymmetry', 1E-3)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631
%

function varargout = ParallelBaseline(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''.');
end

% Default options
smoothness = 1E6;
asymmetry = 1E-4;
parallel = 'on';

% Check user input
if nargin > 1
    
    input = @(x) find(strcmpi(varargin,x),1);
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        
        smoothness = varargin{input('smoothness')+1};
        
        % Check for valid input
        if ~isnumeric(smoothness) || smoothness > 10^15
            smoothness = 10^6;
            
        elseif smoothness <= 0
            smoothness = 10^6;
        end
        
    end
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        
        asymmetry = varargin{input('asymmetry')+1};
        
        % Check for valid input
        if ~isnumeric(asymmetry) || asymmetry <= 0
            asymmetry = 10^-4;
            
        elseif asymmetry >= 1
            asymmetry = 1 - 10^-4;
        end
        
    end
    
    % Check parallel computing options
    if ~isempty(input('parallel'));
        
        parallel = varargin{input('parallel')+1};
        
        % Check for valid input
        if any(strcmpi(parallel, {'default', 'on', 'enable', 'yes'}))
            
            % Determine available toolboxes
            toolbox = dir([matlabroot '/toolbox']);
            
            distcomp = regexp([toolbox.name], '(?i)distcomp', 'match');
            
            if isempty(distcomp)
                disp('Parallel Computing Toolbox not detected. Proceeding without parallel computing.');
                parallel = 'off';
                
            elseif verLessThan('distcomp', '6.2');
                disp('Parallel Computing Toolbox < v6.2. Errors may arise');
                parallel = 'on';
                
            else
                parallel = 'on';
            end
            
        elseif any(strcmpi(parallel, {'off', 'disable', 'no'}))
            parallel = 'off';
            
        else
            disp('Parallel Computing Toolbox not detected. Proceeding without parallel computing.');
            parallel = 'off';
        end
        
    else
        parallel = 'off';
    end
end

% Check data precision
if ~isa(y, 'double')
    y = double(y);
end

% Check data length
if all(size(y) <= 3)
    disp('Insufficient number of points');
    return
end

% Check for negative values
if any(min(y) < 0)
    
    % Determine offset
    offset = min(y);
    offset(offset > 0) = 0;
    offset(offset < 0) = abs(offset(offset < 0));
    
else
    offset = zeros(1, length(y(1,:)));
end

% Pre-allocate memory
baseline = zeros(size(y));

% Variables
rows = length(y(:,1));
index = 1:rows;

switch parallel
    
    case 'on'
        
        % Variables
        d = diff(speye(rows), 2);
        d = smoothness * (d' * d);
        
        % Calculate baseline
        parfor i = 1:length(y(1,:))
            
            % Pre-allocate memory
            weights = ones(rows, 1);
            
            % Variables
            w = spdiags(weights, 0, rows, rows);
            
            % Check offset
            if offset(i) ~= 0
                y(:,i) = y(:,i) + offset(i);
            end
            
            % Check values
            if ~any(y(:,i) ~= 0)
                continue
            end
            
            b = zeros(rows,1);
            
            % Number of iterations
            for j = 1:10
                
                % Cholesky factorization
                w = chol(w + d);
                
                % Left matrix divide, multiply matrices
                b = w \ (w' \ (weights .* y(:,i)));
                
                % Determine weights
                weights = asymmetry * (y(:,i) > b) + (1 - asymmetry) * (y(:,i) < b);
                
                % Reset sparse matrix
                w = sparse(index, index, weights);
            end
            
            % Check offset
            if offset(i) ~= 0
                
                % Preserve negative values from input
                baseline(:,i) = b - offset(i);
                
            elseif offset(i) == 0
                
                % Correct negative values from smoothing
                b(b < 0) = 0;
                baseline(:,i) = b;
            end
        end
        
    case 'off'
        
        % Pre-allocate memory
        weights = ones(rows, 1);
        
        % Variables
        d = diff(speye(rows), 2);
        d = smoothness * (d' * d);
        
        w = spdiags(weights, 0, rows, rows);
        
        % Calculate baseline
        for i = 1:length(y(1,:))
            
            % Check offset
            if offset(i) ~= 0
                y(:,i) = y(:,i) + offset(i);
            end
            
            % Check values
            if ~any(y(:,i) ~= 0)
                continue
            end
            
            b = zeros(rows,1);
            
            % Number of iterations
            for j = 1:10
                
                % Cholesky factorization
                w = chol(w + d);
                
                % Left matrix divide, multiply matrices
                b = w \ (w' \ (weights .* y(:,i)));
                
                % Determine weights
                weights = asymmetry * (y(:,i) > b) + (1 - asymmetry) * (y(:,i) < b);
                
                % Reset sparse matrix
                w = sparse(index, index, weights);
            end
            
            % Check offset
            if offset(i) ~= 0
                
                % Preserve negative values from input
                baseline(:,i) = b - offset(i);
                
            elseif offset(i) == 0
                
                % Correct negative values from smoothing
                b(b < 0) = 0;
                baseline(:,i) = b;
            end
            
            % Reset variables
            weights = ones(rows, 1);
        end
end

% Set output
varargout{1} = baseline;

end