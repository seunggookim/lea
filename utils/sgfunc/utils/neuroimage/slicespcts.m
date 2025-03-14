function [H, Cfg, Base, Data] = slicespcts(Base, Data, Cfg)
%SLICESPCTS shows SLICES with principal component time series (PCTS)
%
%USAGE
% [H, Cfg, Base, Data] = slicespcts(Base, Data, Cfg)
%
%INPUT
% Base
%
% Data
%  .vol  [#X x #Y x #Z x #compo] 4-D image of component loadings
%  .info (1x1 struct) NIFTI image header
%  .ts   [#time x #compo] time series of each component
%  .expl [1 x #compo] explained variance %
%
% Cfg
%
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

if not(exist('Cfg','var')), Cfg = []; end
Cfg = defaultcfg(struct( nComp=size(Data.vol,4) ), Cfg, mfilename);

axesSlices = axeslayout([Cfg.nComp, 9], [0 0 0 0], [.25 0 0 0]);
axesTimeseries = axeslayout([Cfg.nComp, 1], [0.22 0.05 0.2 0.3], [0 .75 0 0]);
hFig = figure;

H = struct(Img = [], Ts = []);
for iComp = 1:Cfg.nComp
  Data.info.VolumeToView = iComp;
  idx = (1:9)+9*(iComp-1);
  axes_ = struct(x=axesSlices.x(idx), y=axesSlices.y(idx), w=axesSlices.w, h=axesSlices.h);
  h = slices(Base, Data, struct( figurehandle = hFig, sliceaxes = axes_, layout = [1 9], colorbarvisible = 'off', ...
    coordinatelocation_slice = 1.08, thres = prctile(reshape(abs(Data.vol(:,:,:,iComp)),[],1),80)));
  H.Img = [H.Img, h];

  h = axespos(axesTimeseries, iComp);
  plot(Data.ts(:,iComp), LineWidth=1, color=[0 .8 .1])
  xlim([0 size(Data.ts,1)+1])
  set(gca, xcolor=.65*[1 1 1], ycolor=.65*[1 1 1], color=.03*[1 1 1])
  titleText = sprintf('[Comp-%02i]',iComp);
  if isfield(Data, 'expl')
    titleText = [titleText, sprintf(' %.2f%%', Data.expl(iComp))];
  end
  title(titleText, Color='w')
  xlabel('Time [vol]'); ylabel('PC-score [AU]')
  H.Ts = [H.Ts, h];
end

set(hFig, Position=[1 1 700 100*Cfg.nComp]);

end
