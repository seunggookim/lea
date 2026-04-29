function youtubedl(Url, FnAudio, IsCheck)
% youtubedl(Url, FnAudio, IsCheck)
%
% (cc) 2022,2025, seung-goo.kim@ae.mpg.de

if ~exist('IsCheck','var'), IsCheck=true; end

% Installing:
[~,ste] = system('which yt-dlp');
if isempty(ste)
  if ismac
    system('brew install yt-dlp');
    system('brew install ffmpeg');
  elseif isunix
    system('sudo pip3 install --upgrade yt-dlp');
    system('sudo apt install ffmpeg');
  else
    error('You are using Windows? WHY? Delete Windows and install Linux!');
  end
end

% Nagging the user:
warning('download audio contents only for RESEARCH PURPOSES.');

% Command:
[~,~,Ext] = fileparts(FnAudio);
assert(contains(Ext,{'aac','flac','mp3','m4a','opus','vorbis','wav'}),...
  'Audio format "%s" not supported.', Ext)
Cmd = sprintf( ...
  'yt-dlp --rm-cache-dir -x --audio-format %s -o "%s" %s', ...
  Ext(2:end), FnAudio, Url);

if ~isfile(FnAudio)
  % Run:
  system(Cmd);
end

if IsCheck
  % Waiting:
  fprintf('[%s:%s] Waiting for the file to be created...\n', ...
    mfilename, datestr(now,31))
  while ~isfile(FnAudio)
    % By default it runs in the background... which is a good idea for the
    % restricted download speed from the Youtube server. But just make sure
    % that we have it.
  end
  fprintf('[%s:%s] Done: ', mfilename, datestr(now,31))
  ls(FnAudio)
end

end
