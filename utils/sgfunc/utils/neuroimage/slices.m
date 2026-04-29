function [H, cfg, base, data] = slices(base, data, cfg)
%
% [H, cfg] = slices(base, data, cfg)
%
% [INPUT]
% BASE can be (1) filename, (2) structure, (3) 3-D numarray
% DATA can be (1) filename, (2) structure, (3) 3-D numarray, (4) vector
%             (5) 'fslho-thr0' | 'fslho-thr25' | 'fslho-thr50'
%             (6) a structure with 4-D numarray with "VolumeToView" field (e.g., Data.VolumeToView = 1)
% CFG is a structure:
% (.contour) can be (1) filename, (2) structure, or (3) 3-D numarray
%                   or a cell array of such
% (.basemethod)  'nearest' | 'linear' | 'mip'
% (.method)
% (.contoursmoothing)
% (.colorbarvisible)
%
%
% (CC4-BY) 2021-2024, seung-goo.kim@ae.mpg.de

%% C O N F I G ============================================================
if ~exist('cfg','var'), cfg=[]; end
if ~isfield(cfg,'method')
  cfg.method = 'linear';
end
if ~isfield(cfg,'basemethod')
  cfg.basemethod = 'linear';
end
if ~isfield(cfg,'contoursmoothing')
  cfg.contoursmoothing = 1;
end

%% CHECK INPUT ============================================================
% - Base volume
if ischar(base) || isstring(base) % for filenames
  base = helper_read(base);
end
if islogical(base)
  base = double(base);
end
if isnumeric(base)
  warning('Numeric base volume: vox2ras = eye(4) assumed.')
  cfg.unit = 'vox';
  Q = eye(4); Q(1:3,4) = 1;
  base = struct('vol',base, 'vox2ras',Q);
else
  cfg.unit = 'mm';
end
base = helper_conform(base); % make sure all have .vol and .vox2ras

% - Data volume
if ~exist('data','var'), data = []; end
if ischar(data) || isstring(data)
  [p1,f1,e1] = myfileparts(data);
  if contains(lower(data),'fslho') && isempty(e1)
    [data, cmap] = helper_readfslatlas(data);
    if ~isfield(cfg, 'colormap')
      cfg.colormap = cmap;
    end
    cfg.method = 'nearest';
  else
    data = helper_read(data);
  end
end
if islogical(data)
  data = double(data);
end
if isnumeric(data) % numeric vector of matrix
  if ~isempty(data) % Allowing data to be null (possibly only base+contour)
    if isvector(data)
      assert(numel(data)==numel(base.vol), '1-D data does not seem to be in the same space as base.vol')
      data = reshape(data, size(base.vol));
    end
    data = struct('vol',data, 'vox2ras', base.vox2ras);
  end
end
if ~isempty(data)
  data = helper_conform(data);
end


%% - Contour volume
if isfield(cfg,'contour')
  if ~iscell(cfg.contour)
    cfg.contour = {cfg.contour};
  end
  ncons = numel(cfg.contour);
  for icon = 1:ncons
    if ischar(cfg.contour{icon}) % for filenames
      cfg.contour{icon} = helper_read(cfg.contour{icon});
    end
    if islogical(cfg.contour{icon})
      cfg.contour{icon} = double(cfg.contour{icon});
    end
    if isnumeric(cfg.contour{icon})
      cfg.contour{icon} = struct('vol',cfg.contour{icon}, 'vox2ras',base.vox2ras);
    end
    % make sure all have .vol and .vox2ras:
    cfg.contour{icon} = helper_conform(cfg.contour{icon});
  end
end

%% XYZ coordinates
if ~isfield(cfg,'xyz')
  cfg.xyz = ['sag3';'cor3';'axi3'];
end

% bounding box for BASE:
ijk = [];
ind_nnz = ~isnan(base.vol) & base.vol~=0;
[ijk(:,1),ijk(:,2),ijk(:,3)] = ind2sub(size(base.vol), find(ind_nnz));
ijk = [min(ijk); max(ijk)];
if ~isempty(ijk)
  bbox_base = base.vox2ras*[ijk-1 ones(2,1)]';
else
  bbox_base = [1 1 1 1; size(base.vol) 1]';
end

% bounding box for DATA ???
if ~isempty(data)
  ijk = [];
  ind_nnz = ~isnan(data.vol) & data.vol~=0;
  [ijk(:,1),ijk(:,2),ijk(:,3)] = ind2sub(size(data.vol), find(ind_nnz));
  ijk = [min(ijk); max(ijk)];
  if ~isempty(ijk)
    bbox_data = data.vox2ras*[ijk-1 ones(2,1)]';
  else
    bbox_data = [1 1 1 1; size(data.vol) 1]';
  end
end

% set up coordinates
if ischar(cfg.xyz)
  xyz = [];
  for irow = 1:size(cfg.xyz,1)
    switch(cfg.xyz(irow,1:3))
      case 'sag'
        xyzdim = 1;
      case 'cor'
        xyzdim = 2;
      case 'axi'
        xyzdim = 3;
    end
    nslices = str2double(cfg.xyz(irow,4:end)); % # slices for this row

    % equidistance over a volume (Data if exist; otherwise BASE)
    bbox = bbox_base; % Why data? when it is useful? when you have sparse data consistently across all conditions, 
                      % but if not this can be inconvenient.
    coords = linspace(bbox(xyzdim,1), bbox(xyzdim,2), nslices+2);
    xyz_add = nan(nslices,3);
    xyz_add(:,xyzdim) = sort(coords(2:end-1)); % excluding both ends
    xyz = [xyz; xyz_add];
  end
  cfg.xyz = xyz;
end
nslices = size(cfg.xyz,1);

%% ANNOTATIONS
if ~isfield(cfg,'showticks')
  cfg.showticks = false;
end
% background color of the coordinate label, color, size...


%% LAYOUT
if ~isfield(cfg,'layout')
  cfg.layout = [ceil(sqrt(nslices)) ceil(sqrt(nslices))];
end
if nslices > prod(cfg.layout)
  error('nslices > prod(cfg.layout)')
end
if ~isfield(cfg,'sliceaxes')
  if ~cfg.showticks
    cfg.sliceaxes = axeslayout(cfg.layout, [0 0 0 0],[0 0 0 0]);
  else
    cfg.sliceaxes = axeslayout(cfg.layout, [0.1 0 0 0.1],[0 0 0 0]);
  end
end

%% Figure
if ~isfield(cfg,'figureposition')
  figpos = get(0,'defaultFigurePosition');
  cfg.figureposition = [figpos(1:2)  150*cfg.layout(2) 150*cfg.layout(1)];
end
if ~isfield(cfg,'figurecolor')
  cfg.figurecolor = 'k';
end

%% Color range
% DATA:
if ~isempty(data)
  if ~isfield(cfg,'mask')
    cfg.mask = true(size(data.vol));
  end
  numvals = data.vol(:);
  numvals(~cfg.mask(:)) = [];
  numvals(numvals==0) = [];
else
  numvals = [];
end
numvals(isnan(numvals)) = [];
numvals(isinf(numvals)) = [];
if isempty(numvals) && ~isempty(data)
  warning('All DATA voxels are masked')
  numvals = 0;
end
if ~isfield(cfg,'caxis')
  [cfg.caxis, ~] = winsorcaxis(numvals);
end
if ischar(cfg.caxis)
  if strcmp(cfg.caxis,'minmax')
    cfg.caxis = [min(numvals) max(numvals)];
  end
end
if ~isfield(cfg,'thres')
  cfg.thres = [0 0];
end
if isscalar(cfg.thres)
  cfg.thres = [-abs(cfg.thres) abs(cfg.thres)];
end

% BASE:
if ~isfield(cfg,'basecaxis')
  basenumvals = base.vol(:);
  basenumvals(numvals==0) = [];
  [~,cfg.basecaxis] = winsorcaxis(basenumvals);
end


%% -- Color map
if ~isfield(cfg,'subthres')
  cfg.subthres = 0;
end
if ~isfield(cfg,'colormap')
  if strcmp(cfg.method,'mip')
    cfg.colormap = flipud(gray);
  else
    cfg.colormap = getcolormap(numvals, cfg);
  end
end
if ~isequal(cfg.thres,[0 0])
  cfg.colormap = threscolormap(cfg);
end

%% -- Figure color and basecolormap
if ~isfield(cfg,'figurecolor')
  cfg.figurecolor = 'k';
end
if ~isfield(cfg,'basecolormap')
  cfg.basecolormap = gray;
end

%% -- Annotations
if ~isfield(cfg,'coordfontcolor')
  cfg.coordfontcolor = 'w';
end
if ~isfield(cfg, 'coordfontsize')
  cfg.coordfontsize = 7;
end

%% -- Remove temp variables
clear numvals

%% M A I N ================================================================
%% -- Initialize figure
if ~isfield(cfg,'figurehandle')
  cfg.figurehandle = figure;
else

end
set(gcf, 'position', cfg.figureposition, 'color', cfg.figurecolor);
if isfield(cfg,'fname_png') % if fname_png is given, make it invisible
  set(gcf,'visible','off')
end

%% -- DRAW slices
H = struct();
for iaxes = 1:nslices
  % Set axes
  H(iaxes).baseaxes = axespos(cfg.sliceaxes, iaxes);
  grid(H(iaxes).baseaxes,'on')

  if ~isempty(data)
    H(iaxes).overaxes = axespos(cfg.sliceaxes, iaxes);
  end

  % Get slices
  [Vbase,Ubase,Wbase] = helper_vol2slice(base.vol, vox2ras_0to1(base.vox2ras), cfg.xyz(iaxes,:), cfg.basemethod);

  if ~isempty(data)
    [Vover,Uover,Wover] = helper_vol2slice(data.vol, vox2ras_0to1(data.vox2ras), cfg.xyz(iaxes,:), cfg.method);
  end

  % Draw base/over slices
  switch (cfg.method)
    case 'mip'
      % - mip of overlay
      H(iaxes).overslice = helper_over(H(iaxes).overaxes, Vover, Uover, Wover, cfg);

      % - base contour
      H(iaxes).baseslice = helper_contour(H(iaxes).baseaxes, Vbase, Ubase, Wbase, cfg);

      % - mip-specific setting
      set(H(iaxes).baseaxes, 'color','none')
      axis(H(iaxes).baseaxes, 'image')

      % - equalize axes
      helper_equalizeaxes(H(iaxes).baseaxes, H(iaxes).overaxes)

    otherwise
      % - base image
      H(iaxes).baseslice = imagesc(H(iaxes).baseaxes, Ubase.axis, Wbase.axis, Vbase);

      % - overlay
      if ~isempty(data)
        H(iaxes).overslice = helper_over(H(iaxes).overaxes, Vover, Uover, Wover, cfg);
        helper_equalizeaxes(H(iaxes).baseaxes, H(iaxes).overaxes)
      end

      % - overlay-specific setting
      if ~cfg.showticks
        set(H(iaxes).baseaxes,'xtick',[],'ytick',[])
        grid(H(iaxes).baseaxes,'off')
      end

  end

  % - add contours
  if isfield(cfg,'contour')
    H(iaxes).contour = {};
    ncons = numel(cfg.contour);
    if ~isfield(cfg,'contourwidth'), cfg.contourwidth = 1; end
    if isfield(cfg,'contourcolormap')
      cmap = cfg.contourcolormap;
    else
      cmap = brewermap(ncons, 'Set1');
    end
    for icon = 1:ncons
      [Vi, U, W] = helper_vol2slice( ...
        cfg.contour{icon}.vol, vox2ras_0to1(cfg.contour{icon}.vox2ras), cfg.xyz(iaxes,:), 'nearest');
      if ~isempty(data)
        axes_ref = H(iaxes).overaxes;
      else
        axes_ref = H(iaxes).baseaxes;
      end
      H(iaxes).contour{icon} = helper_contour(axes_ref, Vi, U, W, cfg);
      H(iaxes).contour{icon}.Color = cmap(icon,:);
      H(iaxes).contour{icon}.LineWidth = cfg.contourwidth;
    end
  end

  % - add annotations

  % -- WORLD cooridinate (XYZ=RAS)
  xyzdim = find(~isnan(cfg.xyz(iaxes,:)));
  xyzlabel = 'XYZ';
  u1 = median(Ubase.axis);
  if not(isfield(cfg,'coordinatelocation_slice'))
    w1 = prctile(Wbase.axis,95);
  else
    w1 = Wbase.axis(1) + range(Wbase.axis) * cfg.coordinatelocation_slice;
  end
  text(H(iaxes).baseaxes, u1, w1, sprintf('%s = %.0f %s', xyzlabel(xyzdim), cfg.xyz(iaxes,xyzdim), cfg.unit), ...
    'fontsize',cfg.coordfontsize, 'color',cfg.coordfontcolor, 'HorizontalAlignment','center');

  % -- FILE NAME? TITLE BAR?


  % - common setting
  set(H(iaxes).baseaxes, 'DataAspectRatio',[1 1 1], 'Ydir','nor', 'Visible','off')
  colormap(H(iaxes).baseaxes, cfg.basecolormap)
  if cfg.showticks
    xlabel(H(iaxes).baseaxes, Ubase.axisname);
    ylabel(H(iaxes).baseaxes, Wbase.axisname);
    H(iaxes).baseaxes.FontSize = 7;
  end

  if ~isempty(data)
    set(H(iaxes).overaxes, 'visible','off', 'DataAspectRatio',[1 1 1], 'Ydir','nor')
    colormap(H(iaxes).overaxes, cfg.colormap)
    try
      clim(H(iaxes).overaxes, cfg.caxis)
    catch 
      warning('caxis not sane')
    end
    try
      clim(H(iaxes).baseaxes, cfg.basecaxis)
    catch 
      warning('caxis not sane')
    end
  else
    try
      clim(H(iaxes).baseaxes, cfg.basecaxis)
    catch 
      warning('caxis not sane')
    end
  end
end


%% Colorbar
iaxes = min(prod(cfg.layout), ceil(nslices/2)+1);
if ~isempty(data)
  apos = get(H(iaxes).overaxes,'position');
  H(iaxes).colorbar = colorbar(H(iaxes).overaxes);
  set(H(iaxes).overaxes,'position',apos)
else
  apos = get(H(iaxes).baseaxes,'position');
  H(iaxes).colorbar = colorbar(H(iaxes).baseaxes);
  set(H(iaxes).baseaxes,'position',apos)
end
H(iaxes).colorbar.Color = cfg.coordfontcolor;
H(iaxes).colorbar.Location = 'southOutside';
if isfield(cfg,'colorbarposition')
  H(iaxes).colorbar.Position = cfg.colorbarposition;
else
  H(iaxes).colorbar.Position = [.4 .41 .2 .02];
end
  
H(iaxes).colorbar.FontSize = cfg.coordfontsize;
if isfield(cfg,'colorbarxlabel')
  H(iaxes).colorbar.Label.String = cfg.colorbarxlabel;
end
if isfield(cfg,'colorbartitle')
  title(H(iaxes).colorbar, cfg.colorbartitle, 'color',cfg.coordfontcolor, 'interp','none')
end
if isfield(cfg,'colorbarvisible')
  H(iaxes).colorbar.Visible = cfg.colorbarvisible;
end

%% Title
if isfield(cfg,'title')
  title(cfg.title, 'color', cfg.coordfontcolor)
end

%% OUT
if isfield(cfg,'fname_png')
  if ~isfield(cfg,'dpi')
    cfg.dpi = 150;
  end
  r = rendererinfo;
  if contains(r.GraphicsRenderer, 'OpenGL')
    rendopt = '-opengl';
  else
    rendopt = '-painters';
  end
  export_fig(cfg.fname_png,['-r',num2str(cfg.dpi)],rendopt)
  close(cfg.figurehandle)
end
if ~nargout, clear H cfg; end

end
