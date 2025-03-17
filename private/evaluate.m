function [Acc, Bhat] = evaluate(XiTest, YiTest, CxxTrain, CxyTrain, LambdaOpt)
% [Acc, Bhat] = evaluate(XiTest, YiTest, CxxTrain, CxyTrain, LambdaOpt)
% Input:
%   Xi: A matrix (nSamples x nRegressors)      Test set
%   Yi: A matrix (nSamples x nResponses)       Test set
%   Cxx: A matrix (nPredictors x nPredictors)  Auto-covariance from the training set
%   Cxy: A matrix (nPredictors x nResponses)   Cross-covariance from the training set
%   LambdaOpt: A vector (1 x nResponses)
% Output:
%   Acc: A vector (1 x nResponses)
%   Bhat: A matrix (nPredictors x nResponses)

UniqueLambdas = unique(LambdaOpt);
[~, nPred] = size(XiTest);
[~, nResp] = size(YiTest);
Bhat = nan(nPred, nResp, 'double');
for iL = 1:numel(UniqueLambdas)
  IdxResp = LambdaOpt == UniqueLambdas(iL);
  L = double(UniqueLambdas(iL)) * speye(nPred);
  L(1,1) = 0;
  warning off
  Bhat(:,IdxResp) = (CxxTrain+L)\CxyTrain(:,IdxResp);
  warning on
end
Acc = corrvec(YiTest, XiTest*Bhat);
end
