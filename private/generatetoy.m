function [X, Y] = generatetoy(Job)
% [X, Y] = generatetoy(Job)

X = cell(Job.nSets, 1);
Y = cell(Job.nSets, 1);
for iSet = 1:Job.nSets
  X{iSet} = ts(smoothdata(normrnd(0, 1, [Job.nSamples, Job.nFeatures]), ...
    'gauss', 'SmoothingFactor', Job.SmoothingFactor));
  Y{iSet} = ts(smoothdata(normrnd(0, 1, [Job.nSamples, Job.nResponses]), ...
    'gauss', 'SmoothingFactor', Job.SmoothingFactor));
  Y{iSet}.Data(:,1) = Y{iSet}.Data(:,1) + X{iSet}.Data(:,1)*Job.EffectSize;
  Y{iSet}.Name = 'toy';
end
end
