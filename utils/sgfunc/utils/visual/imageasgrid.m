function h = imageasgrid(I, MarkerSize)
if not(exist('MarkerSize','var'))
  MarkerSize = 2000;
end
[X,Y] = meshgrid(1:size(I,2), 1:size(I,1));
h = scatter(X(:), Y(:), MarkerSize, I(:), 'square', 'filled');
axis ij image
axis([0.5 size(I,2)+0.5 0.5 size(I,1)+0.5])
if not(nargout)
  clear h
end
end
