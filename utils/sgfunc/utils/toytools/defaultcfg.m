function Cfg = defaultcfg(DefaultCfg, Cfg, ProcName, IsVerbose)
%defaultcfg check input fields and set them to default values
%
% Cfg = defaultjob(DefaultCfg, Cfg, [ProcName], [IsVerbose])
%
% (cc) 2021, sgKIM.

if not(exist('IsVerbose','var')), IsVerbose=true; end
if exist('ProcName','var')
  ProcName = ['[',ProcName, '] '];
else
  ProcName = '';
end

FldNames = fieldnames(DefaultCfg);
for iFld = 1:numel(FldNames)
  if ~isfield(Cfg, FldNames{iFld})
    value = DefaultCfg.(FldNames{iFld});
    if IsVerbose
      fprintf('%s(DEFAULT) Cfg.%s = ', ProcName, FldNames{iFld})
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
    Cfg.(FldNames{iFld}) = value;
  end
end

end
