function JOB = myspm_coreg_hdr(JOB)
% JOB = myspm_coreg_hdr(JOB)
% finds optimal rigid-body transform and applied in the header (no resampling)
%
% .fname_epi
% .fname_t1w
%
% (cc) 2015-2019, sgKIM.
if ~nargin,  help myspm_coreg_hdr;  return; end
if ~isfield(JOB,'interp'), JOB.interp=1; end
ls(JOB.fname_epi);
ls(JOB.fname_t1w);
[p1,f1,e1]=myfileparts(JOB.fname_epi);

% %% 1. Intensity-bias correction of EPI (for stable coregistration)
% fname_epi_unbiased = [p1,'/mmean',f1,e1]; % bias-corrected EPI
% JOB.fname_epi_unbiased = fname_epi_unbiased;
if ~exist([p1,'/mean',f1,e1],'file')
  unix(['FSLOUTPUTTYPE=NIFTI; fslmaths ',p1,'/',f1,e1,' -Tmean ',p1,'/mean',f1,e1]);
end
% if ~exist(fname_epi_unbiased,'file')
%   unix(['mri_nu_correct.mni --i ',p1,'/mean',f1,e1,' --o ',fname_epi_unbiased]);
%   ls(fname_epi_unbiased)
% end
fname_epi_unbiased = [p1,'/mean',f1,e1];

%% 2. Coregistration of EPI to native T1w
% outputs: <modifying transform matrices in headers>
% [1]  mmeanua${epi}.nii
% [2]  ua${epi}.nii        : "other" images, header modified
% [3]  ua${epi}.mat        : "other" images, header modified
[p2,f2,e2] = myfileparts(JOB.fname_t1w);
estimate1=[];
estimate1.ref{1}    = JOB.fname_t1w;
estimate1.source{1} = fname_epi_unbiased;
% ------------------here you specified OTHER imgaes-----------------
estimate1.other{1} = JOB.fname_epi; % NIFTI-format have only ONE xfm for all volumes (no need to put all frames here)
% ------------------------------------------------------------------
estimate1.eoptions.cost_fun = 'nmi';
estimate1.eoptions.sep = [4 2];
estimate1.eoptions.tol = ...
  [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
estimate1.eoptions.fwhm = [7 7];
matlabbatch={};
matlabbatch{1}.spm.spatial.coreg.estimate = estimate1;
fname_out = [p1,'/',f1,'.mat'];
if ~exist(fname_out,'file')
  fname_matlabbatch=[p1,'/myspm_coreg_hdr_',f1,'.mat'];
  save(fname_matlabbatch,'matlabbatch');
  warning('This function CHANGES the header of %s',JOB.fname_epi);
  spm_jobman('run', matlabbatch);
  ls(fname_out)
end

%% resample the first volume (to check coregistration quality)
fn_epi_in_t1w = spm_file(fname_epi_unbiased,'prefix','o');
if not(isfile(fn_epi_in_t1w))
  matlabbatch={};
  matlabbatch{1}.spm.spatial.coreg.write.ref{1}    = JOB.fname_t1w;
  matlabbatch{1}.spm.spatial.coreg.write.source{1} = [fname_epi_unbiased,',1'];
  matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
  matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
  matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
  matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'o';
  spm_jobman('run', matlabbatch);
  slices(fn_epi_in_t1w,[], struct('fname_png', strrep(fn_epi_in_t1w, e2,'.png'), 'contour',JOB.fname_t1w))
end
