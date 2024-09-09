function [X, Y] = generatetoy(Job)
% [X, Y] = generatetoy(Job)

X = {};
Y = {};
for iSet = 1:Job.nSets
  X = [X, smoothdata(normrnd(0, 1, [Job.nSamples, Job.nFeatures]), 'gauss', Job.TempGaussWin) ];
  Y = [Y, smoothdata(normrnd(0, 1, [Job.nSamples, Job.nResponses]), 'gauss', Job.TempGaussWin) ];
  Y{end}(:,1) = Y{end}(:,1) + X{end}(:,1)*Job.EffectSize;
end
end
