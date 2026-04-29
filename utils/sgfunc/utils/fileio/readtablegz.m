function t = readtablegz(filenamegz, varargin)

assert(isequal(filenamegz(end-2:end), '.gz'));
dnTemp = tempname;
mkdir(dnTemp);
fn = gunzip(filenamegz, dnTemp);
t = readtable(fn{1}, varargin{:});

end