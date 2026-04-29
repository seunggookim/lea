function myfs_bbr(job)

job = defaultjob(struct(dnameSubj=getenv('SUBJECTS_DIR'), fnameMov='MOVING-FILE', subId='SUBJECT-ID'), job);
if not(isfield(job, 'fnameReg'))
  [~,~,ext] = myfileparts(job.fnameMov);
  job.fnameReg = strrep(job.fnameMov, ext, '_reg.dat');
end
fnameOut = strrep(job.fnameMov, ext, ['_reg',ext]);
if isfile(job.fnameReg)
  logthis('FILE EXISTS: ');
  ls(job.fnameReg)
  return
end

setenv('SUBJECTS_DIR', job.dnameSubj);
assert(isfile(fullfile(job.dnameSubj, job.subId, 'scripts', 'recon-all.done')))
assert(isfile(job.fnameMov))

opt = '--t2 ';
if isfield(job,'fnameWhole')
  assert(isfile(job.fnameWhole));
  opt = [opt, sprintf('--int %s ', job.fnameWhole)];
end

system(sprintf( ...
  'bbregister %s --s %s --mov %s --reg %s --o %s %s', opt, job.subId, job.fnameMov, job.fnameReg, fnameOut))

end