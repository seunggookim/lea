function fnOut = myspm_seg25(Job)
% fnBrain = myspm_seg25(fnameT1w)
% fnBrain = myspm_seg25(Job)
%
%(cc0) 2025-09-14, seung-goo.kim@ae.mpg.de

if ischar(Job) || isstring(Job)
  % EVERYTHING DEFAULT
  fnameT1w = Job;
  Job = struct(FnameT1w=fnameT1w);
end

Job = defaultjob(struct(IsEastern=false, IsSaveFwdDef=false, IsSaveInvDef=false), Job, mfilename);
[f_,n_,e_] = myfileparts(Job.FnameT1w);
Job.FnameT1w = fullfile(f_, [n_,e_]);
assert(isfile(Job.FnameT1w), 'File "%s" NOT FOUND!', Job.FnameT1w)
fnOut = spm_file(Job.FnameT1w, 'suffix','_brain');
if isfile(fnOut)
  logthis('Exiting; FILE exists: "%s"\n', fnOut)
  return
end

matlabbatch = {};
matlabbatch{1}.spm.spatial.preproc.channel.vols = {[Job.FnameT1w,',1']};
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1]; % INU corrected
if Job.IsEastern
  matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'eastern';
end
matlabbatch{1}.spm.spatial.preproc.warp.write = [Job.IsSaveInvDef, Job.IsSaveFwdDef];
spm_jobman('run',matlabbatch);

stripskull(Job.FnameT1w, fnOut)
end

function stripskull(fnameT1w, fnOut)
[f_,n_,e_] = myfileparts(fnameT1w);
[t1w,info] = niftireadgz(fullfile(f_,['m',n_,e_]));
mask = false(size(t1w));
for c = 1:3
  p = niftiread(fullfile(f_,sprintf('c%i%s%s', c, n_, e_)));
  mask = mask | (p>=uint8(255*0.50));
end
niftiwrite(t1w .* single(mask), fnOut, info=info)
logthis('File created: "%s"\n', fnOut)
slices(fnameT1w, fnOut, struct(fname_png=strrep(fnOut,'.nii','.png')))
end
