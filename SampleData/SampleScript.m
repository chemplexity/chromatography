% FileIO: Sample Script

% Initialize class
obj = FileIO;

% Import sample data
data = obj.import('FileExtension', '.D');

% Print the amount of time spent converting the raw data
sprintf(['Processing time: ', num2str(sum([data.processing_time_import]), '%6.3f'), ' seconds'])

% Plot the total ion chromatograms from each file
for i = 1:length(data)
    
    % Normalize data first
    x = data(i).time_values;
    y = data(i).total_intensity_values;
    ymin = min(y);
    ymax = max(y);
    
    % Subtract i to give a stacked plot
    y = (y - ymin) / (ymax - ymin) - i;
    
    plot(x, y, 'linesmoothing', 'on');
    
    hold all
end

% Set ylim
ylim([-(i+0.05), 0.05]);

clear i x y
clear ymin ymax