% ------------------------------------------------------------------------
% Method      : ParallelSmooth [EXPERIMENTAL]
% Description : Asymmetric least squares smoothing with parallel computing
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
%   y = ParallelSmooth(y)
%   y = ParallelSmooth(y, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   y (required)
%       Description : intensity values
%       Type        : array or matrix
%
%   'parallel' (optional)
%       Description : parallel compute smoothing data
%       Type        : 'on', 'off'
%       Default     : 'on'
%
%   'smoothness' (optional)
%       Description : smoothness parameter used for smoothing calculation
%       Type        : number
%       Default     : 0.5
%       Range       : 0 to 10000
%
%   'asymmetry' (optional)
%       Description : asymmetry parameter used for smoothing calculation
%       Type        : number
%       Default     : 0.5
%       Range       : 0.0 to 1.0
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   y = ParallelSmooth(y)
%   y = ParallelSmooth(y, 'smoothness', 500)
%   y = ParallelSmooth(y, 'parallel', 'on', 'smoothness', 10)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631
%

function varargout = ParallelSmooth(y, varargin)

% Check input
if nargin < 1
    error('Not enough input arguments.');
    
elseif ~isnumeric(y)
    error('Undefined input arguments of type ''y''.');
end

% Default options
smoothness = 0.5;
asymmetry = 0.5;
parallel = 'on';

% Check user input
if nargin > 1
    
    input = @(x) find(strcmpi(varargin,x),1);
    
    % Check smoothness options
    if ~isempty(input('smoothness'));
        
        smoothness = varargin{input('smoothness')+1};
        
        % Check for valid input
        if ~isnumeric(smoothness) || smoothness > 1E15
            smoothness = 1E6;
            
        elseif smoothness <= 0
            smoothness = 1E-6;
        end
    end
    
    % Check asymmetry options
    if ~isempty(input('asymmetry'));
        
        asymmetry = varargin{input('asymmetry')+1};
        
        % Check for valid input
        if ~isnumeric(asymmetry) || asymmetry <= 0
            asymmetry = 1E-4;
            
        elseif asymmetry >= 1
            asymmetry = 1 - 1E-4;
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
smoothed = zeros(size(y));

% Variables
rows = length(y(:,1));
index = 1:rows;

switch parallel
    
    case 'on'
        
        % Variables
        d = diff(speye(rows), 2);
        d = smoothness * (d' * d);
        
        % Calculate smoothed data
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
            
            s = zeros(rows,1);
            
            % Number of iterations
            for j = 1:10
                
                % Cholesky factorization
                w = chol(w + d);
                
                % Left matrix divide, multiply matrices
                s = w \ (w' \ (weights .* y(:,i)));
                
                % Determine weights
                weights = asymmetry * (y(:,i) > s) + (1 - asymmetry) * (y(:,i) < s);
                
                % Reset sparse matrix
                w = sparse(index, index, weights);
            end
            
            % Check offset
            if offset(i) ~= 0
                
                % Preserve negative values from input
                smoothed(:,i) = s - offset(i);
                
            elseif offset(i) == 0
                
                % Correct negative values from smoothing
                s(s < 0) = 0;
                smoothed(:,i) = s;
            end
        end
        
    case 'off'
        
        % Pre-allocate memory
        weights = ones(rows, 1);
        
        % Variables
        d = diff(speye(rows), 2);
        d = smoothness * (d' * d);
        
        w = spdiags(weights, 0, rows, rows);
        
        % Calculate smoothed data
        for i = 1:length(y(1,:))
            
            % Check offset
            if offset(i) ~= 0
                y(:,i) = y(:,i) + offset(i);
            end
            
            % Check values
            if ~any(y(:,i) ~= 0)
                continue
            end
            
            s = zeros(rows,1);
            
            % Number of iterations
            for j = 1:15
                
                % Cholesky factorization
                w = chol(w + d);
                
                % Left matrix divide, multiply matrices
                s = w \ (w' \ (weights .* y(:,i)));
                
                % Determine weights
                weights = asymmetry * (y(:,i) > s) + (1 - asymmetry) * (y(:,i) < s);
                
                % Reset sparse matrix
                w = sparse(index, index, weights);
            end
            
            % Check offset
            if offset(i) ~= 0
                
                % Preserve negative values from input
                smoothed(:,i) = s - offset(i);
                
            elseif offset(i) == 0
                
                % Correct negative values from smoothing
                s(s < 0) = 0;
                smoothed(:,i) = s;
            end
            
            % Reset variables
            weights = ones(rows, 1);
        end
end

% Set output
varargout{1} = smoothed;

end