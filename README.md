#Chromatography Toolbox

|Open-source code for processing chromatography data in the MATLAB programming environment.|![Imgur](http://i.imgur.com/K25Rfsa.png)|
|:--|--:|

##Download

Select the [`Download ZIP`](https://github.com/chemplexity/chromatography/archive/master.zip) button on this page or visit the [MATLAB File Exchange](http://www.mathworks.com/matlabcentral/fileexchange/47696-chromatography-toolbox) to download a copy of the current release.

##Features

Check out the [in-depth guide](https://github.com/chemplexity/chromatography/wiki/) for a full overview of features.

<table style="width:100%">
<tr>
<td align="center"><b>File Conversion</b></td>
<td valign="middle"><br><ul>
<li>Agilent (.D, .MS)</li>
<li>netCDF (.CDF)</li>
</ul>
</td>
</tr>
<tr>
<td colspan="2">
</td>
</tr>
<tr>
<td align="center"><b>Baseline Correction</b></td>
<td align="center"><a href="http://imgur.com/TJU9o9s"><img src="http://i.imgur.com/TJU9o9s.png" title="baseline" width="400" height="125"/></a></td>		
</tr>
<tr>
<td colspan="2">
</td>
</tr>
<tr>
<td align="center"><b>Peak Detection</b></td>
<td align="center"><a href="http://imgur.com/hhHHgNO"><img src="http://i.imgur.com/hhHHgNO.png" title="peakdetection" width="275" height="125"/></a></center></td>
</tr>
<tr>
<td colspan="2">
</td>
</tr>
<tr>
<td align="center"><b>Curve Fitting</b></td>
<td align="center"><a href="http://imgur.com/HSbEmhi.png"><img src="http://imgur.com/HSbEmhi.png" title="curvefit" width="150" height="125"/></td>
</tr>
</table>

####System Requirements

Current release stable on the following systems:

* OSX 10.9, Windows 7
* MATLAB >2013b

## Usage

Run the following commands on the MATLAB command line or incorporate them into existing code.

####Importing Data

Use the `FileIO` class to import data into the MATLAB workspace. Initialize the `FileIO` class with the following command:

````matlab
obj = FileIO
```

Import files using the `import` method. For example, the following command will prompt you to select Agilent (.D) files to import into the MATLAB workspace:

````matlab
data = obj.import('FileType', '.D')
````

####Baseline Correction

Use the `BaselineCorrection` class for baseline correction. Intialize the `BaselineCorrection` class with the command:

````matlab
obj = BaselineCorrection
````

Calculate baselines with the `baseline` method. For example, determine the baseline for each ion chromatogram in your LC/MS dataset:

````matlab
data = obj.baseline(data, 'Samples', 'all', 'Ions', 'all')
````

####Peak Integration

Use the `PeakProcessing` class for peak detection and peak area determination. Initialize the `PeakProcessing` class with the following:

````matlab
obj = PeakProcessing
````

Calculate peak area using the `integrate` method. Use the following command to automatically detect and integrate the largest peak in each ion chromatogram in your LC/MS dataset:

````matlab
data = obj.integrate(data, 'Samples', 'all', 'Ions', 'all')
````

####Misc.

Use the `Normalize` method to normalize a signal between 0 and 1:

````matlab
y = Normalize(y)
````

Take the derivative of a signal using the `Derivative` method:

````matlab
dy = Derivative(y)
````

Calculate the derivative of a signal to the n<sup>th</sup> degree with the `Degree` option. For example, to return the fourth derivative of a signal, issue the following command:

````matlab
dy = Derivative(y, 'Degree', 4)
````

Obtain better results when determining the derivative signal by including the `Smoothing` option:

````matlab
dy = Derivative(y, 'Degree', 4, 'Smoothing', true)
````

