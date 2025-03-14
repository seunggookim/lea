function createstimnsl(Job)
%CREATEMDLNSL creates Stimulus features using NSL toolbox
% createstimnsl(Job)
% Job requires:
%   .Fs
%   .Shift
%   .DnameStim
%   .FnamesStim

% Check inputs
FieldsNeeded = {'DnameStim','FnamesStim','Fs','Shift'};
for i = 1:numel(FieldsNeeded)
    assert(isfield(Job,FieldsNeeded{i}), 'Job."%s" NOT DEFINED!', FieldsNeeded{i});
end

% Check if all done already
NslMdls = {'env','onset','cochgram','filtcoch'};
isDone = true;
for iStim = 1:numel(Job.FnamesStim)
    DnOut = fullfile(Job.DnameStim, Job.StimNames{iStim});
    for iMdl = 1:numel(NslMdls)
        isDone = isDone && isfile(fullfile(DnOut, [NslMdls{iMdl},'.mat']));
    end
end
if isDone
    return
end

%% Not all done, let's create them.
logthis('Not all NSL-models are ready. Creating all-in-one...\n');

for iStim = 1:numel(Job.FnamesStim)
    % Read audio data ("WAVEFORM")
    [yWav, FsWav] = audioread(Job.FnamesStim{iStim});
    logthis('Filename="%s": nChans=%i: SamplingRate=%iHz\n', Job.FnamesStim{iStim}, size(yWav,2), FsWav);

    % Multichannels to Mono
    if size(yWav,2) > 1
        logthis('Multichannles given: averaging across channels.\n')
        yWav = mean(yWav,2);
    end

    % Set NSL filter parameters (see WAV2AUD, AUD2COR)
    FsAud = 8e3; % auditory nerve representation sampling rate
    assert(FsAud==16e3 || FsAud==8e3) % only 8 kHz or 16 kHz allowed
    loadload() % fill in other parameters with default values
    paras(4) = (FsAud==16e3)*0 + (FsAud==8e3)*-1; % shifted by # of octaves
    yWavResampled = resample(yWav, (0:numel(yWav)-1)/FsWav, FsAud);

    % Compute the Auditory Representation (i.e., cochleogram)
    logthis('Computing a cochelogram...\n');
    AudRep = wav2aud(yWavResampled, paras); % Time x Freq (128 chans)

    % Compute the Cortical Representation
    logthis('Computing a "filtered" cochleogram...\n')
    %{
Nakai et al. 2021: (music with vocals)
freq = 128 -> 20 bins
rv = 2 .^ (-1.5:0.5:3) % 10 rates [0.35, ..., 8] Hz
sv = 2 .^ (1.5:0.5:6)  % 10 scales [0.35, ..., 64] cyc/oct
PCA: 20*10*10 = 2000 -> 302 (99%)

Santoro et al., 2014: (speech, environmental, ...)
Freq = 180-7040 Hz -> 3 or 8 freq ranges
rv = 3 .^ (0:3)  % 4 rates  [1, 3, 9, 27] Hz
sv = 2 .^ (-1:2) % 4 scales [0.5, 1, 2, 4] cyc/oct
    %}

    %{
Temporal mod rate: to include slow temporal modulations
(Ding: speech, ~7 Hz; music, ~2 Hz) around 2 Hz
0.5, 1, 2, 4, 8, 16 (6 rates)
    %}
    rv = 2 .^ (-1:1:4);

    %{
Sepctral mod rate: to include finer spectral modulations (6 scales)
for 128 freq bins over 5.3 octaves: 24.15 bins/oct
: Nyquist limit is ~12 cyc/oct; 0.5, 1, .., 16 cyc/oct (6 scales)
    %}
    sv = 2 .^ (-1:1:4);

    FT = 0; % fullness of temporal margin
    FX = 0; % fullness of spectral margin
    BP = 0; % pure bandpass indicator (0=outer filters as LP/HP filters)
    Fn_ = [tempname,'.cor'];
    c = onCleanup(@() delete(Fn_));
    Mag = abs(aud2cor(AudRep, [paras FT FX BP], rv, sv, Fn_));
    % Average upward and downward temporal modulations:
    nTM = numel(rv);
    Mag = single((Mag(:,1:nTM,:,:) + Mag(:,nTM+1:end,:,:))/2);

    AdjFactor = 1*(FsAud==8e3) + 2*(FsAud==16e3);
    AudFreqs = 440 * 2 .^ ((-31:97)/24) * AdjFactor;
    AudFreqs(end) = []; % the highest channel is discarded.
    AudTimes = (0:size(AudRep,1)-1)'*(paras(1)/1000);

    % Downsample & Save
    for iMdl = 1:numel(NslMdls)
        StimMdl = NslMdls{iMdl};
        StimInfo = [];
        switch (StimMdl)
            case {'env'} % (variants): All Bandpass frequency summed:
                StimVal_125Hz = sum(AudRep(:,2:end-1), 2);
                StimInfo.StimMdl = StimMdl;
                StimInfo.Names = {sprintf('%04.0f-%4.0fHz', AudFreqs([2, end-1]))};
                StimInfo.Freqs = geomean(AudFreqs(2:end-1));
                StimTimes_125Hz = AudTimes;

            case {'onset'} % (variants): All Bandpass frequency summed, onset (rectified positive difference)
                StimVal_125Hz = [0; diff(sum(AudRep(:,2:end-1), 2))];
                StimInfo.StimMdl = StimMdl;
                StimInfo.Names = {sprintf('%04.0f-%4.0fHz', AudFreqs([2, end-1]))};
                StimInfo.Freqs = geomean(AudFreqs(2:end-1));
                StimTimes_125Hz = AudTimes;

            case {'cochgram'} % only "auditory nerve" representation
                StimInfo.StimMdl = StimMdl;
                nFbins = 16;
                StimVal_125Hz = zeros([size(AudRep,1),nFbins]);
                StimInfo.Freqs = zeros(nFbins,2);
                StimInfo.Names = cell(1,nFbins);
                for i = 1:nFbins
                    FromFreq = 1+(128/nFbins)*(i-1);
                    ToFreq = (128/nFbins)*i;
                    StimVal_125Hz(:,i) = mean(AudRep(:,FromFreq:ToFreq),2);
                    StimInfo.Freqs(i,:) = AudFreqs([FromFreq, ToFreq]);
                    StimInfo.Names{i} = sprintf('%04.0f-%4.0fHz', AudFreqs(FromFreq), AudFreqs(ToFreq));
                end
                clear i FromFreq ToFreq
                StimTimes_125Hz = AudTimes;

            case {'filtcoch'} % via Stationary Wavelet Transform:
                % StimVal: time x (rate-scale-freq)
                % mag: [#scales x #rates x #samples x #freq]
                % Average the magnitudes in frequency bins:
                nFbins = 8;
                StimVal_125Hz = zeros([size(Mag,1:3),nFbins]);
                StimInfo.Freqs = zeros(nFbins,2);
                for i = 1:nFbins
                    FromFreq = 1+(128/nFbins)*(i-1);
                    ToFreq = (128/nFbins)*i;
                    StimVal_125Hz(:,:,:,i) = mean(Mag(:,:,:,FromFreq:ToFreq),4);
                    StimInfo.Freqs(i,:) = AudFreqs([FromFreq, ToFreq]);
                end
                clear i FromFreq ToFreq

                % still [#scales x #rates x #times x #freqs].
                % permute it to [#rates x #scales x #freqs x #times]:
                StimVal_125Hz = permute(StimVal_125Hz, [2 1 4 3]);

                % Create names
                Names = cell(size(StimVal_125Hz,1:3));
                for iRate = 1:numel(rv)
                    for iScale = 1:numel(sv)
                        for iFreq = 1:nFbins
                            Names{iRate,iScale,iFreq} = sprintf('r%02i-s%02i-f%02i', iRate, iScale, iFreq);
                        end
                    end
                end
                clear iRate iScale iFreq
                StimInfo.Rates = rv;
                StimInfo.Scales = sv;

                % Add metainfo:
                StimInfo.StimMdl = StimMdl;

                % RESHAPE:
                StimInfo.Dim = size(StimVal_125Hz,1:3); % keep the original dimensions
                StimVal_125Hz = reshape(StimVal_125Hz, [], size(StimVal_125Hz,4))';
                StimTimes_125Hz = AudTimes;
                StimInfo.Names = reshape(Names, [], 1);
                clear Names
            otherwise
                error('Unrecognized StimMdl=%s', StimMdl)
        end

        % Downsample at the fMRI sampling rate for the common time frame (with rectification):
        StimVal = max(0, interp1(StimTimes_125Hz, StimVal_125Hz, Job.Times{iStim}', 'linear') );

        % Meta-info:
        StimInfo.Times = Job.Times{iStim}';
        StimInfo.TR_sec = 1/Job.Fs;

        % SAVE
        DnOut = fullfile(Job.DnameStim, Job.StimNames{iStim});
        if ~isfolder(DnOut), mkdir(DnOut); end
        save(fullfile(DnOut,[NslMdls{iMdl},'.mat']), 'StimVal', 'StimInfo')
    end
end


%% PCA once all stimuli are done.
% case {'filtcochpc'} % Principle components from the full mtfs
%{
Even with a coarser MTF grid (400 features), many of them are redundant.
e.g., 102/400 components can explain >99% of variance.
Furthermore, when downsampled from 21087 to 169 timepoints, 
40/400 components exaplain >99% of variance (16 f x 5 s x 5 r)
39/288 components exaplain >99% of variance (8 freqs x 6 scales x 6 rates)
%}
% For this, we need to have "filtcoch" computed for all stimuli.
% FIND the common loading after all stimuli are done:
for iStim = 1:3
    DnOut = fullfile(Job.DnameStim, Job.StimNames{iStim});
    FnPca = fullfile(fileparts(DnOut), 'filtcoch-pca.mat');
    [~,~] = mkdir(fileparts(FnPca));
    if ~isfile(FnPca)
        ThisJob = struct('FnPca',FnPca, 'StimNames', {Job.StimNames});
        createcommonpcfiltcoch(ThisJob);
        clear ThisJob
    end

    % Apply the common PC loadings to the features:
    That = load(fullfile(DnOut,'filtcoch.mat'));
    This = load(FnPca);
    Scores = (That.StimVal-mean(That.StimVal,1))*This.Pca.coeff;
    StimVal = Scores(:,1:This.Pca.order99);
    StimInfo = That.StimInfo;
    StimInfo = rmfield(StimInfo, {'Freqs','Rates','Scales','Dim'});
    StimInfo.Names = cellfun(@(x) sprintf('pc%02i',x), num2cell(1:This.Pca.order99), 'uni',0);
    StimInfo.StimMdl = 'filtcoch-pc';
    StimInfo.ExplVar = sum(This.Pca.explained(1:This.Pca.order99));
    StimInfo.FnamePca = FnPca;

    % SAVE
    save(fullfile(DnOut,'filtcoch-pc.mat'), 'StimVal', 'StimInfo')
end

end



function createcommonpcfiltcoch(Job)
% Job requires:
% .FnPca
% .StimNames

[DnStim,~,~] = fileparts(Job.FnPca);
StimMdl = 'filtcoch';

%% Check all StimMdl files are ready:
Job.FnamesStimMdl = cellfun(@(x) fullfile(DnStim,x,[StimMdl,'.mat']), Job.StimNames, 'uniformOutput',0);
validatefilenames(Job, 'FnamesStimMdl');

%% Now read and concatenate:
Y = []; idxStim = [];
for iStim = 1:numel(Job.StimNames)
    This = load(Job.FnamesStimMdl{iStim});
    Y = [Y; This.StimVal];
    idxStim = [idxStim; ones(size(This.StimVal,1),1)*iStim];
end
clear iStim
fprintf('[%s] StimMdl="%s", %i columns.\n', mfilename, StimMdl, size(Y,2))
fprintf('[%s] Concatenating %i stimuli: total %i timepoints.\n', mfilename, numel(Job.StimNames), size(Y,1))

%% Run PCA
Pca = [];
[Pca.coeff, Pca.score, Pca.latent, Pca.tsquared, Pca.explained] = pca(Y);
%{
Score = deMeanedData * Coeff
deMeanedData = Score * Coeff' OR Score * inv(Coeff)
    Because Coeff*Coeff' ~ Identity
%}
clear Y
Pca.order99 = find(cumsum(Pca.explained)>99,1,'first');
Pca.order95 = find(cumsum(Pca.explained)>95,1,'first');
logthis('%i/%i PCs explain >95%% of variance.\n', Pca.order95, size(Pca.coeff,2))
logthis('%i/%i PCs explain >99%% of variance.\n', Pca.order99, size(Pca.coeff,2))
Pca.idxStim = idxStim;
save(Job.FnPca, 'Job', 'Pca')

%% Visualize in 3D view
Layout = [1 1]*ceil(sqrt(Pca.order95));
figure('visible','off','position',[1 1 120*Layout(2) 120*Layout(1)])
axes = axeslayout(Layout,[.25, .03, .14, .25],[.02, .1, .02, .02]);
Caxis = winsorcaxis(reshape(Pca.coeff(:,1:Pca.order95),[],1));

Xtick = [1 numel(This.StimInfo.Scales)];
Xticklabel = This.StimInfo.Scales([1 end]);
Ytick = [1 numel(This.StimInfo.Rates)];
Yticklabel = This.StimInfo.Rates([1 end]);
Ztick = [1 size(This.StimInfo.Freqs,1)];
meanfreqs = mean(This.StimInfo.Freqs,2);
Zticklabel = cellfun(@(x) sprintf('%.1f',x), num2cell(meanfreqs([1 end])/1000), 'uni',0);

for iPc = 1:Pca.order95
    axespos(axes,iPc)
    showrsft(Pca.coeff(:,iPc), This.StimInfo, true)
    set(gca, 'Xtick',Xtick, 'Xticklabel',Xticklabel, 'Ytick',Ytick, 'Yticklabel',Yticklabel, ...
        'Ztick',Ztick, 'Zticklabel',Zticklabel);
    title(sprintf('PC%02i',iPc))
    caxis(Caxis)
    if iPc >1
        xlabel('');ylabel('');zlabel('')
    end
end
cb = colorbar('location','eastoutside');
set(cb,'Position',[0.9330    0.0577    0.0158    0.1416])
export_fig(strrep(Job.FnPca,'.mat','-95pcs-3D.png'),'-r100')
close(gcf)

%% Visualize in 2D view
Layout = [Pca.order95 1];
figure('visible','off', 'position',[1 1 80*numel(meanfreqs)/2*Layout(2) 75*Layout(1)])
axes = axeslayout(Layout,[.1, .05, .1, .1],[.02, .02, .02, .03]);
for iPc = 1:Pca.order95
    axespos(axes,iPc)
    showrsft(Pca.coeff(:,iPc), This.StimInfo, false)
    title(sprintf('PC%02i',iPc))
    caxis(Caxis)
    if iPc < Pca.order95
        xlabel('');ylabel('');zlabel('')
    end
end
cb = colorbar('location','southoutside');
set(cb,'Position',[0.15 0.02 0.20 0.005])

export_fig(strrep(Job.FnPca,'.mat','-95pcs-2D.png'),'-r100')
close(gcf)

end