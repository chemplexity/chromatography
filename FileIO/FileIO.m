% James Dillon @ Brown University (2014)
%
% Class: FileIO
% Description: Import raw LC/MS data into the MATLAB workspace
%
% Initialize: 
%   obj = FileIO;
%
% Import: 
%   obj.import(filetype);
%   obj.import(filetype, data);
%
% Help:
%   obj.help
%
% File Extensions (Import):
%   - Agilent (.D)
%   - Agilent (.MS)
%   - netCDF (.CDF)
%
% Examples:
%   Import Agilent (.D) LC/MS data.
%       data = obj.import('.D');
%
%   Import and append to existing data structure.
%       data = obj.import('.D', data);

classdef FileIO
    
    properties
        % Input properties
        filetype 
    end

    properties (SetAccess = private)
        % Internal properties
        options
    end

    methods
        
        % Constructor method
        function obj = FileIO()
            
            % Initialize properties
            obj.filetype = [];
            
            obj.options.import = {'.CDF', 'netCDF (*.CDF)';...
                                  '.D', 'Agilent (*.D)';...
                                  '.MS', 'Agilent (*.MS)'};
            
            obj.options.export = {'.CSV', 'Comma Separated Values (*.CSV)';...
                                  '.MAT', 'MATLAB File (*.MAT)'};
        end
        
        % Import method
        function data = import(obj, varargin)
            
            % Check for any input
            if nargin == 1 || nargin > 3
                data = importDataStructure(obj);
                return
                
            % Check for valid filetype
            elseif ~any(strcmp(varargin{1}, obj.options.import(:,1)))
                data = importDataStructure(obj);
                return
                
            % Set filetype
            elseif nargin == 2
                obj.filetype = varargin{1};
                data = importDataStructure(obj);
                
            % Set filetype and existing data structure
            elseif nargin == 3
                obj.filetype = varargin{1};
                
                % Check for valid input
                if isstruct(varargin{2})
                    data = importDataStructure(obj, varargin{2});
                else
                    data = importDataStructure(obj);
                end
            end
            
            % Open file selection dialog
            files = importDialog(obj);
            
            % Check for any input
            if isempty(files)
                return
            end
            
            % Remove entries with incorrect filetype
            files(~strcmp(files(:,3), obj.filetype), :) = [];
            
            % Set path to selected folder
            path(files{1,1}, path);
            
            % Determine which import function to execute
            switch obj.filetype
                
                % Import data with the '*.CDF' extension
                case {'.CDF'}
                    for i = 1:length(files(:,1))
                        
                        % Start timer
                        tic;
                        
                        % Import data
                        newdata(i) = ImportCDF(strcat(files{i,2},files{i,3}));
                        
                        % Stop timer
                        processing_time(i) = toc;
                        
                        % Assign a unique id
                        id(i) = length(data) + i;
                    end
                    
                    % Import data with the '*.MS' extension
                case {'.MS'}
                    for i = 1:length(files(:,1))
                        
                        % Start timer
                        tic;
                        
                        % Import data
                        newdata(i) = ImportAgilent(strcat(files{i,2},files{i,3}));
                        
                        % Stop timer
                        processing_time(i) = toc;
                        
                        % Assign a unique id
                        id(i) = length(data) + i;
                    end
                    
                    % Import data with the '*.D' extension
                case {'.D'}
                    for i = 1:length(files(:,1))
                        
                        % Set folder path
                        files{i,4} = fullfile(files{i,1}, strcat(files{i,2}, files{i,3}));
                        path(files{i,4}, path);
                        
                        % List folder contents
                        foldercontents = ls(files{i,4});
                        
                        % Format folder contents
                        if length(foldercontents(:,1)) == 1 || length(foldercontents(1,:)) == 1
                            foldercontents = strsplit(foldercontents);
                        else
                            foldercontents = cellstr(foldercontents);
                        end
                        
                        % Check for any input
                        if ~length([foldercontents{:}]) > 0
                            return
                        end
                        
                        % Parse folder contents
                        for j = 1:length(foldercontents)
                            [contents{j,1},contents{j,2},contents{j,3}] = ...
                                fileparts(fullfile(files{i,4}, foldercontents{j}));
                        end
                        
                        % Remove entries with incorrect filetype
                        contents(~strcmp(contents(:,3), '.MS'), :) = [];
                        
                        % Check for any input
                        if isempty(contents{1,3})
                            return
                        end
                        
                        % Start timer
                        tic;
                        
                        % Import data
                        newdata(i) = ImportAgilent(fullfile(contents{1,1},strcat(contents{1,2},contents{1,3})));
                        
                        % Stop timer
                        processing_time(i) = toc;
                        
                        % Assign a unique id
                        id(i) = length(data) + i;
                        
                        % Remove path to folder
                        rmpath(files{i,4});
                    end
            end
            
            % Add id and processing_time
            for j = 1:length(id)
                newdata(j).id = id(j);
                newdata(j).processing_time_import = processing_time(j);
            end
            
            % Concatenate imported data with existing data
            data = [data, newdata];
        end

        % Help method
        function help(varargin)
            
            % Print syntax and valid file types
            sprintf(['Syntax: \n' ...
                '   Initialize: obj = FileIO \n' ...
                '   Import: obj.import(filetype) \n'...
                '           obj.import(filetype, data) \n'...
                '   Export: obj.export(filetype) \n'...
                '   Help: obj.help \n \n'...
                'File Extensions (Import): \n'...
                '   - Agilent (.D) \n'...
                '   - Agilent (.MS) \n'...
                '   - netCDF (.CDF) \n \n'...
                'File Extension (Export): \n'...
                '   - Comma Separated Values (.CSV) \n'...
                '   - MATLAB File (.MAT) \n \n'...
                'Examples: \n'...
                '   - Initialize the FileIO class. \n'...
                '       obj = FileIO; \n'...
                '   - Import Agilent LC/MS data. \n'...
                '       data = obj.import(''.D''); \n'...
                '   - Import netCDF LC/MS data. \n'...
                '       data = obj.import(''.CDF''); \n'...
                '   - Append data to an existing data structure. \n'...
                '       data = obj.import(''.D'', data);'])
        end
    end
    
    methods (Access = private)
        
        % Open dialog box to select files
        function files = importDialog(obj, varargin)
            
            % Initialize JFileChooser object
            fileChooser = javax.swing.JFileChooser(java.io.File(cd));
            
            % Select directories if certain filetype
            if strcmp(obj.filetype, '.D')
                fileChooser.setFileSelectionMode(fileChooser.DIRECTORIES_ONLY);
            end
            
            % Determine file description and file extension
            filter = com.mathworks.hg.util.dFilter;
            description = [obj.options.import{strcmp(obj.options.import(:,1), obj.filetype), 2}];
            extension = lower(obj.filetype(2:end));
            
            % Set file description and file extension
            filter.setDescription(description);
            filter.addExtension(extension);
            fileChooser.setFileFilter(filter);
            
            % Enable multiple file selections and open dialog box
            fileChooser.setMultiSelectionEnabled(true);
            status = fileChooser.showOpenDialog(fileChooser);
            
            % Determine paths of selected files
            if status == fileChooser.APPROVE_OPTION
                
                % Get file information
                fileinfo = fileChooser.getSelectedFiles();
                
                % Parse file information
                for i=1:size(fileinfo, 1)
                    [files{i,1},files{i,2},files{i,3}] = fileparts(char(fileinfo(i).getAbsolutePath));
                end
                
            % If file selection was cancelled
            else
                files = [];
            end
        end
        
        % Check and format data structure
        function data = importDataStructure(varargin)
           
            % Field names
            fields = {...
                'id',...
                'file_name',...
                'sample_name',...
                'method_name',...
                'experiment_date',...
                'experiment_time',...
                'time_values',...
                'total_intensity_values',...
                'intensity_values',...
                'mass_values',...
                'processing_time_import'};
            
            % Field values
            values{length(fields)} = [];
            
            % Check for any input
            if nargin == 2
                
                % Set data to input 
                data = varargin{1};
                
                % Check for missing fields
                missing_fields = fields(~isfield(data, fields));
                
                % Add missing fields
                if ~isempty(missing_fields)
                    missing_values{length(missing_fields)} = {};
                    
                    for i = 1:length(missing_fields)
                        data.(missing_fields{i}) = missing_values{i};
                    end
                end
            else
                % Create new data structure
                data = cell2struct(values, fields, 2);
                data(1) = [];
            end
        end
    end
end