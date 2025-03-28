function slurmmanyout(FuncHandle, Jobs, varargin)
% slurmmanyout(FuncHandle, Jobs, varargin)
%
% SEE ALSO: SLURMITOUT
MAX_NUM_ARRAY = 999; %512;

nJobs = numel(Jobs);
idxJob = cellfun(@(x) x:min(MAX_NUM_ARRAY-1+x,nJobs), num2cell(1:MAX_NUM_ARRAY:nJobs), 'uni',0);
for iBatch = 1:numel(idxJob)
  slurmitout(FuncHandle, Jobs(idxJob{iBatch}), varargin{:})
end
end