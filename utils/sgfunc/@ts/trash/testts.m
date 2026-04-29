function testts()
checkthis('int8',  [5*1000 10*1000])
checkthis('double', [1000 100*1000])  % 700 MB, 0.8 ssc to write, 0.4 sec to read [good!]
checkthis('double', [1000*1000 50])
checkthis('single', [500 100*1000])
checkthis('int32',  [500 100*1000])
end

function checkthis(precision, dimensions)
a = timeseries(randi(255, dimensions, precision), 'Name','eeg');
a.DataInfo.Units = 'uV';
fname = [tempname,'.mat'];
tic; savets(a, fname); fprintf('saving a TS (%s, [%i x %i]): ', upper(precision), dimensions); toc
s = dir(fname);
fprintf('> HEADER FILE SIZE = %s\n', formatbytes(s.bytes))
s = dir(strrep(fname, '.mat', '.dat'));
fprintf('> DATA FILE SIZE = %s\n', formatbytes(s.bytes))
tic; b = loadts(fname); fprintf('loading a TS (%s, [%i x %i]): ', upper(precision), dimensions); toc
assert(isequal(a.Data ,b.Data))
assert(isequal(a.Time ,b.Time))
a.DataInfo
b.DataInfo
b.DataInfo.UserData
assert(isequal(a.TimeInfo ,b.TimeInfo))
fprintf('[PASS]: saved and loaded matched!\n\n')
end
