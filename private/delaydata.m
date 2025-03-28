function Data = delaydata(X, Y, Job)
%(LEA's private) for given X and Y cell arrays, delay without zeropadding, crop, and standardize them
% Data = delaydata(X, Y, Job)
% (cc) 2024, seung-goo.kim@ae.mpg.de

assert(numel(X) == numel(Y), "Dimensions of X and Y mismatched")
nSets = numel(X);
Data = [];

for iSet = 1:nSets
  % Find out overlapping time samples and apply the relative time of interest
  timeXSec = X{iSet}.Time;
  timeYSec = Y{iSet}.Time;
  maxTimeSec = min(timeXSec(end), timeYSec(end));
  timeMaskX = (Job.RelToiSec(1) <= timeXSec) & (timeXSec <= (maxTimeSec + Job.RelToiSec(2)));
  timeMaskY = (Job.RelToiSec(1) <= timeYSec) & (timeYSec <= (maxTimeSec + Job.RelToiSec(2)));
  
  % Delay without zeropadding, crop, & standardize stimulus
  X_ = zscore(delayreg(X{iSet}.Data, timeMaskX, Job.DelaysSmp, false));
  X_ = [ones(size(X_,1),1), X_]; % adding a bias term

  % Crop & standardize response
  Y_ = zscore(Y{iSet}.Data(timeMaskY,:));

  % Sample times
  T_ = timeXSec(timeMaskX);

  % Contain all in a structure:
  Data = [Data, struct(X=X_, Y=Y_, T=T_, XDataInfo=X{iSet}.DataInfo.UserData, YDataInfo=Y{iSet}.DataInfo.UserData)];
  clear *_
end

end

