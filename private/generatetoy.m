function [FnamesX, FnamesY] = generatetoy(Job)
% [FnamesX, FnamesY] = generatetoy(Job)

FnamesX = cell(Job.nSets, 1);
FnamesY = cell(Job.nSets, 1);
for iSet = 1:Job.nSets
  FnamesX{iSet} = [tempname,'.ts'];
  FnamesY{iSet} = [tempname,'.ts'];

  X = Ts(smoothdata(normrnd(0, 1, [Job.nSamples, Job.nFeatures]), 'gauss', 'SmoothingFactor', Job.SmoothingFactor));
  Y = Ts(smoothdata(normrnd(0, 1, [Job.nSamples, Job.nResponses]), 'gauss', 'SmoothingFactor', Job.SmoothingFactor));
  Y.Data(:,1) = Y.Data(:,1) + X.Data(:,1)*Job.EffectSize;
  Y.Name = 'toy';
  save(X, FnamesX{iSet});
  save(Y, FnamesY{iSet});

end

end
