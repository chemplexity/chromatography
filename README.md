#Chromatography Toolbox

|Open-source code for processing chromatography data in the MATLAB programming environment.|![Imgur](http://i.imgur.com/K25Rfsa.png)|
|:--|--:|

##Download

Select the [`Download ZIP`](https://github.com/chemplexity/chromatography/archive/master.zip) button on this page or visit the [MATLAB File Exchange](http://www.mathworks.com/matlabcentral/fileexchange/47696-chromatography-toolbox) to download a copy of the current release.

##Features

Check out our [in-depth guide](https://github.com/chemplexity/chromatography/wiki/) for a full overview of features.

####File Conversion

Import raw signal data into the MATLAB workspace. Supported file types include:

**LC/MS Files**
  *  Agilent (.D)
  *  netCDF (.CDF)  

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
data = obj.import('.D')
````

Append an existing data structure with additional files of any supported file type. Just include the name of your data structure when using the `import` method.

````matlab
data = obj.import('.D', data)
````

Need more help using the `FileIO` class? Use the `help` method on the MATLAB command line to print available methods and syntax for the `FileIO` class.

````matlab
obj.help
````
