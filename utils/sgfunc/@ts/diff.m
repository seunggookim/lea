function ts = diff(ts, isZeropad)
%
%Example:
%TsOut = diff(TsIn, 1)

ts.Data = [zeros(1, size(ts.Data,2)); diff(ts.Data)];

if not(isZeropad)
  ts = delsample(ts, 'Index',1);
end

end
