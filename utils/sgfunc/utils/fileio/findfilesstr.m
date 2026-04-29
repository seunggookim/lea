function files = findfilesstr(varargin)
files = string(findfiles(varargin{:}))';
end
