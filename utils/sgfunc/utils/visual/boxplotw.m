function h =  boxplotw(varargin)
%prettier boxplot with data points
%
% boxplotx(varargin)
%
% (CC4-BY) seung-goo.kim@ae.mpg.de

cmap = brewermap(8,'set2');
hold on
h = [];
h.box = boxplot(varargin{:});
set(h.box(5,:), Color=cmap(1,:), LineWidth=1)   % BOX
set(h.box([1 2 3 4 6],:), Color=cmap(8,:), LineWidth=1.5) % WHISKER, MEDIAN BAR
set(h.box(6,:), Color=cmap(7,:), LineWidth=3) % WHISKER, MEDIAN BAR
set(h.box(7,:), visible='off') % OUTLIER?
if numel(varargin) == 2 && iscell(varargin)
  X = double(varargin{2});
else
  X = ones(size(varargin{1}));
end
JITTER_RANGE = 0.2;
h.scatter = scatter(X+(rand(size(X))-0.5)*JITTER_RANGE, varargin{1});
set(h.scatter, MarkerEdgeColor=cmap(4,:), LineWidth=1.5, MarkerFaceColor='w')
hold off

if not(nargout)
  clear h
end
end
