function vararginlike = parsertovarargin(p)
%vararginlike = parsertovarargin(p)

vararginlike = {};
keys = fieldnames(p.Results);
for i = 1:numel(keys)
  vararginlike = [vararginlike, {string(keys{i})}, p.Results.(keys{i})];
end
end
