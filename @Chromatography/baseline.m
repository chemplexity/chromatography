% Method: baseline
%  -Calculate baseline of chromatographic data
%
% Syntax
%   data = baseline(data)
%   data = baseline(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'    : 'all', [sampleindex]
%   'ions'       : 'all', 'tic', [ionindex]
%   'smoothness' : value (~10^3 to 10^9)
%   'asymmetry'  : value (~10^-1 to 10^-6)
%
% Description
%   data         : an existing data structure
%   'samples'    : row index of samples in data structure -- (default: all)
%   'ions'       : column index of ions in data structure -- (default: all)
%   'smoothness' : smoothing parameter for baseline calculation -- (default: 10^6)
%   'asymmetry'  : asymetry parameter for baseline calcaultion -- (default: 10^-4)
%
% Examples
%   data = obj.baseline(data)
%   data = obj.baseline(data, 'samples', [2:5, 8, 10])
%   data = obj.baseline(data, 'ions', [1:34, 43:100])
%   data = obj.baseline(data, 'ions', 'all', 'smoothness', 10^5)
%   data = obj.baseline(data, 'smoothness', 10^7, 'asymmetry', 10^-3)
%
% References
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

function data = baseline(obj, varargin)

% Check number of inputs
if nargin < 2
    error('Not enough input arguments');
end          
  
% Check data structure
if isstruct(varargin{1})
    data = DataStructure('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check sample options
if ~isempty(input('samples'))
    samples = varargin{input('samples')+1};
                    
    % Check user input
    if strcmpi(samples, 'all')
        samples = 1:length(varargin{1});
    elseif ~isnumeric(samples)
        error('Undefined input arguments of type ''samples''');
    elseif max(samples) > length(data) || min(samples) < 1
        error('Index exceeds matrix dimensions')
    end
        
else
    % Default samples options
    samples = 1:length(varargin{1});
end
                
% Check ion options
if ~isempty(input('ions'))
    ions = varargin{input('ions')+1};
else
    % Default ions options
    ions = 'all';
end

% Check smoothness options
if ~isempty(input('smoothness'))
    smoothness = varargin{input('smoothness')+1};
    
    % Check user input
    if ~isnumeric(smoothness)
        error('Undefined input arguments of type ''smoothness''');
    end
else
    % Default smoothness options
    smoothness = obj.options.baseline.smoothness;
end

% Check asymmetry options
if ~isempty(input('asymmetry'))
    asymmetry = varargin{input('asymmetry')+1};
     
    % Check user input
    if ~isnumeric(asymmetry)
        error('Undefined input arguments of type ''asymmetry''');
    end
else
    % Default asymmetry options
    asymmetry = obj.options.baseline.asymmetry;
end

% Calculate baseline
for i = 1:length(samples)
                
    % Check ion options
    if ~ischar(ions)
        y = data(samples(i)).intensity_values(:, ions);
    else
        switch ions
                    
        % Use total ion chromatograms
        case 'tic'
            y = data(samples(i)).total_intensity_values;
                     
        % Use all ion chromatograms    
        case 'all'
            y = data(samples(i)).intensity_values;

            otherwise
                error('Undefined input arguments of type ''ions''');
        end
    end

    % Start timer
    tic;
                
    % Whittaker Smoother
    baseline = WhittakerSmoother(y, 'smoothness', smoothness, 'asymmetry', asymmetry);
                
    % Stop timer
    compute_time = toc;
    
    % Format output
    if isempty(data(samples(i)).intensity_values_baseline)
        data(samples(i)).intensity_values_baseline = zeros(...
            length(data(samples(i)).intensity_values(:,1)),...
            length(data(samples(i)).intensity_values(1,:)));
    end

    if ~ischar(ions)
        data(samples(i)).intensity_values_baseline(:, ions) = baseline;
    else
        switch ions
            case 'tic' 
                data(samples(i)).total_intensity_values_baseline = baseline;  
            case 'all'
                data(samples(i)).intensity_values_baseline = baseline;
        end
    end
    
    % Update baseline dianostics
    data(samples(i)).statistics.compute_time(end+1) = compute_time;
    data(samples(i)).statistics.function{end+1} = 'baseline';
    data(samples(i)).statistics.calls(end+1) = length(y(1,:));
end
end