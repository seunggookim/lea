function Ts = detrendts(Ts, method)
%ts/detrendts detrends the data of a TS object
%   TSOUT = DETRENDTS(TSIN, METHOD)
%   TSIN is an input TS object to detrend
%   METHOD is a detrending method ["none" | "constant" | "linear"]
%   TSOUT ia a detrended TS object with the original offset and slope in .DataInfo.UserData.Detrend
%
% Example:
% TsOut = detrendts(TsIn, "linear")


if not(isfield(Ts.DataInfo.UserData, 'Detrend'))
  Ts.DataInfo.UserData.Detrend.Method = 'none';
end
if not(strcmp(Ts.DataInfo.UserData.Detrend.Method, 'none'))
  error('The input has already been detrended "%s"', Ts.DataInfo.UserData.Detrend)
else
  if contains(method, ["none", "constant", "linear"])
    switch method
      case "constant"
        Ts.DataInfo.UserData.Detrend.OrigMean = mean(Ts);
        Ts.Data = Ts.Data - Ts.DataInfo.UserData.Detrend.OrigMean;
      case "linear"
        X = (1:size(Ts.Time,1))';
        X = X - mean(X);
        X = [ones(size(Ts.Time,1),1), X];
        B = (X'*X)\X'*Ts.Data;
        Ts.Data = Ts.Data - X*B;
        Ts.DataInfo.UserData.Detrend.OrigMean = B(1,:);
        Ts.DataInfo.UserData.Detrend.OrigSlope = B(2,:);
    end
  else
    error('"%s": unrecognizable detrending methods! ["none" | "constant" | "linear"]')
  end
end
Ts.DataInfo.UserData.Detrend.Method = method;

end
