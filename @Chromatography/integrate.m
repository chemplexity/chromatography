% ------------------------------------------------------------------------
% Method      : Chromatography.integrate
% Description : Find and integrate peaks
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   data = obj.integrate(data)
%   data = obj.integrate(data, Name, Value)
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
%   'results' (optional)
%       Description : replace, append or reset previous peak results
%       Type        : 'replace', 'append', 'reset'
%       Default     : 'replace'
%
%   ----------------------------------------------------------------------
%   Integration Parameters
%   ----------------------------------------------------------------------
%   'center' (optional)
%       Description : center of window used for peak detection
%       Type        : number
%       Default     : x at max(y)
%       Range       : 0 - max(x)
%
%   'width' (optional)
%       Description : width of window used for peak detection
%       Type        : number
%       Default     : 0.05 * max(x)
%       Range       : 0 - max(x)
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'samples', [2:5, 8, 10], ions, 'all')
%   data = obj.integrate(data, 'ions', [1:34, 43:100], 'center', 14.5)
%   data = obj.integrate(data, 'center', 18.5, 'width', 5.0)
%   data = obj.integrate(data, 'results', 'append')
%
% ------------------------------------------------------------------------
% References
% ------------------------------------------------------------------------
%   K. Lan, et. al. Journal of Chromatography A, 915 (2001) 1-13
%


function varargout = integrate(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;
ions = options.ions;
center = options.center;
width = options.width;
results = options.results;

timer = 0;
count.peaks = 0;
count.time = [];
count.error = [];

fprintf([...
    '\n[INTEGRATE]\n',...
    '\nFind and integrate peaks for ', num2str(length(samples)), ' samples...\n\n']);

% Calculate peak area
for i = 1:length(samples)
    tic;
    
    % Display progress
    fprintf(['[', num2str(i), '/', num2str(length(samples)), ']']);
    
    % Input values
    x = data(samples(i)).time;
    
    % Check ion options
    if isnumeric(ions)
        ions = 'xic';
    end
    
    switch ions
        
        case 'tic'
            y = data(samples(i)).tic.values;
            baseline = data(samples(i)).tic.baseline;
            
        case 'all'
            
            if ~isempty(data(samples(i)).xic.values)
                y = data(samples(i)).xic.values;
                baseline = data(samples(i)).xic.baseline;
                
            else
                timer = timer + toc;
                fprintf(' No data matches input criteria...\n');
                continue
            end
            
        case 'xic'
            
            if ~isempty(data(samples(i)).xic.values)
                y = data(samples(i)).xic.values(:, options.ions);
                baseline = data(samples(i)).xic.baseline;
                
            else
                timer = timer + toc;
                fprintf(' No data matches input criteria...\n');
                continue
            end
            
            if ~isempty(baseline)
                baseline = baseline(:, options.ions);
            end
    end
    
    % Calculate baseline correction
    if ~isempty(baseline)
        y = y - baseline;
    end
    
    % Calculate curve fitting results
    switch obj.defaults.integrate_model
        
        case 'exponential gaussian hybrid'
            peaks = ExponentialGaussian(x, y, 'center', center, 'width', width);
            
        otherwise
            peaks = ExponentialGaussian(x, y, 'center', center, 'width', width);
    end
    
    if isempty(peaks)
        timer = timer + toc;
        fprintf(' No data matches input criteria...\n');
        continue;
    end
    
    switch ions
        
        case 'tic'
            peak_data = data(samples(i)).tic.peaks;
            column = 1;
            
            % Check peak data
            if isempty(peak_data.time)
                peak_data.time(1,1) = 0;
            end
            
        case 'all'
            peak_data = data(samples(i)).xic.peaks;
            column = 1:length(data(samples(i)).xic.values(1,:));
            
            % Check peak data
            if isempty(peak_data.time)
                peak_data.time(1,column) = 0;
                peak_data.height(1,column) = 0;
                peak_data.width(1,column) = 0;
                peak_data.area(1,column) = 0;
                peak_data.error(1,column) = 0;
            end
            
        case 'xic'
            peak_data = data(samples(i)).xic.peaks;
            column = 1:length(data(samples(i)).xic.values(1,:));
            
            % Check peak data
            if isempty(peak_data.time)
                peak_data.time(1,column) = 0;
                peak_data.height(1,column) = 0;
                peak_data.width(1,column) = 0;
                peak_data.area(1,column) = 0;
                peak_data.error(1,column) = 0;
            end
            
            column = options.ions;
    end
    
    switch results
        
        case 'reset'
            
            % Reset values to zero
            peak_data.time(:, column) = 0;
            peak_data.height(:, column) = 0;
            peak_data.width(:, column) = 0;
            peak_data.area(:, column) = 0;
            peak_data.error(:, column) = 0;
            
            if isempty(peak_data.fit)
                peak_data.fit{1, max(column)} = [];
            else
                peak_data.fit(:, column) = {[]};
            end
            
            % Remove rows
            if length(peak_data.time(:,1)) > 2
                
                peak_data.time(2:end, :) = [];
                peak_data.height(2:end, :) = [];
                peak_data.width(2:end, :) = [];
                peak_data.area(2:end, :) = [];
                peak_data.error(2:end, :) = [];
                
                if ~isempty(peak_data.fit)
                    peak_data.fit(2:end, :) = [];
                end
            end
            
            row(1, column) = 1;
            row(row == 0) = [];
            
        case 'replace'
            row = peak_data.time(:, column) ~= 0;
            
            if length(row(:,1)) > 1
                row = sum(row);
            else
                row(row == 0) = 1;
            end
            
        case 'append'
            row = peak_data.time(:, column) ~= 0;
            
            if length(row(:,1)) > 1
                row = sum(row) + 1;
            else
                row = row +1;
            end
    end
    
    % Assign peak data
    for j = 1:length(column)
        peak_data.time(row(j),column(j)) = peaks.time(j);
        peak_data.height(row(j),column(j)) = peaks.height(j);
        peak_data.width(row(j),column(j)) = peaks.width(j);
        peak_data.area(row(j),column(j)) = peaks.area(j);
        peak_data.fit(row(j),column(j)) = {peaks.fit(:,j)};
        peak_data.error(row(j),column(j)) = peaks.error(j);
    end
    
    % Reattach peak data
    if strcmpi(ions, 'tic')
        data(samples(i)).tic.peaks = peak_data;
    else
        data(samples(i)).xic.peaks = peak_data;
    end
    
    % Elapsed time
    timer = timer + toc;
    fprintf([' in ', num2str(timer, '%.1f'), ' sec']);
    
    % Results
    count.peaks = count.peaks + length(peaks.time(peaks.time ~= 0));
    count.time= [count.time, peaks.time(peaks.time~=0)];
    count.error = [count.error, peaks.error(peaks.time~=0)];
    
    n = num2str(length(peaks.time(peaks.time ~= 0)));
    
    if length(peaks.time) == 1
        t = [num2str(peaks.time, '%.1f'), ' min'];
        e = [num2str(peaks.error, '%.1f'), '%%'];
        
    else
        t = [num2str(min(peaks.time), '%.1f'), '-', num2str(max(peaks.time), '%.1f'), ' min'];
        e = [num2str(min(peaks.error), '%.1f'), '-' , num2str(max(peaks.error), '%.1f'), '%%'];
    end
    
    fprintf([' (', n, ', ', t, ', ', e, ')\n']);
end

% Set output
varargout{1} = data;

% Display summary
if timer > 60
    elapsed = [num2str(timer/60, '%.1f'), ' min'];
else
    elapsed = [num2str(timer, '%.1f'), ' sec'];
end

if count.peaks == 1
    time = [num2str(count.time, '%.1f'), ' min'];
    error = [num2str(count.error, '%.1f'), ' %%'];
    
elseif count.peaks == 0
    time = 'N/A';
    error = 'N/A';
    
else
    time = [...
        num2str(min(count.time), '%.1f'), '-',...
        num2str(max(count.time), '%.1f'), ' min'];
    
    error = [...
        num2str(mean(count.error), '%.1f'), '%% (',...
        num2str(min(count.error), '%.1f'), '-',...
        num2str(max(count.error), '%.1f'), '%%)'];
end

fprintf(['\n',...
    'Samples : ', num2str(length(samples)), '\n',...
    'Elapsed : ', elapsed, '\n',...
    'Peaks   : ', num2str(count.peaks), '\n'...
    'Range   : ', time, '\n',...
    'Error   : ', error, '\n']);

fprintf('\n[COMPLETE]\n\n');

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


% Center options
if ~isempty(input('center'))
    center = varargin{input('center')+1};
    
    % Check for valid input
    if ~isnumeric(center)
        options.center = [];
    elseif center <= 0
        options.center = [];
    else
        options.center = center;
    end
else
    options.center = [];
end


% Width options
if ~isempty(input('width'))
    width = varargin{input('width')+1};
    
    % Check for valid input
    if ~isnumeric(width)
        options.width = [];
    elseif width <= 0
        options.width = [];
    else
        options.width = width;
    end
else
    options.width = [];
end


% Results options
if ~isempty(input('results'))
    results = varargin{input('results')+1};
    
    % Set keywords
    results_append = {'append', 'add'};
    results_replace = {'default', 'replace', 'overwrite'};
    results_reset = {'reset', 'erase'};
    
    % Check for valid input
    if any(strcmpi(results, results_append))
        options.results = 'append';
        
    elseif any(strcmpi(results, results_replace))
        options.results = 'replace';
        
    elseif any(strcmpi(results, results_reset))
        options.results = 'reset';
        
    else
        options.results = 'replace';
    end
else
    options.results = 'replace';
end

% Return input
varargout{1} = data;
varargout{2} = options;

end