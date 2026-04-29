function [c,lags] = xcorrnan(x, varargin)

if exist('varargin','var')
  y = varargin{1};
  varargin(1) = [];
  assert(isvector(x))
  assert(isvector(y))
  x = x(:);
  y = y(:);
  isValid = not(isnan(x)) & not(isnan(y));
  [c,lags] = xcorr(x(isValid), y(isValid), varargin{:});
else
  isValid = all(not(isnan(x)),2);
  [c,lags] = xcorr(x(isValid,:), varargin{:});
end


end