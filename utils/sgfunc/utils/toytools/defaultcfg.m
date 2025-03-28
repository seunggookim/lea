function Cfg = defaultcfg(DefaultCfg, Cfg, ProcName, IsVerbose)
%defaultcfg check input fields and set them to default values
%
% Cfg = defaultjob(DefaultCfg, Cfg, ProcName, IsVerbose)
%
% (cc) 2021, sgKIM.

if not(exist('IsVerbose','var')), IsVerbose=true; end

FldNames = fieldnames(DefaultCfg);
for iFld = 1:numel(FldNames)
  if ~isfield(Cfg, FldNames{iFld})
    if IsVerbose
      fprintf('[%s] (DEFAULT) Cfg.%s = ', ProcName, FldNames{iFld})
      if isempty(DefaultCfg.(FldNames{iFld}))
        fprintf('\n')
      else
        disp(DefaultCfg.(FldNames{iFld}))
      end
    end
    Cfg.(FldNames{iFld}) = DefaultCfg.(FldNames{iFld});
  end
end

end
