% Method: baseline
%  -Calculate baseline of chromatographic data
%
% Syntax
%   data = obj.baseline(data)
%   data = obj.baseline(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'    : 'all', [index]
%   'ions'       : 'all', 'tic', [index]
%   'smoothness' : value (~10^3 to 10^9)
%   'asymmetry'  : value (~10^-1 to 10^-6)
%
% Description
%   data         : data structure
%   'samples'    : row index of samples (default = 'all')
%   'ions'       : column index of ions (default = 'tic')
%   'smoothness' : smoothing parameter (default = 10^6)
%   'asymmetry'  : asymetry parameter (default = 10^-4)
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

function varargout = baseline(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;
ions = options.ions;
asymmetry = options.asymmetry;
smoothness =  options.smoothness;

% Calculate baseline
for i = 1:length(samples)

    % Variables
    n = length(data(samples(i)).xic.values(:,1));
    m = length(data(samples(i)).xic.values(1,:));
    
    % Pre-allocate memory
    if isempty(data(samples(i)).xic.baseline)
        data(samples(i)).xic.baseline = zeros(n, m);
        
    elseif length(data(samples(i)).xic.baseline(1,:)) ~= m
        data(samples(i)).xic.baseline = zeros(n, m);
    end
    
    % Check ion options
    if isnumeric(ions)
        ions = 'xic';
    end
    
    % Input values
    switch ions
        case 'tic'
            y = data(samples(i)).tic.values;
        case 'all'
            y = data(samples(i)).xic.values;
        otherwise
            y = data(samples(i)).xic.values(:, options.ions);
    end
    
    % Calculate baseline values
    baseline = Baseline(y, 'smoothness', smoothness, 'asymmetry', asymmetry);

    % Output values
    switch ions
        case 'tic' 
            data(samples(i)).tic.baseline = baseline;  
        case 'all'
            data(samples(i)).xic.baseline = baseline;
        otherwise
            data(samples(i)).xic.baseline(:, options.ions) = baseline;
    end
end

% Return data
varargout{1} = data;
end


% Parse user input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments.');
elseif isstruct(varargin{1})
    data = obj.format('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''.');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Sample options
if ~isempty(input('samples'))
    samples = varargin{input('samples')+1};

    % Set keywords
    samples_all = {'default', 'all'};
        
    % Check for valid input
    if any(strcmpi(samples, samples_all))
        samples = 1:length(data);

    % Check input type
    elseif ~isnumeric(samples)
        
        % Check string input
        samples = str2double(samples);
        
        % Check for numeric input
        if ~any(isnan(samples))
            samples = round(samples);
        else
            samples = 1:length(data);
        end
    end
    
    % Check maximum input value
    if max(samples) > length(data)
        samples = samples(samples <= length(data));
    end
    
    % Check minimum input value
    if min(samples < 1)
        samples = samples(samples >= 1);
    end
    
    options.samples = samples;
    
else
    options.samples = 1:length(data);
end


% Ion options
if ~isempty(input('ions'))
    ions = varargin{input('ions')+1};
    
    % Set keywords
    ions_tic = {'default', 'tic', 'tics', 'total_ion_chromatograms'};
    ions_all = {'all', 'xic', 'xics', 'eic', 'eics', 'extracted_ion_chromatograms'};
    
    % Check for valid input
    if any(strcmpi(ions, ions_tic))
        options.ions = 'tic';
    
    elseif any(strcmpi(ions, ions_all))
        options.ions = 'all';

    elseif ~isnumeric(ions) && ~ischar(ions)
        options.ions = 'tic';
    else
        options.ions = ions;
    end

    % Check input range
    if isnumeric(options.ions)
        
        % Check maximum input value
        if any(max(options.ions) > cellfun(@length, {data(options.samples).mz}))
            options.ions = options.ions(options.ions <= min(cellfun(@length, {data(options.samples).mz})));
        end
        
        % Check minimum input value
        if min(options.ions) < 1
            options.ions = options.ions(options.ions >= 1);
        end
    end
    
else
    options.ions = 'tic';
end


% Smoothness options
if ~isempty(input('smoothness'))
    smoothness = varargin{input('smoothness')+1};
    
    % Check for valid input
    if ~isnumeric(smoothness)
        options.smoothness = obj.Defaults.baseline.smoothness;
    else
        options.smoothness = smoothness;
    end
else
    options.smoothness = obj.Defaults.baseline.smoothness;
end


% Asymmetry options
if ~isempty(input('asymmetry'))
    asymmetry = varargin{input('asymmetry')+1};
    
    % Check for valid input
    if ~isnumeric(asymmetry)
        options.asymmetry = obj.Defaults.baseline.asymmetry;
    else
        options.asymmetry = asymmetry;
    end
else
    options.asymmetry = obj.Defaults.baseline.asymmetry;
end

% Return input
varargout{1} = data;
varargout{2} = options;
end