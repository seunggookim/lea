function Job = myspm_fmriglm (Job)
% Job = myspm_fmriglm (Job)
%
% This script helps you to run GLMs for the 1st-level fMRI analysis using
%   fMRI model specification & specification. A result report of the
%   1st-level GLM is created using myspm_result.m and myspm_graph.m. The
%   important difference from the simple GLM is that it deals with temporal
%   aspects of fMRI data including slow hedonamics, pre-whitening for auto-
%   correlation, as well as high-pass filtering for detrending.
%
% [INPUTS]
% JOB requires fields for myspm_fmriglm.m:
% -input files
%  .files_query '1xN' for query to find image filenames using "dir" function
%                (e.g., "/path/to/subj/EPI_r*.nii")
% or
%  .filenames   {1xJ} EPI files for J sessions (instead of files_query)
%
% -output directory
%  .dir_glm     '1xN' directory to save SPM results
%
% -HRF model: default is a canonical HRF
% (.microt0)        [1x1] where you STC [0,1] default = 0.5
% (.fir)            (1x1) finite-impulse-response model parameters
% (.fir.length_sec) [1x1] Post-stimulus window length (in seconds)
%                         (default: stimulus-duration)
% (.fir.order)      [1x1] the number of basis functions (or # of shifts/lags)
%                         (default: stimulus-duration/TR_sec)
% (.num_ISSS)       [1x1] interleaved silent steady state (Schwarzbauer, 2006)
%                         Number of images during the "scanning block"
%
% -for fMRI design matrix
%  .TR_sec
% (.stimdur_sec)       This could be a vector
% (.cond(j,k).name)    for j-th session, k-th condition
% (.cond(j,k).onset)
% (.cond(j,k).dur)
% (.cond(j,k).param)
%
% -autocorrelation modeling:
% (.hpfcutoff)     [1x1] high-pass cut-off period default=128 [s]
% (.autocorr)      '1xN'  "none" | "AR(1)" (default) | "FAST"
%
% -nuissance regressors
% (.suffix_rp)     {1xJ} rigid-body motion parameters for J sessions
%                        "rp_{suffix_rp{j}}.txt"
% (.num_rp)        [1x1] # of columns to include
% (.prefix_cc)     {1xJ} CompCor parameters for J sessions
%                        "{prefix_cc{j}}_eigenvec.txt"
% (.num_cc)        [1x1] # of columns to include
% (.scrb_thres)    [1x1] threshold to scrub in dTrans/dt [mm] or
%                        dRot/dt [deg]
%
% -custom regressor
% (.reg(j,k).name) '1xN' (additional regressors with/without FIR)
% (.reg(j,k).val)  [Tx1] for the k-th regressor in the j-th session
% (.reg(j,k).fir.order)   [1x1] number of equal-spaced shifts within a kernel
% (.reg(j,k).fir.length)  [1x1] length of a kernel in samples (TRs)
%
% -PPI,
% (.fname_ppi)
%
% -for myspm_cntrst.m:
% (.cntrstMtx)
% (.titlestr)
% (.effectOfInterest)
% (.FcntrstMtx)
% (.Ftitlestr)
%
% -for myspm_result.m:
% (.noreport)       [1x1] creates no reports (stops after cntrst)
% (.masking)        '1xN' filename for an explicit (inclusive) mask
%                         * NECESSARY for images with negative values!
% (.maskthres)      [1x1] masking threshold prop. to gloabl (default = 0.8)
% (.thres.desc)     '1xN'  'FWE','none', or 'cluster'(default)
% (.thres.alpha)    [1x1] alpha level (default=0.05)
% (.thres.extent)   [1x1] extent threshold of clusters in voxels (default=0)
% (.thres.clusterInitAlpha)   [1x1] cluster forming height threshold (default=0.0001)
% (.thres.clusterInitExtent)  [1x1] cluster forming extent (in voxels) threshold (default=10)
% (.fname_struct)   '1xN' fullpath filename for background anatomical image for orthogonal slices
%                         (default='$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz')
% (.titlestr)       {1xK} Title texts for K contrasts for SPM result report (default={'positive','negative'})
% (.dir_sum)        '1xN' a summary directory into where you want to copy significant results
% (.append)         [1x1] whether to append results into an existing report (default=0)
% (.print)          [1x1] whether to generate results (default=1)
% (.mygraph.x_name) '1xN' x-axis label in a scatterplot (default='x')
% (.mygraph.y_name) '1xN' y-axis label in a scatterplot (default='y')
% (.atlas)          '1xN' atlas to find anatomical names: 'fsl' (default) or 'spm12'
%
% -misc.
% (.keepResidual)  [1x1] to keep residual timeseries in RESI.nii
%
%
% [OUTPUT]
%
% (cc) 2015-2024. dr.seunggoo.kim@gmail.com


% (Should we still use 30-year-old code? `_`a )
%
% Results (from spm_spm.m):
% The following SPM.fields are set by spm_spm (unless specified)
%
%     xVi.V      - estimated non-sphericity trace(V) = rank(V)
%     xVi.h      - hyperparameters  xVi.V = xVi.h(1)*xVi.Vi{1} + ...
%     xVi.Cy     - spatially whitened <Y*Y'> (used by ReML to estimate h)
%
%                            ----------------
%
%     Vbeta     - struct array of beta image handles (relative)
%     VResMS    - file struct of ResMS image handle  (relative)
%     VM        - file struct of Mask  image handle  (relative)
%
%                            ----------------
%
%     xX.W      - if not specified W*W' = inv(x.Vi.V)
%     xX.V      - V matrix (K*W*Vi*W'*K') = correlations after K*W is applied
%     xX.xKXs   - space structure for K*W*X, the 'filtered and whitened'
%                 design matrix
%               - given as spm_sp('Set',xX.K*xX.W*xX.X) - see spm_sp
%     xX.pKX    - pseudoinverse of K*W*X, computed by spm_sp
%     xX.Bcov   - xX.pKX*xX.V*xX.pKX - variance-covariance matrix of
%                 parameter estimates
%                 (when multiplied by the voxel-specific hyperparameter ResMS
%                 of the parameter estimates (ResSS/xX.trRV = ResMS) )
%     xX.trRV   - trace of R*V
%     xX.trRVRV - trace of RVRV
%     xX.erdf   - effective residual degrees of freedom (trRV^2/trRVRV)
%     xX.nKX    - design matrix (xX.xKXs.X) scaled for display
%                 (see spm_DesMtx('sca',... for details)
%
%                            ----------------
%
%     xVol.M    - 4x4 voxel->mm transformation matrix
%     xVol.iM   - 4x4 mm->voxel transformation matrix
%     xVol.DIM  - image dimensions - column vector (in voxels)
%     xVol.XYZ  - 3 x S vector of in-mask voxel coordinates
%     xVol.S    - Lebesgue measure or volume       (in voxels)
%     xVol.R    - vector of resel counts           (in resels)
%     xVol.FWHM - Smoothness of components - FWHM, (in voxels)
%
%                            ----------------
%
%     xCon      - Contrast structure (created by spm_FcUtil.m)
%     xCon.name - Name of contrast
%     xCon.STAT - 'F', 'T' or 'P' - for F/T-contrast ('P' for PPMs)
%     xCon.c    - (F) Contrast weights
%     xCon.X0   - Reduced design matrix (spans design space under Ho)
%                 It is in the form of a matrix (spm99b) or the
%                 coordinates of this matrix in the orthogonal basis
%                 of xX.X defined in spm_sp.
%     xCon.iX0  - Indicates how contrast was specified:
%                 If by columns for reduced design matrix then iX0 contains
%                 the column indices. Otherwise, it's a string containing
%                 the spm_FcUtil 'Set' action: Usually one of {'c','c+','X0'}
%                 (Usually this is the input argument F_iX0.)
%     xCon.X1o  - Remaining design space (orthogonal to X0).
%                 It is in the form of the coordinates of this matrix in
%                 the orthogonal basis of xX.X defined in spm_sp.
%     xCon.eidf - Effective interest degrees of freedom (numerator df)
%     xCon.Vcon - ...for handle of contrast/ESS image (empty at this stage)
%     xCon.Vspm - ...for handle of SPM image (empty at this stage)
%__________________________________________________________________________
%
% The following images are written to disk:
%
% mask.<ext>                                          - analysis mask image
% 8-bit (uint8) image of zero-s & one's indicating which voxels were
% included in the analysis. This mask image is the intersection of the
% explicit, implicit and threshold masks specified in the xM argument.
% The XYZ matrix contains the voxel coordinates of all voxels in the
% analysis mask. The mask image is included for reference, but is not
% explicitly used by the results section.
%
%                            ----------------
%
% beta_????.<ext>                                     - parameter images
% These are 32-bit (float32) images of the parameter estimates. The image
% files are numbered according to the corresponding column of the
% design matrix. Voxels outside the analysis mask (mask.<ext>) are given
% value NaN.
%
%                            ----------------
%
% ResMS.<ext>                           - estimated residual variance image
% This is a 64-bit (float64) image of the residual variance estimate.
% Voxels outside the analysis mask are given value NaN.
%
%                            ----------------
%
% RPV.<ext>                              - estimated resels per voxel image
% This is a 64-bit (float64) image of the RESELs per voxel estimate.
% Voxels outside the analysis mask are given value 0.  These images
% reflect the nonstationary aspects the spatial autocorrelations.
%
%                            ----------------
%
% ResI_????.<ext>                - standardised residual (temporary) images
% These are 64-bit (float64) images of standardised residuals. At most
% maxres images will be saved and used by spm_est_smoothness, after which
% they will be deleted.
%__________________________________________________________________________
%
% References:
%
% Statistical Parametric Maps in Functional Imaging: A General Linear
% Approach. Friston KJ, Holmes AP, Worsley KJ, Poline JB, Frith CD,
% Frackowiak RSJ. (1995) Human Brain Mapping 2:189-210.
%
% Analysis of fMRI Time-Series Revisited - Again. Worsley KJ, Friston KJ.
% (1995) NeuroImage 2:173-181.


%% -2. prompt help
if nargin == 0, help(mfilename); return; end

%% 0. parsing & check inputs
if ~isfield(Job,'overwrite'), Job.overwrite=0; end
spm('Defaults','fmri');
spm_jobman('initcfg');
% spm fmri % initialize! or MATLAB@Linux will crash while running spm_spm()

%% 0-1. find glm directory name and create one
[~,Job.model_desc,~] = myfileparts(Job.dir_glm);
logthis('[0a] Model description = "%s"\n', Job.model_desc)
[~,~] = mkdir(Job.dir_glm);

%% 0-2. check files exist
logthis('[0b] checking inputs..\n')
if isfield(Job,'files_query')
  Job.filenames = findfiles(Job.files_query);
end
validatefilenames(Job, 'filenames')

%% 0-3. set other params
Job.NumSess = numel(Job.filenames);
Job.NumFrames = zeros(1,Job.NumSess);
for j = 1:Job.NumSess
  hdr = niftiinfo(Job.filenames{j});
  Job.NumFrames(j) = hdr.ImageSize(4);
  logthis('[0c] # of frames: run(%i) = %i\n', j, Job.NumFrames(j))
end

% find conditions to contruct design matrix
if isfield(Job,'cond')
  Job.NumCond = size(Job.cond,2);
else
  Job.NumCond = 0; % no condition is given
end
if ~isfield(Job,'hpfcutoff')
  Job.hpfcutoff = 128;
end

%% 1. model specification

matlabbatch = {};
matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {''}; % for spm12
matlabbatch{1}.spm.stats.fmri_spec.dir = {Job.dir_glm};

% Basis functions: hrf or fir
if isfield(Job,'fir')
  if ~isfield(Job.fir,'length_sec') && ~isfield(Job.fir,'order')
    Job.fir.length_sec = Job.cond(1,1).dur;
    Job.fir.order  = round(Job.cond(1,1).dur/Job.TR_sec);
  end
  matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = Job.fir.length_sec;
  matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order  = Job.fir.order;
  matlabbatch{1}.spm.stats.fmri_spec.timing.RT = Job.TR_sec;
  matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
  matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 1;
  matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
else
  matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
  matlabbatch{1}.spm.stats.fmri_spec.timing.RT = Job.TR_sec;
  matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16; % # of bins
  if ~isfield(Job,'microt0')
    Job.microt0 = 0.5;
  end
  matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = round(Job.microt0 * 16); % middle point after STC
  if isfield(Job,'hrfderivs')
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = Job.hrfderivs;
  else
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
  end
end
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';

sess = [];
for j = 1:Job.NumSess
  % find image files
  for t = 1:Job.NumFrames(j)
    sess(j).scans{t,1} = [Job.filenames{j},',',num2str(t)]; % this must be <Tx1>
  end
  [dir_sess,~,~] = myfileparts(sess(j).scans{t,1});
  sess(j).cond = struct('name',{}, 'onset',{}, 'duration',{}, 'tmod',{}, 'pmod', {});
  if Job.NumCond
    for k = 1:Job.NumCond
      if ~isempty(Job.cond(j,k).name)
        % onset as a vector
        sess(j).cond(k).onset = Job.cond(j,k).onset;
        % condition name
        sess(j).cond(k).name  = Job.cond(j,k).name;
        % condition duration
        sess(j).cond(k).duration = Job.cond(j,k).dur;
        % For temporal modulation:
        sess(j).cond(k).tmod = 0;
        % For PARAMETRIC modulation (only one & 1st-order parameter)
        if isfield(Job.cond(j,k),'paramname') && ~isempty(Job.cond(j,k).paramname)
          sess(j).cond(k).pmod(1).name  = Job.cond(j,k).paramname;
          sess(j).cond(k).pmod(1).param = Job.cond(j,k).param;
          sess(j).cond(k).pmod(1).poly  = 1;
        else
          sess(j).cond(k).pmod = struct('name', {}, 'param', {}, 'poly', {});
        end
      end
    end % loop for conditions
  end
  
  l = 1;
  % custom regressors (with or without FIR)
  if isfield(Job,'reg')
    disp(['[1a] Covarying custom regressors']);
    NumReg = size(Job.reg,2);
    for k = 1:NumReg
      if ~isfield(Job,'fir')
        if isfield(Job.reg(j,k),'name')
          sess(j).regress(l).name = Job.reg(j,k).name;
        else
          sess(j).regress(l).name = ['reg',num2str(k)];
        end
        sess(j).regress(l).val  = Job.reg(j,k).val;
        l=l+1;
      else
        % 1. create a FIR kernel
        xBF = struct('name','Finite Impulse Response', 'order',Job.fir.order, 'length',Job.fir.length_sec, ...
          'dt',Job.TR_sec, 'UNITS','secs');
        xBF = spm_get_bf(xBF);
        % 2. convolute a centered regressor & resample it for each order
        x = Job.reg(j,k).val;
        x = [x; zeros(Job.NumFrames(j)-size(x,1),1)]; % zero-padding
        xconv = zeros(size(x,1), xBF.order);
        for i = 1:xBF.order
          temp = conv(demean(x), xBF.bf(:,i));
          xconv(:,i) = temp(1:size(x,1));
        end
        % 3. orthogonalize them... or not?
        xconv = spm_orth(xconv);
        % 4. add regressors
        for i = 1:xBF.order
          sess(j).regress(l).name = sprintf('%s*fir(%i)',Job.reg(j,k).name,i);
          sess(j).regress(l).val = xconv(:,i);
          l=l+1;
        end
      end
    end
  end
  
  % rigid-motion parameters
  if ~isfield(Job,'num_rp'), Job.num_rp=0; end
  if Job.num_rp
    if ~isfield(Job,'suffix_rp')
      [~,fname] = myfileparts(Job.filenames{j});
      [fwhm,isW,isU,isA,origname] = myspm_parse_filename(fname);
      prefixA={'','a'};
      fn_rp = [dir_sess,'/rp_',prefixA{isA+1},origname,'.txt'];
    else
      fn_rp = [dir_sess,'/rp_',Job.suffix_rp{j},'.txt'];
    end
    rpname={'dx','dy','dz','rx','ry','rz','dTrans/dt','dRot/dt'};
    logthis('[1b] Covarying %i motion parameters: ',Job.num_rp);
    disp(rpname);
    rp = load(fn_rp);
    rp = [ rp(:,1:6), [0; l2norm(diff(rp(:,1:3)))], [0; l2norm(diff(rp(:,4:6)))] ];
    for k = 1:Job.num_rp
      sess(j).regress(l).name = rpname{k};
      sess(j).regress(l).val  = rp(:,k);
      l = l + 1;
    end
  end
  
  % CompCor parameters
  if ~isfield(Job,'num_cc'), Job.num_cc=0; end
  if Job.num_cc
    logthis('[1c] Covarying %i CompCor parameters\n', Job.num_cc);
    if ~isfield(Job,'prefix_cc')
      [~,fname] = myfileparts(Job.filenames{j});
      [fwhm,isW,isU,isA,origname] = myspm_parse_filename(fname);
      prefixA={'','a'}; prefixU={'','u'};
      fn_cc = [dir_sess,'/',prefixU{isU+1},prefixA{isA+1},origname,...
        sprintf('_n%ib%.2f-Inf_eigenvec.txt', Job.num_cc, 1/Job.hpfcutoff)];
    else
      fn_cc = [dir_sess,'/',Job.prefix_cc{j},'_eigenvec.txt'];
    end
    cc=load(fn_cc);
    for k=1:Job.num_cc
      sess(j).regress(l).name = ['cc',num2str(k)];
      sess(j).regress(l).val  = cc(:,k);
      l=l+1;
    end
  end
  
  % Scrubbing parameters
  if isfield(Job,'scrb_thres')
    idx = [find(rp(:,7)>Job.scrb_thres); find(rp(:,8)./pi.*180>Job.scrb_thres)];
    idx = unique([idx; idx-1]);
    idx(idx<1) = [];
    idx(idx>Job.NumFrames(j)) = [];
    fprintf('[1d] Found %i frames exceeding a threshold of %f mm in dTrans/dt or %f deg in dRot/dt\n', ...
      numel(idx), [1 1]*Job.scrb_thres);
    if numel(idx)
      for k=1:numel(idx)
        sess(j).regress(l).name=['scrb',num2str(k)];
        sess(j).regress(l).val=zeros(Job.NumFrames(j),1);
        sess(j).regress(l).val(idx(k))=1;
        l=l+1;
      end
    end
  end
  
  sess(j).hpf = Job.hpfcutoff;
  disp(['[1e] high-pass cut-off: ',num2str(sess(j).hpf),' s']);
  
  matlabbatch{1}.spm.stats.fmri_spec.sess = sess;
  matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
  if isfield(Job,'masking')
    disp(['[1f] A mask is given: ',Job.masking{j}]);
    matlabbatch{1}.spm.stats.fmri_spec.mask = {[Job.masking{j},',1']};
  end
  if isfield(Job,'maskthres')
    disp(['[1f] Masking threshold (wrt global) is given: ',num2str(Job.maskthres)]);
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = Job.maskthres;
  end
  
  % autocorrelation model
  if ~isfield(Job,'autocorr')
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
  else
    matlabbatch{1}.spm.stats.fmri_spec.cvi = Job.autocorr;
  end
end

if ~exist([Job.dir_glm,'/SPM.mat'],'file') || Job.overwrite
  save ([Job.dir_glm,'/myspm_fmriglm_1spec.mat'],'matlabbatch');
  spm_jobman('initcfg');
  spm_jobman('run', matlabbatch);
end

%% 2. Model estimation
matlabbatch={};
matlabbatch{1}.spm.stats.fmri_est.spmmat = {[Job.dir_glm,'/SPM.mat']};
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1; % ReML
if isfield(Job,'keepResidual') % since SPM12?
  matlabbatch{1}.spm.stats.fmri_est.write_residuals = Job.keepResidual;
end

% running a batch
if (~exist([Job.dir_glm,'/beta_0001.img'],'file') && ~exist([Job.dir_glm,'/beta_0001.nii'],'file')) || Job.overwrite
  save ([Job.dir_glm,'/myspm_fmriglm_2est.mat'],'matlabbatch');
  spm_jobman('initcfg');
  spm_jobman('run', matlabbatch);
end

%% (optional: create a NIFTI file to keep ResI.*)
pwd0 = pwd;
cd (Job.dir_glm)
if isfield(Job,'keepResidual') && Job.keepResidual
  % create NIFTI
  setenv('FSLOUTPUTTYPE','NIFTI_GZ')
  unix('fslmerge -t RES Res_????.nii');
  ls('RES.nii.gz')
  setenv('FSLOUTPUTTYPE','NIFTI')
end
% delete
unix('rm -f Res_????.nii');
unix('rm -f ResI_????.nii');
cd (pwd0);

%% 4. Design review & Orthogonality check
% set figure filename
if ~isfield(Job,'fname_spm_fig')
  today = datestr(now,'yyyymmmdd');
  Job.fname_spm_fig = fullfile(Job.dir_glm,[Job.model_desc,'_spm_',today,'.ps']);
  Job.fname_spm_fig = strrep(Job.fname_spm_fig,'>','-gt-');
  Job.fname_spm_fig = strrep(Job.fname_spm_fig,'<','-lt-');
end
% delete previous figure files today (rewriting)
if exist(Job.fname_spm_fig,'file')
  delete(Job.fname_spm_fig);
end

% review the design matrix and save it:
toDisplay = {'matrix','orth','covariance'};
spm_figure('clear')
for j=1:numel(toDisplay)
  matlabbatch = {};
  matlabbatch{1}.spm.stats.review.spmmat = {[Job.dir_glm,'/SPM.mat']};
  matlabbatch{1}.spm.stats.review.display.(toDisplay{j})= 1;
  matlabbatch{1}.spm.stats.review.print = false;
  spm_jobman('run', matlabbatch);
  spm_print(Job.fname_spm_fig);
end

%% 5. set contrasts and print out all results
if ~isfield(Job,'thres')
  Job.thres.desc  = 'cluster';
  Job.thres.alpha = 0.05;
end
if ~(isfield(Job,'NOCNTRST') && Job.NOCNTRST)
  myspm_cntrst (Job);
end

% %% 6. Comutes contrasts quickly..?
% if isfield(Job,'convec') && isfield(Job,'conname')
%   error('myspm_mycon is depricated. just use regular contrast estimation module.')
%   %   JOB=myspm_mycon(JOB);
% end

end

