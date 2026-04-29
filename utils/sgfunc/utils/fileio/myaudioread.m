function [y,fs] = myaudioread(fn)
assert(isfile(fn), 'FILE NOT FOUND: "%s"', fn)
try
  [y,fs] = audioread(fn);
catch
  fnTemp = [tempname,'.wav'];
  c = onCleanup(@() delete(fnTemp));
  [~,~] = system(sprintf('ffmpeg -i %s %s', fn, fnTemp));
  [y, fs] = audioread(fnTemp);
end
end
