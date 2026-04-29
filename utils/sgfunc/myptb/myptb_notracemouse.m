function Job = myptb_notracemouse(Job)
KEYCODE_ESC = 27;

Job = defaultjob(struct(TracingWindow_sec=inf, IsPlayAudio=false), Job);

% instruction at the top
Screen('TextSize', Job.PtrWin, Job.TextSize);
ScreenText = sprintf('LISTEN ONLY: CLICK to START');
DrawFormattedText(Job.PtrWin, ScreenText, 'center', [], Job.TextColor, [], [], [], Job.Vspace);

% draw axes
Job.AxesLabels = {'' '' '' ''};
Job = mypbt_drawaxes(Job);  % grab .AxesLength
Screen('Flip', Job.PtrWin); % update the screen
HideCursor;

%% WAIT FOR USER's INPUT
GetClicks;

ScreenText = sprintf('LISTEN ONLY: ESC to STOP');
DrawFormattedText(Job.PtrWin, ScreenText, 'center', [], Job.TextColor, [], [], [], Job.Vspace);
mypbt_drawaxes(Job);
Screen('Flip', Job.PtrWin);

%% init T0: Start play
% KbQueueStart(DevIdx); % start queueing events
if Job.IsPlayAudio
  PsychPortAudio('Start', Job.PtrAud, 1, 0, 0); % play audio if given
end
T0 = GetSecs;


%% PLAY
IsStillPlaying = true;
IsEscPressed = false;
T0_sec = 0;

while not(IsEscPressed) && IsStillPlaying
  [~, ~, keyCode, ~] = KbCheck(-1);
  IsEscPressed = ismember(KEYCODE_ESC, find(keyCode));
  T_sec = GetSecs - T0;
  IsStillPlaying = (T_sec) < (Job.TracingWindow_sec + .5);

  % SEND one-second marker
  if (T0_sec < floor(T_sec)) && isfield(Job,'PtrTrg')
    io64(Job.PtrTrg, Job.TriggerAddress, 128);
    WaitSecs(0.005); % 5-ms square wave
    io64(Job.PtrTrg, Job.TriggerAddress, 0);
    logthis('PLAY TIME (%i sec) TRIGGER [128]\n', floor(T_sec));
    T0_sec = floor(T_sec);
  end
  
  clear *_
end

% BAIL OUT: END of TRACING WINDOW or ESCAPE KEY PRESSED
PsychPortAudio('Stop', Job.PtrAud, 1, 0, 0); % stop audio
ScreenText = sprintf('LISTENING ONLY: END');
DrawFormattedText(Job.PtrWin, ScreenText, 'center', [], Job.TextColor, [], [], [], Job.Vspace);
Screen(Job.PtrWin,'Flip');
ShowCursor;



end