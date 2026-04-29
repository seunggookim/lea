function h = plotlines(x, Y, vHop, colorMap, varargin)
%PLOTLINES draws lines in a single axis
%   H = PLOTLINES(X, Y, [VHOP], [COLORMAP], ...)
%   X is a vector with values along the X-axis.
%   Y is a matrix <#Poins x #Groups>.
%   VHOP is a vertical hopping factor (default: temporal std of all groups).
%   COLORMAP is a <#Groups x 3> RGB matrix.
%   Additional PLOT arguments can be added after COLORMAP.
%
%Example:
%plotlines(1:10, rand(10,5))
%plotlines(1:10, rand(10,5), [], [], LineWidth=2)
%
%(CC4-BY) seung-goo.kim@ae.mpg.de

assert(ismatrix(Y))
assert(numel(x)==size(Y,1))
if not(exist('vHop','var')) || isempty(vHop)
 vHop = mean(std(Y,'omitnan'),'omitnan')*4;
end
if not(exist('colorMap','var')) || isempty(colorMap)
  colorMap = get_colormap(round(size(Y,2)*1.2), 1);
  colorMap = colorMap(1:size(Y,2),:);
end
assert(size(colorMap,1)==size(Y,2))
h = plot(x, Y + (1:size(Y,2))*vHop, varargin{:});
set(gca, 'ColorOrder', colorMap)

if not(nargout)
  clear h
end
end
