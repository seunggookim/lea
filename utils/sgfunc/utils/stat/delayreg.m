function X = delayreg(x, TimeMask, Delays, isZeropad)
% X = delayreg(x, TimeMask, Delays, isZeropad)
%
% INPUTS:
%   x          [numeric: #times x #predictors]
%   TimeMask   [logical: #samples x 1]
%   Delays     [numeric: 1 x #delays]
%   isZeropad  [logical: false (default) | true]
%
% OUTPUTS:
% For X = [x1, x2, x3, ...]
%     DELAYS = [d0, d1, d2,...],
% Returns  X = [x1(d0), x1(d1), ..., x2(d0), x2(d1), ...]
%
% because this is easier to concatenate along the columns for various
% predictor sets: [X1 X2]
%
% without zeropadding:
%  - if x(delay) is NaNs or undefined, return an error 
%
% (cc) 2021-2022, sgKIM

% y(t) = [x(t-tau1), x(t-tau2), x(t-tau3), ...]*beta
%
% e.g., tau = [0, 1, 2, ...]    y(t) is modelled by previous x's
%       tau = [-2, -1, 0]       y(t) is modelled by following x's

if ~exist('isZeropad','var'), isZeropad = false; end
TimeMask = not(not(TimeMask));
[~,nPreds] = size(x);
nSamples = sum(TimeMask);
nLags = numel(Delays);
X = zeros(sum(TimeMask), nPreds*numel(Delays), class(x));
for i = 1:nLags
  Idx = delay(TimeMask, Delays(i));  % delaying a logical index array
  nZeros = nSamples - sum(Idx);      % count #zeros to pad
  
  if ~isZeropad
    assert(~nZeros, 'Chosen TimeMask & Delays select undefined X!')
  end
  
  X(:,i+(0:(nPreds-1))*nLags) = [...
    zeros(nZeros*(Delays(i)>0),nPreds)     % zeropadding for positive lags
    x(Idx,:)                               % slicing input
    zeros(nZeros*(Delays(i)<0),nPreds) ... % zeropadding for negative lags
    ];
end

% denan:
X(isnan(X)) = 0;

end

function U = delay(I, tau)
if (tau<=0) % a negative delay
  U = [false(-tau,1); I(1:end+tau)];
else % a positive delay
  U = [I(1+tau:end); false(tau,1)];
end
end

%% TEST
%{
rng(1234)
x = rand(5,2)
TimeMask = ~~([0 0 1 1 1]');
X = delayreg(x, TimeMask, [0 1 2])
%}
