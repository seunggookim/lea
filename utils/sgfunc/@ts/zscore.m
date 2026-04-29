function ts = zscore(ts, isZscore)
%ts/zscore standardizes the data while keeping original means and stds in .DataInfo.UserData.Zscore
%   TSOUT = ZSCORE(TSIN, ISZSCORE)
%   TSIN is an input TS object.
%   ISZSCORE ia a boolean flag to execute it or not.
%   TSOUT.DataInfo.UserData.Zscore will keep .OrigMean and .OrigStd when zscored.
%
%Example:
%TsOut = zscore(TsIn, 1)

if not(isfield(ts.DataInfo.UserData, 'Zscore'))
  ts.DataInfo.UserData.Zscore.IsDone = false;
end
if not(ts.DataInfo.UserData.Zscore.IsDone) && isZscore
  ts.DataInfo.UserData.Zscore.OrigMean = mean(ts);
  ts.DataInfo.UserData.Zscore.OrigStd = std(ts);
  ts.Data = (ts.Data - ts.DataInfo.UserData.Zscore.OrigMean) ./ ts.DataInfo.UserData.Zscore.OrigStd;
  ts.DataInfo.UserData.Zscore.OrigUnits = ts.DataInfo.Units;
  ts.DataInfo.Units = 'Z-sc';
end
ts.DataInfo.UserData.Zscore.IsDone = isZscore;

end
