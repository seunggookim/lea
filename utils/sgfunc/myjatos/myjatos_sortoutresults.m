function Job = myjatos_sortoutresults(Job)
%MYJATOS_SORTOUTRESULTS sort out the results
%
% Job = myjatos_deploy(Job)
%
% Job [1x1] structure contains:
%  .StudyUuid
%
% (CC0) seung-goo.kim@ae.mpg.de
%
% SEE ALSO https://github.com/JATOS/JATOS/blob/main/jatos-api.yaml


global DN_PROJ
% Job.StudyDesc = defaultjob(struct(studyIds=[], componentIds=[], batchIds=[]), Job.StudyDesc, mfilename);
dnameRaw = [DN_PROJ,'/local/jatos-data/'];

fnamesJrzip = findfiles('%s/*/*.jrzip', dnameRaw);
logthis('Found %i JRZIP files.\n', numel(fnamesJrzip))
fnamesUnzipped = {};
for i = 1:numel(fnamesJrzip)
  copyfile(fnamesJrzip{i}, strrep(fnamesJrzip{i},'.jrzip','.zip'));
  dname = strrep(fnamesJrzip{i},'.jrzip','');
  fnamesUnzipped = [fnamesUnzipped, unzip(strrep(fnamesJrzip{i},'.jrzip','.zip'), dname)];
  delete(strrep(fnamesJrzip{i},'.jrzip','.zip'))
end
logthis('Found %i data.txt files.\n', sum(contains(fnamesUnzipped,'data.txt')))


%% Copy data into Prolific folders based on Prolific ID


%% Read out Prolific Participant IDs from the meta files
fnamesJson = findfiles('%s/*/*/metadata.json', dnameRaw);
PPID = {}; FilesToCheck = {};
for iJson = 1:numel(fnamesJson)
  Meta = jsondecode(fileread(fnamesJson{iJson}));
  disp(Meta.data)
  assert(isequal(Meta.data.studyUuid,Job.StudyUuid), 'STUDY UUID MISMATCH! %s', fnamesJson{iJson})
  results = Meta.data.studyResults;
  if isstruct(results)
    results = {};
    for j = 1:numel(Meta.data.studyResults)
      results = [results Meta.data.studyResults(j)];
    end
  end
  isFinished = arrayfun(@(x) isequal(results{x}.componentResults(end).componentState, 'FINISHED'), ...
    1:numel(results));
  finishedResults = results(isFinished);
  PPID = [PPID, arrayfun(@(x) finishedResults{x}.urlQueryParameters.PROLIFIC_PID, 1:numel(finishedResults), uniform=0)];
  fnames = arrayfun(@(x) [fileparts(fnamesJson{iJson}),'/',finishedResults{x}.componentResults(end).path,'/data.txt'], ...
    1:numel(finishedResults), uniform=false);
  FilesToCheck = [FilesToCheck, fnames];
end

%%
DnProlific = [DN_PROJ,'/local/prolific-data/raw'];
fnamesDemo = findfiles([DnProlific,'/*/*csv']);
assert(numel(fnamesDemo), 'cannot find prolific demo tables!')
logthis('%i Profilic demographic tables found.\n', numel(fnamesDemo))

for iProlific = 1:numel(fnamesDemo)
  TblDemo = readtable(fnamesDemo{iProlific}, VariableNamingRule='preserve');
  isDone = contains(TblDemo.Status, {'APPROVED','AWAITING REVIEW'});
  TblDemo = TblDemo(isDone,:);
  nLogs = size(TblDemo,1);
  nResults = sum(ismember(TblDemo.("Participant id"), PPID));
  [~,batchName,~] = fileparts(fileparts(fnamesDemo{iProlific}));
  logthis('BatchName="%s": %i PROLIFIC logs & %i JATOS results found.\n', batchName, nLogs, nResults)
  if nLogs ~= nResults
    warning('MISMATCH')
  end
  for iSubj = 1:size(TblDemo,1)
    thisPPID = TblDemo.("Participant id"){iSubj};
    isFound = ismember(PPID, thisPPID);
    if sum(isFound)==1
      fnOut = fullfile(fileparts(fnamesDemo{iProlific}), [thisPPID,'.txt']);
      copyfile(FilesToCheck{isFound}, fnOut)
      % ls(fnOut)
      assert(isfile(fnOut))
      fprintf('.')
    elseif sum(isFound)>1
      error('PPID=%s MORE THAN ONCE?', thisPPID)
    end
  end
  fprintf('\n')
end

%%
if not(nargout)
  clear Job
end

end


function json = parsetxt(fname)
txt = fileread(fname);
idx = strfind(txt, 'sequence_id');
if numel(idx) > 1
  warning('Multiple entry: taking the last one.')
  txt = txt(idx(end)-2:end);
end
json = jsondecode(['[', strrep(txt, '}{', '},{'), ']']);
end