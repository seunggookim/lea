function [dnLog, jobId] = findslurmlogpath()
%FINDSLURMLOGPATH finds a next natural number for the name of SLURM log folder
% [DnLog, JobId] = findslurmlogpath()

dnTemp = fullfile(getenv('HOME'), 'slurm');
if not(isfolder(dnTemp))
  mkdir(dnTemp)
end
Dirs = dir(fullfile(dnTemp, '*'));
Dirs = Dirs([Dirs.isdir]);
lastJobId = max(cell2mat(cellfun(@str2num, {Dirs.name}, uni=0)));
if isempty(lastJobId)
    jobId = 0; 
else
    jobId = lastJobId + 1;
end
jobId = num2str(jobId,'%04i');
dnLog = fullfile(dnTemp, jobId);
mkdir(dnLog);
end
