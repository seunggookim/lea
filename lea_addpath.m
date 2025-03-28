function lea_addpath(Job)
%LEA_ADDPATH adds paths to access functions
%   LEA_ADDPATH(Job)

myPath = fileparts(mfilename('fullpath'));
addpath(myPath)

if not(exist('defaultjob','file'))
  addpath(fullfile(myPath,'utils','sgfunc'))
  sgfunc_addpath()
end

if not(exist('Job','var')), Job = []; end
Job = defaultjob(struct(IsEeglab=false, IsFieldtrip=false, IsNsl=true, IsCnn=true), Job, mfilename, false);


% MATLAB UTILITIES (INTERNAL & EXTRENAL)
assert(exist('sgfunc_addpath','file'), 'SGFUNC not in MATLAB PATH!')
if ~exist('randomize_phase','file')
  sgfunc_addpath()
  warning off export_fig:exportgraphics
end

% external utilities: only to be locally stored (> 1 GB; NOT git-tracked)
localdir = fullfile(myPath,'.external-local');
if not(isfolder(localdir))
  [~,~] = mkdir(localdir);
end

if Job.IsEeglab
  % EEGLAB for EEG preprocessing
  addpath(fullfile(localdir,'eeglab-develop'))
  if not(exist('eeglab','file'))
    logthis('Installing <strong>EEGLAB</strong>.\n')  % takes less than 20 seconds
    installwebfile('https://github.com/sccn/eeglab/archive/refs/heads/develop.zip', localdir, 'eeglab-develop')
    addpath(fullfile(localdir,'eeglab-develop'))
  end
  eeglab nogui
  clear global
end

if Job.IsFieldtrip
  % Fieldtrip for permutation test
  if not(isfolder(fullfile(localdir,'fieldtrip-master')))
    logthis('Installing <strong>Feidltrip</strong>.\n')  % takes less than 20 seconds
    installwebfile('https://github.com/fieldtrip/fieldtrip/archive/refs/heads/master.zip', localdir, 'fieldtrip-master')
    addpath(fullfile(localdir,'fieldtrip-master'))
  end
  addpath(fullfile(localdir,'fieldtrip-master'))
  ft_defaults
end

if Job.IsNsl
  % NSLtool for the low-level auditory model
  if not(isfolder(fullfile(localdir,'nsltools')))
    logthis('Installing <strong>NSL toolbox</strong> for the low-level auditory model.\n')
    installwebfile('http://www.isr.umd.edu/~speech/nsltools.tar.gz', localdir)
  end
  addpath(fullfile(localdir,'nsltools'))
end

if Job.IsCnn
  % MATLAB Deep Learning toolbox
  matlabsupportdir = fullfile(localdir,'matlab-support');
  if not(isfolder(matlabsupportdir))
    % INSTALL MATLAB support files if needed
    audiocnnfiles = ["vggishPreTrained.mat", "YAMNetWeights.mat", "openl3_mel256_music_6144.mat"];
    audiocnnurls = [
      "https://ssd.mathworks.com/supportfiles/audio/vggish.zip"
      "https://ssd.mathworks.com/supportfiles/audio/yamnet.zip"
      "https://ssd.mathworks.com/supportfiles/audio/openl3.zip"
      ];
    
    [~,~] = mkdir(matlabsupportdir);
    for i = 1:numel(audiocnnfiles)
      if not(exist(audiocnnfiles(i), 'file'))
        [~, mdlName, ~] = fileparts(audiocnnurls(i));
        logthis('Installing MATLAB support files for the audio CNN model <strong>`%s`</strong>.\n', mdlName)
        installwebfile(audiocnnurls(i), matlabsupportdir)
      end
    end
  end
  addpath(genpath(matlabsupportdir))
end

%% for fMRI plotting
fnMni = fullfile(myPath,'utils','standards','MNI152_T1_2mm_brain.nii.gz');
if not(isfile(fnMni))
  [~,~] = mkdir(fullfile(myPath,'utils','standards'));
  websave(fnMni, 'https://git.fmrib.ox.ac.uk/fsl/data_standard/-/raw/master/MNI152_T1_2mm_brain.nii.gz');
end


%% for EEG plotting


%%
logthis('Halo! ^o^)/\n')

end
