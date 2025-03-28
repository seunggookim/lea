function [dataX, dataY, Itc] = prepdata(Job)
%(LEA's private) given FnamesX and FnamesY, read data, align, resample, 
%  and return dataX and dataY cell arrays with timeseries
%[dataX, dataY, Itc] = prepdata(Job)
tic
if not(isempty(Job.FnamesY))
  assert( size(Job.FnamesX, 1) == size(Job.FnamesY, 1) )
end
nSets = size(Job.FnamesX, 1);
dataX = cell(nSets,1);
dataY = cell(nSets,1);
Itc = [];

% Read & Resample
for iSet = 1:nSets
  % FIND a reference time vector for a given Job.SampleRateHz, Job.RelToiSec based on the first X
  Ts = ts.load(Job.FnamesX(iSet,1));
  Ts_ = ts.load(Job.FnamesY(iSet,1));
  referenceTimeVector = max(Ts.Time(1),Ts_.Time(1)) : 1/Job.SampleRateHz : min(Ts.Time(end),Ts_.Time(end));
  
  dataX{iSet} = resample(Ts, referenceTimeVector, 'linear');
  for jSpace = 2:size(Job.FnamesX, 2)
    Ts = ts.load(Job.FnamesX(iSet,jSpace));
    dataX{iSet} = helper_concatts(dataX{iSet}, resample(Ts, referenceTimeVector, 'linear'));
  end

  Ts = Ts_;
  clear Ts_
  dataY{iSet} = resample(Ts, referenceTimeVector, 'linear');
  for jSpace = 2:size(Job.FnamesY, 2)
    Ts = ts.load(Job.FnamesY(iSet,jSpace));
    dataY{iSet} = helper_concatts(dataY{iSet}, resample(Ts, referenceTimeVector, 'linear'));
  end
end

% Check time points
nTimes = cell2mat(cellfun(@(x) dataY{x}.TimeInfo.Length, num2cell(1:nSets), uni=0));
if isscalar(unique(nTimes))
  logthis('The numbers of timepoints of all trials are identical..-_-;;\n')
  if Job.IsComputeItc  % can be RAM-challenging for fMRI data
    % now compute inter-set (inter-subject or inter-trial) correlation
    Itc = struct(X=helper_itc(dataX), Y=helper_itc(dataY));
    logthis('max ITC(X) = %.3f\n', max(Itc.X.meanCorr))
    logthis('max ITC(Y) = %.3f\n', max(Itc.Y.meanCorr))
    if max(max(Itc.X.meanCorr), max(Itc.Y.meanCorr))>0.1
      warning('Too high (>0.1) ITC! >>>RDD-ALERT!!<<<')
    end
  end
end

logthis('DONE: took %s\n', char(duration(seconds(toc), Format='hh:mm:ss.SSS')))
end



function ts = helper_concatts(ts, ts2)
ts.Data = [ts.Data, ts2.Data];
ts.DataInfo.UserData = [ts.DataInfo.UserData, ts2.DataInfo.UserData];
end

function itc = helper_itc(TsSets)
X = [];
for i = 1:numel(TsSets)
  X = cat(3, X, TsSets{i}.Data);
end
[mR,R] = compute_isc(X);
itc = struct(meanCorr=mR, subjCorr=squeeze(R));
end
