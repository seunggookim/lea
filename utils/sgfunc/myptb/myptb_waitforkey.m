function [secs, keyCode] = myptb_waitforkey(keyChar)
% keyChar = "5%" means the keyboard (5), "5" means the keypad (5).
% keyChar = ["1!", "2@", "3#", "4$"] 
KEYCODE_ESC = 27;
if ischar(keyChar)
  RestrictKeysForKbCheck([KEYCODE_ESC, KbName(keyChar)]); 
elseif isstring(keyChar)
  RestrictKeysForKbCheck([KEYCODE_ESC, arrayfun(@(x) KbName(char(x)), keyChar)]);
end
[secs, keyCode] = KbStrokeWait; 
RestrictKeysForKbCheck([]);
end