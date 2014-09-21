#Chromatography Toolbox

|Open-source code for processing chromatography data in the MATLAB programming environment.|![Imgur](http://i.imgur.com/K25Rfsa.png)|
|:--|--:|

##Download

Select the [`Download ZIP`](https://github.com/chemplexity/chromatography/archive/master.zip) button on this page or visit the [MATLAB File Exchange](http://www.mathworks.com/matlabcentral/fileexchange/47696-chromatography-toolbox) to download a copy of the current release.

##Features

Check out the [in-depth guide](https://github.com/chemplexity/chromatography/wiki/) for a full overview of features.

####File Conversion

Import raw signal data into the MATLAB workspace. Supported file types include:

**LC/MS Files**
  *  Agilent (.D, .MS)
  *  netCDF (.CDF)  

####Data Processing

Available methods for data processing include:

**Preprocessing**
  * Baseline Correction

**Peak Detection**
  * Derivative Filter
 
**Peak Area**
  * Curve Fitting
 
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
