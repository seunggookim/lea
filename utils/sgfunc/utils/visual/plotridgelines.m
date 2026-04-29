function [H, u] = plotridgelines(CellArray, ColorMap, vHopScale, Bndry, Scale, Markers, ColorScheme)
% plotridgelines(CellArray, ColorMap, vHopScale, Bndry, Scale, Markers, ColorScheme)

if not(exist('ColorMap','var')) || isempty(ColorMap)
  ColorMap = get_colormap(numel(CellArray),1);
end

if not(exist('vHopScale','var')) || isempty(vHopScale)
  vHopScale = 1;
end

if not(exist('Scale','var')) || isempty(Scale)
  Scale = ones(numel(CellArray), 1);
end

if not(exist('ColorScheme','var'))
  ColorScheme='normal';
end

switch ColorScheme
  case 'normal'
    RIDGE_COLORS = ColorMap;
    BAR_COLORS = ones(numel(CellArray),3);
    BAR_ALPHA = 0.75;
  case 'nobar'
    RIDGE_COLORS = ColorMap;
    BAR_COLORS = ones(numel(CellArray),3);
    BAR_ALPHA = 0;
  case 'inverse'
    RIDGE_COLORS = .97*ones(numel(CellArray),3);
    BAR_COLORS = ColorMap;
    BAR_ALPHA = 1;
  otherwise
    error('ColorScheme="%s" UNKNOWN!', ColorScheme)
end

hold on
H = struct(ridges = [], markers=[], yticks=[]);
for k = numel(CellArray):-1:1
  if exist('Bndry','var') && not(isempty(Bndry))
    [fout0,xout,u,ksinfo] = ksdensity(CellArray{k}, BoundaryCorrection='reflection', Function='pdf', Support=Bndry);
  else
    [fout0,xout,u,ksinfo] = ksdensity(CellArray{k}, BoundaryCorrection='reflection', Function='pdf');
  end
  % logthis('bandwidht=%g\n',u)
  if numel(CellArray{k})>1
    fout0 = fout0./max(fout0)*Scale(k);
    plot(xout, fout0+k*vHopScale, LineWidth=3, Color='k')
    H.yticks = [k*vHopScale, H.yticks];
    H.ridges = [patch(xout, fout0+k*vHopScale, RIDGE_COLORS(k,:), LineStyle='none'), H.ridges];
    [~,~,ci,~] = ttest(CellArray{k});
    idx = find(xout >= ci(1) & xout <= ci(2));
    if not(isempty(idx)) && BAR_ALPHA>0
      patch([xout(idx(1)), xout(idx), xout(idx(end))], [0 fout0(idx) 0]+k*vHopScale, BAR_COLORS(k,:), ...
        FaceAlpha=BAR_ALPHA, LineStyle='none')
    end   
    if exist('Markers','var') && not(isempty(Markers))
      idx = dsearchn(reshape(xout,[],1), Markers(k));
      H.markers = [...
        scatter(Markers(k), fout0(idx)+k*vHopScale, 80, 'o', MarkerFaceColor='w', MarkerEdgeColor='k', LineWidth=2), ...
        H.markers];
    end
    
  end
end
hold off

if not(nargout)
  clear H
end

end
