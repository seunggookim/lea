function [H, u] = plotridgelinesplus(cellArray, cfg)
% plotridgelinesplus(CellArray, cfg)
%
%

cellArray = cellArray(:);
cfg = defaultcfg(struct( colorMap=get_colormap(numel(cellArray),1), yHop=1, vDirection=+1, colorScheme='normal', ...
  yScale=ones(1,numel(cellArray)), boundaries=[], yTickLabel=(1:numel(cellArray)), markerXPosition=[], isCloudplot=0 ...
  ), cfg);
YTICK = (1:numel(cellArray))*cfg.vHop;

switch cfg.colorScheme
  case 'normal'
    RIDGE_COLORS = cfg.colorMap;
    BAR_COLORS = ones(numel(cellArray),3);
    BAR_ALPHA = 0.75;
  case 'nobar'
    RIDGE_COLORS = cfg.colorMap;
    BAR_COLORS = ones(numel(cellArray),3);
    BAR_ALPHA = 0;
  case 'inverse'
    RIDGE_COLORS = .97*ones(numel(cellArray),3);
    BAR_COLORS = cfg.colorMap;
    BAR_ALPHA = 1;
  otherwise
    error('cfg.colorScheme="%s" UNKNOWN!', cfg.colorScheme)
end

if cfg.vDirection<0
  cellArray = flipud(cellArray);
  cfg.yTickLabel = flipud(cfg.yTickLabel(:));
  RIDGE_COLORS = flipud(RIDGE_COLORS);
end


%%
hold on
H = struct(ridges = [], markers=[], yticks=[]);
for k = numel(cellArray):-1:1
  if not(isempty(cfg.boundaries))
    [fout0,xout,u] = ksdensity(cellArray{k}, BoundaryCorrection='reflection', Function='pdf', Support=cfg.boundaries);
  else
    [fout0,xout,u] = ksdensity(cellArray{k}, BoundaryCorrection='reflection', Function='pdf');
  end
  
  if numel(cellArray{k})>1
    fout0 = fout0 ./ max(fout0) * cfg.yScale(k);
    plot(xout, fout0+k*cfg.vHop, LineWidth=3, Color='k')
    H.yticks = [k*cfg.vHop, H.yticks];
    H.ridges = [patch(xout, fout0 + k * cfg.vHop, RIDGE_COLORS(k,:), LineStyle='none'), H.ridges];
    [~,~,ci,~] = ttest(cellArray{k}, [], 'alpha',0.01);
    idx = find(xout >= ci(1) & xout <= ci(2));
    if not(isempty(idx)) && BAR_ALPHA>0
      patch([xout(idx(1)), xout(idx), xout(idx(end))], [0 fout0(idx) 0] + k * cfg.vHop, BAR_COLORS(k,:), ...
        FaceAlpha=BAR_ALPHA, LineStyle='none')
    end   
    if not(isempty(cfg.markerXPosition))
      idx = dsearchn(reshape(xout,[],1), cfg.markerXPosition(k));
      H.markers = [...
        scatter(cfg.markerXPosition(k), fout0(idx)+k*cfg.vHop, 80, 'o', MarkerFaceColor='w', MarkerEdgeColor='k', ...
        LineWidth=2), ...
        H.markers];
    end
    if cfg.isCloudplot
      scatter(cellArray{k}, k*cfg.vHop-cfg.vHop*0.05, 30, 'o', 'filled', MarkerFaceAlpha=0.25, ...
        MarkerFaceColor=RIDGE_COLORS(k,:))
    end
    
  end
end
set(gca, ytick=YTICK, yTickLabel=cfg.yTickLabel)
hold off

if not(nargout)
  clear H
end

end
