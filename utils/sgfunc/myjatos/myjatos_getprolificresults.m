function Job = myjatos_getprolificresults(Job)
%MYJATOS_GETRESULTS download results and rename 
%
% Job = myjatos_deploy(Job)
%
% Job [1x1] structure contains:
% .ServerUrl  '1xN' upto 'jatos'  e.g., 'https://cortex.jatos.org'
% .ServerKey  '1xN'
% .StudyDesc  [1x1] structure contains:
%  (.studyIds)
%  (.componentIds)
%  (.batchIds)
% .DnameProlific
%
% (CC0) seung-goo.kim@ae.mpg.de
%
% SEE ALSO https://github.com/JATOS/JATOS/blob/main/jatos-api.yaml


%{
TODO

[X] the multi queries are always conjuncted with OR (not AND)

%}
global DN_PROJ

API_PATH = '/jatos/api/v1';
import matlab.net.*
import matlab.net.http.*
import matlab.net.http.io.*

% clean URLs:
Job.ServerUrl(end) = strrep(Job.ServerUrl(end),'/','');


%% DOWNLOAD RESULTS FROM THE SERVER
headers = [
  HeaderField('Authorization', ['Bearer ',Job.ServerKey])
  HeaderField('Content-Type', 'application/json')
  ]';
options = weboptions('HeaderFields', headers, 'MediaType', 'application/json', 'Timeout', 60);
uri = URI([Job.ServerUrl,API_PATH,'/results']);
response = webwrite(uri, jsonencode(Job.StudyDesc), options);

dnameTemp = tempname;
mkdir(dnameTemp)
fnameZip = [tempname,'.zip'];
fileID = fopen(fnameZip, 'wb');
fwrite(fileID, response);
fclose(fileID);
fnames = unzip(fnameZip, dnameTemp);
logthis('Downloaded [%i] component RESULTS.\n', numel(fnames)-1)
% StudyResult1 = [CompoResult1, CompoResult2[reloaded], ...], so I take 0 or 1 componentRes from 1 studyRes.
% API issue??

serverPath = strrep(strrep(Job.ServerUrl,'http://',''),'https://','');
dnameRaw = [DN_PROJ,'/local/jatos-data/',serverPath];
[~,~] = mkdir(dnameRaw);
[flag] = system(['rsync -azu ',dnameTemp,'/ ',dnameRaw,'/']);
assert(flag==0, 'RSYNC FAILED')
logthis('copied to: %s\n', dnameRaw)
ls(dnameRaw)

%% Copy data into Prolific folders based on Prolific ID
Meta = jsondecode(fileread([dnameRaw,'/metadata.json']));
disp(Meta.data)
indices = num2cell(1:numel(Meta.data.studyResults));

if not(isempty(Job.StudyDesc.batchIds))
  isThisBatch = cellfun(@(x) ismember(Job.StudyDesc.batchIds, Meta.data.studyResults{x}.batchId), indices);
else
  isThisBatch = true(1,numel(Meta.data.studyResults));
end
isFinished = cellfun(@(x) isequal(Meta.data.studyResults{x}.componentResults.componentState, 'FINISHED'), indices);

FilesToCheck = cellfun(@(x) Meta.data.studyResults{x}.componentResults.path, indices, uniform=false);
FilesToCheck = FilesToCheck(isFinished & isThisBatch);
logthis('Found %i FINISHED component results.\n', numel(FilesToCheck))

PPIDs = {};
for iResult = 1:numel(FilesToCheck)
  try
    json = parsetxt([dnameRaw,FilesToCheck{iResult},'/data.txt']);
    PPIDs = [PPIDs, json{2}.PROLIFIC_PID];
  catch
    PPIDs = [PPIDs, 'N/A'];
  end
end

% DnProlific = [DN_PROJ,'/local/prolific-data/raw'];
fnamesDemo = findfiles([Job.DnameProlific,'/*csv']);
assert(numel(fnamesDemo), 'cannot find prolific demo tables!')
logthis('%i Profilic demographic tables found.\n', numel(fnamesDemo))
warning on
for iProlific = 1:numel(fnamesDemo)
  TblDemo = readtable(fnamesDemo{iProlific}, VariableNamingRule='preserve');
  isDone = contains(TblDemo.Status, {'APPROVED','AWAITING REVIEW'});
  TblDemo = TblDemo(isDone,:);
  nLogs = size(TblDemo,1);
  nResults = sum(ismember(TblDemo.("Participant id"), PPIDs));
  logthis('Profilic table="%s": %i FINISHED logs & %i FINISHED results found.\n', ...
    fnamesDemo{iProlific}, nLogs, nResults)
  if nLogs ~= nResults
    warning('#logs & #results MISMATCH! Reults could be in another server than "%s"', Job.ServerUrl)
  end
  logthis('Renaming files...')
  for iSubj = 1:size(TblDemo,1)
    thisPPID = TblDemo.("Participant id"){iSubj};
    isFound = ismember(PPIDs, thisPPID);
    if sum(isFound)==1
      copyfile([dnameRaw,FilesToCheck{isFound},'/data.txt'], [Job.DnameProlific,'/',thisPPID,'.txt'])
    elseif sum(isFound)>1
      warning('Duplicate PPID=%s! Copying only the first one!', thisPPID)
      idx = find(isFound);
      copyfile([dnameRaw,FilesToCheck{idx(1)},'/data.txt'], [Job.DnameProlific,'/',thisPPID,'.txt'])
    elseif sum(isFound)==0
      warning('Result not found for PPI=%s', thisPPID)
    end
  end
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
