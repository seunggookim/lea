function sgfunc_addpath()
[mypath,~,~] = fileparts(mfilename('fullpath'));
paths = genpath(mypath);
paths_cell = strsplit(paths,':');
paths_cell = paths_cell(~contains(paths_cell,'trash'));
addpath(strjoin(paths_cell,':'))
warning off MATLAB:prnRenderer:opengl
warning off export_fig:exportgraphics

set(0, 'DefaultAxesColorOrder', brewermap(5, 'Set1'));
set(0, 'DefaultLegendBox','off')
set(0, 'DefaultLegendLocation','best')
set(0, 'DefaultAxesFontname','Ubuntu')
set(0, 'DefaultFigurePosition',[1 300 560 420])

% if contains(version, 'R2025')
%   set(0, 'DefaultFigureColor','k')
% else
%   set(0, 'DefaultFigureColor','w')
% end
set(0, 'DefaultFigureColor','w')

end
