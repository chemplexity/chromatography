%% Chromatography Toolbox - Getting Started
%  -Data processing methods for liquid and gas chromatography
%
% Try the following examples with the sample data provided.
%
% Methods
%   1. Initialize
%   2. Import
%   3. Baseline
%   4. Integrate
%   5. Visualize

%% 1 .Initialize
obj = Chromatography;


%% 2a. Import - New 
data = obj.import('.D');

%% 2b. Import - Append
data = obj.import('.CDF', data);


%% 3a. Baseline - Default
data = obj.baseline(data);

%% 3b. Baseline - Custom
data = obj.baseline(data, 'smoothness', 10^7, 'asymmetry', 10^-5);


%% 4a. Integration - Default
data = obj.integrate(data);

%% 4b. Integration - Custom
data = obj.integrate(data, 'center', 9.0, 'width', 1.0, 'results', 'reset');


%% 5a. Visualize (Default)
obj.visualize(data);

%% 5b. Visualize (Custom)
obj.visualize(data, 'ions', 'all', 'legend', 'off', 'scale', 'normalize', 'layout', 'stacked');
