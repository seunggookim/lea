function files = findfiles(varargin)
% files = findfiles(query)
% files = findfiles('formatted-text', argument1, argument2, ...)

if numel(varargin) > 1
  query = sprintf(varargin{:});
else
  query = varargin{1};
end

Files = dir(query);
if numel(Files)
  files = strcat({Files.folder},'/',{Files.name})';
else
  files = {};
end

end
