function Job = myants_fmriprep(Job)
% Job = myants_fmriprep(Job)
%
% EPI -> T1w -> MNI registration & resampling of EPI timeseries in MNI space
%
% Job requires:
%  .FnameT1w
% (.FnameT1wBrain)
%  .FnameEpi
% (.FnameEpiMeanBrain)
%  .FnameRegT1wToMni
% (.Vox_mm)
%
% (CC0) 2025-09-16, seung-goo.kim@ae.mpg.de

%% Bias correction and skull-stripping
if not(isfield(Job, 'FnameT1wBrain'))
  logthis('Skull stripping T1w...\n',Job.FnameT1w)
  myfs_synthstrip(Job.FnameT1w);
  Job.FnameT1wBrain = spm_file(Job.FnameT1w, 'suffix', '_brain');
end
if not(isfield(Job, 'FnameEpiMeanBrain'))
  logthis('Skull stripping mean EPI...\n')
  fnEpiMean = spm_file(Job.FnameEpi, 'prefix','mean');
  if not(isfile(fnEpiMean))
    mysystem(sprintf('FSLOUTPUTTYPE=NIFTI; fslmaths %s -Tmean %s', Job.FnameEpi, fnEpiMean));
  end
  % myfs_synthstrip(fnEpiMean);
  if not(isfile(spm_file(fnEpiMean, 'suffix', '_brain')))
    mysystem(['mri_synthstrip ', ...
      ' -i ',fnEpiMean, ...
      ' -o ',spm_file(fnEpiMean,'suffix','_brain'), ...
      ' -m ',spm_file(fnEpiMean,'suffix','_mask')]);
  end
  Job.FnameEpiMeanBrain = spm_file(fnEpiMean, 'suffix', '_brain');
end

%% WARP T1w to MNI
if not(isfile(Job.FnameRegT1wToMni))
  logthis('Warp T1w -> MNI')
  JobAnts1 = [];
  JobAnts1.FnameFixed = fullfile(getenv('FSLDIR'),'data','standard','MNI152_T1_1mm_brain.nii.gz');
  JobAnts1.FnameMoving = spm_file(Job.FnameT1w, 'suffix','_brain');
  JobAnts1.RegStages = 2;
  myants_antsRegistration(JobAnts1)
end

%% RIGID from EPI to T1w
Job_ = [];
Job_.FnameMoving = Job.FnameEpiMeanBrain;  % bias-corrected (skull-stripped) EPI
Job_.FnameFixed  = Job.FnameT1wBrain;      % bias-corrected (skull-stripped) T1w
Job_.RegStages   = 0;
[dnEpi,nameEpi,~] = fileparts(Job_.FnameMoving);
[~,nameT1w,~]  = fileparts(Job_.FnameFixed);
fnRegEpiToT1w = [dnEpi,'/',nameEpi,'_to_',nameT1w,'_stage0_Composite.h5'];
if ~isfile(fnRegEpiToT1w)
  logthis('Coreg EPI to T1w using ANTs..\n')
  myants_antsRegistration(Job_);
  logthis('FILE created: '); ls(fnRegEpiToT1w)
end

%% CREATE FUNCTIONAL REFERENCE AT GIVEN VOXE RESOLUTION
if not(isfield(Job,'Vox_mm'))
  info = niftiinfo(Job.FnameEpi);
  Job.Vox_mm = [1 1 1] * min(info.PixelDimensions(1:3));
end
Job.FnameMniLow = fullfile(dnEpi, 'mni_funcref.nii');
if ~isfile(Job.FnameMniLow)
  fname_mni = fullfile(getenv('FSLDIR'), 'data', 'standard', 'MNI152_T1_1mm_brain.nii.gz');
  % NOTE: both MNI152_T1_1mm and MNI152_T1_1mm_brain are in [182x218x182]
  mysystem(sprintf('mri_convert -vs %f %f %f %s %s', Job.Vox_mm, fname_mni, Job.FnameMniLow));
  % bounding-box
  if isfield(Job,'Bbox_mm') && ~isempty(Job.Bbox_mm)
    myspm_boundingbox(Job.FnameMniLow, Job.Bbox_mm, Job.FnameMniLow);
  else
    myspm_boundingbox(Job.FnameMniLow, 'canon', Job.FnameMniLow);
  end
  logthis('FILE created: '); ls(Job.FnameMniLow)
end

%% COMBINE TRANSFORMS
Job.FnWarping = [dnEpi, '/Warping_', nameEpi,'_to_mni.nii.gz'];
Job_ = struct('FnameOut',Job.FnWarping, 'FnameFixed',Job.FnameMniLow, ...
  'Transforms',{{fnRegEpiToT1w,0; Job.FnameRegT1wToMni,0}});
if not(isfile(Job.FnWarping))
  logthis('Combining two level transforms in ANTs..\n')
  myants_combinetransforms(Job_);
  logthis('File created: '); ls(Job.FnWarping)
end

%% APPLY ON TIMESERIES
Job.EpiNorm = spm_file(Job.FnameEpi, 'prefix', 'x');
Job_ = struct('FnameMoving',Job.FnameEpi, 'FnameFixed',Job.FnameMniLow, 'Transforms',{{Job.FnWarping,0}}, ...
  'FnameOut',Job.EpiNorm);
if not(isfile(Job.EpiNorm))
  logthis('Resampling EPI in MNI152 using ANTs..\n')
  myants_antsApplyTransformsTimeseries(Job_);
  logthis('FILE created: '); ls(Job.EpiNorm)
end

%% VISUALIZE
[~,~,ext] = myfileparts(Job.EpiNorm);
slices(Job.EpiNorm,[], struct(layout=[1 9], contour=Job.FnameMniLow, contourwidth=2, ...
  fname_png=strrep(Job.EpiNorm, ext, '.png')));


end