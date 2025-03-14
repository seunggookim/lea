function savets(TimeSeries, fnameTs)
% savets(TimeSeries, fnameTs)
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

assert( isequal(class(TimeSeries), 'timeseries') )
assert( contains(fnameTs, '.ts') )
precision = class(TimeSeries.Data);
fnameMat = strrep(fnameTs, '.ts',  '.mat');
fid = fopen(fnameTs, 'w');
fwrite(fid, TimeSeries.Data(:), precision);
fclose(fid);

TimeSeries.UserData.('OrigTimeInfo') = TimeSeries.TimeInfo;
TimeSeries.DataInfo.UserData.('MatrixDimension') = size(TimeSeries.Data);
TimeSeries.DataInfo.UserData.('Precision') = precision;
TimeSeries.UserData.('OrigDataInfo') = TimeSeries.DataInfo;
TimeSeries = delsample(TimeSeries, 'Index',1:TimeSeries.TimeInfo.Length);
save(fnameMat, 'TimeSeries');
end


