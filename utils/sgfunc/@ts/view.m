function h = view(ts, cmd, cfg)
%TS/VIEW shows data depending on TS.Name ['fmri-*','eeg-*','bhv-*','stim-*']
%   VIEW(ts, CMD)
%   ts is a Ts object to view
%   CMD can be a function handle to apply to TS.Data
%   CMD can be a character vector or a string scalar specific to TS.Name
%      - fmri: 'firstvol' [default] | 'origmean' | 'origstd' | 'mask'
%      - eeg:
%      - bhv|stim:
%
%<strong>Examples</strong>:
%view(ts)               % view the default mode (the first volume for fmri data)
%view(ts, @mean)        % view the temporal mean
%view(ts, 'origmean')   % view the original mean of the fmri data before Z-scoring
%view(ts, 'origstd')    % view the original std of the fmri data before Z-scoring
%view(ts, 'firstvol')   % view the first volume of the fmri data
%view(ts, 'pca')        % view the first FIVE principal components of the fmri data
%
% see also TS
%
% (CC4-BY) seung-goo.kim@ae.mpg.de

if not(exist('cfg','var')), cfg = []; end
h = [];
DataType = strsplit(ts.Name,'-');
DataType = DataType{1};
assert(not(strcmpi(DataType, 'unnamed')), 'TS.Name = "unnamed"!')
eval(['view',DataType,'();']) % SEE NESTED FUNCTIONS below
if not(nargout)
  clear h
end

  function viewfmri()
    info_ = ts.DataInfo.UserData.Info;
    info_.ImageSize = info_.ImageSize(1:3);
    info_.PixelDimensions = info_.PixelDimensions(1:3);
    mri = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
    clear info_

    if not(exist('cmd','var'))
      cmd = 'firstvol';
    end
    if isa(cmd, 'function_handle')
      mri.vol(mri.info.Mask(:)) = feval(cmd, double(ts.Data));
    else
      switch lower(cmd)
        case 'firstvol'
          mri.vol(mri.info.Mask(:)) = ts.Data(1,:);

        case 'origmean'
          X = mean(ts.Data, 1, 'omitnan');
          if not(strcmpi(ts.DataInfo.UserData.Detrend.Method, 'none'))
            X = X + ts.DataInfo.UserData.Detrend.OrigMean;
          end
          if ts.DataInfo.UserData.Zscore.IsDone
            X = X + ts.DataInfo.UserData.Zscore.OrigMean;
          end
          mri.vol(mri.info.Mask(:)) = X;

        case 'origstd'
          X = std(ts.Data, [], 1, 'omitnan');
          if ts.DataInfo.UserData.Zscore.IsDone
            X = X + ts.DataInfo.UserData.Zscore.OrigStd;
          end
          mri.vol(mri.info.Mask(:)) = X;

        case 'mask'
          mri.vol(mri.info.Mask(:)) = 1;

        case 'pca'
          NUM_COMPO = min(5, size(ts.Data,1)-1);
          info_ = ts.DataInfo.UserData.Info;
          info_.ImageSize = info_.ImageSize(1:3);
          info_.PixelDimensions = info_.PixelDimensions(1:3);
          mri = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          [coef, scores, ~, ~, explained] = pca(ts.Data, NumComponents=NUM_COMPO);
          for iComp = 1:NUM_COMPO
            img_ = zeros(mri.info.ImageSize);
            img_(mri.info.Mask(:)) = coef(:,iComp);
            mri.vol(:,:,:,iComp) = img_;
          end
          mri.info.ImageSize(4) = NUM_COMPO;
          mri.info.PixelDimensions(4) = 1;
          base = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          try
            base.vol(mri.info.Mask(:)) = ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean;
          catch
            warning('Ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean not found!')
          end
          mri.cts = scores(:,1:NUM_COMPO);
          mri.cstcfg = struct(xTickLabels=ts.Time, xLabel=sprintf('Time [%s]', ts.TimeInfo.Units));
          mri.expl = explained;

        case 'mean'
          info_ = ts.DataInfo.UserData.Info;
          info_.ImageSize = info_.ImageSize(1:3);
          info_.PixelDimensions = info_.PixelDimensions(1:3);
          mri = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          mri.vol(mri.info.Mask(:)) = mean(ts.Data, 1);
          mri.info.ImageSize(4) = 1;
          mri.info.PixelDimensions(4) = 1;
          base = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          try
            base.vol(mri.info.Mask(:)) = ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean;
          catch
            warning('Ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean not found!')
          end

        otherwise
          error ('CMD="%s" not defined!', cmd)
      end
    end
    
    switch (cmd)
      case 'pca'
        h = slicespcts(base, mri, cfg);
      case 'mean'
        h = slices(base, mri, cfg);
      otherwise
        h = slices(mri, [], cfg); %, xyz=[0 nan nan; nan 0 nan; nan nan 0], layout=[1 3]));
    end

  end % of viewfmri()


  function vieweeg()
    % Colored plots + chan locs + mean topolot + std topoplot + skewedness topoplot
    origMean = mean(ts);
    if contains(ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + ts.DataInfo.UserData.Zscore.OrigMean;
      origUnits = ts.DataInfo.UserData.Zscore.OrigUnits;
    else
      origUnits = ts.DataInfo.Units;
    end

    origStd = std(ts);
    if ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf
    axes(Position=[.05 .35 .9 .6])
    if nChans > 64 % high-density EEG in a carpet plot
      imagesc(ts.Time, 1:nChans, ts.Data');
      hold on
      h = scatter(zeros(1,nChans), 1:nChans,'o','filled');
      h.CData = colorMap; axis xy
    else % standard (up to 64 channels) in a line plot
      plotlines(ts.Time, ts.Data, [], colorMap, LineWidth=1)
    end

    xlabel(sprintf('Time [%s] | Stim="%s", Subj="%s"', ts.TimeInfo.Units, ts.UserData.StimName, ts.UserData.SubjName))
    ylabel(sprintf('Channels [%s]', ts.DataInfo.Units))
    set(gca, yTick=[])

    axesLayout = axeslayout([1 4], [0 0 0 0], [.03 .08 .7 .0]);
    axesLayout.x(2:4) = axesLayout.x(2:4) - 0.05;

    axespos(axesLayout, 1)
    myeeg_plotchan(colorMap, ts.DataInfo.UserData.chanlocs)

    axespos(axesLayout, 2);
    topoplot(origMean, ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.44-0.04 .1 .01 .1];
    title(hcb, sprintf('Mean [%s]', origUnits))

    axespos(axesLayout, 3);
    topoplot(origStd.^2, ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.66-0.04 .1 .01 .1];
    title(hcb, sprintf('Var [%s^2]', origUnits))

    axespos(axesLayout, 4);
    topoplot(skewness(ts.Data), ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.88-0.04 .1 .01 .1];
    title(hcb, sprintf('Skew [%s^3]', origUnits))

    set(gcf, Color='w', Colormap=flipud(brewermap(256, 'spectral')))
  end

  function viewbhv()
    origMean = mean(ts);
    if contains(ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + ts.DataInfo.UserData.Zscore.OrigMean;
    end
    origStd = std(ts);
    if ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf

    axes(Position=[.05 .45 .9 .53])
    plotlines(ts.Time, ts.Data, [], colorMap, LineWidth=1)
    xlabel(sprintf('Time [%s] | Stim="%s", Subj="%s"', ts.TimeInfo.Units, ts.UserData.StimName, ts.UserData.SubjName))
    ylabel(sprintf('Ratings [%s]', ts.DataInfo.Units))
    set(gca, yTick=[])

    axesLayout = axeslayout([1 3], 'tight', [.08 .08 .65 .05]);
    axespos(axesLayout, 1)
    plotridgelines(cellfun(@(x) ts.Data(:,x), num2cell(1:nChans), Uni=0), colorMap)
    xlabel(sprintf('Ratings [%s]', ts.DataInfo.Units))
    set(gca, yTick=1:nChans, yTickLabel=ts.UserData.VariableNames)

    axespos(axesLayout, 2)
    imagesc(corr(ts.Data),[-1 1]); axis xy
    set(gca, yTick=1:nChans, yTickLabel=cellfun(@(x) x(1:3), ts.UserData.VariableNames, uni=0))
    set(gca, xTick=1:nChans, xTickLabel=cellfun(@(x) x(1:3), ts.UserData.VariableNames, uni=0), ...
      xTickLabelRotation=0)
    axis square; xlabel('Correlation matrix', FontWeight='bold'); ylabel('Variables')

    axespos(axesLayout, 3)
    imagesc(corr(ts.Data'),[-1 1]); axis xy; colorbaro
    axis square; ylabel('Time points'); xlabel('Temp corr matrix', FontWeight='bold')

  end


  function viewstim()
    origMean = mean(ts);
    if contains(ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + ts.DataInfo.UserData.Zscore.OrigMean;
    end
    origStd = std(ts);
    if ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf

    axes(Position=[.05 .35 .9 .6])
    plotlines(ts.Time, ts.Data, [], colorMap, LineWidth=1)
    xlabel(sprintf('Time [%s]', ts.TimeInfo.Units))
    ylabel(sprintf('Features [%s]', ts.DataInfo.Units))
    set(gca, yTick=[])
  end


end
