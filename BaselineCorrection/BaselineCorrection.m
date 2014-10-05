% Class: BaselineCorrection
% Description: Methods for baseline correction of chromatographic data
%
% Initialize: 
%   obj = BaselineCorrection;
%
% Baseline:
%   obj.baseline(data, 'OptionName', optionvalue...)
%
%   Options:
%       Samples    : 'all', [sampleindex]
%       Ions       : 'all', 'tic', [ionindex]
%       Smoothness : 10^3 to 10^9
%       Asymmetry  : 10^1 to 10^-6
%
% Help:
%   obj.help
%
% Examples:
%   data = obj.baseline(data)
%   data = obj.baseline(data, 'Samples', [2:5, 8, 10])
%   data = obj.baseline(data, 'Ions', [1:34, 43:100])
%   data = obj.baseline(data, 'Samples', 'all', 'Ions', 'tic')
%   data = obj.baseline(data, 'Samples', [1,4,5], 'Ions', 'all', 'Smoothness', 10^7, 'Asymmetry', 10^-3)
%
% References:
%   -P.H.C. Eilers, Analytical Chemistry, 75 (2003) 3631

classdef BaselineCorrection
    
    properties
        % Input properties
        smoothness
        asymmetry
    end

    methods
        % Constructor methods
        function obj = BaselineCorrection()
           
            % Initialize default values
            obj.smoothness = 10^6;
            obj.asymmetry = 10^-6;
        end
        
        % Baseline correction method
        function varargout = baseline(obj, varargin)
            
            % Check number of inputs
            if nargin < 2
                return
            end
            
            % Check structure for correct fields
            if isstruct(varargin{1})
                varargin{1} = DataStructure('Validate', varargin{1});
            else
                return
            end
                
            % Check sample options
            if ~isempty(find(strcmp(varargin, 'Samples'),1))
                samples = varargin{find(strcmp(varargin, 'Samples'),1) + 1};
                    
                % Check specific sample options
                if strcmp(samples, 'all')
                    samples = 1:length(varargin{1});
                end
            else
                % Default to all samples
                samples = 1:length(varargin{1});
            end
                
            % Check ion options
            if ~isempty(find(strcmp(varargin, 'Ions'),1))
                ions = varargin{find(strcmp(varargin, 'Ions'),1) + 1};
            else
                % Default to all ions
                ions = 'all';
            end
                
            % Check smoothness options
            if ~isempty(find(strcmp(varargin, 'Smoothness'),1))
                obj.smoothness = varargin{find(strcmp(varargin, 'Smoothness'),1) + 1};
            end
            
            % Check asymmetry options
            if ~isempty(find(strcmp(varargin, 'Asymmetry'),1))
                obj.asymmetry = varargin{find(strcmp(varargin, 'Asymmetry'),1) + 1};
            end
            
            % Calculate baseline
            for i = 1:length(samples)
                
                % Check ion options
                switch ions
                    
                    % Use total ion chromatograms
                    case 'tic'
                        y = varargin{1}(samples(i)).total_intensity_values;
                     
                    % Use all ion chromatograms    
                    case 'all'
                        y = varargin{1}(samples(i)).intensity_values;
                     
                    % User specified ion chromatograms    
                    otherwise
                        y = varargin{1}(samples(i)).intensity_values(:, ions);
                end

                % Start timer
                tic;
                
                % Whittaker Smoother
                baseline = WhittakerSmoother(y, 'Smoothness', obj.smoothness, 'Asymmetry', obj.asymmetry);
                
                % Stop timer
                processing_time = toc;
                
                % Format output
                switch ions
                    case 'tic' 
                        varargin{1}(samples(i)).total_intensity_values_baseline = baseline;  
                    case 'all'
                        varargin{1}(samples(i)).intensity_values_baseline = baseline;
                    otherwise
                        varargin{1}(samples(i)).intensity_values_baseline(:, ions) = baseline;
                end
                
                % Update processing time
                if ~isempty(varargin{1}(i).diagnostics.processing_time_baseline)
                    varargin{1}(samples(i)).diagnostics.processing_time_baseline = varargin{1}(samples(i)).diagnostics.processing_time_baseline + processing_time;
                else
                    varargin{1}(samples(i)).diagnostics.processing_time_baseline = processing_time;
                end
            end
            
            % Output
            varargout{1} = varargin{1};
        end
        
        % Help method
        function help(varargin)
            
            % Print syntax and valid file types
            fprintf([...
                'Syntax \n' ...
                '   Initialize : obj = BaselineCorrection \n' ...
                '   Baseline   : obj.baseline(data, ''OptionName'', optionvalue) \n'...
                '   Help       : obj.help \n\n'...
                'Baseline \n'...
                '   Samples    : ''all'', [sampleindex] \n'...
                '   Ions       : ''all'', ''tic'', [ionindex] \n'...
                '   Smoothness : 10^3 to 10^9 \n'...
                '   Asymmetry  : 10^-1 to 10^-6 \n\n'...
                'Examples \n'...
                '   data = obj.baseline(data) \n'...
                '   data = obj.baseline(data, ''Samples'', [2:5, 8, 10]) \n'...
                '   data = obj.baseline(data, ''Ions'', [1:34, 43:100]) \n'...
                '   data = obj.baseline(data, ''Samples'', ''all'', ''Ions'', ''tic'') \n'...
                '   data = obj.baseline(data, ''Samples'', [1,4,5], ''Ions'', ''all'', ''Smoothness'', 10^7, ''Asymmetry'', 10^-3) \n'])
        end
    end
end