% Chromatography Toolbox
%   - Try out the following examples with the included sample data

%% File Conversion
obj = FileIO;

% Import Agilent .D files
data = obj.import('Filetype', '.D');

% Append netCDF .CDF files to existing data
data = obj.import('Filetype', '.CDF', 'Data', data);

% Normalize all total ion chromatograms and plot
for i = 1:length(data)
    
    plot(data(i).time_values, Normalize(data(i).total_intensity_values) - i,...
        'linesmoothing', 'on',...
        'color', 'black');
    
    hold all;
end


%% Data Binning

% Round full scan spectra to nearest 0.5 m/z
data = DataBinning(data, 'BinSize', 0.5);


%% Baseline Correction
obj = BaselineCorrection;

% Calculate baselines for all ion chromatograms in your dataset
data = obj.baseline(data);

% Plot first five ion chromatograms and baselines from last sample
for i = 1:5
    
    plot(data(end).time_values, data(end).intensity_values(:,i),...
        'linesmoothing', 'on',...
        'color', 'black');
    
    hold all;
    
    plot(data(end).time_values, data(end).intensity_values_baseline(:,i),...
        'linesmoothing', 'on',...
        'color', 'blue');
end

% Calculate baseline for ion chromatograms in last sample with different parameters
data = obj.baseline(data, 'Samples', length(data), 'Asymmetry', 0.01, 'Smoothness', 10^5);

% Plot new baselines from last sample
for i = 1:5
    
    plot(data(end).time_values, data(end).intensity_values_baseline(:,i),...
        'linesmoothing', 'on',...
        'color', 'red');
end

% Print time spent calculating baselines
processing_time = data.diagnostics;

sprintf(['Processing Time: ',num2str(sum(processing_time.processing_time_baseline)), ' sec.'])

%% Peak Integration
obj = PeakProcessing;

% Integrate largest peak in ion chromatograms in last sample between 15-25 min
data = obj.integrate(data, 'Samples', length(data), 'WindowCenter', 20, 'WindowSize', 10);

% Plot data and calculated curves
for i = 1:length(data(end).intensity_values(1,:))
    
    plot(data(end).time_values, data(end).intensity_values(:,i),...
        'linesmoothing', 'on',...
        'color', 'black');
    
    hold all;
    
    plot(data(end).time_values, data(end).intensity_values_peaks.peak_fit(:,i)-max(max(data(end).intensity_values)),...
        'linesmoothing', 'on');
end