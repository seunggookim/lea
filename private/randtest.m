function Rnd = randtest(X, Y, Mdl, Job)
%(LEA's private) runs nested CVs for phase-randomization data [computationally intensive]
% Rnd = randtest(X, Y, Mdl, Job)

if not(Job.nRands)
  Rnd = [];
  return
end

tic
AccRnd = cell(Job.nRands, 1);
for iRnd = 1:Job.nRands % TODO: for parfor? or for slurm?
  AccRnd{iRnd,1} = randthis(X, Y, Mdl, Job);
end

AccRnd = cell2mat(AccRnd);
PvalUnc = mean([mean(Mdl.Acc,1); AccRnd] >= mean(Mdl.Acc,1));
[~,~,PvalFdr] = fdr(PvalUnc);

Rnd = struct(PvalUnc=PvalUnc, PvalFdr=PvalFdr, AccRnd=AccRnd);
logthis('DONE: took %s\n', char(duration(seconds(toc), Format='hh:mm:ss.SSS')))

end


function [predAcc, betaHat] = randthis(X, Y, Mdl, Job)
Cv = Mdl.Cv; % Use the same CV scheme as the observed data
RandX = X;
for iSet = 1:numel(X)
  RandX{iSet}.Data = randomize_phase(X{iSet}.Data);
end
Data = delaydata(RandX, Y, Job); % TODO: confirming Y is unnecessarily repeated
[Cxx, Cxy] = findcov(Data);
nPreds = size(Data(1).X, 2);
nResps = size(Data(1).Y, 2);
predAcc = zeros(Cv.NumTestSets, nResps);
if Job.IsKeepRandBetaHat
  betaHat = zeros(Cv.NumTestSets, nPreds, nResps);
else
  betaHat = [];
end

for iOuter = 1:numel(Data)
  idxTest = find(test(Cv, iOuter));

  % find covariance matrices of the training sets
  CxxTrain = Cxx;
  CxyTrain = Cxy;
  for j = 1:numel(idxTest)
    CxxTrain = CxxTrain - Data(idxTest(j)).X' * Data(idxTest(j)).X;
    CxyTrain = CxyTrain - Data(idxTest(j)).X' * Data(idxTest(j)).Y;
  end

  % use the same optimization as the observed data

  % predict test responses (averaged across test sets):
  for j = 1:numel(idxTest)
    [predAcc_, betaHat_] = evaluate(Data(idxTest(j)).X, Data(idxTest(j)).Y, CxxTrain, CxyTrain, Mdl.Lopt(iOuter,:));
    predAcc(iOuter,:) = predAcc(iOuter,:) + predAcc_;
    if Job.IsKeepRandBetaHat
      betaHat(iOuter,:,:) = betaHat(iOuter,:,:) + permute(betaHat_,[3 1 2]); % PERMUTE to add a leading singleton
    end
    clear *_
  end
  predAcc(iOuter,:) = predAcc(iOuter,:) ./ numel(idxTest);
  if Job.IsKeepRandBetaHat
    betaHat(iOuter,:,:) = betaHat(iOuter,:,:) ./ numel(idxTest); 
  end
end

predAcc = mean(predAcc,1);
if Job.IsKeepRandBetaHat
  betaHat = mean(betaHat,1);
end
end
