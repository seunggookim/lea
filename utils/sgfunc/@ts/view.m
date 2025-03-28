function h = view(Ts, cmd)
%TS/VIEW shows data depending on TS.Name ['fmri-*','eeg-*','bhv-*','stim-*']
%   VIEW(TS, CMD)
%   TS is a TS object to view
%   CMD can be a function handle to apply to TS.Data
%   CMD can be a character vector or a string scalar specific to TS.Name
%      - fmri: 'firstvol' [default] | 'origmean' | 'origstd' | 'mask'
%      - eeg:
%      - bhv|stim:
%
%<strong>Examples</strong>:
%view(Ts)               % view the default mode (the first volume for fmri data)
%view(TS, @mean)        % view the temporal mean
%view(Ts, 'origmean')   % view the original mean of the fmri data before Z-scoring
%view(Ts, 'origstd')    % view the original std of the fmri data before Z-scoring
%view(Ts, 'firstvol')   % view the first volume of the fmri data
%view(Ts, 'pca')        % view the first FIVE principal components of the fmri data
%
% see also TS
%
% (CC4-BY) 2024-2025, seung-goo.kim@ae.mpg.de

h = [];
DataType = strsplit(Ts.Name,'-');
DataType = DataType{1};
assert(not(strcmpi(DataType, 'unnamed')), 'TS.Name = "unnamed"!')
eval(['view',DataType,'();']) % SEE NESTED FUNCTIONS below
if not(nargout)
  clear h
end

  function viewfmri()
    info_ = Ts.DataInfo.UserData.Info;
    info_.ImageSize = info_.ImageSize(1:3);
    info_.PixelDimensions = info_.PixelDimensions(1:3);
    Mri = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
    clear info_

    if not(exist('cmd','var'))
      cmd = 'firstvol';
    end
    if isa(cmd, 'function_handle')
      Mri.vol(Mri.info.Mask(:)) = feval(cmd, double(Ts.Data));
    else
      switch lower(cmd)
        case 'firstvol'
          Mri.vol(Mri.info.Mask(:)) = Ts.Data(1,:);

        case 'origmean'
          X = mean(Ts.Data, 1, 'omitnan');
          if not(strcmpi(Ts.DataInfo.UserData.Detrend.Method, 'none'))
            X = X + Ts.DataInfo.UserData.Detrend.OrigMean;
          end
          if Ts.DataInfo.UserData.Zscore.IsDone
            X = X + Ts.DataInfo.UserData.Zscore.OrigMean;
          end
          Mri.vol(Mri.info.Mask(:)) = X;

        case 'origstd'
          X = std(Ts.Data, [], 1, 'omitnan');
          if Ts.DataInfo.UserData.Zscore.IsDone
            X = X + Ts.DataInfo.UserData.Zscore.OrigStd;
          end
          Mri.vol(Mri.info.Mask(:)) = X;

        case 'mask'
          Mri.vol(Mri.info.Mask(:)) = 1;

        case 'pca'
          NUM_COMPO = min(5, size(Ts.Data,1));
          info_ = Ts.DataInfo.UserData.Info;
          info_.ImageSize = info_.ImageSize(1:3);
          info_.PixelDimensions = info_.PixelDimensions(1:3);
          Mri = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          Data = double(Ts.Data);
          Data(isnan(Data(:))) = mean(Data(:), 'omitnan');
          [coef, scores, ~, ~, explained] = pca(Data, NumComponents=NUM_COMPO);
          for iComp = 1:NUM_COMPO
            img_ = zeros(Mri.info.ImageSize);
            img_(Mri.info.Mask(:)) = coef(:,iComp);
            Mri.vol(:,:,:,iComp) = img_;
          end
          Mri.info.ImageSize(4) = NUM_COMPO;
          Mri.info.PixelDimensions(4) = 1;
          Base = struct(vol=zeros(info_.ImageSize, 'double'), info=info_);
          try
            Base.vol(Mri.info.Mask(:)) = Ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean;
          catch
            warning('Ts.UserData.OrigDataInfo.UserData.Detrend.OrigMean not found!')
          end
          Mri.ts = scores(:,1:NUM_COMPO);
          Mri.expl = explained;

        otherwise
          error ('CMD="%s" not defined!', cmd)
      end
    end
    
    if strcmpi(cmd, 'pca')
      h = slicespcts(Base, Mri);
    else
      figure;
      h = slices(Mri, [], struct(figurehandle=gcf)); %, xyz=[0 nan nan; nan 0 nan; nan nan 0], layout=[1 3]));
    end

  end % of viewfmri()


  function vieweeg()
    % Colored plots + chan locs + mean topolot + std topoplot + skewedness topoplot
    origMean = mean(Ts);
    if contains(Ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + Ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if Ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + Ts.DataInfo.UserData.Zscore.OrigMean;
      origUnits = Ts.DataInfo.UserData.Zscore.OrigUnits;
    else
      origUnits = Ts.DataInfo.Units;
    end

    origStd = std(Ts);
    if Ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + Ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(Ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf
    axes(Position=[.05 .35 .9 .6])
    if nChans > 64 % high-density EEG in a carpet plot
      imagesc(Ts.Time, 1:nChans, Ts.Data');
      hold on
      h = scatter(zeros(1,nChans), 1:nChans,'o','filled');
      h.CData = colorMap; axis xy
    else % standard (up to 64 channels) in a line plot
      plotlines(Ts.Time, Ts.Data, [], colorMap, LineWidth=1)
    end

    xlabel(sprintf('Time [%s] | Stim="%s", Subj="%s"', Ts.TimeInfo.Units, Ts.UserData.StimName, Ts.UserData.SubjName))
    ylabel(sprintf('Channels [%s]', Ts.DataInfo.Units))
    set(gca, yTick=[])

    axesLayout = axeslayout([1 4], [0 0 0 0], [.03 .08 .7 .0]);
    axesLayout.x(2:4) = axesLayout.x(2:4) - 0.05;

    axespos(axesLayout, 1)
    myeeg_plotchan(colorMap, Ts.DataInfo.UserData.chanlocs)

    axespos(axesLayout, 2);
    topoplot(origMean, Ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.44-0.04 .1 .01 .1];
    title(hcb, sprintf('Mean [%s]', origUnits))

    axespos(axesLayout, 3);
    topoplot(origStd.^2, Ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.66-0.04 .1 .01 .1];
    title(hcb, sprintf('Var [%s^2]', origUnits))

    axespos(axesLayout, 4);
    topoplot(skewness(Ts.Data), Ts.DataInfo.UserData.chanlocs);
    hcb = colorbar;
    hcb.Position = [.88-0.04 .1 .01 .1];
    title(hcb, sprintf('Skew [%s^3]', origUnits))

    set(gcf, Color='w', Colormap=flipud(brewermap(256, 'spectral')))
  end

  function viewbhv()
    origMean = mean(Ts);
    if contains(Ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + Ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if Ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + Ts.DataInfo.UserData.Zscore.OrigMean;
    end
    origStd = std(Ts);
    if Ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + Ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(Ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf

    axes(Position=[.05 .45 .9 .53])
    plotlines(Ts.Time, Ts.Data, [], colorMap, LineWidth=1)
    xlabel(sprintf('Time [%s] | Stim="%s", Subj="%s"', Ts.TimeInfo.Units, Ts.UserData.StimName, Ts.UserData.SubjName))
    ylabel(sprintf('Ratings [%s]', Ts.DataInfo.Units))
    set(gca, yTick=[])

    axesLayout = axeslayout([1 3], 'tight', [.08 .08 .65 .05]);
    axespos(axesLayout, 1)
    plotridgelines(cellfun(@(x) Ts.Data(:,x), num2cell(1:nChans), Uni=0), colorMap)
    xlabel(sprintf('Ratings [%s]', Ts.DataInfo.Units))
    set(gca, yTick=1:nChans, yTickLabel=Ts.UserData.VariableNames)

    axespos(axesLayout, 2)
    imagesc(corr(Ts.Data),[-1 1]); axis xy
    set(gca, yTick=1:nChans, yTickLabel=cellfun(@(x) x(1:3), Ts.UserData.VariableNames, uni=0))
    set(gca, xTick=1:nChans, xTickLabel=cellfun(@(x) x(1:3), Ts.UserData.VariableNames, uni=0), ...
      xTickLabelRotation=0)
    axis square; xlabel('Correlation matrix', FontWeight='bold'); ylabel('Variables')

    axespos(axesLayout, 3)
    imagesc(corr(Ts.Data'),[-1 1]); axis xy; colorbaro
    axis square; ylabel('Time points'); xlabel('Temp corr matrix', FontWeight='bold')

  end


  function viewstim()
    origMean = mean(Ts);
    if contains(Ts.DataInfo.UserData.Detrend.Method, ["constant", "linear"])
      origMean = origMean + Ts.DataInfo.UserData.Detrend.OrigMean;
    end
    if Ts.DataInfo.UserData.Zscore.IsDone
      origMean = origMean + Ts.DataInfo.UserData.Zscore.OrigMean;
    end
    origStd = std(Ts);
    if Ts.DataInfo.UserData.Zscore.IsDone
      origStd = origStd + Ts.DataInfo.UserData.Zscore.OrigStd;
    end
    nChans = size(Ts.Data,2);
    colorMap = get_colormap(round(nChans*1.2),1);
    colorMap = colorMap(1:nChans,:);

    clf

    axes(Position=[.05 .35 .9 .6])
    plotlines(Ts.Time, Ts.Data, [], colorMap, LineWidth=1)
    xlabel(sprintf('Time [%s]', Ts.TimeInfo.Units))
    ylabel(sprintf('Features [%s]', Ts.DataInfo.Units))
    set(gca, yTick=[])
  end


end
