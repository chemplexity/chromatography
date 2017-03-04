function checksum = MD5(varargin)
% ------------------------------------------------------------------------
% Method      : MD5
% Description : Returns the MD5 checksum of file
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   checksum = MD5(file)
%
% ------------------------------------------------------------------------
% Input (Required)
% ------------------------------------------------------------------------
%   file -- absolute or relative path of file
%       string
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   checksum = MD5('FID1A.CH')
%   checksum = MD5('001-32-2.RAW')

% ---------------------------------------
% Initialize
% ---------------------------------------
checksum = 0;

% ---------------------------------------
% Input
% ---------------------------------------
p = inputParser;

addRequired(p, 'file', @ischar);

parse(p, varargin{:});

% ---------------------------------------
% Parse
% ---------------------------------------
file = p.Results.file;

% ---------------------------------------
% Validate
% ---------------------------------------
[status, attributes] = fileattrib(file);

if ~status || attributes.directory
    return
end

if attributes.UserRead
    file = attributes.Name;
end

if ~usejava('jvm')
    return
end

% ---------------------------------------
% MD5
% ---------------------------------------
md5 = java.security.MessageDigest.getInstance('MD5');

file = java.io.FileInputStream(java.io.File(file));
file = java.security.DigestInputStream(file, md5);

while file.read() ~= -1
end

checksum = reshape(dec2hex(typecast(md5.digest(), 'uint8'))', 1, []);

end