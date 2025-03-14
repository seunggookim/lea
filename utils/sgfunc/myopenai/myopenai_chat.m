%MYOPENAI_GETEMBEDDING
%
% Job = myopenai_getembedding(Job)
%
%Job
%  .Input      a character array
%  .FnameChat  a filename to save
% (.Model)    'gpt-4o-2024-08-06' (defalt) | 'o1' (reasoning model)
% (.KeyLoc)   '~/Documents/OpenAI/proj-key.txt' (default)
% 
% (CC4-BY) seung-goo.kim@ae.mpg.de

function Job = myopenai_chat(Job)

%{
REF: https://platform.openai.com/docs/api-reference/chat

METHOD: POST https://api.openai.com/v1/chat/completions

Request body:

%}


Job = defaultjob(struct( ...
  ServerUrl='https://api.openai.com/v1/chat/completions', Model='gpt-4o-2024-08-06', ...
  KeyLoc='~/Library/Mobile Documents/com~apple~CloudDocs/Documents/OpenAI/proj-key.txt' ...
  ), ...
  Job, mfilename);
if isfile(Job.FnameChat)
  ls(Job.FnameChat)
  return
end

assert(isfile(Job.KeyLoc))
key = textscan(fopen(Job.KeyLoc,'r'), '%s');
setenv('OPENAI_API_KEY', key{1}{1})

inputText = strrep(Job.Input, newline, ' ');
inputText = strrep(inputText, '(', '');
inputText = strrep(inputText, ')', '');
inputText = strrep(inputText, '''', '');

msgStruct = [ ...
  struct(role='developer', content=['You are a highly intelligenable experimental psychologist ',...
  'who has decades of experience in editting various scientific manuscripts in a range of disciplines of '...
  'psychology.']), ...
  struct(role='user', content=['Create a conference section title in about five words or less, ', ...
  'in specific and concrete academic English that faithfully encapsulates and summarize the following abstracts: ', ...
  inputText]) ...
  ];

RequestBody = struct(messages=msgStruct, model=Job.Model);
cmd = sprintf('curl %s -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_API_KEY" -d ''%s''', ...
  Job.ServerUrl, jsonencode(RequestBody));
[~, stdout] = system(cmd);
try
  Chat = jsondecode(stdout);
  disp(Chat.choices.message.content)
  save(Job.FnameChat, 'Chat')
  logthis('DONE: '); ls(Job.FnameChat)
catch
  error('JSON decoding error!\n%s', stdout)
end
end
