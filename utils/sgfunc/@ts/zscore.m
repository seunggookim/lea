function Ts = zscore(Ts, isZscore)
%ts/zscore standardizes the data while keeping original means and stds in .DataInfo.UserData.Zscore
%   TSOUT = ZSCORE(TSIN, ISZSCORE)
%   TSIN is an input TS object.
%   ISZSCORE ia a boolean flag to execute it or not.
%   TSOUT.DataInfo.UserData.Zscore will keep .OrigMean and .OrigStd when zscored.
%
%Example:
%TsOut = zscore(TsIn, 1)

if not(isfield(Ts.DataInfo.UserData, 'Zscore'))
  Ts.DataInfo.UserData.Zscore.IsDone = false;
end
if not(Ts.DataInfo.UserData.Zscore.IsDone) && isZscore
  Ts.DataInfo.UserData.Zscore.OrigMean = mean(Ts);
  Ts.DataInfo.UserData.Zscore.OrigStd = std(Ts);
  Ts.Data = (Ts.Data - Ts.DataInfo.UserData.Zscore.OrigMean) ./ Ts.DataInfo.UserData.Zscore.OrigStd;
  Ts.DataInfo.UserData.Zscore.OrigUnits = Ts.DataInfo.Units;
  Ts.DataInfo.Units = 'Z-sc';
end
Ts.DataInfo.UserData.Zscore.IsDone = isZscore;

end
