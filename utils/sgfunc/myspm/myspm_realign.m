function Job = myspm_realign(Job)
% Job = myspm_realign(fname_epi)
% Job = myspm_realign(Job)
%
% realignment estimation and resample
%
% JOB requires:
%  .fname_epi 
%
% (cc0) 2015-2024, seung-goo.kim@ae.mpg.de

if ~isstruct(Job)
  Job = struct('fname_epi',Job);
end
[p1,f1,e1] = myfileparts(Job.fname_epi);
fname_in = [p1,'/',f1,e1];
fname_out = [p1,'/r',f1,e1];
if isfile(fname_out)
  logthis('FILE exists: "%s". Exiting.\n', fname_out)
  return
end

assert(isfile(fname_in), 'FILE "%s" NOT FOUND!', fname_in)

%% realign to MEAN IMAGE
% outputs:
% [1]  rp_${epi}.txt   : six rigid-body motion parameters [mm & rad]
% [2]  ${epi}.mat      : [4x4xT] realign transform
% [3]  r${epi}.nii     : realigned image
% [4]  mean${epi}.nii : mean image of [4]

info = niftiinfo([p1,'/',f1,e1]);
scans = cellfun(@(x) [p1,'/',f1,e1,',',num2str(x)], num2cell(1:info.ImageSize(4))', uni=false);
matlabbatch{1}.spm.spatial.realign.estwrite.data = {scans}; % yes this should be a nested cell array
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;  % because MEAN image is used in coregistration.
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 1; % Trilinear (works also for skull-stripped data)
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 1;  % Trilinear (works also for skull-stripped data)
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

spm_jobman('run', matlabbatch);
logthis('FILE created: ')
ls(fname_out)

myspm_viewrp(Job.fname_epi);
end
