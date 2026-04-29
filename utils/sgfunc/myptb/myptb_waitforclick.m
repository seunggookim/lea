function [secs, keyCode] = myptb_waitforclick(Job)
% ONLY MAKE SENSE for 4-buttons Kensington trackball with TopLeft="Digit2", TopRight="Digit3"
% Job.ResponseKeys = ["1!", "2@", "3#", "4$"] 
% KensingtonWorks: TopLeft="Digit2", TopRight="Digit3"

KEYCODE_ESC = 27;
if ischar(Job.ResponseKeys)
  RestrictKeysForKbCheck([KEYCODE_ESC, KbName(Job.ResponseKeys)]); 
elseif isstring(Job.ResponseKeys)
  RestrictKeysForKbCheck([KEYCODE_ESC, arrayfun(@(x) KbName(char(x)), Job.ResponseKeys)]);
end
KbReleaseWait;
buttons = true;
while any(buttons) % wait for release
  [~,~,buttons] = GetMouse;
end
isInput = false;
while not(isInput)
  [~,~,keyCode] = KbCheck; % check for keyboard (TopLeft, TopRight)
  [~,~,buttons] = GetMouse;
  if find(buttons) == 1 % ButtomLeft click
    keyCode(KbName('1!')) = true;
  end
  if find(buttons) == 3 % ButtomRight click
    keyCode(KbName('4$')) = true;
  end
  isInput = any(keyCode);
end
secs = GetSecs;
RestrictKeysForKbCheck([]);

end