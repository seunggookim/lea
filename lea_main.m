function Job = lea_main(Job)
%LEA_MAIN  Linearized Encoding Analysis (LEA 👧)
%
% Job 
% .FnamesX   {#stims x #feature-spaces (terms)} (or a string array)
% .FnamesY   {#stims x #response-spaces (modalities)} (or a string array)
% .DnameMdl  '1 x #char'
% .nRands
% .DelaysSmp OR .DelayRange <duration: 1x2>
% .SampleRateHz
% .LambdaGrid
% .CvDesign  'loocv' | [1 x 2] for a nested (#outer-fold x #inner-fold) k-fold | hmm..
%
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

%HISTORY
% 2024-09-02: for behavioral data analysis
% 2024-11-05: add-ons for fmri & eeg data analysis with a custom class TS (time series)

%TODOs
% - [_] better optimization for multi-penalty

%STYLE-GUIDE
%- public text width (e.g., help message): 80
%- private text width (e.g., everything else): 120
%- UpperCamelCase: Structure, Fieldnames, Table, Row/VariableNames, AnyObjectsWithProperties, PropertyNames
%- lowerCamelCase: numArray, cellArray, stringArray
%- lowergermancase: function()
%- snake_case: onlyonce_forpackageprefix()
%- UPPER_SNAKE_CASE: CONSTANT_VALUE


% house-keeping 🧹:
assert(isfield(Job,'FnamesX') && isfield(Job,'FnamesY'), 'INPUTS {.FnamesX, .FnamesY} NEED TO BE DEFINED!')
Job.FnamesX = string(Job.FnamesX);
Job.FnamesY = string(Job.FnamesY);
validatefilenames(Job, {'FnamesX', 'FnamesY'})

%- set delays by delayRange
if isfield(Job,'DelayRange') && isfield(Job,'SampleRateHz')
  fprintf('Checking Job.DelayRange..\n');
  validateattributes(Job.DelayRange, 'duration', {'numel', 2})  % very handy!
  delayRangeSmp = round(seconds(Job.DelayRange)*Job.SampleRateHz);
  Job.DelaysSmp = delayRangeSmp(1):delayRangeSmp(2);
  fprintf( '(Job.DelayRange=[%s, %s]): Job.DelaysSmp = \n', char(Job.DelayRange(1)), char(Job.DelayRange(2)) );
  disp(Job.DelaysSmp)
end

%- default parameters:
Job = defaultjob(struct( SampleRateHz=1, DelaysSmp=0:3, RelToiSec=[15 -15], LambdaGrid=10.^(-20:1:20), ...
  nRands=10000, DnameMdl=tempdir, CvDesign='loocv', IsKeepRandBetaHat=false ), Job, mfilename);

%- create an output directory and a log file
[~,~] = mkdir(Job.DnameMdl);
FnameLog = fullfile(Job.DnameMdl, 'lea_main.log');
tStart = tic;
logfile(FnameLog, Job, true)
logCloser = onCleanup(@() eval('diary off'));


% prepare data 🍱:
logthis('READING DATA!\n')
[dataX, dataY, Isc] = prepdata(Job);


% run cv folds to fit a model 🏃‍♀️‍➡️‍:
logthis('RUNNING CVs!\n')
[Mdl] = runcv(dataX, dataY, Job);
Job.FnameMdl = fullfile(Job.DnameMdl, 'mdl.mat');
save(Job.FnameMdl, 'Mdl', 'Isc', 'Job')


% randomization test with null data 😈:
if Job.nRands
  [Rnd] = randtest(dataX, dataY, Mdl, Job);
  Job.FnameRnd = fullfile(Job.DnameMdl, 'rnd.mat');
  save(Job.FnameRnd, 'Rnd', 'Job')
end


% create nice plots 📊️:
if Job.IsPlot
  plotmdl(dataX, dataY, Mdl, Isc, Rnd, Job)
end

% close the log 📝:
logfile(FnameLog, Job, false, tStart)
end
