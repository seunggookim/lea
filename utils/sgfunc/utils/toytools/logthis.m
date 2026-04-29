function LineLength = logthis(varargin)
%LOGTHIS FPRINTF with a header "[CallerName|TimeString-ISO8601+] "
%
% LineLength = logthis('{FORMAT}', Inputs, ..., Verbosity={0|1})
%
% (cc) 2021, sgKIM.

if numel(varargin)>1 && strcmpi(varargin{end-1}, 'Verbosity') 
  if not(varargin{end})
    return
  else
    varargin(end-1:end) = [];
  end
end

DateStrNow = char(datetime('now'),'yyyy-MM-dd''_''HH:mm:ss');
st = dbstack;
callername = st(2).name;
callerline = st(2).line;
LineLength = fprintf('[%s:%i|%s] %s', callername, callerline, DateStrNow, sprintf(varargin{:}));
if ~nargout
  clear LineLength
end
end
