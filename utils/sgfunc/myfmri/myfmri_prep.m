function Job = myfmri_prep(Job)
%MYFMRI_PREP process functional EPI data with my mojo.
%
% Job = myfmri_prep(Job)
%(CC4-BY) seung-goo.kim@ae.mpg.de

% Start over to simplify the complexity.
% With no legacy...


Job = defaultjob(struct( ...
  FnameFunc = [], FnameFuncJson = [], ...   % allowing to run without fmri (although the name is 'fmri')
  IsEastern = false, IsMp2rage = false, ... % information needed for anatomical image segmentation
  IsAnts = false, IsIcaaroma = false, IsFreesurfer = false ... % additional processes
  ), Job, mfilename);

% CHECK input files
validatefilenames(Job, {'FnameAnat', 'FnameFunc', 'FnameFuncJson'});
if not(iscell(Job.FnameAnat))
  Job.FnameAnat = {Job.FnameAnat};
end

if not(isempty(Job.FnameFunc))
  if not(iscell(Job.FnameFunc))
    Job.FnameFunc = {Job.FnameFunc};
  end
  funcInfo = niftiinfo(Job.FnameFunc{1});
  voxMm = [1 1 1] * round(min(funcInfo.PixelDimensions(1:3)));
  Job = defaultjob(struct( FuncVoxMm = voxMm, FuncFwhmMm = [1 1 1]*round(2.5*voxMm(1)) ), Job, mfilename);
end

% CHECK software
% - SPM
assert(exist('SPM','file'))
% - ANTs
if Job.IsAnts
  % check it somehow...
end
% - FSL/ICA-AROMA
if Job.IsIcaaroma
  % check
end
% - FreeSurfer
if Job.IsFreesurfer
  % check
  getenv('FREESURFER_HOME')
end


%%
% START diary
% Job.FnameLog = fullfile(fileparts(Job.FnameFunc{1}), [mfilename, '.log']);
tStart = tic;
% logfile(Job.FnameLog, Job, true)


%% RUN SPM
Job = helper_spm_smriprep(Job);


%% (RUN ANTs)


%% (RUN ICA-AROMA)


%% (RUN FreeSurfer)


% END diary
% logfile(Job.FnameLog, Job, false, tStart)

end


