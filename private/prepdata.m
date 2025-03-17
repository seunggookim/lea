function [dataX, dataY, Isc] = prepdata(Job)
%(LEA's private) given FnamesX and FnamesY, read data, align, resample, and return dataX and dataY cell arrays with
%timeseries
% [dataX, dataY] = prepdata(Job)
tic
if not(isempty(Job.FnamesY))
  assert( size(Job.FnamesX, 1) == size(Job.FnamesY, 1) )
end
nSets = size(Job.FnamesX, 1);
dataX = cell(nSets,1);
dataY = cell(nSets,1);
Isc = [];

% Read & Resample
for iSet = 1:nSets
  % FIND a reference time vector for a given Job.SampleRateHz, Job.RelToiSec based on the first X
  Ts = ts.load(Job.FnamesX(iSet,1));
  referenceTimeVector = Ts.Time(1) : 1/Job.SampleRateHz : Ts.Time(end);
  dataX{iSet} = resample(Ts, referenceTimeVector, 'linear');
  for jSpace = 2:size(Job.FnamesX, 2)
    Ts = ts.load(Job.FnamesX(iSet,jSpace));
    dataX{iSet} = helper_concatts(dataX{iSet}, resample(Ts, referenceTimeVector, 'linear'));
  end

  if not(isempty(Job.FnamesY))
    Ts = ts.load(Job.FnamesY(iSet,1));
    dataY{iSet} = resample(Ts, referenceTimeVector, 'linear');
    for jSpace = 2:size(Job.FnamesY, 2)
      Ts = ts.load(Job.FnamesY(iSet,jSpace));
      dataY{iSet} = helper_concatts(dataY{iSet}, resample(Ts, referenceTimeVector, 'linear'));
    end
  end
end

if isempty(Job.FnamesY)
  logthis('DONE: only reading X: took %s\n', char(duration(seconds(toc), Format='hh:mm:ss.SSS')))
  return
end

% Check time points
nTimes = cell2mat(cellfun(@(x) dataY{x}.TimeInfo.Length, num2cell(1:nSets), uni=0));
if isscalar(unique(nTimes))
  logthis('>>>RDD-WARNING<<< the numbers of timepoints of all trials are identical!!\n')
  if Job.IsComputeIsc  % can be RAM-challenging for fMRI data
    % now compute intersubject correlation
    Isc = struct(X=helper_isc(dataX), Y=helper_isc(dataY));
    logthis('max ISC(X) = %.3f\n', max(Isc.X.meanCorr))
    logthis('max ISC(Y) = %.3f\n', max(Isc.Y.meanCorr))
  end
end

logthis('DONE: took %s\n', char(duration(seconds(toc), Format='hh:mm:ss.SSS')))
end



function ts = helper_concatts(ts, ts2)
ts.Data = [ts.Data, ts2.Data];
ts.DataInfo.UserData = [ts.DataInfo.UserData, ts2.DataInfo.UserData];
end

function isc = helper_isc(TsSets)
X = [];
for i = 1:numel(TsSets)
  X = cat(3, X, TsSets{i}.Data);
end
[mR,R] = compute_isc(X);
isc = struct(meanCorr=mR, subjCorr=squeeze(R));
end