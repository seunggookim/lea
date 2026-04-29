function [Job, Out] = lea_test(Job)
% [Job, Out] = lea_test(Job)

% set up parameters🍽️:
if not(nargin); Job = []; end
disp(repmat('=',[1 80]))
Job = defaultjob(struct(nSamples=50, nFeatures=2, nResponses=3, nSets=4, ...
  EffectSize=1, SampleRateHz=1, DelaysSmp=[0, 1], RelToiSec=[2 -2], IsComputeItc=1, ...
  LambdaGrid=10.^(-5:0.5:5), nRands=1000, IsPlot=false, IsVerbose=false, ...
  SmoothingFactor=0.5, IsAssert=true, CvDesign='loocv', IsKeepRandBetaHat=false), Job, mfilename);
disp(Job)

% generate toy data🧸:
[Job.FnamesX, Job.FnamesY] = generatetoy(Job);

% prepare data🍱:
logthis('READING DATA!\n')
[dataX, dataY, Itc] = prepdata(Job);

% run cv folds🏃‍♀️‍➡️‍:
Job.FnameMdl = fullfile(tempname, 'mdl.mat');
mkdir(fileparts(Job.FnameMdl))
Mdl = runcv(dataX, dataY, Job);

logthis('Mean Lopt = ')
disp(geomean(Mdl.Lopt, 1))
if Job.IsAssert
  assert( geomean(Mdl.Lopt(:,1), 1) < 10, "OVER-OPTIMIZED" )
  assert( min(geomean(Mdl.Lopt(:,2:end), 1)) > 1, "UNDER-OPTIMIZED" )
end

logthis('Mean acc = ')
disp(mean(Mdl.Acc, 1))
if Job.IsAssert
  assert( mean(Mdl.Acc(:,1), 1) > 0.5, "FALSE NEGATIVE" )
  assert( max(mean(Mdl.Acc(:,2:end), 1)) < 0.5, "FALSE POSITIVE")
end

% randomization test😈:
Rnd = randtest(dataX, dataY, Mdl, Job);

% create nice plots📊️:
if Job.IsPlot
  plotmdl(dataX, dataY, Mdl, [], Rnd, Job)
end

if Job.IsAssert
  logthis('ALL PASSED!\n')
end

Out = struct(Mdl=Mdl, Rnd=Rnd, Itc=Itc);

if not(nargout)
  clear Job Out
end

end
