% Method: integrate
%  -Find and integrate chromatographic peaks
%
% Syntax
%   data = integrate(data)
%   data = integrate(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'  : 'all', [sampleindex]
%   'ions'     : 'all', 'tic', [ionindex]
%   'center'   : value
%   'width'    : value
%   'results'  : 'replace', 'append', 'reset'
%
% Description
%   data       : an existing data structure
%   'samples'  : row index of samples in data structure -- (default: all)
%   'ions'     : column index of ions in data structure -- (default: tic)
%   'center'   : search for peak at center value -- (default: x at max(y))
%   'width'    : search for peak at center +/- width/2 -- (default: 2)
%   'results'  : replace, append or reset existing peak values -- (default: replace)
%
% Examples
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'samples', [2:5, 8, 10], ions, 'all')
%   data = obj.integrate(data, 'ions', [1:34, 43:100], 'center', 14.5)
%   data = obj.integrate(data, 'center', 18.5, 'width', 5.0, 'results', 'append')
%
% References
%   Y. Kalambet, et.al, Journal of Chemometrics, 25 (2011) 352

function varargout = integrate(obj, varargin)

% Check input
[data, options] = parse(varargin);
 
% Variables
id = options.samples;

if strcmpi(options.ions, 'tic')
    index = 1;
else
    index = options.ions;
end

% Calculate peak area
for i = 1:length(id)

    % Determine x-values
    x = data(id(i)).time_values;

    % Determine y-values
    if strcmpi(options.ions, 'tic')
        y = data(id(i)).total_intensity_values;
    else
        y = data(id(i)).intensity_values(:,index);
    end
    
    % Determine baseline
    if strcmpi(options.ions, 'tic') && ~isempty(data(id(i)).total_intensity_values_baseline)
        baseline = data(id(i)).total_intensity_values_baseline;
    elseif ~isempty(data(id(i)).intensity_values_baseline)
        baseline = data(id(i)).intensity_values_baseline(:, index);
    else
        baseline = [];
    end
    
    % Perform baseline correction
    if ~isempty(baseline)
        y = y - baseline;
    end
        
    % Determine curve fitting model to apply
    switch obj.options.integration.model
                    
        case 'exponential gaussian hybrid'
 
            % Start timer
            tic;
                    
            % Calculate peaks
            peaks = ExponentialGaussian(x, y, 'center', options.center, 'width', options.width);
                    
            % Stop timer
            compute_time = toc;
    end
    
    % Retreive peak data
    if strcmpi(options.ions, 'tic')
        peak_data = data(id(i)).total_intensity_values_peaks;
    else
        peak_data = data(id(i)).intensity_values_peaks;
    end
    
    % Check peak data
    if isempty(peak_data.time)
        peak_data.time(1,index) = 0;
    end
    
    % Update peak data
    switch options.results
        
        case 'reset'
            column = index;
            row(1:length(index)) = 1;
            
            peak_data.time(:,column) = 0;
            peak_data.height(:,column) = 0;
            peak_data.width(:,column) = 0;
            peak_data.a(:,column) = 0;
            peak_data.b(:,column) = 0;
            peak_data.area(:,column) = 0;
            peak_data.error(:,column) = 0;
            
            if isempty(peak_data.fit)
                peak_data.fit{1,length(column)} = [];
            else
                peak_data.fit(:,column) = {[]};
            end
            
        case 'replace'
            column = index;
            row = sum(peak_data.time(:,column) ~= 0);
            row(row==0) = 1;    
            
        case 'append'             
            column = index;
            row = sum(peak_data.time(:,column) ~= 0)+1;
    end
    
    if isempty(peaks.time) || any(peaks.time == 0)
        continue
    end
    
    % Assign peak data
    for j = 1:length(column)
        peak_data.time(row(j),column(j)) = peaks.time(j);
        peak_data.height(row(j),column(j)) = peaks.height(j);
        peak_data.width(row(j),column(j)) = peaks.width(j);
        peak_data.a(row(j),column(j)) = peaks.a(j);
        peak_data.b(row(j),column(j)) = peaks.b(j);
        peak_data.fit{row(j),column(j)} = peaks.fit(:,j);
        peak_data.area(row(j),column(j)) = peaks.area(j);
        peak_data.error(row(j),column(j)) = peaks.error(j);
    end
    
    % Reattach peak data
    if strcmpi(options.ions, 'tic')
        data(id(i)).total_intensity_values_peaks = peak_data;
    else
        data(id(i)).intensity_values_peaks = peak_data;
    end
    
    % Update statistics
    data(id(i)).statistics.compute_time(end+1) = compute_time;
    data(id(i)).statistics.function{end+1} = {'integration'};
    data(id(i)).statistics.calls(end+1) = length(y(1,:));
end

% Set output
varargout{1} = data;
end

% Parse user input
function varargout = parse(varargin)

varargin = varargin{1};
nargin = length(varargin);

% Check input
if nargin < 1
    error('Not enough input arguments');
elseif isstruct(varargin{1})
    data = DataStructure('validate', varargin{1});
else
    error('Undefined input arguments of type ''data''');
end

% Check user input
input = @(x) find(strcmpi(varargin, x),1);

% Check sample options
if ~isempty(input('samples'))
    options.samples = varargin{input('samples')+1};
                    
    % Check for valid input
    if strcmpi(options.samples, 'all')
        options.samples = 1:length(data);
    elseif ~isnumeric(options.samples)
        error('Undefined input arguments of type ''samples''');
    elseif max(options.samples) > length(data) || min(options.samples) < 1
        error('Index exceeds matrix dimensions')
    end
else
    options.samples = 1:length(data);
end
                
% Check ion options
if ~isempty(input('ions'))
    options.ions = varargin{input('ions')+1};
    
    % Check for valid input
    if ~isnumeric(options.ions) && ~ischar(options.ions)
        error('Undefined input arguments of type ''ions''');
    elseif isnumeric(options.ions)
        if max(options.ions) > cellfun(@length, {data(options.samples).mass_values})
            error('Index exceeds matrix dimensions');
        elseif min(options.ions) < 1
            error('Index exceeds matrix dimensions');
        end
    elseif strcmpi(options.ions, 'all')
        options.ions = 1:min(cellfun(@length, {data(options.samples).mass_values}));
    end
else
    options.ions = 'tic';
end

% Check center options
if ~isempty(input('center'))
    options.center = varargin{input('center')+1};
    
    % Check for valid input
    if ~isnumeric(options.center)
        error('Undefined input arguments of type ''center''');
    end
else
    options.center = [];
end

% Check width options
if ~isempty(input('width'))
    options.width = varargin{input('width')+1};
    
    % Check for valid input
    if ~isnumeric(options.width)
        error('Undefined input arguments of type ''width''');
    end
else
    options.width = [];
end

% Check height options
if ~isempty(input('height'))
    options.height = varargin{input('height')+1};
    
    % Check for valid input
    if ~isnumeric(options.height)
        error('Undefined input arguments of type ''height''');
    elseif min(options.height) <= 0
        options.height = [];
    end
else
    options.height = [];
end

% Check decay options
if ~isempty(input('decay'))
    options.decay = varargin{input('decay')+1};
    
    % Check for valid input
    if ~isnumeric(options.decay)
        error('Undefined input arguments of type ''decay''');
    elseif min(options.decay) < 0
        options.decay = [];
    end
else
    options.decay = [];
end

% Check amount options
if ~isempty(input('amount'))
    options.amount = varargin{input('amount')+1};
                
    % Check for valid input
    if ~strcmpi(options.amount, 'all') && ~isnumeric(options.amount)
        error('Undefined input arguments of type ''amount''');
    elseif isnumeric(options.amount) && min(options.amount) < 1
        options.amount = 1;
    end
else
    options.amount = 5;
end

% Check previous options
if ~isempty(input('results'))
    options.results = varargin{input('results')+1};
                
    % Check for valid input
    if ~ischar(options.results)
        error('Undefined input arguments of type ''results''');
    end
else
    options.results = 'replace';
end

% Return input
varargout{1} = data;
varargout{2} = options;
end