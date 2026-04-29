function [eventTbl, jVol, isEscPressed] = myptb_waitloggingpulse(eventTbl, StimDur_sec, KEYCODE_ESC, KEYCODE_PULSE, tPulse1, tOnset, isShowPb, jVol)
if isShowPb
  upd = textprogressbar(ceil(StimDur_sec));
end
isEscPressed = false; isStillPlaying = true; nextTick = 1;
while not(isEscPressed) && isStillPlaying
  % CHECK if bailed or ended
  [~, ~, keyCode, ~] = KbCheck;
  isEscPressed = ismember(KEYCODE_ESC, find(keyCode));
  tNow = GetSecs - tPulse1;
  isStillPlaying = ((tNow-tOnset) < StimDur_sec);

  % CHECK if a pulse trigger came
  if ismember(KEYCODE_PULSE, find(keyCode))
    eventTbl = [eventTbl; table(nan, tNow, string(sprintf('vol-%04i', jVol)), "PULSE", ...
      VariableNames=["iTrl","time_sec", "fname","event"])];
    jVol = jVol + 1;
  end

  % UPDATE the progress bar for a single-trial-run
  if isShowPb && (tNow >= nextTick)
    nextTick = nextTick + 1;
    upd(round(tNow))
  end
end
end