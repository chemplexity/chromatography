% Method      : MD5
% Description : Returns the MD5 checksum of a file
%
% Syntax
%   checksum = MD5(file)
%
% Pararmeters
%   Name        : file
%   Type        : string
%   Description : valid file name
%
% Examples
%   checksum = MD5('FID1A.ch')
%   checksum = MD5('.ch')

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