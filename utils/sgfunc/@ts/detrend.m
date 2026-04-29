function ts = detrend(ts, method)
%ts/detrend detrends the data of a TS object
%   TSOUT = DETREND(TSIN, METHOD)
%   TSIN is an input TS object to detrend
%   METHOD is a detrending method ["none" | "constant" | "linear"]
%   TSOUT ia a detrended TS object with the original offset and slope in .DataInfo.UserData.Detrend
%
% Example:
% TsOut = detrend(TsIn, "linear")


if not(isfield(ts.DataInfo.UserData, 'Detrend'))
  ts.DataInfo.UserData.Detrend.Method = 'none';
end
if not(strcmp(ts.DataInfo.UserData.Detrend.Method, 'none'))
  error('The input has already been detrended "%s"', ts.DataInfo.UserData.Detrend)
else
  if contains(method, ["none", "constant", "linear"])
    switch method
      case "constant"
        ts.DataInfo.UserData.Detrend.OrigMean = mean(ts);
        ts.Data = ts.Data - ts.DataInfo.UserData.Detrend.OrigMean;
      case "linear"
        X = (1:size(ts.Time,1))';
        X = X - mean(X);
        X = [ones(size(ts.Time,1),1), X];
        B = (X'*X)\X'*ts.Data;
        ts.Data = ts.Data - X*B;
        ts.DataInfo.UserData.Detrend.OrigMean = B(1,:);
        ts.DataInfo.UserData.Detrend.OrigSlope = B(2,:);
    end
  else
    error('"%s": unrecognizable detrending methods! ["none" | "constant" | "linear"]')
  end
end
ts.DataInfo.UserData.Detrend.Method = method;

end
