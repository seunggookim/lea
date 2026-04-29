
function Output = myapi(Job)

Job = defaultjob(struct( ...
  ServerUrl='', Query='', ...
  KeyLoc='~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Jamendo/jamendo-api-key.json' ...
  ), ...
  Job, mfilename);

assert(isfile(Job.KeyLoc))
key = textscan(fopen(Job.KeyLoc,'r'), '%s');
setenv('API_KEY', key{1}{1})

Query = strrep(Job.Query, newline, ' ');
Query = strrep(Query, '(', '');
Query = strrep(Query, ')', '');
Query = strrep(Query, '''', '');

cmd = sprintf('curl %s -H "Content-Type: application/json" -H "Authorization: Bearer $API_KEY" -d ''%s''', ...
  Job.ServerUrl, Query);
[~, stdout] = system(cmd);
try
  Output = jsondecode(stdout);
catch
  error('JSON decoding error!\n%s', stdout)
end
end

%%
% https://api.jamendo.com/v3.0/albums/tracks/?client_id=" +
%     //       jamendoApiJson.id +
%     //       "&format=jsonpretty&track_id=" +
%     //       Number(item.trackId);

% myapi(Query='', ServerUrl='')