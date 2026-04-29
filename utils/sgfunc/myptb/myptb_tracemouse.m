function Job = myptb_tracemouse(Job)

Job = defaultjob(struct(TracingWindow_sec=inf, IsPlayAudio=false), Job);
Job.IsAborted = false;

% instruction at the top
Screen('TextSize', Job.PtrWin, Job.TextSize);
ScreenText = sprintf('CLICK to START');
DrawFormattedText(Job.PtrWin, ScreenText, 'center', 'center', [0 255 0], [], [], [], Job.Vspace);

% draw axes
Screen('TextSize', Job.PtrWin, Job.TextSize);
Job = myptb_drawaxes(Job);  % grab .AxesLength
Screen('Flip', Job.PtrWin); % update the screen

%%
KbReleaseWait;             % wait for all keys released
devIdx = GetMouseIndices;  % In Windows, all mouses are unified.
devIdx = devIdx(1);        % So, just pick the first one.
KbQueueCreate(devIdx);

winXCenter = Job.ScreenRect(1) + 0.5*(Job.ScreenRect(3)-Job.ScreenRect(1));
winYCenter = Job.ScreenRect(2) + 0.5*(Job.ScreenRect(4)-Job.ScreenRect(2));

% Constrain Cursor position:
v = Screen('Version');
if (v.minor==0) && (v.point>=12)
  winBound = [0 0 Job.AxesLength*2 Job.AxesLength*2];
  rectBound = CenterRectOnPointd(winBound, winXCenter, winYCenter);
  Screen('ConstrainCursor', Job.PtrWin, 1, rectBound);
end

% Change cursor shape:
% ShowCursor('CrossHair');


%% WRITE the header line:
if not(isfield(Job,'FnameMouse')), Job.FnameMouse = [tempname,'.txt']; end
fid = fopen(Job.FnameMouse, 'w');
if isfield(Job, 'AxesLabels')
  fprintf(fid, 'T_msec\t%s\t%s\n', Job.AxesLabels{1}, Job.AxesLabels{2});
else
  fprintf(fid, 'T_msec\tX+\tY+\n');
end
% fclose(fid); % flush

%% WAIT FOR USER's INPUT
SetMouse(winXCenter, winYCenter);
[~,~,~,whichButton] = GetClicks;
if whichButton==3
  fclose(fid);
  Job.IsAborted = true;
  return
end

%% init X0, Y0
SetMouse(winXCenter, winYCenter);
[X0, Y0] = GetMouse; % Y: top-to-bottom direction
% DisplayCoordinate -> AxesCoordinate:
X0 = +(X0 - winXCenter)/Job.AxesLength;
Y0 = -(Y0 - winYCenter)/Job.AxesLength; % Y: bottom-to-top direction

%% init T0: Start play
KbQueueStart(devIdx); % start queueing events
if Job.IsPlayAudio
  PsychPortAudio('Start', Job.PtrAud, 1, 0, 0); % play audio if given
end
T0_sec = GetSecs;
nextTick = 1;

% SEND START-TIME TRIGGER
mae_trigger(Job, 'sound-onset');

% DISPLAY STOP INSTRUCTION
Screen('TextSize', Job.PtrWin, Job.TextSize);
Job = myptb_drawaxes(Job);  % grab .AxesLength
Screen('Flip', Job.PtrWin); % update the screen

KEYCODE_ESC = 27;
isStillPlaying = true;
isEscPressed = false;

while not(isEscPressed) && isStillPlaying
  [~, ~, keyCode, ~] = KbCheck(-1);
  isEscPressed = ismember(KEYCODE_ESC, find(keyCode));
  T_sec = GetSecs - T0_sec;
  isStillPlaying = (T_sec) < (Job.TracingWindow_sec + .5);

  % Read mouse coordinate:
  [X, Y] = GetMouse; % Y: top-to-bottom direction
  % DisplayCoordinate -> AxesCoordinate:
  X = +(X - winXCenter)/Job.AxesLength;
  Y = -(Y - winYCenter)/Job.AxesLength; % Y: bottom-to-top direction

  if (X ~= X0) || (Y ~= Y0) % if the coordinate changes
    fprintf(fid, '%.0f\t%.6f\t%.6f\n', T_sec*1000, X, Y); % single-precision
    X0 = X; Y0 = Y; % update the current coordinate
  end

  % DRAW TARGET (or making the cursor bigger somehow?)
  if isfield(Job, 'TracingTarget')
    Idx = find(T_sec>=Job.TracingTarget.T, 1, 'last');
    X_ = Job.TracingTarget.X(Idx)*Job.AxesLength + winXCenter;
    Y_ = -Job.TracingTarget.Y(Idx)*Job.AxesLength + winYCenter;
    Screen('Drawdots', Job.PtrWin, [X_, Y_], 50, [0 255 0], [], 1);
  end

  %  DRAW CURSOR
  [X_, Y_] = GetMouse; % from the cursor
  myptb_drawaxes(Job);
  Screen('Drawdots', Job.PtrWin, [X_, Y_], 30, [255 0 0], [], 1);
  Screen('Flip', Job.PtrWin);

  % SEND one-second marker
  if (T_sec >= nextTick)
    mae_trigger(Job, 'sound-1sec');
    nextTick = nextTick + 1;
  end

  clear *_
end
fclose(fid); % flush (expected max size for 5 minutes = 1 MB)

% BAIL OUT: END of TRACING WINDOW or ESCAPE KEY PRESSED
if isEscPressed
  mae_trigger(Job, 'run-aborted');
  Job.IsAborted = true;
else
  % SEND END-TIME TRIGGER
  mae_trigger(Job, 'sound-offset');
end

PsychPortAudio('Stop', Job.PtrAud, 1, 0, 0); % stop audio
KbQueueStop(devIdx);  % stop queueing events
KbQueueRelease(devIdx); % clean up the queue
Screen(Job.PtrWin,'Flip');
if (v.minor==0) && (v.point>=12)
  Screen('ConstrainCursor', Job.PtrWin, 0) % release the cursor
end
logthis('Mouse-tracing saved: "%s"\n', Job.FnameMouse);

end
