%% Chromatography Toolbox - Help
%  -Data processing methods for liquid and gas chromatography
%
% Methods
% 1. Initialize
% 2. Import
% 3. Baseline
% 4. Integrate
% 5. Visualize
%
%% 1 .Initialize

obj = Chromatography;

%% 2. Import (New)

data = obj.import('.D');

%% 2. Import (Append)

data = obj.import('.CDF', data);

%% 3. Baseline (Default)

data = obj.baseline(data);

%% 3. Baseline (Advanced)

data = obj.baseline(data, 'smoothness', 10^7, 'asymmetry', 10^-5);

%% 4. Integration (Default)

data = obj.integrate(data);

%% 4. Integration (Advanced)

data = obj.integrate(data, 'center', 9.0, 'width', 1.0, 'results', 'reset');