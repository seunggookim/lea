function save(Ts, fnameTs)
%ts.save saves a TS object in a .TS/.HD pair
%   SAVE(TSTOSAVE, FILENAME)
%   TSTOSAVE is a TS object to save.
%   FILENAME is a character vector or a string scalar as 'example.ts' or "example.ts"
%
%Example:
%save(Ts, "example.ts")

assert(Ts.TimeInfo.isUniform, 'Sorry!:( TS class only handles a uniform time vector for the efficiency of data I/O.')
assert(isequal(class(Ts), 'ts'))
assert(contains(fnameTs, '.ts'))
precision = class(Ts.Data);
fnameHdr = strrep(fnameTs, '.ts',  '.hd');
fid = fopen(fnameTs, 'w');
fwrite(fid, Ts.Data(:), precision);
fclose(fid);

Ts.UserData.('OrigTimeInfo') = Ts.TimeInfo;
Ts.DataInfo.UserData.('MatrixDimension') = size(Ts.Data);
Ts.DataInfo.UserData.('Precision') = precision;
Ts.UserData.('OrigDataInfo') = Ts.DataInfo;
Ts = delsample(Ts, 'Index',1:Ts.TimeInfo.Length);
save(fnameHdr, 'Ts', '-MAT', '-nocompression');
end
