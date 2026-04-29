function validatefilenames(Job, FldNames)
%validatefilenames(Job, FldName)
%
% (cc) 2021, sgKIM.
if not(iscell(FldNames))
  FldNames = {FldNames};
end
for jFld = 1:numel(FldNames)
  for iJob = 1:numel(Job)
    Filenames = Job(iJob).(FldNames{jFld});
    if iscell(Filenames)
      cellfun(@(x) assert(isfile(x), 'FILE NOT FOUND: "%s"',x), Filenames, 'uni',false)
    elseif isstring(Filenames)
      arrayfun(@(x) assert(isfile(x), 'FILE NOT FOUND: "%s"',x), Filenames, 'uni',false)
    elseif ischar(Filenames)
      assert(isfile(Filenames), 'FILE NOT FOUND: "%s"',Filenames)
    end
  end
end
end
