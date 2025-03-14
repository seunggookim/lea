function Job = lea_rdd(Job)
% Linearized Encoding Analysis (LEA👧): Reverse-double dipping demonstration
%
% Job 
% .FnamesX  cell or string array #stims x #features x #randomizations
% .FnamesY  cell or string array #stims x #responses
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

%HISTORY
% 2024-09-02: for behavioral data analysis
% 2024-11-05: add-ons for fmri & eeg data analysis with a custom class TS (time series)
% 2024-12-17: reserved double-dipping for the paper (*DANGER* DON'T USE THIS!!)

%TODOs
% - [_] better optimization for multi-penalty

%CODING-FORMAT
%- public width: 80
%- private width: 120
%- UpperCamelCase: Structure, Fieldnames, Table, Row/VariableNames, AnyObjectsWithProperties, PropertyNames
%- lowerCamelCase: numArray, cellArray, stringArray
%- lowergermancase: function()
%- snake_case: onlyonce_forpackageprefix()

error('DO NOT USE THIS!')

% house-keeping🧹:
assert(isfield(Job,'FnamesX') && isfield(Job,'FnamesY'), 'INPUTS {.FnamesX, .FnamesY} NEED TO BE DEFINED!')
Job.FnamesX = string(Job.FnamesX);
Job.FnamesY = string(Job.FnamesY);
validatefilenames(Job, {'FnamesX', 'FnamesY'})

%- set delays by delayRange
if isfield(Job,'DelayRange') && isfield(Job,'SampleRateHz')
  validateattributes(Job.DelayRange, 'duration', {'numel', 2})  % very handy!
  delayRangeSmp = round(seconds(Job.DelayRange)*Job.SampleRateHz);
  Job.DelaysSmp = delayRangeSmp(1):delayRangeSmp(2);
  fprintf( '(Job.DelayRange=[%s, %s]): Job.DelaysSmp = \n', char(Job.DelayRange(1)), char(Job.DelayRange(2)) );
  disp(Job.DelaysSmp)
end

Job = defaultjob(struct( SampleRateHz=1, DelaysSmp=0:3, RelToiSec=[15 -15], LambdaGrid=10.^(-20:1:20), ...
  DnameMdl=tempdir, CvDesign='loocv' ), Job, mfilename);

[~,~] = mkdir(Job.DnameMdl);
FnameLog = fullfile(Job.DnameMdl, 'lea_main.log');
tStart = tic;
logfile(FnameLog, Job, true)
logCloser = onCleanup(@() eval('diary off'));


% preprocess data🍱:
Job_ = Job;
Job_.FnamesX = Job.FnamesX(:,:,1);
[~, dataY, Isc] = prepdata(Job_);
Mdls = [];

for iRep = 1:size(Job.FnamesX,3)
  Job_ = Job;
  Job_.FnamesX = Job.FnamesX(:,:,iRep);
  Job_.FnamesY = [];

  % preprocess randomized features🍱:
  [dataX, ~, ~] = prepdata(Job_);

  % run cv folds to fit a model🏃‍♀️‍➡️‍ (with re-optimization):
  [Mdl_] = runcv(dataX, dataY, Job_);

  Mdls = [Mdls, Mdl_];
end

Job.FnameMdls = fullfile(Job.DnameMdl, 'mdls.mat');
save(Job.FnameMdls, 'Mdls', 'Isc', 'Job')



% close the log📝:
logfile(FnameLog, Job, false, tStart)
end
