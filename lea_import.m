function Job = lea_import(Job)
%LEA_IMPORT reads all kinds of data and save them as TS (a custom subclass of TIMESERIES) objects
%
% Job = lea_import(Job)
%
% Job is a structure with:
%  .FnameData   '1 x #Char'   filename to import
%  .DataType    '1 x #Char'   data type: 'bhv' | 'eeg' | 'fmri' | 'stim'
%  .FnameTs     '1 x #Char'   filename to save the input as a timeSeries (.MAT)
% (.Detrend)    '1 x #Char'   'none' | 'constant' | 'linear' [default]
% (.IsZscore)   '1 x #Char'   true [default] | false
% (.FnameMask)  '1 x #Char'   for .DataType='fmri' only | 'bet' | '' (non-zero) [default]
%
% The files to import need to be in a format:
% BHV data
% - CSV/EXCEL table with:
%   + a column named "TimeSec" (case-insensitive) with UNIFORMLY spaced timestamps in SECONDS
%   + other columnes with behavioral values will be read from the header
%
% EEG data
% - minimal EEGlab structure (.SET | "EEG" in .MAT) with these fields:
%    .data       [#Chans x #Times]   (no repetition of the same stimulus)
%    .srate
%    .chanlocs
%
% FMRI data
% - NIFTI/MGH 4-D images // TODO: MGH surface-mapped time series
%
% STIM data
% - CSV/EXCEL table with:
%   + a column name including "TIME" (case-insensitive) with timestamps in SECONDS
%   + other columnes with behavioral values will be read from the header
%
% TIME VECTOR will be created as:
%   fmri2ts()   Time=(0:nVol-1)/TR
%   eeg2ts()    Time=(0:nPnt-1)*srate
%   bhv2ts()    Time=(firstSample:lastSample)*srate
%   stim2st()   Time=(0:floor(max(TimeStamp)/srate)-1)*srate
%
% See timeSeries.UserData for metadata of the imported data
%
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de
% SEE ALSO: LEA_MAIN TS

VALID_DATA_TYPES = ["bhv", "eeg", "fmri", "stim"];

% check if required fields are defined
validatefields(Job, ["FnameData", "DataType", "FnameTs"]);

% set default parameters
Job = defaultjob(struct(Detrend="linear", IsZscore=true, BpfHz=[0 inf], SampleRateHz=nan, FnameMask=''), ...
  Job, mfilename);

% force field types to character arrays
Job.FnameData = char(Job.FnameData);
Job.FnameTs = char(Job.FnameTs);

% check if it's already done
if isfile(Job.FnameTs)
  logthis('TimeSeries file is already there: '); ls(Job.FnameTs)
  return
end

logthis('START\n'); tStart = tic;
disp(Job)


%% READ data
Ts = []; % NESTED functions cannot create a new variable in the PARENT's variable space
assert(contains(Job.DataType, VALID_DATA_TYPES), 'Jog.DataType="%s" is unrecognizable!', Job.DataType)
eval(sprintf('%s2ts()', Job.DataType)) % <<< SEE NESTED FUNCTIONS below >>>
%{
  fmri2ts()   Time=(0:nVol-1)/TR
  eeg2ts()    Time=(0:nPnt-1)*srate
  bhv2ts()    Time=(0:floor(max(TimeStamp)/srate)-1)*srate
  stim2st()   Time=(0:floor(max(TimeStamp)/srate)-1)*srate
%}

%% Validate and prep
assert(not(any(isnan(Ts.Data(:)))), 'NaN found in Ts.Data!')

% Resample 
if isnan(Job.SampleRateHz)
  Job.SampleRateHz = 1/Ts.TimeInfo.Increment;
end
if Job.SampleRateHz ~= (1/Ts.TimeInfo.Increment)
  Ts = resample(Ts, (Ts.Time(1) : 1/Job.SampleRateHz : Ts.Time(end))');
  Ts = setuniformtime(Ts, Interval=1/Job.SampleRateHz);
end

% Linear detrending by default
Ts = detrend(Ts, Job.Detrend);

% Bandpass filtering (optional)
FILTER_TYPE = 'fir';
if Job.BpfHz(1)==0 && not(isinf(Job.BpfHz(2)))
  Ts.Data = lowpass(Ts.Data, Job.BpfHz(2), Job.SampleRateHz, 'ImpulseResponse',FILTER_TYPE);
elseif Job.BpfHz(1)>0 && isinf(Job.BpfHz(2))
  Ts.Data = highpass(Ts.Data, Job.BpfHz(1), Job.SampleRateHz, 'ImpulseResponse',FILTER_TYPE);
elseif Job.BpfHz(1)>0 && not(isinf(Job.BpfHz(2)))
  Ts.Data = bandpass(Ts.Data, Job.BpfHz, Job.SampleRateHz, 'ImpulseResponse',FILTER_TYPE);
end

% Z-scoring by default
Ts = zscore(Ts, Job.IsZscore);

%% RETURN
[~,~] = mkdir(myfileparts(Job.FnameTs)); % create a directory to save in
save(Ts, Job.FnameTs)
logthis('TimeSeries saved: '); ls(Job.FnameTs)
logthis('DONE: took %s\n',  duration(seconds(toc(tStart)), Format='hh:mm:ss.SSS'));

if not(nargout)
  clear Job
end

%%
% >>> NESTED FUNCTIONS <<< can access/modify variables in their PARENT function.
% But cannot create a new variables in the PARAENT's scpoe.
% Is A NESTED FUNCTION A GOOD THING OR NOT? I'M NOT SURE...
  function bhv2ts()
    Ts = helper_readtbl(Job.FnameData);
    Ts.Name = 'bhv';
    if isfield(Job,'UserData')
      Ts.UserData = Job.UserData;
    else
      Ts.UserData = struct(StimName=[], SubjName=[]);
    end
  end

  function stim2ts()
    Ts = helper_readtbl(Job.FnameData);
    Ts.Name = 'stim';
    if isfield(Job,'UserData')
      Ts.UserData = Job.UserData;
    else
      Ts.UserData = struct(StimName=[]);
    end
  end

  function eeg2ts()
    [~, ~, dataExt] = myfileparts(Job.FnameData);
    switch lower(dataExt)
      case '.set'
        EEG = pop_loadset(Job.FnameData);
      case '.mat'
        load(Job.FnameData, 'EEG');
        assert(exist('EEG', 'var'), 'No variable named "EEG" found in "%s"', Job.FnameData)
    end
    assert(ismatrix(EEG.data), 'No repetition must be in EEG.data!')
    
    Ts = ts(EEG.data', (0:size(EEG.data,2)-1)'/EEG.srate);
    % //TODO: do I need to concatenate multiple responses?
    Ts.Name = 'eeg';
    Ts.UserData = struct(StimName=[], SubName=[]); % some more metadata! like...
    Ts.TimeInfo.Units = 'seconds';
    Ts.DataInfo.Units = '\muV';
    Ts.DataInfo.UserData.chanlocs = EEG.chanlocs;
    Ts.DataInfo.UserData.Info = [];
    if isfield(EEG, 'Info')
      Ts.DataInfo.UserData.Info = EEG.Info;
      Ts.UserData.StimName = Ts.DataInfo.UserData.Info.StimName;
      Ts.UserData.SubjName = Ts.DataInfo.UserData.Info.SubjName;
    end
    Ts.DataInfo.UserData.Info.OrigSetName = EEG.setname;
    Ts.DataInfo.UserData.Info.OrigFileName = EEG.filename;
    
    % //TODO: import EEG.event too?
  end

  function fmri2ts()
    Mri = helper_readmri(Job.FnameData);
    tr = Mri.info.PixelDimensions(4);
    dat = reshape(Mri.vol, [], Mri.info.ImageSize(4))';
    if not(isa(dat, 'double'))   % if DOUBLE, leave it
      dat = single(dat);         % otherwise, upscale it to SINGLE
    end

    if isempty(Job.FnameMask)
      Mri.info.Mask = any(Mri.vol, 4);  % to discard zero voxels
    else
      [isBetReady,~] = system('bet');
      if isfile(Job.FnameMask)
        Mri.info.Mask = niftireadgz(Job.FnameMask) > 0;

      elseif strcmpi(Job.FnameMask, 'bet') && isBetReady
        fnTemp = [tempname, '.nii'];
        info_ = Mri.info;
        info_.ImageSize(4) = [];
        info_.PixelDimensions(4) = [];
        info_.Datatype = 'single';
        niftiwrite(single(mean(Mri.vol,4)), fnTemp, Info=info_);
        fnBet = [tempname, '.nii'];
        [flag, stdout] = system(sprintf('export FSLOUTPUTTYPE=NIFTI; bet %s %s -f 0.4 -o -R', fnTemp, fnBet));
        assert(not(flag), 'FSL/BET FAILED!: %s', stdout)
        Mri.info.Mask = niftiread(fnBet) > 0;

      else
        error('Job.FnameMask="%s" UNPARSABLE!', Job.FnameMask)
      end
    end

    Ts = ts(dat(:,Mri.info.Mask(:)), (0:size(dat,1)-1)'*tr);
    Ts.Name = 'fmri';
    Ts.TimeInfo.Units = 'seconds';
    Ts.DataInfo.UserData.Info = Mri.info;
    if isfield(Job,'UserData')
      Ts.UserData = Job.UserData;
    else
      Ts.UserData = struct(StimName=[], SubjName=[]);
    end

    % //TODO: do I really need to use all three of .TimeInfo.UserData, .DataInfo.UserData 
    % and .UserData? Or put everything into .UserData?
  end

end



%% Additional helpers
function mri = helper_readmri(fname)  % from SLICES.m
[~,~,ext] = fileparts_gz(fname);
switch (ext)
  case {'.nii','.nii.gz','.img'}
    % Try "my" version of MATLAB Image Processing Toolbox (since 2016)
    if exist('niftiinfogz','file') && exist('niftireadgz','file')
      [V,info] = niftireadgz(fname);
      mri = struct('vol',V, 'info',info);
      % NOTE: NIFTIREAD doesn't upscale precision (hmm...)
    elseif exist('load_nifti','file') % FreeSurfer MATLAB function
      mri = load_nifti(fname);
    elseif exist('load_untouch_nii','file') % NIFTI toolbox
      mri = load_untouch_nii(fname);
    else
      error('CANNOT FIND any function to read NIFTI/ANALYZE files!')
    end
  case {'.mgh','.mgz'} % FreeSurfer file format
    [~, M, P] = load_mgh(fname, [], [], 1);
    mri = struct('vox2ras',M, 'tr',P(1), 'filpangle',P(2), 'te',P(3), ...
      'ti',P(3), 'fov',P(4));
    [mri.vol] = load_mgh(fname);
  otherwise
    error('FILE TYPE UNRECOGNIZED: "%s"',ext)
end
end


function Ts = helper_readtbl(fname)
[~, ~, ext] = myfileparts(fname);
switch ext
  case '.mat'
    load(fname, 'Tbl')
  otherwise
    Tbl = readtable(fname);
end
isTime = contains(lower(Tbl.Properties.VariableNames), 'time');
assert(sum(isTime) == 1, 'A column with "time" is not just one (many or nothing)!')
timeSec = Tbl(:,isTime).Variables;
values = Tbl(:,not(isTime)).Variables;

Ts = ts(values, timeSec);
Ts.TimeInfo.Units = 'seconds';
Ts.DataInfo.Units = string(Tbl.Properties.VariableNames(not(isTime)));
Ts.UserData = Tbl.Properties.UserData;

% oversampling for uniform sampling:
srate = 1/min(diff(Ts.Time));
firstSmp = ceil(Ts.Time(1)*srate);
lastSmp = floor(Ts.Time(end)*srate);
Ts = resample(Ts, ((firstSmp:lastSmp)./srate)');
Ts = setuniformtime(Ts, 'Interval', 1/srate);

end
