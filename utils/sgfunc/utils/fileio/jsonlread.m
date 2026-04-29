function jsonl = jsonlread(file)
jsonl = strsplit(deblank(fileread(file)), newline);
for i = 1:numel(jsonl)
  jsonl{i} = jsondecode(jsonl{i});
end
jsonl = [jsonl{:}];
end
