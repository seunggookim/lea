%MYOPENAI_GETEMBEDDING
%
% Job = myopenai_getembedding(Job)
%
%Job
%  .Input     a character array
%  .FnameEmb  a filename to save
% (.Model)     'text-embedding-3-large' (default) | 'text-embedding-3-small' | 'text-embedding-ada-002' (legacy)
% (.KeyLoc)   '~/Documents/OpenAI/proj-key.txt' (default)
% 
% (CC4-BY) seung-goo.kim@ae.mpg.de

function Job = myopenai_getembedding(Job)

%{
REF: https://platform.openai.com/docs/api-reference/embeddings/create

METHOD: post https://api.openai.com/v1/embeddings

Request body:
  input <string or array> Required
    Input text to embed, encoded as a string or array of tokens. To embed multiple inputs in a single request, pass an
    array of strings or array of token arrays. The input must not exceed the max input tokens for the model (8192 tokens
    for text-embedding-ada-002), cannot be an empty string, and any array must be 2048 dimensions or less. Example
    Python code for counting tokens.

  model <string> Required
    ID of the model to use. You can use the List models API to see all of your available models, or see our Model
    overview for descriptions of them.

  encoding_format <string> Optional. Defaults to float
    The format to return the embeddings in. Can be either float or base64.

  dimensions <integer> Optional
    The number of dimensions the resulting output embeddings should have. Only supported in text-embedding-3 and later
    models.

  user <string> Optional
    A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. Learn more.

%}


Job = defaultjob(struct( ...
  ServerUrl='https://api.openai.com/v1/embeddings', Model='text-embedding-3-large', ...
  KeyLoc='~/Library/Mobile Documents/com~apple~CloudDocs/Documents/OpenAI/proj-key.txt' ...
  ), ...
  Job, mfilename);
if isfile(Job.FnameEmb)
  ls(Job.FnameEmb)
  return
end

assert(isfile(Job.KeyLoc))
key = textscan(fopen(Job.KeyLoc,'r'), '%s');
setenv('OPENAI_API_KEY', key{1}{1})

inputText = strrep(Job.Input, newline, ' ');
inputText = strrep(inputText, '(', '');
inputText = strrep(inputText, ')', '');
inputText = strrep(inputText, '''', '');
RequestBody = struct(input=inputText, model=Job.Model);
cmd = sprintf('curl %s -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_API_KEY" -d ''%s''', ...
  Job.ServerUrl, jsonencode(RequestBody));
[~, stdout] = system(cmd);
try
  Embedding = jsondecode(stdout);
  save(Job.FnameEmb, 'Embedding')
  logthis('DONE: '); ls(Job.FnameEmb)
catch
  error('JSON decoding error!\n%s', stdout)
end
end
