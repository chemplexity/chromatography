%% Chromatography Toolbox - Getting Started
%  -Data processing methods for liquid and gas chromatography
%
%  Try the following examples with the sample data provided (./Examples/Data)
%
%  Contents
%
%    1.0 Initialize
%
%    2.0 Import Data
%    2.1 Append Data
%
%    3.0 Centroid
%    3.1 Centroid Parameters
%
%    4.0 Baseline
%    4.1 Baseline Parameters
%    4.2 Baseline Selection
%
%    5.0 Smooth
%    5.1 Smoothing Parameters
%    5.2 Smoothing Selection
%
%    6.0 Reset Data
%
%    7.0 Peak Integration
%    7.1 Peak Parameters
%    7.2 Peak Selection
%
%    8.0 Visualize
%    8.1 Visualize Parameters
%
%    9.0 Mass Spectra
%    9.1 Mass Spectra Export


%% 1.0 Initialize

% Create a new instance of the 'Chromatography' class
obj = Chromatography;

%% 2.0 Import Data

% Import .D files
data = obj.import('.D');

%% 2.1 Append Data

% Import .CDF files and append exisiting data
data = obj.import('.CDF', 'append', data);

%% 3.0 Centroid

% Centroid mass values for all samples
data = obj.centroid(data);

%% 3.1 Centroid Parameters
i = 2;

% Restore original data
data = obj.reset(data);

% Centroid mass values for selected samples
data = obj.centroid(data, 'samples', i);

%% 4.0 Baseline
i = 2;

% Calculate baseline for all samples
data = obj.baseline(data);

% Plot TIC w/ baseline subtraction
plot([data(i).tic.values, data(i).tic.values-data(i).tic.baseline]);

%% 4.1 Baseline Parameters
i = 2;

% Store baseline for later...
b = data(i).tic.baseline;

% Decrease smoothness parameter (~1E3 < smoothness < 1E9)
data = obj.baseline(data, 'smoothness', 1E5);

% Append new baseline...
b(:,2) = data(i).tic.baseline;

% Plot TIC and baselines...
plot([data(i).tic.values, b]);

clear b

%% 4.2 Baseline Selection

% Calculate baselines for ion chromatograms from selected sample
data = obj.baseline(data, 'samples', i, 'ions', 'all');

% Plot data before and after baseline subtraction
a = subplot(2,1,1);
plot(data(i).xic.values);

b = subplot(2,1,2);
plot(data(i).xic.values - data(i).xic.baseline);

linkaxes([a, b]);

% Hint: best results are obtained w/ centroided data
clear a b

%% 5.0 Smooth
i = 2;

% Store TIC for later...
tic = data(i).tic.values;

% Smooth all total ion chromatograms
data = obj.smooth(data);

% Append new TIC...
tic(:,2) = data(i).tic.values;

%% 5.1 Smoothing Parameters

% Change the smoothness parameter (0.5 < smoothness < 5000)
data = obj.smooth(data, 'smoothness', 10);

% Append new TIC...
tic(:,3) = data(i).tic.values;

% Plot TIC values...
cla;
plot(tic);

%% 5.2 Smooth Selection
i = 2;

% Smooth all ion chromatograms from selected sample index
data = obj.smooth(data, 'samples', i, 'ions', 'all');

plot(data(i).xic.values);

%% 6.0 Reset Data

% Restore processed data to original state
data = obj.reset(data);

%% 7.0 Peak Integration
i = 2;

% Find largest peak for each TIC
data = obj.integrate(data);

% Plot curve fitting results
plot([data(i).tic.values, data(i).tic.peaks.fit{1,1}]);

%% 7.1 Peak Parameters
i = 2;

% Find peak within a narrow window
data = obj.integrate(data, 'center', 16.2, 'width', 1);

plot([data(i).tic.values, data(i).tic.peaks.fit{1,1}]);

%% 7.2 Peak Selection
i = 2;

% Find largest peak for each ion chromatogram
[~,index] = max(max(data(i).xic.values));

data = obj.integrate(data, 'samples', i, 'ions', index);

% Calculate and plot residuals
residuals = data(i).xic.values(:,index) - data(i).xic.peaks.fit{1,index};
plot(residuals, '.', 'color', 'red');

hold all;

% Plot curve fitting results for largest peak
plot(data(i).xic.values(:,index), 'color', 'black');
plot(data(i).xic.peaks.fit{1,index}, 'color', 'blue');

% Print curve fitting error
fprintf(['\nError: ', num2str(data(i).xic.peaks.error(1,index), '%.2f'), '%%\n']);

clear index residuals

%% 8.0 Visualize

% Plot overlay of all chromatograms in data
obj.visualize(data);

%% 8.1 Visualize Parameters

% Customize plot
obj.visualize(data, ...
    'samples', length(data),...
    'ions', 'all',...
    'legend', 'on',...
    'scale', 'full',...
    'layout', 'overlaid',...
    'colormap', 'winter');

%% 9.0 Mass Spectra
i = 2;

% Plot mass spectra for largest peak in TIC
data = obj.integrate(data, 'samples', i);

x = data(i).time;
y = data(i).xic.values;
mz = data(i).mz;

center = data(i).tic.peaks.time;
width = data(i).tic.peaks.width;

index = x > center-width & x < center+width;

cla;
plot(data(i).time, [data(i).tic.values, data(i).tic.peaks.fit{1,1}]);

MassSpectra(mz, y(index, :))

clear x y z center width index

%% 9.1 Mass Spectra Export
i = 2;

% Export mass spectra to 300 dpi .PNG file
MassSpectra(data(i).mz, data(i).xic.values,...
    {'ExampleMassSpectra', '-dpng', '-r300'});
