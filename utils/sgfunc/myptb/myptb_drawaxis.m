function Job = myptb_drawaxis(Job)

winWidth = Job.ScreenRect(3)-Job.ScreenRect(1);
winHeight = Job.ScreenRect(4)-Job.ScreenRect(2);
winXCenter = winWidth/2;
winYCenter = winHeight/2;

%% GRID:
Job.AxesLength = winWidth*.4;
grids = linspace(-1, 1, 9)*Job.AxesLength;

% THESE ARE WINDOW COORDINATES, not display coordinates.
lineWidths = [1 1 2 1 3 1 2 1 1];
if not(isfield(Job,'TextColors'))
  Job.TextColors = [255 0 0; 0 255 0];
end
colors = [round(255*0.45*[1 1 1]); round(255*0.6*[1 1 1]); round(255*0.75*[1 1 1])];
colorAxes = colors(3,:);

Screen('DrawLine', Job.PtrWin, colors(lineWidths(1),:), ...
  winXCenter+grids(1), winYCenter, winXCenter+grids(9), winYCenter, lineWidths(1));
for i = 2:(numel(grids)-1)
  Screen('DrawLine', Job.PtrWin, colors(lineWidths(i),:), ...
    winXCenter+grids(i), winYCenter+sqrt(lineWidths(i))*15, winXCenter+grids(i), winYCenter-sqrt(lineWidths(i))*15, ...
    lineWidths(i));
end

% arrow heads:
i = 5;
arrowWidth = round(Job.AxesLength*0.07);
points = cell(1,3);
% East:
points{1} = [0 0; -arrowWidth -arrowWidth/2; -arrowWidth arrowWidth/2] + [winXCenter+grids(end)+3 winYCenter+grids(i)];
% West:
points{2} = [0 0; arrowWidth -arrowWidth/2; arrowWidth arrowWidth/2] + [winXCenter+grids(1)-3 winYCenter+grids(i)];
for j = [1 2]
  Screen('FillPoly', Job.PtrWin, colorAxes, points{j});
end

% Axes labels
alignX = {'right', 'left', 'center'};
alignY = {'top', 'top'};
Screen('TextSize', Job.PtrWin, round(Job.TextSize*1.3));
for j = [1 2]
  [~, ~, bbox, ~] = DrawFormattedText2(Job.AxesLabels{j}, 'win',Job.PtrWin, 'xalign',alignX{j}, ...
    'yalign',alignY{j}, 'baseColor',colorAxes, 'sx',points{j}(1,1), 'sy',points{j}(1,2)*1.1);
  % this version cannot remove bbox. So I just draw it over it.
  Screen('FillRect', Job.PtrWin, Job.FillRect, bbox);
  marginX = round(Job.TextSize*0.15);
  Screen('DrawText', Job.PtrWin, Job.AxesLabels{j}, bbox(1)+(-marginX*(j==2)), bbox(2), Job.TextColors(j,:));
end
Screen('TextSize', Job.PtrWin, Job.TextSize);

% max-min-max labels
maxMinMax = {'Max','Max','Min'};
alignX = {'right', 'left', 'center'};
alignY = {'bottom', 'bottom', 'bottom'};
points{3} = [0 0; 0 0] + [winXCenter+grids(5) winYCenter+grids(5)];
Screen('TextSize', Job.PtrWin, round(Job.TextSize*0.8));
for j = [1 2 3]
  [~, ~, bbox, ~] = DrawFormattedText2(maxMinMax{j}, 'win',Job.PtrWin, 'xalign',alignX{j}, ...
    'yalign',alignY{j}, 'baseColor',colorAxes, 'sx',points{j}(1,1), 'sy',points{j}(1,2)*0.9);
  % this version cannot remove bbox. So I just draw it over it.
  Screen('FillRect', Job.PtrWin, Job.FillRect, bbox);
  marginX = round(Job.TextSize*0.15);
  Screen('DrawText', Job.PtrWin, maxMinMax{j}, bbox(1)+(-marginX*(j==2)), bbox(2), colorAxes);
end
Screen('TextSize', Job.PtrWin, Job.TextSize);

end

