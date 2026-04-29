function Job = myptb_drawaxes(Job)

winWidth = Job.ScreenRect(3)-Job.ScreenRect(1);
winHeight = Job.ScreenRect(4)-Job.ScreenRect(2);
winXCenter = winWidth/2;
winYCenter = winHeight/2;

%% GRID:
Job.AxesLength = min(winHeight*.4, winWidth*.4);
grids = linspace(-1, 1, 9)*Job.AxesLength;

% THESE ARE WINDOW COORDINATES, not display coordinates.
lineWidths = [1 1 2 1 3 1 2 1 1];
colorAxes = round(255*0.75*[1 1 1]);
colors = [round(255*0.45*[1 1 1]); round(255*0.6*[1 1 1]); round(255*0.75*[1 1 1])];

for i = 1:numel(grids)
  Screen('DrawLine', Job.PtrWin, colors(lineWidths(i),:), ...
    winXCenter+grids(i), winYCenter+grids(1), winXCenter+grids(i), winYCenter+grids(end), lineWidths(i));
  Screen('DrawLine', Job.PtrWin, colors(lineWidths(i),:), ...
    winXCenter+grids(1), winYCenter+grids(i), winXCenter+grids(end), winYCenter+grids(i), lineWidths(i));
end

% arrow heads:
i = 5;
arrowWidth = round(Job.AxesLength*0.07);
points = {};
% East:
points{1} = [0 0; -arrowWidth -arrowWidth/2; -arrowWidth arrowWidth/2] + [winXCenter+grids(end)+3 winYCenter+grids(i)];
% North:
points{2} = [0 0; -arrowWidth/2 arrowWidth; arrowWidth/2 arrowWidth] + [winXCenter+grids(i) winYCenter+grids(1)-3];
% West:
points{3} = [0 0; arrowWidth -arrowWidth/2; arrowWidth arrowWidth/2] + [winXCenter+grids(1)-3 winYCenter+grids(i)];
% South:
points{4} = [0 0; -arrowWidth/2 -arrowWidth; arrowWidth/2 -arrowWidth] + [winXCenter+grids(i) winYCenter+grids(end)+3];
for j = 1:4
  Screen('FillPoly', Job.PtrWin, colorAxes, points{j});
end

% Axes labels
alignX = {'left', 'center', 'right', 'center'};
alignY = {'center', 'bottom', 'center', 'top'};
for j = 1:4
    [~, ~, bbox, ~] = DrawFormattedText2(Job.AxesLabels{j}, 'win',Job.PtrWin, ...
      'xalign',alignX{j}, 'yalign',alignY{j}, 'baseColor',colorAxes, 'sx',points{j}(1,1), 'sy',points{j}(1,2));
    % this version cannot remove bbox. So I just draw it over it.
    Screen('FillRect', Job.PtrWin, Job.FillRect, bbox);
    marginX = round(Job.TextSize*0.1);
    Screen('DrawText', Job.PtrWin, Job.AxesLabels{j}, bbox(1)+(-marginX*(j==3)), bbox(2), colorAxes);
end


end
