% Method: DataLibrary
% Description: Retrieve lists of compound names and m/z values
%
% Syntax:
%   list = DataLibrary('OptionName', optionvalue...)
%
%   Options:
%       Class    : 'all', class
%       Subclass : 'all', subclass
%       ShowAll  : 'classes', 'subclasses', 'compounds'
%
% Examples:
%   list = DataLibrary('Class', 'FAEEs')
%   list = DataLibrary('Class', 'Alkenones')
%   list = DataLibrary('Class', 'All')

function varargout = DataLibrary(varargin)

% Check input
class_index = find(strcmp(varargin, 'Class'));
subclass_index = find(strcmp(varargin, 'Subclass'));
show_index = find(strcmp(varargin, 'ShowAll'));

% Check class options
if ~isempty(class_index)
    class_name = varargin{class_index + 1};
else
    class_name = 'all';
end

% Check subclass options
if ~isempty(subclass_index)
    subclass_name = varargin{subclass_index + 1};
else
    subclass_name = 'all';
end

% Check show options
if ~isempty(show_index)
    show_name = varargin{show_index + 1};
else
    show_name = [];
end

% Build library
lists = compoundclasses();
library = struct('class', [], 'subclass', [], 'compound', [], 'mz', []);

% Update library
for i = 1:length(lists(:,1))
    for j = 1:length(lists{i,3})

        % Add new line to library
        index = length(library) + 1;
        
        % Class/Subclass
        library(index).class = lists{i,1};
        library(index).subclass = lists{i,2};
        
        % Compound/MW
        library(index).compound = lists{i,3}{j,1};
        library(index).mz = lists{i,3}{j,2};
    end
end

% Check for empty values
if isempty(library(1).class)
    library = library(2:end);
end

% Create copy of library to pass through filters
filter_library = library;

% Check class options
if ~strcmp(class_name, 'all')
    filter_library = filter_library(strcmp({filter_library.class}, class_name));
end

% Check subclass options
if ~strcmp(subclass_name, 'all')
    filter_library = filter_library(strcmp({filter_library.subclass}, subclass_name));
end

% Output selection
if isempty(show_name)
    varargout{1} = filter_library;
elseif strcmp(show_name, 'classes')
    varargout{1} = filter_library;
    disp(unique({filter_library.class}));
elseif strcmp(show_name, 'subclasses')
    varargout{1} = filter_library;
    disp(unique({filter_library.subclass}));
elseif strcmp(show_name, 'compounds')
    varargout{1} = filter_library;
    disp(unique({filter_library.compound}));
end
end

function varargout = compoundclasses(varargin)

    % Class - FAs, Subclass - FAEEs
    FAEEs = {...
        'C16:0', 285;
        'C16:1', 283;
        'C16:2', 281;
        'C16:3', 279;
        'C16:4', 277;
        'C18:0', 313;
        'C18:1', 311;
        'C18:2', 309;
        'C18:3', 307;
        'C18:4', 305;
        'C20:0', 341;
        'C20:1', 339;
        'C20:2', 337;
        'C20:3', 335;
        'C20:4', 333;
        'C20:5', 331;
        'C22:0', 369;
        'C22:1', 367;
        'C22:2', 365;
        'C22:3', 363;
        'C22:4', 361;
        'C22:5', 359;
        'C22:6', 357;
        };
    
    FAMEs = {...
        'C16:0', 271;
        'C16:1', 269;
        'C16:2', 267;
        'C16:3', 265;
        'C16:4', 263;
        'C18:0', 299;
        'C18:1', 297;
        'C18:2', 295;
        'C18:3', 293;
        'C18:4', 291;
        'C20:0', 327;
        'C20:1', 325;
        'C20:2', 323;
        'C20:3', 321;
        'C20:4', 319;
        'C20:5', 317;
        'C22:0', 355;
        'C22:1', 353;
        'C22:2', 351;
        'C22:3', 349;
        'C22:4', 347;
        'C22:5', 345;
        'C22:6', 343;
        };

    % Class - GDGTs, Subclass - Branched
    BranchedGDGTs = {...
        'brGDGT - Ia',    1022;
        'brGDGT - Ib'     1020;
        'Ic',    1018;
        'IIa',   1036;
        'IIb',   1034;
        'IIc',   1032;
        'IIIa',  1050;
        'IIIb',  1048;
        'IIIc',  1046;
        };
    
    % Class - GDGTs, Subclass - Isoprenoid
    IsoprenoidGDGTs = {...
        '0',     1302;
        '1',     1300;
        '2',     1298;
        '3',     1296;
        '4',     1294;
        'Cren.', 1292;
        };
    
    % Class - Alkenones, Subclass - Ketones
    Alkenones = {...
        'C37:4', 527;
        'C37:3', 529;
        'C37:2', 531;
        'C38:4', 541;
        'C38:3', 543;
        'C38:2', 545;
        'C39:4', 555;
        'C39:3', 557;
        'C39:2', 559;
        };
    
    % Store list names here
    ListNames = {...
        'FAs',       'FAEEs',       FAEEs;
        'FAs',       'FAMEs',       FAMEs;
        'GDGTs',     'Branched',    BranchedGDGTs;
        'GDGTs',     'Isoprenoid',  IsoprenoidGDGTs;
        'Alkenones', 'Alkenones',   Alkenones;
        };
    
    varargout{1} = ListNames;
end
