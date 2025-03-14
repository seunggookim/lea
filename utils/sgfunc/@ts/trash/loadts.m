function TimeSeries = loadts(fnameTs)
% TimeSeries = loadts(fnameTs)
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

assert( contains(fnameTs, '.ts') )
fnameMat = strrep(fnameTs, '.ts',  '.mat');

load(fnameMat, 'TimeSeries');
origTimeInfo = TimeSeries.UserData.OrigTimeInfo;
origDataInfo = TimeSeries.UserData.OrigDataInfo;
fid = fopen(fnameTs, 'r');
TimeSeries = addsample(TimeSeries, 'Time', (origTimeInfo.Start : origTimeInfo.Increment : origTimeInfo.End)', ...
  'Data', fread(fid, origDataInfo.UserData.MatrixDimension, origDataInfo.UserData.Precision) );
if origTimeInfo.isUniform
  TimeSeries = setuniformtime(TimeSeries, 'Interval', origTimeInfo.Increment );
end
fclose(fid);
end
