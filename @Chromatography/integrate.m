% Method: integrate
%  -Find and integrate chromatographic peaks
%
% Syntax
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'OptionName', optionvalue...)
%
% Options
%   'samples' : 'all', [index]
%   'ions'    : 'all', 'tic', [index]
%   'center'  : value
%   'width'   : value
%   'results' : 'replace', 'append', 'reset'
%
% Description
%   data      : data structure
%   'samples' : row index of samples (default = 'all')
%   'ions'    : column index of ions (default = 'tic')
%   'center'  : window center (default = x at max(y))
%   'width'   : window width (default = %5 of length(x))
%   'results' : replace, append or reset existing peak data (default = 'replace')
%
% Examples
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'samples', [2:5, 8, 10], ions, 'all')
%   data = obj.integrate(data, 'ions', [1:34, 43:100], 'center', 14.5)
%   data = obj.integrate(data, 'center', 18.5, 'width', 5.0, 'results', 'append')
%
% References
%   K. Lan, et. al. Journal of Chromatography A, 915 (2001) 1-13

function varargout = integrate(obj, varargin)

% Check input
[data, options] = parse(obj, varargin);

% Variables
samples = options.samples;
ions = options.ions;
center = options.center;
width = options.width;
results = options.results;

% Calculate peak area
for i = 1:length(samples)
    
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
            y = data(samples(i)).xic.values;
            baseline = data(samples(i)).xic.baseline;
        case 'xic'
            y = data(samples(i)).xic.values(:, options.ions);
            baseline = data(samples(i)).xic.baseline;
            
            if ~isempty(baseline)
                baseline = baseline(:, options.ions);
            end
    end
    
    % Calculate baseline correction
    if ~isempty(baseline)
        y = y - baseline;
    end
    
    % Calculate curve fitting results
    switch obj.Defaults.integrate.model
        
        case 'exponential gaussian hybrid'
            peaks = ExponentialGaussian(x, y, 'center', center, 'width', width);
            
        otherwise
            peaks = ExponentialGaussian(x, y, 'center', center, 'width', width);
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
end

% Set output
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