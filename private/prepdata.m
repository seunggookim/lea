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
  ts = Ts.load(Job.FnamesX(iSet,1));
  ts_ = Ts.load(Job.FnamesY(iSet,1));
  referenceTimeVector = max(ts.Time(1),ts_.Time(1)) : 1/Job.SampleRateHz : min(ts.Time(end),ts_.Time(end));
  
  dataX{iSet} = resample(ts, referenceTimeVector, 'linear');
  for jSpace = 2:size(Job.FnamesX, 2)
    ts = Ts.load(Job.FnamesX(iSet,jSpace));
    dataX{iSet} = helper_concatts(dataX{iSet}, resample(ts, referenceTimeVector, 'linear'));
  end
  
  ts = ts_;
  clear ts_
  dataY{iSet} = resample(ts, referenceTimeVector, 'linear');
  for jSpace = 2:size(Job.FnamesY, 2)
    ts = ts.load(Job.FnamesY(iSet,jSpace));
    dataY{iSet} = helper_concatts(dataY{iSet}, resample(ts, referenceTimeVector, 'linear'));
  end
end


% Check time points
nTimes = cell2mat(cellfun(@(x) dataY{x}.TimeInfo.Length, num2cell(1:nSets), uni=0));
if isscalar(unique(nTimes))
  warning('The numbers of timepoints of all trials are IDENTICAL: is this expected?')
  if Job.IsComputeItc  % can be RAM-challenging for fMRI data
    % now compute inter-set (inter-subject or inter-trial) correlation
    Itc = struct(X=helper_itc(dataX), Y=helper_itc(dataY));
    logthis('max ITC(X) = %.3f, min P=%.3f\n', max(Itc.X.meanCorr), min(Itc.X.meanCorrP));
    logthis('max ITC(Y) = %.3f, min P=%.3f\n', max(Itc.Y.meanCorr), min(Itc.Y.meanCorrP));
    minP = min(min(Itc.X.meanCorrP), min(Itc.Y.meanCorrP));
    if minP < 0.01
      error('lea_main:highITC',['>>>SDL-ALERT!!<<<\n', ...
        'Min uncorrected P of ITC = %.3f < 0.01.\nReview your CV design for stimulus-driven leakage (SDL).'], minP)
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

nPerms = 1000;
nullMeanR = zeros(nPerms, size(X,2));
for kRnd = 1:nPerms
  U = X;
  for iVox = 1:size(X,2)
    for iSub = 1:size(X,3)
      U(:,iVox,iSub) = randomize_phase(X(:,iVox,iSub));
    end
  end
  nullMeanR(kRnd,:) = compute_isc(U);
end
P = 1 - mean(nullMeanR > mR); % one-sided P-value (r_obs > r_null)
itc = struct(meanCorr=mR, subjCorr=squeeze(R), meanCorrP=P);
end
