function job = myfs_synthrecon7(job)
% job = myfs_synthrecon7(job)
job = defaultjob(struct(dnameSubj=getenv('SUBJECTS_DIR'), fnameT1w='T1w-FILE', subId='SUBJECT-ID'), job)

[~,~] = mkdir(job.dnameSubj);
setenv('SUBJECTS_DIR', job.dnameSubj);
assert(isfile(job.fnameT1w))
[~,~,ext] = myfileparts(job.fnameT1w);
fnBrain = strrep(job.fnameT1w, [ext], ['_brain',ext]);
fnMask = strrep(job.fnameT1w, [ext], ['_mask',ext]);
if not(isfile(fnBrain))
  system(sprintf('mri_synthstrip -i %s -o %s -m %s --no-csf', job.fnameT1w, fnBrain, fnMask));
end
assert(isfile(fnBrain))
system(sprintf('recon-all -all -cm -threads 8 -s %s -i %s -xmask %s', job.subId, job.fnameT1w, fnMask))
end