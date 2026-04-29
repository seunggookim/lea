function Job = myptb_drawkeys(Job)

nBox = numel(Job.ResponseKeys);
Job = defaultjob(struct(...
  ExtremeKeyLabels={{'Min','Max'}}, ...
  PressedKey=nan, ...
  IsResponseKeyActive=true(1, nBox), ...
  IsShowResponseKeyNumber=true), ...
  Job, mfilename, false);

% Get screen size and center
[screenXpixels, screenYpixels] = Screen('WindowSize', Job.PtrWin);
xCenter = screenXpixels*0.5;
yCenter = round(screenYpixels*.7);

% Set box size
boxWidth  = 150;
boxHeight = 150;

% Compute positions for n boxes in a row
gap = 30; % space between boxes
totalWidth = nBox*boxWidth + (nBox-1)*gap;
startX = xCenter - totalWidth/2 + boxWidth/2; % the center of the first box

% Create N box centers
xPositions = startX + (0:(nBox-1)) * (boxWidth + gap);
yPositions = yCenter * ones(1,nBox);
if isfield(Job,'KeyBaseline_box')
  yPositions = yPositions - Job.KeyBaseline_box*boxHeight;
end

% Loop through boxes
for i = 1:nBox
  if Job.PressedKey == i
    textColor = [0 255 0];
  else
    textColor = Job.TextColor;
  end
  if not(Job.IsResponseKeyActive(i))
    textColor = [0 0 0];
  end

  % Create base rect and center it on desired position
  baseRect = [0 0 boxWidth boxHeight];
  centeredRect = CenterRectOnPointd(baseRect, xPositions(i), yPositions(i));

  % Draw rectangle outline
  Screen('FrameRect', Job.PtrWin, textColor, centeredRect, 4);

  if Job.IsShowResponseKeyNumber
    % Draw number in center
    DrawFormattedText(Job.PtrWin, num2str(i), 'center', 'center', textColor, [], [], [], [], [], centeredRect);
  end

  % Note "min", "max" for 1 and nBox
  centeredRect = CenterRectOnPointd(baseRect, xPositions(i), yPositions(i)+boxWidth*.8);
  if i == 1
    DrawFormattedText(Job.PtrWin, Job.ExtremeKeyLabels{1}, 'center', 'center', Job.TextColor, [], [], [], [], [], centeredRect);
  elseif i == nBox
    DrawFormattedText(Job.PtrWin, Job.ExtremeKeyLabels{2}, 'center', 'center', Job.TextColor, [], [], [], [], [], centeredRect);
  end
end


end