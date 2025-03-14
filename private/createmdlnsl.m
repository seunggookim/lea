function Stim = createmdlnsl(FnamesStim, IS_CORTICAL)


% if not(exist('IsCor','var')), IsCor = true; end
% IS_CORTICAL = true;

% Read audio data ("WAVEFORM")
[yWav, FsWav] = audioread(FnamesStim);
logthis('Filename="%s": nChans=%i: SamplingRate=%iHz\n', FnamesStim, size(yWav,2), FsWav);

% Multichannels to Mono
if size(yWav,2) > 1
  logthis('Multichannles given: averaging across channels.\n')
  yWav = mean(yWav,2);
end

% Set NSL filter parameters (see WAV2AUD, AUD2COR)
FsAud = 8e3; % auditory nerve representation sampling rate
assert(FsAud==16e3 || FsAud==8e3) % only 8 kHz or 16 kHz allowed
loadload() % fill in other parameters with default values
paras(4) = (FsAud==16e3)*0 + (FsAud==8e3)*-1; % shifted by # of octaves
yWavResampled = resample(yWav, (0:numel(yWav)-1)/FsWav, FsAud);

% Compute the Auditory Nerve Representation (i.e., cochleogram) ----------
logthis('Computing a cochelogram...\n');
AudRep = wav2aud(yWavResampled, paras); % Time x Freq (128 chans)
AdjFactor = 1*(FsAud==8e3) + 2*(FsAud==16e3);
AudFreqs = 440 * 2 .^ ((-31:97)/24) * AdjFactor;
AudFreqs(end) = []; % the highest channel is discarded.
AudTimes = (0:size(AudRep,1)-1)'*(paras(1)/1000);




% Compute the Auditory Cortical Representation if needed --------------------
%{
Nakai et al. 2021: (music with vocals)
freq = 128 -> 20 bins
rv = 2 .^ (-1.5:0.5:3) % 10 rates [0.35, ..., 8] Hz
sv = 2 .^ (1.5:0.5:6)  % 10 scales [0.35, ..., 64] cyc/oct
PCA: 20*10*10 = 2000 -> 302 (99%)

Santoro et al., 2014: (speech, environmental, ...)
Freq = 180-7040 Hz -> 3 or 8 freq ranges
rv = 3 .^ (0:3)  % 4 rates  [1, 3, 9, 27] Hz
sv = 2 .^ (-1:2) % 4 scales [0.5, 1, 2, 4] cyc/oct
%}

%{
Temporal mod rate: to include slow temporal modulations
(Ding: speech, ~7 Hz; music, ~2 Hz) around 2 Hz
0.5, 1, 2, 4, 8, 16 (6 rates)
%}
rv = 2 .^ (-1:1:4);

%{
Sepctral mod rate: to include finer spectral modulations (6 scales)
for 128 freq bins over 5.3 octaves: 24.15 bins/oct
: Nyquist limit is ~12 cyc/oct; 0.5, 1, .., 16 cyc/oct (6 scales)
%}
sv = 2 .^ (-1:1:4);
% CorInfo = struct(TemporalModRateHz=rv, SpectralModRateCycOct=sv);
% if IS_CORTICAL
logthis('Computing a "filtered" cochleogram...\n')

FT = 0; % fullness of temporal margin
FX = 0; % fullness of spectral margin
BP = 0; % pure bandpass indicator (0=outer filters as LP/HP filters)
Fn_ = [tempname,'.cor'];
c = onCleanup(@() delete(Fn_));
CorRep = abs(aud2cor(AudRep, [paras FT FX BP], rv, sv, Fn_));
% Cor: [4D] scale-rate(up-down)-time-freq.
% Average upward and downward temporal modulations:
nTM = numel(rv);
CorRep = single((CorRep(:,1:nTM,:,:) + CorRep(:,nTM+1:end,:,:))/2);
% else
%   CorRep = [];
% end

% Stim = struct(CochVal=AudRep, CochFreqs=AudFreqs, CochTimes=AudTimes, FiltVal=CorRep, FiltInfo=CorInfo);

env = struct(Val=mean(AudRep,2), Info=struct(TimeSec=AudTimes, FreqHz=[AudFreqs(64)], DimOrder=["TimeSec", "FreqHz"]));
coch = struct(Val=AudRep, Info=struct(TimeSec=AudTimes, FreqHz=AudFreqs, DimOrder=["TimeSec", "FreqHz"]));
filtcoch = struct(Val=reshape(permute(CorRep,[1 2 4 3]),[],numel(AudTimes))', ...
  Info=struct(SpecModCpo=sv, TempModHz=rv, TimeSec=AudTimes, FreqHz=AudFreqs, ...
  DimOrder=["TimeSec", "SpecModCpo-by-TempModHz-by-FreqHz"]));
Stim = struct(env=env, coch=coch, filtcoch=filtcoch);

end