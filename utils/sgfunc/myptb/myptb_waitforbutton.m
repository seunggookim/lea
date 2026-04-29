function [secs, keyCode] = myptb_waitforbutton(Job)
% Job.ResponseKeys = "5%" means the keyboard (5), "5" means the keypad (5).
% Job.ResponseKeys = ["1!", "2@", "3#", "4$"] 

KEYCODE_ESC = 27;
if ischar(Job.ResponseKeys)
  RestrictKeysForKbCheck([KEYCODE_ESC, KbName(Job.ResponseKeys)]); 
elseif isstring(Job.ResponseKeys)
  RestrictKeysForKbCheck([KEYCODE_ESC, arrayfun(@(x) KbName(char(x)), Job.ResponseKeys)]);
end
CedrusResponseBox('ClearQueues', Job.CedPtr);
KbReleaseWait;
isInput = false;
while not(isInput)
  [~,secs,keyCode] = KbCheck; % check for keyboard
  evt = CedrusResponseBox('GetButtons', Job.CedPtr); % check for response button pad
  if not(isempty(evt)) && evt.action == 1 % only pressing-down
    % map the button to key
    keyCode(KbName(char(Job.ResponseKeys(ismember(Job.CedrusResponseBoxButtonIds, evt.buttonID))))) = true;
    secs = evt.ptbfetchtime;
  end
  
  isInput = any(keyCode);
end
RestrictKeysForKbCheck([]);

end