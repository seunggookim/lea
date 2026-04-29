function myspm_checkenv()
%% 0-1. Windows
if ispc
  error('Use Linux or Mac (I don''t have a Windows machine to test)')
end

%% 0-2. FSL
assert(isfile(fullfile(getenv('FSLDIR'),'bin','fslmaths')), ...
  'FSL not accessible!')

%% 0-3. Freesurfer
assert(isfile(fullfile(getenv('FREESURFER_HOME'),'bin',...
  'mri_nu_correct.mni')), 'FREESURFER not accessible!')

%% 0-4. ANTs
if Job.UseAnts
  LD_LIBRARY_PATH = getenv('LD_LIBRARY_PATH');
  PATH_ = strsplit(LD_LIBRARY_PATH,':');
  ind = contains(upper(PATH_),'ANTS');
  assert(sum(ind), 'No ANTs library in LD_LIBRARY_PATH?!')
end

%% 0-5. SPM
assert(exist('spm', 'file'), 'SPM is not accessible!')
a = spm('Ver');
if ~strcmp(a(4:5),'25')
  error('Run this script on SPM25!');
end
spm('Defaults','fmri');
spm_jobman('initcfg');
end