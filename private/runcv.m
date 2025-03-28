function Mdl = runcv(X, Y, Job)
%(LEA's private) runs a nested CV for the observed data
% Mdl = runcv(X, Y, Job)
%
% Input:
%   Data: A structure array [1 x nFolds]
%   Job:  A structure array [1 x 1]
%
% Output:
%   Mdl:     A structure array [1 x 1] with
%   predAcc: A matrix (1 x nResponses)
%   beaHat:  A matrix (nFolds x nPredictors x nResponses)

tic
Data = delaydata(X, Y, Job);
logthis('FIR regressors constructed!\n', verbosity=Job.IsVerbose)
[Cxx, Cxy] = findcov(Data);
logthis('covariances found!\n', verbosity=Job.IsVerbose)
nPreds = size(Data(1).X, 2);
nResps = size(Data(1).Y, 2);

% Design the outer loop
if isequal(Job.CvDesign, 'loocv')
  Cv = cvpartition(numel(Data), 'LeaveOut');
elseif isnumeric(Job.CvDesign) && numel(Job.CvDesign)==2
  Cv = cvpartition(numel(Data), 'KFold', Job.CvDesign(1));
else
  error WHAT_ELSE?
end
logthis('cvpartition set!\n', verbosity=Job.IsVerbose)

lambdaOpt = nan(Cv.NumTestSets, nResps);
predAcc = zeros(Cv.NumTestSets, nResps);
betaHat = zeros(Cv.NumTestSets, nPreds, nResps);

logthis('READY for OUTER LOOP!\n', verbosity=Job.IsVerbose)
for iOuter = 1:Cv.NumTestSets
  idxTest = find(test(Cv, iOuter));
  idxTrain = find(training(Cv, iOuter));

  % find covariance matrices of the training sets
  CxxTrain = Cxx;
  CxyTrain = Cxy;
  for j = 1:numel(idxTest)
    CxxTrain = CxxTrain - Data(idxTest(j)).X' * Data(idxTest(j)).X;
    CxyTrain = CxyTrain - Data(idxTest(j)).X' * Data(idxTest(j)).Y;
  end

  % find optimal lambda via inner loop:
  logthis('iOuter=%i, READY TO OPTIMIZE!\n', iOuter, verbosity=Job.IsVerbose)
  [lambdaOpt(iOuter,:)] = optimize({Data(idxTrain).X}, {Data(idxTrain).Y}, CxxTrain, CxyTrain, Job);
  logthis('iOuter=%i, OPTIMIZED!\n', iOuter, verbosity=Job.IsVerbose)

  % predict test responses (averaged across test sets):
  for j = 1:numel(idxTest)
    logthis('iOuter=%i, iInner=%i, READY TO EVALUATE!\n',iOuter, j, verbosity=Job.IsVerbose)
    [predAcc_, betaHat_] = evaluate(Data(idxTest(j)).X, Data(idxTest(j)).Y, CxxTrain, CxyTrain, lambdaOpt(iOuter,:));
    logthis('iOuter=%i, iInner=%i, EVALUTED!\n', iOuter, j, verbosity=Job.IsVerbose)
    predAcc(iOuter,:) = predAcc(iOuter,:) + predAcc_;
    betaHat(iOuter,:,:) = betaHat(iOuter,:,:) + permute(betaHat_,[3 1 2]); % PERMUTE to add a leading singleton
    clear *_
  end
  predAcc(iOuter,:) = predAcc(iOuter,:) ./ numel(idxTest);
  betaHat(iOuter,:,:) = betaHat(iOuter,:,:) ./ numel(idxTest);
end

Mdl = struct(Lopt=lambdaOpt, Acc=predAcc, Bhat=betaHat, Cv=Cv);
logthis('DONE: took %s\n', char(duration(seconds(toc), Format='hh:mm:ss.SSS')))
end

