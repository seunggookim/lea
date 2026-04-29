function h = axespageannot(axes, j, varargin)
%AXESPAGEBOX
% h = axespageannot(axes, jPage, varargin)
% h = axespageannot(axes, jPage, String='xx', FontSize=10, ...)
% h = axespageannot(axes, jPage, 'xxx')


% parse inputs
p = inputParser;
p.KeepUnmatched = true;
addOptional(p, 'String', sprintf('(%s)', char(j+96)), @ischar);
addParameter(p, 'Fontsize', 11);
addParameter(p, 'FontWeight', 'bold');
addParameter(p, 'Color', 'k');
addParameter(p, 'BackgroundColor', 'none');
addParameter(p, 'EdgeColor', 'none');
addParameter(p, 'Position', [axes.pagebox.x(j), axes.pagebox.y(j)+axes.pagebox.h/2, 0, 0]);
addParameter(p, 'HorizontalAlignment', 'right');
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