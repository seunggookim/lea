function hashStr = hashwithsalt(data, salt)
% hashStr = hashwithsalt(data, salt)
salted_input = [char(salt) char(data)]; 
bytes = uint8(salted_input);  % Convert string to byte array
md = java.security.MessageDigest.getInstance('SHA-256');
hashBytes = md.digest(bytes);

% Convert to hex string
hashHex = dec2hex(typecast(hashBytes, 'uint8'))';
hashStr = lower(reshape(hashHex, 1, []));
end
