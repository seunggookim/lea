function jsonl = readjsonl(file)
jsonl = strsplit(fileread(file), newline);
for i = 1:numel(jsonl)
  jsonl{i} = jsondecode(jsonl{i});
end

end
