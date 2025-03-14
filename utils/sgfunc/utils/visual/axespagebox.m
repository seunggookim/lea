function h = axespagebox(axes, j, varargin)
%AXESPAGEBOX
% h = axespagebox(axes, jPage, varargin)
% h = axespagebox(axes, jPage, String='xx', FontSize=10, ...)
% h = axespagebox(axes, jPage, 'xxx')


% set up inputs
p = inputParser;
p.KeepUnmatched = true;
addOptional(p, 'String', sprintf('Page %g', j), @ischar);
addParameter(p, 'Fontsize', 12);
addParameter(p, 'FontWeight', 'bold');
addParameter(p, 'Color', 'w');
addParameter(p, 'BackgroundColor', .75*[1, 1, 1]);
addParameter(p, 'EdgeColor', 'none');
addParameter(p, 'Position', [axes.pagebox.x(j), axes.pagebox.y(j), axes.pagebox.w, axes.pagebox.h]);
addParameter(p, 'HorizontalAlignment', 'center');
addParameter(p, 'VerticalAlignment', 'middle');
parse(p, varargin{:})

% run it!
axespos(axes.pagebox, j);
vararginlike = parsertovarargin(p);
h = annotation('textbox', vararginlike{:});
axis off
if not(nargout)
  clear h
end

end
