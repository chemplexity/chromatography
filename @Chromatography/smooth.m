% ------------------------------------------------------------------------
% Method      : Chromatography.smooth
% Description : Smooth chromatogram
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.smooth(data)
%   data = obj.smooth(data, Name, Value)
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
%   'ions' (optional)
%       Description : index of ions in data
%       Type        : number | 'all', 'tic'
%       Default     : 'tic'
%
%   ----------------------------------------------------------------------
%   Smoothing Parameters
%   ----------------------------------------------------------------------
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
%

function varargout = smooth(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;
ions = options.ions;

asymmetry = options.asymmetry;
smoothness =  options.smoothness;

count = 0;
timer = 0;

fprintf([...
    '\n[SMOOTH]\n',...
    '\nSmoothing data for ', num2str(length(samples)), ' samples...\n',...
    '\nSmoothness : ', num2str(smoothness),...
    '\nAsymmetry  : ', num2str(asymmetry), '\n\n']);

% Calculate smoothed data
for i = 1:length(samples)
    tic;
    
    % Display progress
    fprintf(['[', num2str(i), '/', num2str(length(samples)), ']']);
    
    % Check ion options
    if isnumeric(ions)
        ions = 'xic';
    end
    
    % Input values
    switch ions
        case 'tic'
            y = data(samples(i)).tic.values;
            
        case 'all'
            
            if ~isempty(data(samples(i)).xic.values)
                y = data(samples(i)).xic.values;
                
            else
                timer = timer + toc;
                fprintf(' No data matches input criteria...\n');
                continue
            end
            
        otherwise
            
            if ~isempty(data(samples(i)).xic.values)
                y = data(samples(i)).xic.values(:, options.ions);
                
                if isempty(data(samples(i)).xic.baseline)
                    data(samples(i)).xic.baseline = zeros(size(y));
                end
                
            else
                timer = timer + toc;
                fprintf(' No data matches input criteria...\n');
                continue
            end
    end
    
    % Calculate smoothed values
    smoothed = Smooth(y, 'smoothness', smoothness, 'asymmetry', asymmetry);
    
    % Output values
    switch ions
        case 'tic'
            data(samples(i)).tic.values = smoothed;
        case 'all'
            data(samples(i)).xic.values = smoothed;
        otherwise
            data(samples(i)).xic.values(:, options.ions) = smoothed;
    end
    
    % Elapsed time
    timer = timer + toc;
    fprintf([' in ', num2str(timer,'%.1f'), ' sec']);
    
    % Data processed (type|vectors)
    count = count + length(y(1,:));
    
    if strcmpi(ions, 'tic')
        fprintf([' (TIC|', num2str(length(y(1,:))), ')\n']);
    else
        fprintf([' (XIC|', num2str(length(y(1,:))), ')\n']);
    end
    
    % Update status
    if strcmpi(ions, 'tic')
        switch data(samples(i)).status.smoothed
            case 'N'
                data(samples(i)).status.smoothed = 'TIC';
            case 'XIC'
                data(samples(i)).status.smoothed = 'Y';
        end
    else
        switch data(samples(i)).status.smoothed
            case 'N'
                data(samples(i)).status.smoothed = 'XIC';
            case 'TIC'
                data(samples(i)).status.smoothed = 'Y';
        end
    end
end

% Return data
varargout{1} = data;

% Display summary
if timer > 60
    elapsed = [num2str(timer/60, '%.1f'), ' min'];
else
    elapsed = [num2str(timer, '%.1f'), ' sec'];
end

fprintf(['\n',...
    'Samples  : ', num2str(length(samples)), '\n',...
    'Elapsed  : ', elapsed, '\n',...
    'Smoothed : ', num2str(count), '\n']);

fprintf('\n[COMPLETE]\n\n');

end


% Parse user input
function varargout = parse(obj, varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments...');
elseif isstruct(varargin{1})
    data = obj.format('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''...');
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
        options.smoothness = obj.defaults.smoothing_smoothness;
    else
        options.smoothness = smoothness;
    end
else
    options.smoothness = obj.defaults.smoothing_smoothness;
end


% Asymmetry options
if ~isempty(input('asymmetry'))
    asymmetry = varargin{input('asymmetry')+1};
    
    % Check for valid input
    if ~isnumeric(asymmetry)
        options.asymmetry = obj.defaults.smoothing_asymmetry;
    else
        options.asymmetry = asymmetry;
    end
else
    options.asymmetry = obj.defaults.smoothing_asymmetry;
end

% Return input
varargout{1} = data;
varargout{2} = options;

end