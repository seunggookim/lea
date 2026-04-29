function result = myapplemusic_search(Job)
%result = myapplemusic_search(Job)
%
%Job
%  .SearchUrl     a character array
%  .KeyLoc        api key local location
%  .CatalogType   'songs' | 'albums' | 'artists'
%  .ApiUrl        'https://api.music.apple.com/v1/catalog'
% 
% (CC4-BY) 2025, seung-goo.kim@ae.mpg.de
%

%{
REF: https://developer.apple.com/documentation/applemusicapi/
%}

Job = defaultjob(struct(CatelogType='songs',ApiUrl='https://api.music.apple.com/v1/catalog',KeyLoc='',SearchUrl=''), ...
  Job, mfilename);
assert(isfile(Job.KeyLoc));
json = jsondecode(fileread(Job.KeyLoc));
setenv('APPLE_API_KEY', json.apple.token);

fields = strsplit(Job.SearchUrl, '/');
storeFront = fields{3};
id = fields{end};

cmd = sprintf('curl %s/%s/%s/%s -H "Content-Type: application/json" -H "Authorization: Bearer $APPLE_API_KEY"', ...
  Job.ApiUrl, storeFront, Job.CatelogType, id);
[flag, stdout] = system(cmd);
if flag ~= 0
  [~, stdout] = system(strrep(cmd, 'curl ', 'curl -v '));
  error (stdout)
end

result = jsondecode(stdout);

end