function [soundOnsetAfterTrigger_ms, EEG_corrected] = myeeg_triggerdelay(EEG, fnameAud, labelDict, fnamePng)
chanlabels = string({EEG.chanlocs.labels});

% FIND a true audio-onset from the stimTrack (if available)
[audWav, fs] = myaudioread(fnameAud);
% audWav = abs(zscore(resample((mean(double(audWav),2)), EEG.srate, fs)));
audWav = ( resample( abs(mean(zscore(double(audWav)),2)), EEG.srate, fs) );

soundOnset_smpl = EEG.event(string({EEG.event.type})==labelDict("sound-onset")).latency;
triggerAudioOnset = seconds( soundOnset_smpl / EEG.srate );
stimTrak = abs(zscore(double(EEG.data(chanlabels==labelDict("STIM"),soundOnset_smpl:end)')));
% stimTrak = ((stimTrak));

[xr, lags] = xcorr(stimTrak, audWav, 500);
[max_xr, ridx] = max(xr);
%% SOME WAY TO DETERMINE GOOD PEAKI-NESS
rz = (max_xr-median(xr)) / mad(xr);
%% AND SYMMETRY ABOUT THE PEAK?
right_side = numel(lags) - ridx;
left_side = ridx - 1;
max_smpl = min(left_side, right_side);
rsym = corr(xr(ridx+(1:max_smpl)), xr(ridx+(-1:-1:-max_smpl)));
%%
triggerLatency = seconds(lags(ridx)/EEG.srate);
xcorrAudioOnset = triggerAudioOnset + triggerLatency;
logthis('Audio-onset based on the trigger=%s; Audio-onset based on the StimTrak=%s\n', ...
  triggerAudioOnset, xcorrAudioOnset)

soundOnsetAfterTrigger_ms = milliseconds(triggerLatency);

%% PLOT timing diagnostics
hf1 = figure(Visible='off', Position=[1 1 600 800]);
if not(exist('fnamePng','var'))
  set(hf1, Visible='on')
end

stimTimes = EEG.times(soundOnset_smpl:end) - soundOnset_smpl;
audTimes = (0:numel(audWav)-1);

subplot(511); hold on;
plot(stimTimes, (stimTrak), 'b')
plot(audTimes, (audWav), 'r')
hold off; xlabel('EEG-time after sound-onset [ms]');
ylabel('|Z|'); legend(["StimTrak", "AudWav[trg]", "delay"])
title([EEG.setname,': from start'], interp="none")
xlim([0 +1000]); grid on;

subplot(512); hold on;
plot(stimTimes, (stimTrak), 'b')
plot(audTimes + soundOnsetAfterTrigger_ms, (audWav), 'r')
xline(soundOnsetAfterTrigger_ms, 'g', lineWidth=2)
hold off; xlabel('EEG-time after sound-onset [ms]');
ylabel('|Z|'); legend(["StimTrak", "AudWav[xcorr]"])
xlim([0 +1000]); grid on;

[~,pidx] = max(stimTrak);

subplot(513); hold on;
plot(stimTimes, (stimTrak), 'b')
plot(audTimes, (audWav), 'r')
hold off; xlabel('EEG-time after sound-onset [ms]');
ylabel('|Z|'); legend(["StimTrak", "AudWav[trg]", "delay"])
title([EEG.setname,': around peak'], interp="none")
xlim([-500 +500]+stimTimes(pidx)); 

subplot(514); hold on;
plot(stimTimes, (stimTrak), 'b')
plot(audTimes + soundOnsetAfterTrigger_ms, (audWav), 'r')
xline(soundOnsetAfterTrigger_ms, 'g', lineWidth=2)
hold off; xlabel('EEG-time after sound-onset [ms]');
ylabel('|Z|'); legend(["StimTrak", "AudWav[xcorr]"])
xlim([-500 +500]+stimTimes(pidx)); grid on;

subplot(515)
plot(lags/EEG.srate*1000, xr)
xlabel('Lag [ms]'); ylabel('xcorr'); hold on
plot(milliseconds(triggerLatency), max_xr, 'or')
title(sprintf('Max corr at %i ms | robust z = %.3f | mirr-sym r = %.3f', soundOnsetAfterTrigger_ms, rz, rsym))

drawnow;
if (exist('fnamePng','var'))
  exportgraphics(hf1, fnamePng)
  close(hf1)
end


end