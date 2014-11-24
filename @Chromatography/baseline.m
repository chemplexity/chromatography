% Method: baseline
%  -Perform baseline correction of chromatographic data
%
% Syntax
%   baseline(data)
%   baseline(data, 'OptionName', OptionValue...)
%
% Options
%   'samples'    : 'all', [sampleindex]
%   'ions'       : 'all', 'tic', [ionindex]
%   'smoothness' : 10^3 to 10^9
%   'asymmetry'  : 10^-1 to 10^-6
%
% Description
%   data         : an existing data structure
%   'samples'    : row index of samples in data structure -- (default: all)
%   'ions'       : column index of ions in data structure -- (default: all)
%   'smoothness' : smoothing parameter for baseline calculation -- (default: 10^6)
%   'asymmetry'  : asymetry parameter for baseline calcaultion -- (default: 10^-6)
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
elseif nargin > 10
    error('Too many input arguments');
end          
  
% Check data structure
if isstruct(varargin{1})
    data = DataStructure('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''');
end

% Check sample options
if ~isempty(find(strcmpi(varargin, 'samples'),1))
    samples = varargin{find(strcmpi(varargin, 'samples'),1) + 1};
                    
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
if ~isempty(find(strcmpi(varargin, 'ions'),1))
    ions = varargin{find(strcmpi(varargin, 'ions'),1) + 1};
else
    % Default ions options
    ions = 'all';
end

% Check smoothness options
if ~isempty(find(strcmpi(varargin, 'smoothness'),1))
    smoothness = varargin{find(strcmpi(varargin, 'smoothness'),1) + 1};
    
    % Check user input
    if ~isnumeric(smoothness)
        error('Undefined input arguments of type ''smoothness''');
    end
else
    % Default smoothness options
    smoothness = obj.options.baseline.smoothness;
end

% Check asymmetry options
if ~isempty(find(strcmpi(varargin, 'asymmetry'),1))
    asymmetry = varargin{find(strcmpi(varargin, 'asymmetry'),1) + 1};
     
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
    processing_time = toc;
    
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
    data(samples(i)).diagnostics.baseline.processing_time = data(samples(i)).diagnostics.baseline.processing_time + processing_time;
    data(samples(i)).diagnostics.baseline.processing_spectra = data(samples(i)).diagnostics.baseline.processing_spectra + length(y(1,:));
    data(samples(i)).diagnostics.baseline.processing_spectra_length = length(y(:,1));
end
end