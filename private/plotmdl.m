function plotmdl(X, Y, Mdl, Itc, Rnd, Job)
% plotmdl(X, Y, Mdl, Rnd, Job)


%% Set up for a given modality
persistent MODALITY
MODALITY = Y{1}.Name;
switch MODALITY
  case 'fmri'
    myPath = fileparts(mfilename('fullpath'));
    Mni = fullfile(myPath,'..','utils','standards','MNI152_T1_2mm_brain.nii.gz');
    INFO = Y{1}.DataInfo.UserData.Info;
    FIG_POS = [800 800];
    axesLayout = axeslayout([3 3], [0 0 0 0], 'tight');
  case 'eeg'
    INFO = Y{1}.DataInfo.UserData.chanlocs;
    FIG_POS = [800 400];
    axesLayout = axeslayout([1 3], 'tight', 'tight');
  case 'bhv'
    INFO = Y{1}.UserData;
    FIG_POS = [600 250];
    axesLayout = axeslayout([1 3]);
  case 'toy'
    % INFO = Y{1}.UserData;
    FIG_POS = [600 600];
    % axesLayout = axeslayout([1 3]);
end
colors = get_colormap(3,1);
cmapR = flipud([linspacevec(colors(1,:), [1 1 1], 128); linspacevec([1 1 1], colors(3,:), 128)]);
cmapL = (brewermap(128,'greys'));
cmapL = flipud(cmapL(1:64+32,:));
cmapB = flipud([linspacevec(colors(2,:), [1 1 1], 128); linspacevec([1 1 1], colors(3,:), 128)]);


%% Additional: if ITC is computed:
if not(isempty(Itc))
  h = figure;
  h.Position(3:4) = [600 250];
  Avg = struct(r=Itc.Y.meanCorr);
  vars = ["r"];
  dictName = dictionary(["r"], ["ITC [r]"]);
  mriSections = [1];
  drawitc()
  fnPdf = strrep(Job.FnameMdl, '.mat', '_itc.pdf');
  exportgraphics(gcf, fnPdf); drawnow;
  logthis('Figure saved: '); ls(fnPdf)
end


%% Set up CV-averaged variables to plot
switch MODALITY
  case 'fmri'
    axesLayout = axeslayout([3 3], [0 0 0 0], 'tight');
  case 'eeg'
    axesLayout = axeslayout([1 3], 'tight', 'tight');
  case 'bhv'
    axesLayout = axeslayout([1 3]);
end
mriSections = [1 2 3];
Avg = struct(r=mean(Mdl.Acc,1), l=log10(geomean(Mdl.Lopt,1)), b=squeeze(mean(mean(Mdl.Bhat,1),2)));
vars = ["r", "l", "b"];
dictName = dictionary(["r", "l", "b"], ["Pred acc [r]","Lambda* [log10]", "Mean weight [au]"]);

%% Draw averaged values
h = figure;
h.Position(3:4) = FIG_POS;
eval(['draw',MODALITY,'()'])
set(h, Color='w')
drawnow;
fnPdf = strrep(Job.FnameMdl, '.mat', '_acc.pdf');
exportgraphics(gcf, fnPdf); drawnow;
logthis('Figure saved: '); ls(fnPdf)



%% TODO: if the randomization test is computed:
% if not(isempty(Rnd))
%   error('Now create this!')
% end


%% NESTED HELPER FUNCTIONS
  function drawitc()
    axesLayout = axeslayout([1 3]);
    eval(['draw',MODALITY,'()'])

    % ITC-Y
    axespos(axesLayout,2)
    bar(max(Itc.Y.subjCorr, [], 'omitnan'))
    xlabel('Trials'); ylabel('max ITC [r]'); title([MODALITY,'-ITC'])

    % ITC-X
    axespos(axesLayout,3)
    bar(max(Itc.Y.subjCorr, [], 'omitnan'))
    xlabel('Trials'); ylabel('max ITC [r]'); title('Feature-ITC')
    
  end


  function drawfmri()
    h_ax = nan(1,numel(vars)*numel(mriSections));
    for i = 1:numel(vars)

      Mri = struct(vol=nan(INFO.ImageSize(1:3), 'double'), info=INFO);
      Mri.vol(Mri.info.Mask(:)) = Avg.(vars(i));
      Base = Mri;
      Base.vol = Base.vol*inf;

      orientations = {'sag1','cor1','axi1'};
      for j = mriSections
        k = i+3*(j-1);
        h_ax(k) = axespos(axesLayout, k); axis off

        % create a slice with a contour of the MNI brain
        h_slice = slicein(Base, Mri, struct(method='linear', contour=Mni, contourcolormap=.5*[1 1 1], ...
          axes=h_ax(k), coordfontcolor='none', ncontourlevels=2, contourwidth=2, xyz=orientations{j}, ...
          caxis='maxabs'));
        h_slice.colorbar.Visible = 'off';
        if contains(dictName(vars(i)), 'E[')
          bgColor = [.985 .985 .900];
        else
          bgColor = [1 1 1];
        end
        colormap(h_slice.baseaxes, bgColor);
        h_img = h_slice.overaxes;
        TitleText = setcolormap(i, h_img, h_slice.colorbar);

        if j == 2 % a title between the sagittal and coronal sections
          title(h_ax(k), TitleText);
        end

        if j ==3 % a colorbar between the coronal and axial sections
          h_slice.colorbar.Visible = 'on';
          pos = get(h_ax(k), 'Position'); % [x y w h]
          width_margin = pos(3)*.6;
          pos(3) = pos(3) - width_margin;
          pos(1) = pos(1) + width_margin/2;
          pos(2) = pos(2) + pos(4);
          pos(4) = pos(4)*0.02;
          set(h_slice.colorbar, xColor='k', yColor='k', FontSize=9, Position=pos)
        end

      end
    end
  end


  function draweeg()
    h_ax = [];
    for i = 1:numel(vars)
      h_ax(i) = axespos(axesLayout, i);
      topoplot(Avg.(vars(i)), INFO); axis image
      h_ch = get(gca, 'children');
      h_ch(5).FaceColor = [1 1 1];
      if contains(dictName(vars(i)), 'E[')
        h_ch(5).FaceColor = [.985 .985 .850];
      end
    end
    for i = 1:numel(vars)
      h_cb = colorbar(h_ax(i), location='southoutside', FontSize=10);
      h_cb.Position(2) = h_cb.Position(2)-0.04; % [x y w h]
      width_margin = h_cb.Position(3)*.5;
      h_cb.Position(3) = h_cb.Position(3) - width_margin;
      h_cb.Position(1) = h_cb.Position(1) + width_margin/2;
      h_cb.Position(4) = h_cb.Position(4)*0.2;

      h_img = h_ax(i);
      TitleText = setcolormap(i, h_img, h_cb);
      title(h_ax(i), TitleText)
    end
  end


  function drawbhv()
    h_ax = [];
    for i = 1:numel(vars)
      h_ax(i) = axespos(axesLayout, i);
      h_b = bar(Avg.(vars(i)));
      yLabel = dictName(vars(i));
      set(h_ax(i), xTicklabel=INFO.VariableNames, FontSize=11)
      switch extract(vars(i),1)
        case "r"
          TitleText = sprintf('max %s = %.3f', dictName(vars(i)), max(Avg.(vars(i))));
          ylabel(yLabel); set(h_b, FaceColor=colors(1,:));
        case "l"
          TitleText = sprintf('min %s = %.2f', dictName(vars(i)), min(Avg.(vars(i))));
          ylabel(yLabel); set(h_b, FaceColor=0.75*[1 1 1]);
        case "b"
          TitleText = sprintf('max |%s| = %.3f', dictName(vars(i)), max(abs(Avg.(vars(i)))));
          ylabel(yLabel); set(h_b, FaceColor=colors(3,:));
      end
      h_t = title(h_ax(i), TitleText, FontSize=10.5, Color=.2*[1 1 1], FontWeight='normal');
      h_t.Position(2) = h_t.Position(2) + 0.08*diff(ylim(h_ax(i)));
      if contains(dictName(vars(i)),'E[')
        set(gca,'color',[.985 .985 .965])
      end
    end
  end


  function TitleText = setcolormap(i, h_img, h_cb)
    switch extract(vars(i),1)
      case "r"
        set(h_img, colormap=cmapR)
        title(h_cb, 'r')
        h_cb.Ruler.TickLabelRotation = 0;
        TitleText = sprintf('max %s = %.3f', dictName(vars(i)), max(Avg.(vars(i))));
      case "l"
        set(h_img, colormap=cmapL);
        title(h_cb, 'log\lambda')
        h_cb.Ruler.TickLabelRotation = 0;
        TitleText = sprintf('min %s = %.2f', dictName(vars(i)), min(Avg.(vars(i))));
      case "b"
        set(h_img, colormap=cmapB)
        title(h_cb, 'b')
        h_cb.Ruler.TickLabelRotation = 0;
        TitleText = sprintf('max |%s| = %.3f', dictName(vars(i)), max(abs(Avg.(vars(i)))));
    end
  end



  function drawtoy()
    Data = delaydata(X, Y, Job);

    set(gcf, Colormap = flipud(brewermap(256,'Spectral')) );
    AxesPos = axeslayout([3 3]);

    axespos(AxesPos,1); imagesc(X{1}.Data); colorbar;
    Title = 'X_1';
    if isfield(Job,'TempGaussWin')
      Title = sprintf('%s | TempGaussWin=%i smp', Title, Job.TempGaussWin);
    end
    title(Title)
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    xlabel('Feature#'); ylabel('Sample#');

    axespos(AxesPos,2); imagesc(Y{1}.Data); colorbar;
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    Title = 'Y_1';
    if isfield(Job,'EffectSize')
      Title = sprintf('%s | EffectSize=%i smp', Title, Job.EffectSize);
    end
    title(Title)
    xlabel('Response#'); ylabel('Sample#')

    axespos(AxesPos,4); imagesc(Data(1).X); colorbar; title('Xc_1')
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    xlabel('Predictor#'); ylabel('Sample#');

    axespos(AxesPos,5); imagesc(Data(1).Y); colorbar;
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    Title = 'Yc_1';
    if isfield(Job,'EffectSize')
      Title = sprintf('%s | EffectSize=%i smp', Title, Job.EffectSize);
    end
    title(Title)
    xlabel('Response#'); ylabel('Sample#')

    nPred = size(Data(1).X, 2);
    nResp = size(Data(1).Y, 2);
    axespos(AxesPos,3); imagesc(reshape(mean(Mdl.Bhat,1), [nPred, nResp]));
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    colorbar; title('mean B-hat [w/ intercept]')
    xlabel('Response#'); ylabel('Predictor#')

    axespos(AxesPos,6); imagesc(log10(Mdl.Lopt)); colorbar; title('log_{10}\lambda')
    cL = clim(); clim([-max(abs(cL)), +max(abs(cL))])
    xlabel('Response#'); ylabel('Fold#')

    axespos(AxesPos,7); imagesc(Mdl.Acc); colorbar; title('Acc [r]')
    clim([-1 1]); xlabel('Response#'); ylabel('Fold#')

    if not(isempty(Rnd))
      axespos(AxesPos,8);
      nResp = size(Rnd.AccRnd,2);
      X_ = cellfun(@(x) Rnd.AccRnd(:,x), num2cell(1:nResp), 'Uni',0);
      plotridgelines(X_, brewermap(nResp,'Set2'), 1, [], [], mean(Mdl.Acc,1))
      ylabel('Response#'); xlabel('Pred. Acc. [r]'); xlim([-1 1])
      title(sprintf('Obs. vs. null (k=%i)', Job.nRands))

      axespos(AxesPos,9);
      bar(-log10(Rnd.PvalFdr)); xlabel('Response#'); ylabel('-log_{10}(P_{fdr})')
      yline(-log10(0.01), color=[0.8500    0.3250    0.0980], LineWidth=2)
      title('FDR-adjusted P-values')
    end
  end

end
