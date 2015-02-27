%% Chromatography Toolbox - Getting Started
%  -Data processing methods for liquid and gas chromatography
%
% Try the following examples with the sample data provided.
%
% Methods
%   1. Initialize
%   2. Import
%   3. Baseline
%   4. Smoothing
%   5. Integrate
%   6. Visualize

%% 1 .Initialize
obj = Chromatography;


%% 2a. Import (New)
data = obj.import('.CDF');

%% 2b. Import (Append)
data = obj.import('.D', data);


%% 3a. Baseline (Default)
data = obj.baseline(data);

%% 3b. Baseline (Custom)
data = obj.baseline(data, 'smoothness', 10^7, 'asymmetry', 10^-5);


%% 4a. Smoothing (Default)
data = obj.smooth(data);

%% 4b. Smoothing (Custom)
data = obj.smooth(data, 'smoothness', 1000, 'asymmetry', 0.4);


%% 5a. Integration (Default)
data = obj.integrate(data);

%% 5b. Integration (Custom)
data = obj.integrate(data, 'center', 22.0, 'width', 1.0, 'results', 'reset');


%% 6a. Visualize (Default)
fig = obj.visualize(data);

%% 6b. Visualize (Custom)
fig = obj.visualize(data, 'samples', 1:3, 'ions', 'tic', 'legend', 'on', 'scale', 'normalize', 'layout', 'stacked', 'colormap', 'hsv');
