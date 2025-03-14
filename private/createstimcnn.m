function createstimcnn(Job)
%CREATEMDLCNN creates Stimulus features using CNN models implemented in MATLAB Deep
%Learning Toolbox .(R2020b/R2021a/..)
% createmdles(Job)
% Job requires:
%   .Fs
%   .Shift
%   .DnameStim
%   .FnamesStim
%   .StimNames
%
% (CC4-BY) 2023, dr.seunggoo.kim@gmail.com

%{
In MATLAB Deep Learning Toolbox, CNNs are ported as:
>> VGGISH_NETWORK = vggish;
>> VGGISH_NETWORK.Layers
 1*  'InputBatch'         Image Input         96×64×1 images
 2   'conv1'              2-D Convolution     64 3×3×1 convolutions with stride [1  1] and padding 'same'
 3   'relu'               ReLU                ReLU
 4*  'pool1'              2-D Max Pooling     2×2 max pooling with stride [2  2] and padding 'same'
 5   'conv2'              2-D Convolution     128 3×3×64 convolutions with stride [1  1] and padding 'same'
 6   'relu2'              ReLU                ReLU
 7*  'pool2'              2-D Max Pooling     2×2 max pooling with stride [2  2] and padding 'same'
 8   'conv3_1'            2-D Convolution     256 3×3×128 convolutions with stride [1  1] and padding 'same'
 9   'relu3_1'            ReLU                ReLU
10   'conv3_2'            2-D Convolution     256 3×3×256 convolutions with stride [1  1] and padding 'same'
11   'relu3_2'            ReLU                ReLU
12*  'pool3'              2-D Max Pooling     2×2 max pooling with stride [2  2] and padding 'same'
13   'conv4_1'            2-D Convolution     512 3×3×256 convolutions with stride [1  1] and padding 'same'
14   'relu4_1'            ReLU                ReLU
15   'conv4_2'            2-D Convolution     512 3×3×512 convolutions with stride [1  1] and padding 'same'
16   'relu4_2'            ReLU                ReLU
17*  'pool4'              2-D Max Pooling     2×2 max pooling with stride [2  2] and padding 'same'
18   'fc1_1'              Fully Connected     4096 fully connected layer
19   'relu5_1'            ReLU                ReLU
20   'fc1_2'              Fully Connected     4096 fully connected layer
21   'relu5_2'            ReLU                ReLU
22   'fc2'                Fully Connected     128 fully connected layer
23   'EmbeddingBatch'     ReLU                ReLU
24*  'regressionoutput'   Regression Output   mean-squared-error [the output of PREDICT and VGGISHEMBEDDINGS]

01	InputBat	[ 96 x  64 x     1]
02	conv1   	[ 96 x  64 x    64]
03	relu    	[ 96 x  64 x    64]
04	pool1   	[ 48 x  32 x    64]
05	conv2   	[ 48 x  32 x   128]
06	relu2   	[ 48 x  32 x   128]
07	pool2   	[ 24 x  16 x   128]
08	conv3_1 	[ 24 x  16 x   256]
09	relu3_1 	[ 24 x  16 x   256]
10	conv3_2 	[ 24 x  16 x   256]
11	relu3_2 	[ 24 x  16 x   256]
12	pool3   	[ 12 x   8 x   256]
13	conv4_1 	[ 12 x   8 x   512]
14	relu4_1 	[ 12 x   8 x   512]
15	conv4_2 	[ 12 x   8 x   512]
16	relu4_2 	[ 12 x   8 x   512]
17	pool4   	[  6 x   4 x   512]
18	fc1_1   	[  1 x   1 x  4096]
19	relu5_1 	[  1 x   1 x  4096]
20	fc1_2   	[  1 x   1 x  4096]
21	relu5_2 	[  1 x   1 x  4096]
22	fc2     	[  1 x   1 x   128]
23	Embeddin	[  1 x   1 x   128]
24	regressi	[  1 x   1 x   128]


>> OPENL3_NETWORK = openl3(SpectrumType='mel128', EmbeddingLength=512, ContentType='music');
>> OPENL3_NETWORK.Layers
 1*  'in'                       Image Input           128×199×1 images
 2   'batch_normalization_33'   Batch Normalization   Batch normalization with 1 channels
 3   'conv2d_29'                2-D Convolution       64 3×3×1 convolutions with stride [1  1] and padding 'same'
 4   'batch_normalization_34'   Batch Normalization   Batch normalization with 64 channels
 5*  'activation_29'            ReLU                  ReLU
 6   'conv2d_30'                2-D Convolution       64 3×3×64 convolutions with stride [1  1] and padding 'same'
 7   'batch_normalization_35'   Batch Normalization   Batch normalization with 64 channels
 8*  'activation_30'            ReLU                  ReLU
 9   'max_pooling2d_17'         2-D Max Pooling       2×2 max pooling with stride [2  2] and padding [0  0  0  0]
10   'conv2d_31'                2-D Convolution       128 3×3×64 convolutions with stride [1  1] and padding 'same'
11   'batch_normalization_36'   Batch Normalization   Batch normalization with 128 channels
12*  'activation_31'            ReLU                  ReLU
13   'conv2d_32'                2-D Convolution       128 3×3×128 convolutions with stride [1  1] and padding 'same'
14   'batch_normalization_37'   Batch Normalization   Batch normalization with 128 channels
15*  'activation_32'            ReLU                  ReLU
16   'max_pooling2d_18'         2-D Max Pooling       2×2 max pooling with stride [2  2] and padding [0  0  0  0]
17   'conv2d_33'                2-D Convolution       256 3×3×128 convolutions with stride [1  1] and padding 'same'
18   'batch_normalization_38'   Batch Normalization   Batch normalization with 256 channels
19*  'activation_33'            ReLU                  ReLU
20   'conv2d_34'                2-D Convolution       256 3×3×256 convolutions with stride [1  1] and padding 'same'
21   'batch_normalization_39'   Batch Normalization   Batch normalization with 256 channels
22*  'activation_34'            ReLU                  ReLU
23   'max_pooling2d_19'         2-D Max Pooling       2×2 max pooling with stride [2  2] and padding [0  0  0  0]
24   'conv2d_35'                2-D Convolution       512 3×3×256 convolutions with stride [1  1] and padding 'same'
25   'batch_normalization_40'   Batch Normalization   Batch normalization with 512 channels
26*  'activation_35'            ReLU                  ReLU
27   'audio_embedding_layer'    2-D Convolution       512 3×3×512 convolutions with stride [1  1] and padding 'same'
28   'max_pooling2d_20'         2-D Max Pooling       16×24 max pooling with stride [16  24] and padding 'same'
29   'flatten'                  Keras Flatten         Flatten activations into 1-D assuming C-style (row-major) order
30*  'out'                      Regression Output     mean-squared-error [the output of PREDICT and OPENL3EMBEDDINGS]

01	in      	[ 128 x  199 x     1]
02	batch_no	[ 128 x  199 x     1]
03	conv2d_2	[ 128 x  199 x    64]
04	batch_no	[ 128 x  199 x    64]
05	activati	[ 128 x  199 x    64]
06	conv2d_3	[ 128 x  199 x    64]
07	batch_no	[ 128 x  199 x    64]
08	activati	[ 128 x  199 x    64]
09	max_pool	[  64 x   99 x    64]
10	conv2d_3	[  64 x   99 x   128]
11	batch_no	[  64 x   99 x   128]
12	activati	[  64 x   99 x   128]
13	conv2d_3	[  64 x   99 x   128]
14	batch_no	[  64 x   99 x   128]
15	activati	[  64 x   99 x   128]
16	max_pool	[  32 x   49 x   128]
17	conv2d_3	[  32 x   49 x   256]
18	batch_no	[  32 x   49 x   256]
19	activati	[  32 x   49 x   256]
20	conv2d_3	[  32 x   49 x   256]
21	batch_no	[  32 x   49 x   256]
22	activati	[  32 x   49 x   256]
23	max_pool	[  16 x   24 x   256]
24	conv2d_3	[  16 x   24 x   512]
25	batch_no	[  16 x   24 x   512]
26	activati	[  16 x   24 x   512]
27	audio_em	[  16 x   24 x   512]
28	max_pool	[   1 x    1 x   512]
29	flatten 	[   1 x    1 x   512]
30	out     	[   1 x    1 x   512]

%}

% Check required inputs
validatefields(Job, {'DnameStim','FnamesStim','Fs','Shift'})

%% RUN Deep Learning Toolbox to extract activations
MdlNames = {'vggish','openl3'};
MdlLongnames = {'vggish-audioset','openl3-music-mel128-emb512'};
LayerIndices = {
  [1:24] %[1 4 7 12 17 24]  % VGGISH
  [2 5 8 12 15 19 22 26 30]  % OPENL3
  };
Networks = {
  vggish
  openl3(ContentType='music', SpectrumType='mel128', EmbeddingLength=512)
  };
PrepFuncs = {
  @vggishPreprocessWithDims
  @openl3PreprocessWithDims
  };
Options = {
  {'OverlapPercentage',50}  % VGGISH
  {'OverlapPercentage',50, 'SpectrumType','mel128'}  % OPENL3
  };

for iMdl = 1:numel(MdlNames)
  for iStim = 1:numel(Job.StimNames)
    DnOut = fullfile(Job.DnameStim, Job.StimNames{iStim});
    IsAllDone = cellfun(@isfile, cellfun(@(x) ...
      fullfile(DnOut, sprintf('%s-l%02i.mat', MdlNames{iMdl}, x)), num2cell(LayerIndices{iMdl}), 'uni',0) );
    if IsAllDone
      continue
    end

    [AudioIn, Fs] = audioread(Job.FnamesStim{iStim});
    AudioIn = mean(AudioIn,2); % stereo -> mono
    OptArgs = Options{iMdl};
    logthis('Extracting Mel-spectrogram from an audio file "%s" for a model "%s"...\n', ...
      Job.FnamesStim{iStim}, MdlLongnames{iMdl})
    [MelSpect, Times_images] = feval( PrepFuncs{iMdl}, AudioIn, Fs, OptArgs{:} );

    for iLayer = LayerIndices{iMdl}
      FnOut = fullfile(DnOut, sprintf('%s-l%02i.mat', MdlNames{iMdl}, iLayer));
      if isfile(FnOut)
        continue % next layer
      end

      % EXTRACT activations (Faster with GPU):
      LayerName_ = Networks{iMdl}.Layers(iLayer).Name;
      logthis('Extracting activations from layer [%02i:"%s"]...\n', iLayer, LayerName_)
      Act_ = activations(Networks{iMdl}, MelSpect, LayerName_);
      assert(ndims(Act_)==4)
      Act_ = reshape(Act_, [], size(Act_,4))'; % Times x [all other dimensions]

      % DOWN-SAMPLE to the "common time frame" & RECTIFY:
      StimVal = max(interp1(Times_images, Act_, Job.Times{iStim}, 'linear'), 0);

      % META-DATA:
      StimInfo = [];
      StimInfo.StimMdl = sprintf('%s:layer%i02:%s', MdlLongnames{iMdl}, iLayer, LayerName_);
      StimInfo.Names = cellfun(@(x) sprintf('lay%02i-dim%04i', iLayer, x), num2cell(1:size(Act_,2)), 'uni',0);
      StimInfo.Times = Job.Times{iStim};
      StimInfo.TR_sec = 1/Job.Fs;

      % SAVE:
      logthis('Saving down-sampled activations...\n')
      save(FnOut, 'StimInfo', 'StimVal', '-v7.3') % okay it's getting bigger than 2GB
      logthis('File created: "%s"\n', FnOut)

      clear *_ StimVal StimInfo FnOut
    end % iLayer
  end % iStim
end % iMdl


%% Now PCA:
for iMdl = 1:numel(MdlNames)
  for iLayer = LayerIndices{iMdl}
    MdlPrefix = sprintf('%s-l%02i', MdlNames{iMdl}, iLayer);

    % Read data
    X_ = []; idxStim_ = []; Stim_ = {};
    for iStim = 1:numel(Job.FnamesStim)
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'.mat']);
      Stim_{iStim} = load(FnMat);
      nPnts = size(Stim_{iStim}.StimVal,1);
      assert(numel(Stim_{iStim}.StimInfo.Times) == nPnts, 'StimVal #row != StimInfo.Times #elem ?!')
      fprintf(':  Stim%i=%i pnts', iStim, nPnts)
      X_ = [X_; Stim_{iStim}.StimVal];
      idxStim_ = [idxStim_; iStim*ones(nPnts,1)];
    end
    assert(size(X_,1) == numel(idxStim_), '#timepoints not match!')
    fprintf('\n')
    logthis('Concatenated activations dim = [%i, %i]\n', size(X_))

    FnPca = fullfile(Job.DnameStim, [MdlPrefix,'-pca.mat']);
    logthis('%s:layer%02i',MdlLongnames{iMdl}, iLayer)
    if isfile(FnPca)
      load(FnPca, 'Pca')
    else
      % Run PCA together
      Pca = [];
      [Pca.coeff, Pca.scores, Pca.latent, Pca.tsquare, Pca.explained] = pca(X_);
      Pca.order95 = find(cumsum(Pca.explained)>95, 1, 'first');
      Pca.order99 = find(cumsum(Pca.explained)>99, 1, 'first');
      Pca.idxStim = idxStim_;
      nComp = size(Pca.explained,1);
      logthis('#PC(95%%)=%i/%i:   #PC(99%%)=%i/%i\n', Pca.order95, nComp, Pca.order99, nComp)
      save(FnPca, 'Pca', '-v7.3')
    end

    %% Visualize PCA results
    figure('position',[338 378 1000 1200], 'visible','off')
    subplot(321); imagesc(Pca.coeff); ylabel('PCs'); xlabel('Feat dims')
    subplot(322); imagesc(Pca.scores); ylabel('Concatenated timepoints'); xlabel('PCs');
    subplot(323); imagesc(Pca.coeff(1:50,:)); ylabel('First 50 PCs'); xlabel('Feat dims');
    subplot(324); imagesc(Pca.scores(:,1:50)); ylabel('Concatenated timepoints'); xlabel('First 50 PCs');
    subplot(325); plot(cumsum(Pca.explained), 'linewidth',2); xlabel('Pcs'); ylabel('Explained variance [%]')
    xline(Pca.order95, 'color','g'); xline(Pca.order99, 'color','r')
    export_fig(strrep(FnPca,'.mat','.png'))
    close(gcf)

    %% Put back to each stim
    for iStim = 1:numel(Job.FnamesStim)

      % Top 99% PCs
      StimVal = Pca.scores(Pca.idxStim == iStim, 1:Pca.order99);
      StimInfo = Stim_{iStim}.StimInfo;
      StimInfo.StimMdl = [MdlNames{iMdl},'-pc'];
      StimInfo.Names = cellfun(@(x) sprintf('pc%03i',x), num2cell(1:size(StimVal,2)), 'uni',0);
      assert(numel(StimInfo.Times) == size(StimVal,1), 'StimVal #row != StimInfo.Times #elem ?!')
      assert(numel(StimInfo.Names) == size(StimVal,2), 'StimVal #col != StimInfo.Names #elem ?!')
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'-pc.mat']);
      save(FnMat, 'StimInfo', 'StimVal', '-v7.3')
      clear StimInfo StimVal

      % Top 10 PCs
      StimVal = Pca.scores(Pca.idxStim == iStim, 1:min(10,size(Pca.scores,2)));
      StimInfo = Stim_{iStim}.StimInfo;
      StimInfo.StimMdl = [MdlNames{iMdl},'-pc10'];
      StimInfo.Names = cellfun(@(x) sprintf('pc%03i',x), num2cell(1:size(StimVal,2)), 'uni',0);
      assert(numel(StimInfo.Times) == size(StimVal,1), 'StimVal #row != StimInfo.Times #elem ?!')
      assert(numel(StimInfo.Names) == size(StimVal,2), 'StimVal #col != StimInfo.Names #elem ?!')
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'-pc10.mat']);
      save(FnMat, 'StimInfo', 'StimVal', '-v7.3')

      % Top 20 PCs
      StimVal = Pca.scores(Pca.idxStim == iStim, 1:min(20,size(Pca.scores,2)));
      StimInfo = Stim_{iStim}.StimInfo;
      StimInfo.StimMdl = [MdlNames{iMdl},'-pc20'];
      StimInfo.Names = cellfun(@(x) sprintf('pc%03i',x), num2cell(1:size(StimVal,2)), 'uni',0);
      assert(numel(StimInfo.Times) == size(StimVal,1), 'StimVal #row != StimInfo.Times #elem ?!')
      assert(numel(StimInfo.Names) == size(StimVal,2), 'StimVal #col != StimInfo.Names #elem ?!')
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'-pc20.mat']);
      save(FnMat, 'StimInfo', 'StimVal', '-v7.3')

      % Top 50 PCs
      StimVal = Pca.scores(Pca.idxStim == iStim, 1:min(50,size(Pca.scores,2)));
      StimInfo = Stim_{iStim}.StimInfo;
      StimInfo.StimMdl = [MdlNames{iMdl},'-pc50'];
      StimInfo.Names = cellfun(@(x) sprintf('pc%03i',x), num2cell(1:size(StimVal,2)), 'uni',0);
      assert(numel(StimInfo.Times) == size(StimVal,1), 'StimVal #row != StimInfo.Times #elem ?!')
      assert(numel(StimInfo.Names) == size(StimVal,2), 'StimVal #col != StimInfo.Names #elem ?!')
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'-pc50.mat']);
      save(FnMat, 'StimInfo', 'StimVal', '-v7.3')

      % Top 100- PCs
      StimVal = Pca.scores(Pca.idxStim == iStim, 1:min(100,size(Pca.scores,2)));
      StimInfo = Stim_{iStim}.StimInfo;
      StimInfo.StimMdl = [MdlNames{iMdl},'-pc100'];
      StimInfo.Names = cellfun(@(x) sprintf('pc%03i',x), num2cell(1:size(StimVal,2)), 'uni',0);
      assert(numel(StimInfo.Times) == size(StimVal,1), 'StimVal #row != StimInfo.Times #elem ?!')
      assert(numel(StimInfo.Names) == size(StimVal,2), 'StimVal #col != StimInfo.Names #elem ?!')
      FnMat = fullfile(Job.DnameStim, Job.StimNames{iStim}, [MdlPrefix,'-pc100.mat']);
      save(FnMat, 'StimInfo', 'StimVal', '-v7.3')
      clear StimInfo StimVal
    end
    clear *_ Pca
  end % for iLayer
end % for iMdl

end