%% Chromatography Toolbox - Getting Started
%  -Data processing methods for liquid and gas chromatography
%
% Try the following examples with the sample data provided.
%
% Methods
%   1. Initialize
%   2. Import
%   3. Centroid
%   4. Baseline
%   5. Smoothing
%   6. Integrate
%   7. Visualize

%% 1 .Initialize
obj = Chromatography;


%% 2a. Import (New)
data = obj.import('.CDF');

%% 2b. Import (Append)
data = obj.import('.D', data);


%% 3a. Centroid (Default)
data = obj.centroid(data);

%% 3b. Centroid (Custom)
data = obj.centroid(data, 'samples', 1);


%% 4a. Baseline (Default)
data = obj.baseline(data);

%% 4b. Baseline (Custom)
data = obj.baseline(data, 'smoothness', 10^6, 'asymmetry', 10^-3);


%% 5a. Smoothing (Default)
data = obj.smooth(data);

%% 5b. Smoothing (Custom)
data = obj.smooth(data, 'smoothness', 10, 'asymmetry', 0.4);


%% 6a. Integration (Default)
data = obj.integrate(data);

%% 6b. Integration (Custom)
data = obj.integrate(data, 'center', 22.0, 'width', 1.0, 'results', 'reset');


%% 7a. Visualize (Default)
fig = obj.visualize(data);

%% 7b. Visualize (Custom)
fig = obj.visualize(data, 'samples', 1:3, 'ions', 'tic', 'legend', 'on', 'scale', 'normalize', 'layout', 'stacked', 'colormap', 'hsv');
