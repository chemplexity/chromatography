function data = baseline(obj, varargin)
% ------------------------------------------------------------------------
% Method      : Chromatography.baseline
% Description : Calculate baseline of chromatogram
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.baseline(data)
%   data = obj.baseline( __ , Name, Value)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   data -- chromatography data structure
%       structure
%
% ------------------------------------------------------------------------
% Input (Name, Value)
% ------------------------------------------------------------------------
%   'samples' -- index of samples in data
%       'all' (default) | number
%
%   'ions' -- index of ions in data
%       'tic' (default) | 'all' | number
%
%   'smoothness' -- smoothing parameter (1E3 to 1E9)
%       1E6 (default) | number
%
%   'asymmetry' -- asymmetry parameter (1E-6 to 1E-1)
%       1E-4 (default) | number
%
%   'iterations' -- maximum number of baseline iterations
%       10 (default) | number
%       
%   'gradient' -- minimum change required for continued iterations
%       1E-4 (default) | number
%
%   'verbose' -- show progress in command window
%       true (default) | false
%            
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = obj.baseline(data)
%   data = obj.baseline(data, 'samples', [2:5, 8, 10])
%   data = obj.baseline(data, 'ions', [1:34, 43:100])
%   data = obj.baseline(data, 'ions', 'all', 'smoothness', 1E5)
%   data = obj.baseline(data, 'smoothness', 1E8, 'asymmetry', 1E-3)
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

% ---------------------------------------
% Defaults
% ---------------------------------------
default.samples    = 'all';
default.ions       = 'tic';
default.smoothness = 1E6;
default.asymmetry  = 1E-4;
default.iterations = 10;
default.gradient   = 1E-4;
default.verbose    = true;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'data', @isstruct);

addParameter(p, 'samples',    default.samples);
addParameter(p, 'ions',       default.ions);
addParameter(p, 'smoothness', default.smoothness, @isscalar);
addParameter(p, 'asymmetry',  default.asymmetry,  @isscalar);
addParameter(p, 'iterations', default.iterations, @isscalar);
addParameter(p, 'gradient',   default.gradient,   @isscalar);
addParameter(p, 'verbose',    default.verbose);

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
data = p.Results.data;

option.samples    = p.Results.samples;
option.ions       = p.Results.ions;
option.smoothness = p.Results.smoothness;
option.asymmetry  = p.Results.asymmetry;
option.iterations = p.Results.iterations;
option.gradient   = p.Results.gradient;
option.verbose    = p.Results.verbose;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: data
data = obj.format('validate', data);

if ischar(option.ions) && strcmpi(option.ions, 'tic')
    field = 'tic';
else
    field = 'xic';
end

% Parameter: 'samples'
n = length(data);
option.samples = obj.validateSample(option.samples, n);

% Parameter: 'ions'
n = cellfun(@length, {data(option.samples).mz});
option.ions = obj.validateChannel(option.ions, n);

% Parameter: 'verbose'
obj.verbose = obj.validateLogical(option.verbose, default.verbose);

% ---------------------------------------
% Status
% ---------------------------------------
obj.dispMsg('header', 'BASELINE');

if isempty(option.samples)
    obj.dispMsg('error', 'Invalid sample selection...');
    obj.dispMsg('header', 'EXIT');
    return
end

% ---------------------------------------
% Baseline
% ---------------------------------------
for i = 1:length(option.samples)

    row = option.samples(i);
    col = option.ions{i};
    
    updateMsg(obj, i, length(option.samples), row, field, length(col));
    
    y = data(row).(field).values;
    b = data(row).(field).baseline;
    
    if isempty(y) || isempty(col)
        continue
    end
    
    if isempty(b)
        b = zeros(size(y), class(y));
    end
    
    b(:, col) = Baseline(y(:, col),...
        'smoothness', option.smoothness,...
        'asymmetry',  option.asymmetry,...
        'iterations', option.iterations,...
        'gradient',   option.gradient);
    
    data(row).(field).baseline = b;

end

obj.dispMsg('header', 'EXIT');

end

function updateMsg(obj, m, n, sample, type, channel)

obj.dispMsg('counter', m, n);
    
obj.dispMsg('string', [' Sample #', num2str(sample)]);
obj.dispMsg('string', [', ', upper(type), ' (']);

if channel == 1
    obj.dispMsg('string', '1 baseline)...');
else
    obj.dispMsg('string', [num2str(channel), ' baselines)...']);
end

obj.dispMsg('newline');

end