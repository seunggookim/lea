function Job = helper_spm_fmriprep(Job)
%HELPER_SPM_FMRIPREP
%   Job = helper_spm_fmriprep(Job)
%
%     {'FnameAnat', 'FnameFunc', 'FuncFwhmMm', 'FuncVoxMm', 'IsEastern'}
%
% REF: http://www.fil.ion.ucl.ac.uk/spm/data/auditory/
% Many parameters can be simply default!

validatefields(Job, {'FnameAnat', 'FnameFunc', 'FuncFwhmMm', 'FuncVoxMm'})


matlabbatch = {};
% Realign
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.realign.estwrite.data = {Job.FnameFunc};
matlabbatch{end}.spm.spatial.realign.estwrite.roptions.which = [0 1];

% Coregister
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.coreg.estimate.ref    = spm_file(Job.FnameFunc{1},'prefix','mean');
matlabbatch{end}.spm.spatial.coreg.estimate.source = Job.FnameFunc;

% % Segment: Anatomical
% %--------------------------------------------------------------------------
% matlabbatch = [matlabbatch, struct()];
% matlabbatch{end}.spm.spatial.preproc.channel.vols  = Job.FnameAnat;
% matlabbatch{end}.spm.spatial.preproc.channel.write = [0 1]; % save INU-corrected image
% matlabbatch{end}.spm.spatial.preproc.warp.write    = [0 1]; % save the forward warping field
% if Job.IsEastern
%   matlabbatch{end}.spm.spatial.preproc.warp.affreg = 'eastern';
% end


% Segment: NU-correct the mean functional image
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.preproc.channel.vols  = spm_file(Job.FnameFunc{1},'prefix','mean');
matlabbatch{end}.spm.spatial.preproc.channel.write = [0 1]; % save INU-corrected image

% Normalise: Write
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.normalise.write.subj.def      = spm_file(Job.FnameAnat,'prefix','y_','ext','nii');
matlabbatch{end}.spm.spatial.normalise.write.subj.resample = Job.FnameFunc;
matlabbatch{end}.spm.spatial.normalise.write.woptions.vox  = Job.FuncVoxMm;

% Smooth
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.smooth.data = spm_file(Job.FnameFunc,'prefix','w');
matlabbatch{end}.spm.spatial.smooth.fwhm = Job.FuncFwhmMm;

% RUN them all
spm('Defaults','fMRI');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

end
