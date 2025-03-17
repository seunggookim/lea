function [Cxx, Cxy] = findcov(Data)
% Compute Cxx and Cxy
% [Cxx, Cxy] = findcov(X,Y)

nFeats = size(Data(1).X, 2);
nResps = size(Data(1).Y, 2);
Cxx = zeros(nFeats, nFeats, 'double');
Cxy = zeros(nFeats, nResps, 'double');
for iSet = 1:numel(Data)
  Cxx = Cxx + Data(iSet).X'*Data(iSet).X;  % autocovariance of X
  Cxy = Cxy + Data(iSet).X'*Data(iSet).Y;  % crosscovariance of X & Y
end
end
