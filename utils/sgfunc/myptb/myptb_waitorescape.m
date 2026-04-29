function isEscPressed = myptb_waitorescape(waitUntil_sec)
% isEspaced = myptb_waitorescape(waitUntil_sec)
KEYCODE_ESC = 27;
isNotDone = true;
T0 = GetSecs;
isEscPressed = false;
while not(isEscPressed) && isNotDone
  [~, ~, keyCode, ~] = KbCheck(-1);
  isEscPressed = ismember(KEYCODE_ESC, find(keyCode));
  T_sec = GetSecs - T0;
  isNotDone = T_sec < waitUntil_sec;
end
end
