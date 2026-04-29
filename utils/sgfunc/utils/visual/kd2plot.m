function [Xgrid, Ygrid, Fgrid] = kd2plot(x, y, varargin)

[f, xi] = ksdensity([x y], varargin{:});
n = sqrt(length(f));
Xgrid = reshape(xi(:,1), n, n);
Ygrid = reshape(xi(:,2), n, n);
Fgrid = reshape(f, n, n);

if not(nargout)
  contourf(Xgrid, Ygrid, Fgrid, 20);
  clear Xgrid Ygrid Fgrid
end

end