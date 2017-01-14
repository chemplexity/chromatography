function data = centroid(obj, varargin)
% ------------------------------------------------------------------------
% Method      : Chromatography.centroid
% Description : Centroid mass values
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.centroid(data)
%   data = obj.centroid( __ , Name, Value)
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
%   'tolerance' -- maximum bin size used for centroiding
%       1 (default) | number
%
%   'iterations' -- number of iterations to perform centroiding
%       10 (default) | number
%
%   'blocksize' -- maximum number of bytes to process at a single time
%       10E6 (default) | number
%
%   'verbose' -- show progress in command window
%       true (default) | false
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = obj.centroid(data)
%   data = obj.centroid(data, 'samples', [2:5, 8, 10])

% ---------------------------------------
% Defaults
% ---------------------------------------
default.samples    = 'all';
default.tolerance  = 1;
default.iterations = 10;
default.blocksize  = 10E6;
default.verbose    = true;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'data', @isstruct);

addParameter(p, 'samples',    default.samples);
addParameter(p, 'tolerance',  default.tolerance,  @isscalar);
addParameter(p, 'iterations', default.iterations, @isscalar);
addParameter(p, 'blocksize',  default.blocksize,  @isscalar);
addParameter(p, 'verbose',    default.verbose);

parse(p, varargin{:});

% ---------------------------------------
% Options
% ---------------------------------------
data = p.Results.data;

option.samples    = p.Results.samples;
option.tolerance  = p.Results.tolerance;
option.iterations = p.Results.iterations;
option.blocksize  = p.Results.blocksize;
option.verbose    = p.Results.verbose;

% ---------------------------------------
% Validate
% ---------------------------------------

% Input: data
data = obj.format('validate', data);

% Parameter: 'samples'
n = length(data);
option.samples = obj.validateSample(option.samples, n);

% Parameter: 'verbose'
obj.verbose = obj.validateLogical(option.verbose, default.verbose);

% ---------------------------------------
% Status
% ---------------------------------------
obj.dispMsg('header', 'CENTROID');

if isempty(option.samples)
    obj.dispMsg('error', 'Invalid sample selection...');
    obj.dispMsg('header', 'EXIT');
    return
end

% ---------------------------------------
% Centroid
% ---------------------------------------
for i = 1:length(option.samples)

    row = option.samples(i);
    col = length(data(row).mz);
    
    obj.dispMsg('counter', i, length(option.samples));
    obj.dispMsg('sample', row);
    
    if col > 1
        obj.dispMsg('channel', 'xic', col);
    else
        obj.dispMsg('channel', 'xic', 0);
        continue
    end
    
    [data(row).mz, data(row).xic.values] = Centroid(...
        data(row).mz, ...
        data(row).xic.values,...
        'tolerance',  option.tolerance,...
        'iterations', option.iterations,...
        'blocksize',  option.blocksize);
    
    if length(data(row).mz) < col
        data(row).xic.baseline = [];
    end
    
end

obj.dispMsg('header', 'EXIT');

end