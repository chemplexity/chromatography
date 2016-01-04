% ------------------------------------------------------------------------
% Method      : MD5
% Description : Calculate MD5 checksum of file
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
% Syntax
% ------------------------------------------------------------------------
%   checksum = MD5(file)
%
% ------------------------------------------------------------------------
% Parameters
% ------------------------------------------------------------------------
%   file (required)
%       Description : absolute or relative path of file
%       Type        : string
%
% ------------------------------------------------------------------------
% Examples
% ------------------------------------------------------------------------
%   checksum = MD5('FID1A.CH')
%   checksum = MD5('001-32-2.RAW')
%

function checksum = MD5(file)

% Input validation
if ~ischar(file) 
    error('Error: input must be of type ''char''');
    
elseif ~exist(file, 'file')
    error('Error: file does not exist');
end

% Initialize java.security
md5 = java.security.MessageDigest.getInstance('MD5');

fstream = java.io.FileInputStream(java.io.File(file));
dstream = java.security.DigestInputStream(fstream, md5);

% Determine MD5 checksum
while(dstream.read() ~= -1); end

checksum = reshape(dec2hex(typecast(md5.digest(),'uint8'))', 1, []);
end