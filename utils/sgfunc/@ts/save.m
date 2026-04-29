function save(ts, fnameTs)
%ts.save saves a TS object in a .TS/.HD pair
%   SAVE(TSTOSAVE, FILENAME)
%   TSTOSAVE is a TS object to save.
%   FILENAME is a character vector or a string scalar as 'example.ts' or "example.ts"
%
%Example:
%save(Ts, "example.ts")

assert(ts.TimeInfo.isUniform, 'Sorry!:( TS class only handles a uniform time vector for the efficiency of data I/O.')
assert(isequal(class(ts), 'Ts'))
assert(contains(fnameTs, '.ts'))
precision = class(ts.Data);
fnameHdr = strrep(fnameTs, '.ts',  '.hd');
fid = fopen(fnameTs, 'w');
fwrite(fid, ts.Data(:), precision);
fclose(fid);

ts.UserData.('OrigTimeInfo') = ts.TimeInfo;
ts.DataInfo.UserData.('MatrixDimension') = size(ts.Data);
ts.DataInfo.UserData.('Precision') = precision;
ts.UserData.('OrigDataInfo') = ts.DataInfo;
ts = delsample(ts, 'Index',1:ts.TimeInfo.Length);
save(fnameHdr, 'ts', '-MAT', '-nocompression');
end
