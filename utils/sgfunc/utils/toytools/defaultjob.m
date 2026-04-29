function Job = defaultjob(DefaultJob, Job, ProcName, IsVerbose)
%defaultjob check input fields and set them to default values
%
% Job = defaultjob(DefaultJob, Job, [ProcName], [IsVerbose])
%
% (cc) 2021, sgKIM.

if not(exist('IsVerbose','var')), IsVerbose = true; end
if exist('ProcName','var')
  ProcName = ['[',ProcName, '] '];
else
  ProcName = '';
end

FldNames = fieldnames(DefaultJob);
for iFld = 1:numel(FldNames)
  if ~isfield(Job, FldNames{iFld})
    value = DefaultJob.(FldNames{iFld});
    if IsVerbose
      fprintf('%s(DEFAULT) Job.%s = ', ProcName, FldNames{iFld})
      if numel(value) > 10
        fprintf('<%s %i x %i> ...', class(value), size(value))
        disp(value(end-5:end)); 
      else
        disp(value);
      end
      if not(contains(class(value), {'string','char'}))
        fprintf('\b')
      end
      if isempty(value) || isequal(value,"")
        fprintf('\n')
      end
    end
    Job.(FldNames{iFld}) = value;
  end
end

end
