function Job = myptb_fixcross(Job)
if not(isfield(Job,'ColorAxes'))
  Job.ColorAxes = [0 0 0];
end

winW = Job.ScreenRect(3)-Job.ScreenRect(1);
winH = Job.ScreenRect(4)-Job.ScreenRect(2);
winWc = winW/2;
winHc = winH/2;

Job.AxesLength = min(winH*.1, winW*.1);
grids = [-0.5 0 0.5]*Job.AxesLength;
Screen('DrawLine', Job.PtrWin, Job.ColorAxes, winWc+grids(2), winHc+grids(1), winWc+grids(2), winHc+grids(end), 4);
Screen('DrawLine', Job.PtrWin, Job.ColorAxes, winWc+grids(1), winHc+grids(2), winWc+grids(end), winHc+grids(2), 4);
Screen(Job.PtrWin,'Flip');

end