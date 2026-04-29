function Job = myptb_slider(Job)
KEYCODE_ESC = 27;
Job = defaultjob(struct(HeadRoom = 3, TracingWindow_sec = 3600, IsAborted = false, BarColors = [255 0 0; 0 255 0], ...
  TextColors = round(255*[0.1020    0.5961    0.3137; 0.8431    0.1882    0.1529]), Lang1='EN', ...
  TracingTarget=[], FnameMouse=[tempname,'.txt']), Job, mfilename, false);
if not(isfield(Job, 'CueText'))
  switch Job.Lang1
    case 'EN'
      Job.CueText = 'Check which direction is which!\nCLICK to START';
    case 'DE'
      Job.CueText = 'Prüfe, welche Richtung welche ist!\nKLICKEN zum START';
    case 'ES'
      Job.CueText = '¡Comprueba qué dirección es cuál!\nCLIC para COMENZAR';
  end
end

%% instruction at the top
Screen('TextSize', Job.PtrWin, round(Job.TextSize*0.9));
DrawFormattedText(Job.PtrWin, Job.CueText, 'center', Job.ScreenRect(4)/6, [255 255 255], [], [], [], Job.Vspace);
Screen('TextSize', Job.PtrWin, Job.TextSize);

% draw axes
Screen('TextSize', Job.PtrWin, Job.TextSize);
Job = myptb_drawaxis(Job);
Screen('Flip', Job.PtrWin); % update the screen

%%
KbReleaseWait;             % wait for all keys released

winXCenter = Job.ScreenRect(1) + 0.5*(Job.ScreenRect(3)-Job.ScreenRect(1));
winYCenter = Job.ScreenRect(2) + 0.5*(Job.ScreenRect(4)-Job.ScreenRect(2));

% Constrain Cursor position:
v = Screen('Version');
if (v.minor==0) && (v.point>=12)
  winBound = [0 0 Job.AxesLength*2 0];
  rectBound = CenterRectOnPointd(winBound, winXCenter, winYCenter);
  Screen('ConstrainCursor', Job.PtrWin, 1, rectBound);
end


%% WRITE the header line:
% if not(isfield(Job,'FnameMouse')), Job.FnameMouse = [tempname,'.txt']; end
fid = fopen(Job.FnameMouse, 'w');
if isfield(Job, 'AxesLabels')
  fprintf(fid, 'T_msec\t%s\n', Job.AxesLabels{1});
else
  fprintf(fid, 'T_msec\tX+\n');
end
fclose(fid); % flush

%% WAIT FOR USER's INPUT
SetMouse(winXCenter, winYCenter);
[~, keyCode] = myptb_waitforclick(Job);
logthis('Trackpad button pressed.\n')
if find(keyCode) == KEYCODE_ESC
  %fclose(fid);
  Job.IsAborted = true;
  return
end

%% init X0, Y0
SetMouse(winXCenter, winYCenter);
[X0, ~] = GetMouse; % Y: top-to-bottom direction
% DisplayCoordinate -> AxesCoordinate:
X0 = +(X0 - winXCenter)/Job.AxesLength;

%% DISPLAY FIXATION CROSS
Screen('TextSize', Job.PtrWin, Job.TextSize);
Job = myptb_drawaxis(Job);  % grab .AxesLength
Screen('Drawdots', Job.PtrWin, [winXCenter, winYCenter], 30, [255 255 255], [], 1);
% (optional: top text)
if isfield(Job,'TopText')
  Screen('TextSize', Job.PtrWin, round(Job.TextSize*.9));
  DrawFormattedText(Job.PtrWin, Job.TopText, 'center', Job.ScreenRect(4)/6, [256 256 256], [], [], [], Job.Vspace);
  Screen('TextSize', Job.PtrWin, Job.TextSize);
end
Screen('Flip', Job.PtrWin); % update the screen
WaitSecs(Job.HeadRoom); % separate Visual-Onset from Audio-Onest

%% init T0: Start play
PsychPortAudio('Start', Job.PtrAud);
T0_sec = GetSecs;
nextTick = 1;

% SEND START-TIME TRIGGER
mae_trigger(Job, 'sound-onset'); % does it make 35 ms delay?
isStillPlaying = true;
isEscPressed = false;
logthis('Trial duration = %s\n', hhmmss(Job.TracingWindow_sec))
upd = textprogressbar(ceil(Job.TracingWindow_sec));

%%
winWidth = Job.ScreenRect(3)-Job.ScreenRect(1);
winHeight = Job.ScreenRect(4)-Job.ScreenRect(2);
winXCenter = winWidth/2;
winYCenter = winHeight/2;

% arrow heads:
i = 5;
arrowWidth = round(Job.AxesLength*0.07);
% GRID:
grids = linspace(-1, 1, 9)*Job.AxesLength;

% THESE ARE WINDOW COORDINATES, not display coordinates.
lineWidths = [1 1 2 1 3 1 2 1 1];
colors = [round(255*0.45*[1 1 1]); round(255*0.6*[1 1 1]); round(255*0.75*[1 1 1])];
colorAxes = colors(3,:);

points = cell(1,3);
% East:
points{1} = [0 0; -arrowWidth -arrowWidth/2; -arrowWidth arrowWidth/2] + [winXCenter+grids(end)+3 winYCenter+grids(i)];
% West:
points{2} = [0 0; arrowWidth -arrowWidth/2; arrowWidth arrowWidth/2] + [winXCenter+grids(1)-3 winYCenter+grids(i)];

% Axes labels
alignX = {'right', 'left', 'center'};
alignY = {'top', 'top'};
marginX = round(Job.TextSize*0.15);
% max-min-max labels
maxMinMax = {'Max','Max','Min'};
alignX_mmm = {'right', 'left', 'center'};
alignY_mmm = {'bottom', 'bottom', 'bottom'};
points{3} = [0 0; 0 0] + [winXCenter+grids(5) winYCenter+grids(5)];


%%
Job.CurrentTarget = 0;

while not(isEscPressed) && isStillPlaying
  [~, ~, keyCode, ~] = KbCheck;
  isEscPressed = ismember(KEYCODE_ESC, find(keyCode));
  T_sec = GetSecs - T0_sec;
  isStillPlaying = (T_sec < Job.TracingWindow_sec);

  % Mark a target
  if not(isempty(Job.TracingTarget))
    % given the current time, what is the right target?
    Job.RightTarget = find(T_sec >= Job.TracingTarget.T, 1, 'last');
    
    % do I have to redraw the target?
    if Job.RightTarget > Job.CurrentTarget
      % redraw
      updatescreen()
      Job.CurrentTarget = Job.RightTarget;
    end
  end


  % Read mouse coordinate:
  [X, ~] = GetMouse; % Y: top-to-bottom direction
  % DisplayCoordinate -> AxesCoordinate:
  X = +(X - winXCenter)/Job.AxesLength;

  if (X ~= X0) % if the coordinate changes
    fid = fopen(Job.FnameMouse, 'a');
    fprintf(fid, '%.0f\t%.6f\n', T_sec*1000, X); % single-precision
    fclose(fid); % flush
    X0 = X;
    
    % UPDATE SCREEN
    updatescreen()
  end


  % SEND one-second marker
  if (T_sec >= nextTick)
    mae_trigger(Job, 'sound-1sec', false);
    nextTick = nextTick + 1;
    upd(round(T_sec))
  end
end
% fclose(fid); % flush (expected max size for 5 minutes = 1 MB)

% BAIL OUT: END of TRACING WINDOW or ESCAPE KEY PRESSED
if isEscPressed
  mae_trigger(Job, 'run-aborted');
  Job.IsAborted = true;
end

PsychPortAudio('Stop', Job.PtrAud, 1, 0, 0); % stop audio
mae_trigger(Job, 'sound-offset'); % SEND a TRIGGER
% KbQueueStop(devIdx);  % stop queueing events
Screen(Job.PtrWin,'Flip');
if (v.minor==0) && (v.point>=12)
  Screen('ConstrainCursor', Job.PtrWin, 0) % release the cursor
end
logthis('Mouse-tracing saved: "%s"\n', Job.FnameMouse);


%% NESTED FUNCTIONS
  function updatescreen()
    [X_px, Y_px] = GetMouse;

    % (optional: Mark a target)
    if not(isempty(Job.TracingTarget))
      % find the target's coordinates
      markerX_px = Job.TracingTarget.X(Job.RightTarget) * (grids(9)-grids(1))/2 + winXCenter;

      % draw the target
      Screen('Drawdots', Job.PtrWin, [markerX_px, Y_px], 60, [0 128 255], [], 1);

      % SEND a trigger: TARGET-ONSET
      mae_trigger(Job, "target-onset", false);
    end

    Screen('DrawLine', Job.PtrWin, colors(lineWidths(1),:), ...
      winXCenter+grids(1), winYCenter, winXCenter+grids(9), winYCenter, lineWidths(1));
    for j = 2:(numel(grids)-1)
      Screen('DrawLine', Job.PtrWin, colors(lineWidths(j),:), ...
        winXCenter+grids(j), winYCenter+sqrt(lineWidths(j))*15, ...
        winXCenter+grids(j), winYCenter-sqrt(lineWidths(j))*15, ...
        lineWidths(j));
    end
    for j = [1 2]
      Screen('FillPoly', Job.PtrWin, colorAxes, points{j});
    end

    Screen('TextSize', Job.PtrWin, round(Job.TextSize*1.3));
    for j = [1 2]
      [~, ~, bbox, ~] = DrawFormattedText2(Job.AxesLabels{j}, 'win',Job.PtrWin, 'xalign',alignX{j}, ...
        'yalign',alignY{j}, 'baseColor',colorAxes, 'sx',points{j}(1,1), 'sy',points{j}(1,2)*1.1);
      Screen('FillRect', Job.PtrWin, Job.FillRect, bbox);
      Screen('DrawText', Job.PtrWin, Job.AxesLabels{j}, bbox(1)+(-marginX*(j==2)), bbox(2), Job.TextColors(j,:));
    end
    Screen('TextSize', Job.PtrWin, Job.TextSize);

    Screen('TextSize', Job.PtrWin, round(Job.TextSize*0.8));
    for j = [1 2 3]
      [~, ~, bbox, ~] = DrawFormattedText2(maxMinMax{j}, 'win',Job.PtrWin, 'xalign',alignX_mmm{j}, ...
        'yalign',alignY_mmm{j}, 'baseColor',colorAxes, 'sx',points{j}(1,1), 'sy',points{j}(1,2)*0.9);
      Screen('FillRect', Job.PtrWin, Job.FillRect, bbox);
      Screen('DrawText', Job.PtrWin, maxMinMax{j}, bbox(1)+(-marginX*(j==2)), bbox(2), colorAxes);
    end
    Screen('TextSize', Job.PtrWin, Job.TextSize);


    % DRAW BAR + CURSOR
    if X_px<winXCenter
      Screen('DrawLine', Job.PtrWin, Job.BarColors(1,:), X_px, Y_px, winXCenter, Y_px, 6);
      Screen('Drawdots', Job.PtrWin, [X_px, Y_px], 30, Job.BarColors(1,:), [], 1);
    elseif X_px>winXCenter
      Screen('DrawLine', Job.PtrWin, Job.BarColors(2,:), winXCenter, Y_px, X_px, Y_px, 6);
      Screen('Drawdots', Job.PtrWin, [X_px, Y_px], 30, Job.BarColors(2,:), [], 1);
    else
      Screen('DrawLine', Job.PtrWin, [255 255 255], winXCenter, Y_px, X_px, Y_px, 6);
      Screen('Drawdots', Job.PtrWin, [X_px, Y_px], 30, [255 255 255], [], 1);
    end

    % (optional: top text)
    if isfield(Job,'TopText')
      Screen('TextSize', Job.PtrWin, round(Job.TextSize*.9));
      DrawFormattedText(Job.PtrWin, Job.TopText, 'center', Job.ScreenRect(4)/6, [256 256 256], [], [], [], Job.Vspace);
      Screen('TextSize', Job.PtrWin, Job.TextSize);
    end

    Screen('Flip', Job.PtrWin);
  end % of UPDATESCREEN
%%

end

function str = hhmmss(secs)
str = datestr(seconds(secs), 'hh:MM:ss');
end
