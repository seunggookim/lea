function [lambdaOpt, SSE] = optimize(X, Y, Cxx, Cxy, Job)
%(LEA's private) grid-search optimal ridge hyperparameters via cross-validation
% [lambdaOpt, SSE] = optimize(X, Y, Cxx, Cxy, Job)
% Input:
%   X: {1 x nFolds} with (nSamples x nPredictors)
%   Y: {1 x nFolds} with (nSamples x nResponses)
%   Cxx: (nPredictors x nPredictors)
%   Cxy: (nPredictors x nResponses)
%   lambdaGrid: (1 x nLambdaValues)
% Output:
%   lambdaOpt: (1 x nResponses)
%   SSE: (nLambdaValues x nResponses)

% Design the inner loop
if isequal(Job.CvDesign, 'loocv')
  Cv = cvpartition(numel(X), 'LeaveOut');
elseif isnumeric(Job.CvDesign) && numel(Job.CvDesign)==2
  Cv = cvpartition(numel(X), 'KFold', Job.CvDesign(2));
else
  error WHAT_ELSE?
end

logthis('getting opt prepared..\n', verbosity=Job.IsVerbose)

nPred = size(X{1}, 2);
nResp = size(Y{1}, 2);
nLambda = numel(Job.LambdaGrid);
SSE = zeros(nLambda,nResp);
for iL = 1:nLambda
  L = double(Job.LambdaGrid(iL)) * speye(nPred);
  L(1,1) = 0;

  for iInner = 1:Cv.NumTestSets
    idxTest = find(test(Cv, iInner));

    CxxTrain = Cxx;
    CxyTrain = Cxy;
    for j = 1:numel(idxTest)
      CxxTrain = CxxTrain - X{idxTest(j)}' * X{idxTest(j)};
      CxyTrain = CxyTrain - X{idxTest(j)}' * Y{idxTest(j)};
    end
    logthis('Train COVs MADE!\n', verbosity=Job.IsVerbose)

    warning off
    % >>>>> INVERSE ONLY ONCE PER LAMBDA GRID <<<<<
    projMatrix = (CxxTrain + L)\CxyTrain;
    warning on
    logthis('Project MATRIX MADE!\n', verbosity=Job.IsVerbose)

    SSE_ = zeros(1,nResp);
    for j = 1:numel(idxTest)
      SSE_ = SSE_ + sum( (Y{idxTest(j)} - X{idxTest(j)} * projMatrix).^2 );
    end
    SSE(iL,:) = SSE(iL,:) + SSE_./numel(idxTest);
    clear SSE_
    logthis('%i-th lambda: iInner=%i DONE.\n', iL, iInner, verbosity=Job.IsVerbose)
  end
  [~, Idx] = min(SSE, [], 1);
  lambdaOpt = Job.LambdaGrid(Idx);
end
