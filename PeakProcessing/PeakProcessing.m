% Class: PeakProcessing
% Description: Methods for peak detection and peak area determination
%
% Initialize: 
%   obj = PeakProcessing;
%
% Integrate:
%   obj.integrate(data, 'OptionName', optionvalue...)
%
%   Options:
%       Samples      : 'all', [sample_index]
%       Ions         : 'all', 'tic', [ion_index]
%       WindowCenter : center
%       WindowSize   : size
%       Overwrite    : true, false
%
% Help:
%   obj.help
%
% Examples:
%   data = obj.integrate(data)
%   data = obj.integrate(data, 'Samples', [3,4,7,10], 'Ions', [2:4, 6,8])
%   data = obj.integrate(data, 'Ions', 2)
%   data = obj.integrate(data, 'Ions', [2:13], 'Overwrite', true)
%
% References:
%   -Y. Kalambet, et.al., J. Chemometrics, 25 (2011) 352

classdef PeakProcessing
    
    properties (SetAccess = private)
        % Options object
        options
    end
    
    methods
        
        % Constructor method
        function obj = PeakProcessing()
            
            % Initialize class variables
            obj.options = 'exponential gaussian';
        end
        
        % Peak integration function
        function varargout = integrate(obj, varargin)
    
            % Check number of inputs
            if nargin < 2
                return
            end
                        
            % Check data structure for correct fields
            if isstruct(varargin{1})
                data = DataStructure('Validate', varargin{1});
            else
                return
            end
            
            % Check samples input
            if ~isempty(find(strcmp(varargin, 'Samples'),1))
                samples = varargin{find(strcmp(varargin, 'Samples'),1) + 1};
                
                % Check sample options
                if strcmp(samples, 'all')
                    samples = 1:length(data);
                end
            else
                % Default to all samples
                samples = 1:length(data);
            end
            
            % Check ions input
            if ~isempty(find(strcmp(varargin, 'Ions'),1))
                ions = varargin{find(strcmp(varargin, 'Ions'),1) + 1};
                
                if ~strcmp(ions, 'tic') && ~strcmp(ions, 'all')
                    ion_index = ions;
                    ions = 'user';
                end 
            else
                % Default to all ions
                ions = 'all';
            end
            
            % Check for window center input
            if ~isempty(find(strcmp(varargin, 'WindowCenter'),1))
                window_center = varargin{find(strcmp(varargin, 'WindowCenter'),1) + 1};
            else
            % Default to empty window center
                window_center = [];
            end
    
            % Check for window size input
            if ~isempty(find(strcmp(varargin, 'WindowSize'),1))
                window_size = varargin{find(strcmp(varargin, 'WindowSize'),1) + 1};
            else
                % Default to empty window size
                window_size = [];
            end
           
            % Check overwrite input
            if ~isempty(find(strcmp(varargin, 'Overwrite'),2))
                overwrite = varargin{find(strcmp(varargin, 'Overwrite'),1)+1};
                
                % Check input is boolean
                if ~islogical(overwrite)
                    overwrite = false;
                end
            else 
                overwrite = true;
            end
            
            % Determine samples and ions to process
            for i = 1:length(samples)
              
                % Fetch time values
                xdata = data(samples(i)).time_values;
                
                % Fetch signal values
                switch ions
                    
                    % Use total ion chromatograms
                    case 'tic'
                        
                        % Check for baseline
                        if ~isempty(data(samples(i)).total_intensity_values_baseline)
                        
                            % Subtract baseline from signal
                            ydata = data(samples(i)).total_intensity_values - ...
                                    data(samples(i)).total_intensity_values_baseline;    
                        else
                            % Use original signal if no baseline exists
                            ydata = data(samples(i)).total_intensity_values;
                        end
                        
                    % Use all ion chromatograms
                    case 'all'
                        
                        % Use all available ions
                        ion_index = 1:length(data(i).mass_values);
                        
                        % Check for baseline
                        if ~isempty(data(samples(i)).intensity_values_baseline)
                            
                            % Subtract baseline from signal
                            ydata = data(samples(i)).intensity_values - ...
                                    data(samples(i)).intensity_values_baseline;    
                        else
                            % Use original signal if no baseline exists
                            ydata = data(samples(i)).intensity_values;
                        end
                        
                    % User specified ion chromatograms
                    otherwise
                        
                        % Check for baseline
                        if ~isempty(data(samples(i)).intensity_values_baseline)
                            
                            % Subtract baseline from signal
                            ydata = data(samples(i)).intensity_values(:,ion_index) - ...
                                    data(samples(i)).intensity_values_baseline(:,ion_index);
                        else
                            % Use original signal if no baseline exists
                            ydata = data(samples(i)).intensity_values(:,ion_index);
                        end
                end
                
                % Determine curve fitting model to apply
                switch obj.options
                    
                    % Use exponential modified gaussian
                    case 'exponential gaussian'
                        
                        % For ion chromatograms
                        if ~strcmp(ions, 'tic')
                    
                            % Start timer
                            tic;
                    
                            % Calculate peaks
                            peaks = ExponentialGaussian(xdata, ydata, 'WindowCenter', window_center, 'WindowSize', window_size);
                    
                            % Stop timer
                            processing_time = toc;
                            
                            % Update processing time
                            if isempty(data(samples(i)).diagnostics.processing_time_peaks)
                                data(samples(i)).diagnostics.processing_time_peaks = processing_time;
                            else
                                data(samples(i)).diagnostics.processing_time_peaks = ...
                                    data(samples(i)).diagnostics.processing_time_peaks + processing_time;
                            end

                            % Temporary data structure
                            peak_data = data(samples(i)).intensity_values_peaks(1);
                            
                            % Update peak data
                            if strcmp(ions,'all') && overwrite
                                peak_data = peaks;
                            
                            % Overwrite existing values
                            elseif overwrite
                                % Peak data
                                peak_data.peak_time(ion_index) = peaks.peak_time;
                                peak_data.peak_width(ion_index) = peaks.peak_width;
                                peak_data.peak_height(ion_index) = peaks.peak_height;
                                peak_data.peak_area(ion_index) = peaks.peak_area;
                                
                                % Fit data
                                peak_data.peak_fit(:,ion_index) = peaks.peak_fit;
                                peak_data.peak_fit_residuals(:,ion_index) = peaks.peak_fit_residuals;
                                peak_data.peak_fit_error(ion_index) = peaks.peak_fit_error;
                                peak_data.peak_fit_options(ion_index) = peaks.peak_fit_options;
                            
                            % Do not overwrite existing values
                            elseif ~overwrite
                                % Check if structure is empty
                                if length(peak_data) <= 1 && ~isempty(peak_data.peak_time);
                                    for j = 1:length(ion_index)
                                        
                                        % Update values if current values are zero
                                        if peak_data.peak_time(j) == 0
                                            % Peak data
                                            peak_data.peak_time(ion_index(j)) = peaks.peak_time(j);
                                            peak_data.peak_width(ion_index(j)) = peaks.peak_width(j);
                                            peak_data.peak_height(ion_index(j)) = peaks.peak_height(j);
                                            peak_data.peak_area(ion_index(j)) = peaks.peak_area(j);
                                            
                                            % Fit data
                                            peak_data.peak_fit(:,ion_index(j)) = peaks.peak_fit(:,j);
                                            peak_data.peak_fit_residuals(:,ion_index(j)) = peaks.peak_fit_residuals(:,j);
                                            peak_data.peak_fit_error(ion_index(j)) = peaks.peak_fit_error(j);
                                            peak_data.peak_fit_options(ion_index(j)) = peaks.peak_fit_options(j);
                                        end
                                    end
                                else
                                    % Peak data
                                    peak_data.peak_time(ion_index) = peaks.peak_time;
                                    peak_data.peak_width(ion_index) = peaks.peak_width;
                                    peak_data.peak_height(ion_index) = peaks.peak_height;
                                    peak_data.peak_area(ion_index) = peaks.peak_area;
                                
                                    % Fit data
                                    peak_data.peak_fit(:,ion_index) = peaks.peak_fit;
                                    peak_data.peak_fit_residuals(:,ion_index) = peaks.peak_fit_residuals;
                                    peak_data.peak_fit_error(ion_index) = peaks.peak_fit_error;
                                    peak_data.peak_fit_options(ion_index) = peaks.peak_fit_options;
                                end
                            end
                            
                            % Reattach peak data structure
                            data(samples(i)).intensity_values_peaks = peak_data;
                        end
                end
            end
            
            % Set output
            varargout{1} = data;
        end
        
        % Help method
        function help(varargin)
            
            % Print syntax and valid file types
            fprintf([...
                '\n'...
                'Syntax \n' ...
                '   Initialize  : obj = PeakProcessing \n' ...
                '   Integration : obj.integrate(data, ''OptionName'', optionvalue) \n'...
                '   Help        : obj.help \n\n'...
                'Integrate \n'...
                '   Samples     : ''all'', [sampleindex] \n'...
                '   Ions        : ''all'', ''tic'', [ionindex] \n'...
                '   Overwrite   : true, false \n\n'...
                'Examples \n'...
                '   data = obj.integrate(data) \n'...
                '   data = obj.integrate(data, ''Samples'', [3,4,7,10], ''Ions'', [2:4, 6,8]) \n'...
                '   data = obj.integrate(data, ''Ions'', 2) \n'...
                '   data = obj.integrate(data, ''Ions'', [2:13], ''Overwrite'', true) \n\n'...    
                'References \n'...
                '   Y. Kalambet, et.al., J. Chemometrics, 25 (2011) 352 \n\n']);
        end
    end
end