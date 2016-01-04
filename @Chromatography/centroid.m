% ------------------------------------------------------------------------
% Method      : Chromatography.centroid
% Description : Centroid mass values
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.centroid(data)
%   data = obj.centroid(data, Name, Value)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   data (required)
%       Description : chromatography data
%       Type        : structure
%
%   ----------------------------------------------------------------------
%   Data Selection
%   ----------------------------------------------------------------------
%   'samples' (optional)
%       Description : index of samples in data
%       Type        : number | 'all'
%       Default     : 'all'
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = obj.centroid(data)
%   data = obj.centroid(data, 'samples', [2:5, 8, 10])
%

function varargout = centroid(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;

count.before = 0;
count.after = 0;
count.removed = 0;
timer = 0;

fprintf([...
    '\n[CENTROID]\n',...
    '\nCentroiding mass values for ', num2str(length(samples)), ' samples...\n\n']);

for i = 1:length(samples)
    tic;
    
    % Display progress
    fprintf(['[', num2str(i), '/', num2str(length(samples)), ']']);
    
    % Input values
    y = data(samples(i)).xic.values;
    mz = data(samples(i)).mz;
    n = length(mz);
    
    % Centroid data
    if length(mz) > 1
        [mz, y] = Centroid(mz, y);
    end
    
    % Output values
    data(samples(i)).xic.values = y;
    data(samples(i)).mz = mz;
    
    % Clear baseline
    data(samples(i)).xic.baseline = [];
    
    % Elapsed time
    timer = timer + toc;
    fprintf([' in ', num2str(timer, '%.1f'), ' sec']);
    
    % Data processed (before|after|removed)
    count.before = count.before + n;
    count.after = count.after + length(mz);
    count.removed = count.removed + (n - length(mz));
    
    fprintf([' (', num2str(n), '|', num2str(length(mz)), '|', num2str(n - length(mz)), ')\n']);
    
    % Update status
    data(samples(i)).status.centroid = 'Y';
end

% Return data
varargout{1} = data;

% Display summary
if timer > 60
    elapsed = [num2str(timer/60, '%.1f'), ' min'];
else
    elapsed = [num2str(timer, '%.1f'), ' sec'];
end

if count.before > 0
    compression = num2str(100-(count.after/count.before)*100, '%.1f');
else
    compression = '0.0';
end

fprintf(['\n',...
    'Samples     : ', num2str(length(samples)), '\n',...
    'Elapsed     : ', elapsed, '\n',...
    'In/Out      : ', num2str(count.before), '/', num2str(count.after), '\n'...
    'Compression : ', compression, ' %%\n']);

fprintf('\n[COMPLETE]\n\n');

end

% Parse input
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

% Return input
varargout{1} = data;
varargout{2} = options;

end
