function [lambdaOpt, SSE] = optimizeloocv(X, Y, Cxx, Cxy, lambdaGrid)
%(LEA's private) grid-search optimal ridge hyperparameters via the leave-one-set-out CV
% [lambdaOpt, SSE] = optimizeloocv(X, Y, Cxx, Cxy, lambdaGrid)
% Input:
%   X: {1 x nFolds} with (nSamples x nPredictors) 
%   Y: {1 x nFolds} with (nSamples x nResponses)
%   Cxx: (nPredictors x nPredictors)
%   Cxy: (nPredictors x nResponses)
%   lambdaGrid: (1 x nLambdaValues)
% Output:
%   lambdaOpt: (1 x nResponses)
%   SSE: (nLambdaValues x nResponses)

nPred = size(X{1}, 2);
nResp = size(Y{1}, 2);
nLambda = numel(lambdaGrid);
SSE = zeros(nLambda,nResp);
for iL = 1:nLambda
  L = double(lambdaGrid(iL)) * speye(nPred);
  L(1,1) = 0;
  for iSet = 1:numel(X)
    Cxx_i = Cxx - X{iSet}' * X{iSet};
    Cxy_i = Cxy - X{iSet}' * Y{iSet};
    Error = Y{iSet} - X{iSet} * ( (Cxx_i+L)\Cxy_i );
    SSE(iL,:) = SSE(iL,:) + sum( Error.^2 );
  end
end
[~, Idx] = min(SSE, [], 1);
lambdaOpt = lambdaGrid(Idx);
end
