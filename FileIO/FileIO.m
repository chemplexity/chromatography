% Class: FileIO
% Description: Import raw LC/MS data into the MATLAB workspace
%
% Initialize: 
%   obj = FileIO;
%
% Import:
%   obj.import('OptionName', optionvalue...);
%
%   Options:
%       Data : dataset
%       FileType : extension
%
%   File Extensions:
%       Agilent : .D, .MS
%       netCDF  : .CDF
%
% Help:
%   obj.help
%
% Examples:
%   data = obj.import('FileType', '.D')
%   data = obj.import('FileType', '.CDF')
%   data = obj.import('Data', data, 'FileExtension', '.D')
%   data = obj.import('Data', data, 'FileExtension', '.CDF')

classdef FileIO
    
    properties (SetAccess = private)
        % File extensions
        extensions
    end

    methods
        
        % Constructor method
        function obj = FileIO()
            
            % Initialize properties
            obj.extensions = {...
                '.CDF', 'netCDF (*.CDF)';
                '.D', 'Agilent (*.D)';
                '.MS', 'Agilent (*.MS)'};
        end
        
        % Import method
        function data = import(obj, varargin)
            
            % Check number of inputs
            if nargin < 2
                return
                
            % Check input
            elseif nargin >= 2
                
                % Check options
                extension_index = find(strcmp(varargin, 'FileType'));
                data_index = find(strcmp(varargin, 'Data'));
                
                % Check file extension options
                if ~isempty(extension_index)
                    file_extension = varargin{extension_index + 1};
                else
                    return
                end
                
                % Check data options
                if ~isempty(data_index) && isstruct(varargin{data_index + 1})
                    data = DataStructure('Validate', varargin{data_index + 1});
                else
                    data = DataStructure();
                end
            end
 
            % Open file selection dialog
            files = dialog(obj, file_extension);
            
            % Check for any input
            if isempty(files)
                return
            end
            
            % Remove entries with incorrect filetype
            files(~strcmp(files(:,3), file_extension), :) = [];
            
            % Set path to selected folder
            path(files{1,1}, path);
            
            % Determine which import function to execute
            switch file_extension
                
                % Import data with the '*.CDF' extension
                case {'.CDF'}
                    for i = 1:length(files(:,1))
                        % Start timer
                        tic;
                        % Import data
                        import_data(i) = ImportCDF(strcat(files{i,2},files{i,3}));
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
                        import_data(i) = ImportAgilent(strcat(files{i,2},files{i,3}));
                        % Stop timer
                        processing_time(i) = toc;
                        % Assign a unique id
                        id(i) = length(data) + i;
                    end
                    
                % Import data with the '*.D' extension
                case {'.D'}
                    for i = 1:length(files(:,1))
                        % Parse folder contents
                        file = obj.filter(files, i, '.MS');
                        % Start timer
                        tic;
                        % Import data
                        import_data(i) = ImportAgilent(fullfile(file{1,1},strcat(file{1,2},file{1,3})));
                        % Stop timer
                        processing_time(i) = toc;
                        % Assign a unique id
                        id(i) = length(data) + i;
                        % Remove path to .D folder
                        rmpath(file{1,4});
                    end
            end
            
            % Validate import data structure
            import_data = DataStructure('Validate', import_data);
            
            % Update data
            for j = 1:length(id)
                import_data(j).id = id(j);
                import_data(j).file_type = file_extension;
                import_data(j).processing_time_import = processing_time(j);
            end
            
            % Concatenate imported data with existing data
            data = [data, import_data];
        end

        % Help method
        function help(varargin)
            
            % Print syntax and valid file types
            fprintf([...
               'Syntax \n'...
                '   Initialize    : obj = FileIO \n'...
                '   Import        : obj.import(''OptionName'', optionvalue) \n'...
                '   Help          : obj.help \n\n'...
                'Options \n'...
                '   Data          : data \n'...
                '   FileType      : type \n\n'...
                'File Extensions \n'...
                '   Agilent       : .D, .MS \n'...
                '   netCDF        : .CDF \n\n'...
                'Examples \n'...
                '   obj = FileIO; \n'...
                '   data = obj.import(''FileType'', ''.D'') \n'...
                '   data = obj.import(''FileType'', ''.CDF'') \n'...
                '   data = obj.import(''FileType'', ''.D'', ''Data'', data) \n'])
        end
    end
    
    methods (Access = private)
        
        % Open dialog box to select files
        function varargout = dialog(obj, varargin)
            
            % Set filetype
            file_extension = varargin{1};
            
            % Initialize JFileChooser object
            fileChooser = javax.swing.JFileChooser(java.io.File(cd));
            
            % Select directories if certain filetype
            if strcmp(file_extension, '.D')
                fileChooser.setFileSelectionMode(fileChooser.DIRECTORIES_ONLY);
            end
            
            % Determine file description and file extension
            filter = com.mathworks.hg.util.dFilter;
            description = [obj.extensions{strcmp(obj.extensions(:,1), file_extension), 2}];
            extension = lower(file_extension(2:end));
            
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
            
            varargout{1} = files;
        end
        
        % Filter folder contents
        function varargout = filter(~, varargin)

            files = varargin{1};
            index = varargin{2};
            fileextension = varargin{3};
            
            % Set folder path
            files{index,4} = fullfile(files{index,1}, strcat(files{index,2}, files{index,3}));
            path(files{index,4}, path);

            % List folder contents
            foldercontents = ls(files{index,4});

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
                
                % File path, file name, file extension
                [file{j,1},file{j,2},file{j,3}] = ...
                    fileparts(fullfile(files{index,4}, foldercontents{j}));
                
                % Full path
                file{j,4} = files{index,4};
            end
            
            % Remove entries with incorrect filetype
            file(~strcmp(file(:,3), fileextension), :) = [];
    
            % Check for any input
            if isempty(file{1,3})
                return
            end
            
            varargout{1} = file;
        end
    end
end