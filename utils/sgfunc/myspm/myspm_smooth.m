function Job = myspm_smooth(Job)
% Job = myspm_smooth(Job)
%
% Job requires:
%  .fname    '1xN' for a file name
%  .fwhm_mm  [1x1] or [1x3]
%  .IsImpMas [T/F] implicit masking (masked smoothing; 0 for INT, nan for FLOAT)
%
% (CC0) 2025, seung-goo.kim@ae.mpg.de
Job = defaultjob(struct(IsIM=false, fwhm_mm=0), Job, mfilename);
validatefilenames(Job, 'fname')
if isscalar(Job.fwhm_mm), Job.fwhm_mm = [1 1 1]*Job.fwhm_mm; end
prefix = sprintf('s%g', Job.fwhm_mm(1));

info = niftiinfo(Job.fname);
if Job.IsIM && contains(info.Datatype, {'single', 'double'})
  logthis('NANinig "%s"...\n', Job.fname)
  img = niftiread(Job.fname);
  img(img==0) = nan;
  niftiwrite(img, Job.fname, info=info);
end

matlabbatchs = {};
matlabbatchs{1}.spm.spatial.smooth.dtype = 0;  % same precision
matlabbatchs{1}.spm.spatial.smooth.im = Job.IsIM;     % implicit masking (0 for INT; NaN for float)
matlabbatchs{1}.spm.spatial.smooth.data = cellfun(@(x) ...
  [Job.fname,',',num2str(x)], num2cell((1:info.ImageSize(4))'), uni=0);
matlabbatchs{1}.spm.spatial.smooth.fwhm = Job.fwhm_mm;
matlabbatchs{1}.spm.spatial.smooth.prefix = prefix;

spm_jobman('initcfg')
spm_jobman('run', matlabbatchs)
end
