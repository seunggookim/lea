function Job = lea_createaud(Job)
%LEA_CREATEAUD creates audio feature tables (ready for lea_import)
%
% Job = lea_createaud(Job)
%
% Job is a structure with:
%  .FnamesAudio   {1 x #Files}   audio filenames
%  .MdlName       '1 x #char'    'nsl' | 'vggish' | 'openl3'
%  .FeatName      '1 x #Char'    [NSL: 'env' | 'coch' | 'filtcoch'], [VGGISH: 'v01' ... 'v24'], 
%                                [OPENL3: 'o01', 'o24']
%  .SampleRateHz  [1 x 1]
%  .DnameStimTbl
%
%
% (CC4-BY) 2025, seung-goo.kim@ae.mpg.de
% SEE ALSO: LEA_IMPORT LEA_MAIN TS

% check if required fields are defined
validatefields(Job, ["FnamesAudio", "FeatName"]);

% set default parameters
Job = defaultjob(struct(), Job, mfilename);
Job.FnamesAudio = string(Job.FnamesAudio);

% SET a model function:
%{
  createmdlnsl()
  createmdlvggish()
  createmdlopenl3()
%}
STIM_FUNC = str2func(sprintf('createmdl%s',Job.MdlName));

for iFile = 1:numel(Job.FnamesAudio)
  % Create stimulus features at the standard sampling rate
  [~,~,fileExt] = fileparts(Job.FnamesAudio(iFile));
  fnameMdl = strrep(Job.FnamesAudio(iFile), fileExt, ['_',Job.MdlName,'.mat']);
  if isfile(fnameMdl)
    load(fnameMdl, 'Stim')
  else
    Stim = feval(STIM_FUNC, Job.FnamesAudio(iFile));
    save(fnameMdl, 'Stim')
  end

  % Create a stimulus table at a given resampling rate
  fnameStim = strrep(fnameMdl, '.mat', sprintf('-%s-ds%gHz.mat', Job.FeatName, Job.SampleRateHz));
  if not(isfile(fnameStim))
    [Y, Ty] = resample(Stim.(Job.FeatName).Val, Stim.(Job.FeatName).Info.TimeSec, Job.SampleRateHz);
    Tbl = table(Ty, max(Y,0));
    Tbl.Properties.VariableNames = ["time", Job.FeatName];
    Tbl.Properties.UserData = struct(Info=Stim.(Job.FeatName).Info, SampleRateHz=Job.SampleRateHz);
    save(fnameStim, 'Tbl')
  end
end

end


