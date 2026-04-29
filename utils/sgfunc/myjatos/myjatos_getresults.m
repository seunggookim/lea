function Job = myjatos_getresults(Job)
%MYJATOS_GETRESULTS download results
%
% Job = myjatos_deploy(Job)
%
% Job [1x1] structure contains:
% .ServerUrl  '1xN' upto 'jatos'  e.g., 'https://cortex.jatos.org'
% .ServerKey  '1xN'
% .StudyDesc  [1x1] structure contains: (API-recognizable)
%  (.studyIds)
%  (.componentIds)
%  (.batchIds)
% .StudyUuid  '1xN' to double-check
% .DnameData  '1xN'
%
% (CC4 NC-BY-SA) seung-goo.kim@ae.mpg.de
%
% SEE ALSO https://github.com/JATOS/JATOS/blob/main/jatos-api.yaml

%{
UPDATES:

[2025-07-18] Now JsPsych result conforms the JSON format.

%}
global DN_PROJ

API_PATH = '/jatos/api/v1';
import matlab.net.*
import matlab.net.http.*
import matlab.net.http.io.*

% clean URLs:
Job.ServerUrl(end) = strrep(Job.ServerUrl(end),'/','');


%% DOWNLOAD EVERYTHING FROM THE SERVER
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
logthis('Downloaded [%i] Component Results.\n', numel(fnames)-1)

serverPath = strrep(strrep(Job.ServerUrl,'http://',''),'https://','');
dnameRaw = [DN_PROJ,'/local/jatos-data/',serverPath];
if not(isfolder(dnameRaw)), mkdir(dnameRaw); end
[flag] = system(['rsync -azu ',dnameTemp,'/ ',dnameRaw,'/']);
assert(flag==0, 'RSYNC FAILED')
logthis('copied to: %s\n', dnameRaw)
ls(dnameRaw)

%% FIND .ONLY "FINISHED" RESULTS
metaJson = jsondecode(fileread([dnameRaw,'/metadata.json']));
assert( isequal(Job.StudyUuid, metaJson.data.studyUuid), 'studyUuid not matched!' )

studyStates = string(cellfun(@(x) x.studyState, metaJson.data.studyResults, 'UniformOutput', false));
resultIds = string(cellfun(@(x) x.id, metaJson.data.studyResults, 'UniformOutput', false));
idxFinished = find(studyStates == "FINISHED");
if isempty(idxFinished)
  return
end
if not(isfolder(Job.DnameData)), mkdir(Job.DnameData); end

%% WEED OUT JSON-conforming results with a VALID morlaId
morlaIds = [];
for i = 1:numel(idxFinished)
  j = idxFinished(i);
  fn = string(findfiles('%s/study_result_%s/*/data.txt', dnameRaw, resultIds(j)));
  try
    resultJson = jsondecode(fileread(fn));
    morlaIds = [morlaIds, string(resultJson{1}.trials.info.moarla_subject_id)];
  catch
    morlaIds = [morlaIds, "DEPRECIATED"];
  end
end
% "mw8zeh" is my test ID.
idxFinished(ismember(morlaIds, ["mw8zeh", "DEPRECIATED"])) = [];
logthis('[%i] FINISHED results found.\n', numel(idxFinished))

%% CREATE a NEW file if it is not there already
morlaIds = [];
for i = 1:numel(idxFinished)
  j = idxFinished(i);
  fn = string(findfiles('%s/study_result_%s/*/data.txt', dnameRaw, resultIds(j)));
  resultJson = jsondecode(fileread(fn));
  morlaId = string(resultJson{1}.trials.info.moarla_subject_id);
  resultJson = [metaJson.data.studyResults(j); resultJson]; % put the metadata in the first
  
  % this is Unix timestamp in milliseconds 0 = 1970-01-01 00:00:00 UTC
  startTime = char(datetime(resultJson{1}.startDate/1e+3, TimeZone='Europe/Berlin', ConvertFrom='posixtime', Format='yyyy-MM-dd''_''HH.mm.ss'));
  fnameJson = sprintf('%s/%sDE_%s.json', Job.DnameData, startTime, morlaId);
  if not(isfile(fnameJson))
    fid = fopen(fnameJson,'w');
    fwrite(fid, jsonencode(resultJson, PrettyPrint=true));
    fclose(fid);
    logthis('new result created: "%s"\n', fnameJson)
  end
  
end



end
