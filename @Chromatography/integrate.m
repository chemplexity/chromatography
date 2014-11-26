% Method: integrate
%  -Perform peak detection and calculate peak area
%
% Syntax
%   integrate(data)
%   integrate(data, 'OptionName', optionvalue...)
%
% Options
%   'samples'   : 'all', [sampleindex]
%   'ions'      : 'all', 'tic', [ionindex]
%   'center'    : value
%   'width'     : value
%   'results'   : 'replace', 'append', 'reset'
%
% Description
%   data        : an existing data structure
%   'samples'   : row index of samples in data structure -- (default: all)
%   'ions'      : column index of ions in data structure -- (default: all)
%   'center'    : search for peak at center value -- (default: x at max(y))
%   'width'     : search for peak at center +/- width/2 -- (default: 2)
%   'results'   : replace, append or reset existing peak values -- (default: append)
%
% Examples
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'samples', [2:5, 8, 10], ions, 'all')
%   data = obj.integrate(data, 'ions', [1:34, 43:100], 'center', 14.5)
%   data = obj.integrate(data, 'center', 18.5, 'width', 5.0, 'results', 'append')
%
% References
%   Y. Kalambet, et.al, Journal of Chemometrics, 25 (2011) 352

function data = integrate(obj, varargin)

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

% Check window center options
if ~isempty(find(strcmpi(varargin, 'center'),1))
    center = varargin{find(strcmpi(varargin, 'center'),1) + 1};
    
    % Check user input
    if ~isnumeric(center)
        error('Undefined input arguments of type ''center''');
    end
else
    % Default center options
    center = [];
end

% Check window width options
if ~isempty(find(strcmpi(varargin, 'width'),1))
    width = varargin{find(strcmpi(varargin, 'width'),1) + 1};
    
    % Check user input
    if ~isnumeric(width)
        error('Undefined input arguments of type ''width''');
    end
else
    % Default width options
    width = [];
end

% Check coverage options
if ~isempty(find(strcmpi(varargin, 'coverage'),1))
    coverage = varargin{find(strcmpi(varargin, 'coverage'),1) + 1};
else
    coverage = 1.5;
end
    
% Check extra options
if ~isempty(find(strcmp(varargin, 'extra'),1))
    exponent = varargin{find(strcmp(varargin, 'extra'),1) + 1};
else
    exponent = 0.05;
end
    
% Check previous options
if ~isempty(find(strcmpi(varargin, 'results'),1))
    results = varargin{find(strcmpi(varargin, 'results'),1) + 1};
                
    % Check user input
    if ~ischar(results)
        error('Undefined input arguments of type ''results''');
    elseif ~strcmpi(results, 'append') && ~strcmpi(results, 'replace') && ~strcmpi(results, 'reset')
        error('Undefined input arguments of type ''results''');
    end
else
    results = 'append';
end

% Calculate peak area
for i = 1:length(samples)

    % Determine x-values
    x = data(samples(i)).time_values;

    % Check ion options
    if ~ischar(ions)
        
        % Check user input
        if max(ions) > length(data(samples(i)).mass_values)
            error('Index exceeds matrix dimensions');
        end
        
        y = data(samples(i)).intensity_values(:, ions);
        baseline = data(samples(i)).intensity_values_baseline(:, ions);
        
        % Perform baseline correction
        if ~isempty(baseline)
            y = y - baseline;
        end        
    else
        switch ions
            
            % Use total ion chromatograms
            case 'tic'
                y = data(samples(i)).total_intensity_values;
                baseline = data(samples(i)).total_intensity_values_baseline;

                % Perform baseline correction
                if ~isempty(baseline)
                    y = y - baseline;
                end
            
            % Use all ion chromatograms
            case 'all'
                y = data(samples(i)).intensity_values;
                baseline = data(samples(i)).intensity_values_baseline;
                
                % Perform baseline correction
                if ~isempty(baseline)
                    y = y - baseline;
                end
        end
    end
    
    % Determine curve fitting model to apply
    switch obj.options.integration.type
                    
        % Use exponential modified gaussian
        case 'exponential gaussian'
 
            % Start timer
            tic;
                    
            % Calculate peaks
            peaks = ExponentialGaussian(x, y, 'center', center, 'width', width, 'coverage', coverage, 'extra', exponent);
                    
            % Stop timer
            processing_time = toc;
                            
            % Calculate peak diagnostics
            diagnostics.processing_time = data(samples(i)).diagnostics.integration.processing_time + processing_time;
            diagnostics.processing_spectra = data(samples(i)).diagnostics.integration.processing_spectra + length(y(1,:));
            diagnostics.processing_spectra_length = length(y(:,1));
            
            % Update peak diagnostics
            data(samples(i)).diagnostics.integration = diagnostics;

            % Update peak data
            if strcmpi(ions, 'tic')
                peak_data = data(samples(i)).total_intensity_values_peaks;
            else
                peak_data = data(samples(i)).intensity_values_peaks;
            end
            
            % Determine peaks to update
            if strcmpi(ions,'all')
                index = 1:length(data(samples(i)).intensity_values(1,:));
            elseif strcmpi(ions,'tic')
                index = 1:length(data(samples(i)).total_intensity_values(1,:));
            else
                index = ions;
            end
                
            % Add peaks
            if strcmpi(results, 'reset') || isempty(peak_data.peak_time)
                 
                % Zero array
                if ~strcmpi(ions,'tic')
                    zero_array = zeros(1, length(data(samples(i)).intensity_values(1,:)));
                else
                    zero_array = zeros(1,1);
                end
                
                % Reset peak data
                peak_data.peak_time = zero_array;
                peak_data.peak_width = zero_array;
                peak_data.peak_height = zero_array;
                peak_data.peak_area = zero_array;
                                
                % Fit data
                peak_data.peak_fit = [];
                peak_data.peak_fit{length(zero_array)} = {};
                peak_data.peak_fit_residuals = [];
                peak_data.peak_fit_residuals{length(zero_array)} = {};
                peak_data.peak_fit_error = zero_array;
                peak_data.peak_fit_options = zero_array;
            end
            
            % Update peak data
            if strcmpi(results, 'replace') || strcmpi(results, 'reset')
                
                % Peak data
                peak_data.peak_time(end,index) = peaks.peak_time;
                peak_data.peak_width(end,index) = peaks.peak_width;
                peak_data.peak_height(end,index) = peaks.peak_height;
                peak_data.peak_area(end,index) = peaks.peak_area;
                                
                % Fit data
                peak_data.peak_fit_error(end,index) = peaks.peak_fit_error;
                peak_data.peak_fit_options(end,index) = peaks.peak_fit_options;
            
                for j = 1:length(index)                                                          
                    peak_data.peak_fit{end,index(j)} = peaks.peak_fit(:,j);
                    peak_data.peak_fit_residuals{end,index(j)} = peaks.peak_fit_residuals(:,j);
                end
                
            elseif strcmpi(results, 'append')
                
                % Determine row to add peak data
                for j = 1:length(index)
                    
                    % Find column index
                    col_index = index(j);
                    row_index = find(peak_data.peak_time(:,col_index)==0, 1);
                    
                    if isempty(row_index)
                        row_index = length(peak_data.peak_time(:,col_index)) + 1;
                    end
                    
                    % Peak data
                    peak_data.peak_time(row_index,col_index) = peaks.peak_time(1,j);
                    peak_data.peak_width(row_index,col_index) = peaks.peak_width(1,j);
                    peak_data.peak_height(row_index,col_index) = peaks.peak_height(1,j);
                    peak_data.peak_area(row_index,col_index) = peaks.peak_area(1,j);
                                
                    % Fit data
                    peak_data.peak_fit{row_index,col_index} = peaks.peak_fit(:,j);
                    peak_data.peak_fit_residuals{row_index,col_index} = peaks.peak_fit_residuals(:,j);
                    peak_data.peak_fit_error(row_index,col_index) = peaks.peak_fit_error(1,j);
                    peak_data.peak_fit_options(row_index,col_index) = peaks.peak_fit_options(1,j);
                end
            end
            
            % Reattach peak data
            if strcmpi(ions, 'tic')
                data(samples(i)).total_intensity_values_peaks = peak_data;
            else
                data(samples(i)).intensity_values_peaks = peak_data;
            end
    end
end
end