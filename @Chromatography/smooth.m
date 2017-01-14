function data = smooth(obj, varargin)
% ------------------------------------------------------------------------
% Method      : Chromatography.smooth
% Description : Smooth chromatogram
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.smooth(data)
%   data = obj.smooth( __ , Name, Value)
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
%   'smoothness' -- smoothing parameter (1E-1 to 1E5)
%       0.5 (default) | number
%
%   'asymmetry' -- asymmetry parameter (0 to 1)
%       0.5 (default) | number
%
%   'iterations' -- maximum number of smoothing iterations
%       5 (default) | number
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
%   data = obj.smooth(data)
%   data = obj.smooth(data, 'samples', [2:5, 8, 10])
%   data = obj.smooth(data, 'ions', [1:34, 43:100])
%   data = obj.smooth(data, 'ions', 'all', 'smoothness', 5)
%   data = obj.smooth(data, 'smoothness', 2500, 'asymmetry', 0.25)
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
default.smoothness = 0.5;
default.asymmetry  = 0.5;
default.iterations = 5;
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
obj.dispMsg('header', 'SMOOTH');

if isempty(option.samples)
    obj.dispMsg('error', 'Invalid sample selection...');
    obj.dispMsg('header', 'EXIT');
    return
end

% ---------------------------------------
% Smooth
% ---------------------------------------
for i = 1:length(option.samples)

    row = option.samples(i);
    col = option.ions{i};
    
    obj.dispMsg('counter', i, length(option.samples));
    obj.dispMsg('sample', row);
    obj.dispMsg('channel', field, length(col));
    
    y = data(row).(field).values;
    
    if isempty(y) || isempty(col)
        continue
    end
    
    y(:, col) = Smooth(y(:, col),...
        'smoothness', option.smoothness,...
        'asymmetry',  option.asymmetry,...
        'iterations', option.iterations,...
        'gradient',   option.gradient);
    
    data(row).(field).values = y;

end

obj.dispMsg('header', 'EXIT');

end