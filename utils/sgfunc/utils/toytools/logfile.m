function logfile(FnameLog, Job, IsStart, tStart)
%LOGFILE creates or closes a log file.
%
% [] = logfile(FnLog, Job, IsStart, tStart)
%
% (cc) 2021, sgKIM.

[~, ProcName,~] = fileparts(FnameLog);
DateStrNow = char(datetime('now'),'yyyy-MM-dd''_''HH:mm:ss');
% DateStrNow = char(datetime('now'),'yyyy-MM-dd HH:mm:ss');

if exist('IsStart','var') && IsStart
  diary(FnameLog)
  disp(repmat('=',[1 72]))
  fprintf('[%s|%s] START\n', ProcName, DateStrNow)
  disp(Job)
  save(strrep(FnameLog,'.log','_job.mat'), 'Job')
else
  if exist('tStart','var')
    fprintf('[%s|%s] END: took %s\n', ProcName, DateStrNow, ...
      char(duration(seconds(toc(tStart)), Format='hh:mm:ss.SSS')) );
  else
    fprintf('[%s|%s] END\n', ProcName, DateStrNow)
  end
  diary off
  save(strrep(FnameLog,'.log','_job.mat'), 'Job')
end
end
