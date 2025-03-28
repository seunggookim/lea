function ax = axeslayout (layout, inset_box, outset_fig, pagemargin_fig, pageboxheight_fig, is_tightpagebox)
% ax = axeslayout (layout, inset_box, outset_fig, pagemargin_fig, pageboxheight_fig)
%
% layout     = [RxCxPrxPc] # of rows, # of columns, # of page-rows, # of page-columns
%                 of a grid of plotboxes to construct
% inset_box  = [1x4] <left right top bottom> inset margin within the grid
%                 values between 0 and 1 [w.r.t a plotbox size]
%                 default = [.25, .03, .14, .25]
%              or 'tight' = [.10, .03, .07, .13]
% outset_fig = [1x4] <LEFT RIGHT TOP BOTTOM> outset margin outside the grid
%                 values between 0 and 1 [w.r.t a figure size]
%                 default = [.020, .020, .020, .020]
%              or 'tight' = [.005, .005, .005, .005]
%
% pagemargin_fig = [1x2] the page margin (WIDTH and HIEHGT) in a proportion to a figure
% pageboxheight_fig = [1x1] the page title box height in a proportion to a figure height
% -------------------------------------------------
%                        TOP
% -------------------------------------------------
%      |....................................|
%      |:      top       ::      top       :|
%      |....................................|
% LEFT |:left:(^o^):right::left:(TxT):right:| RIGHT
%      |....................................|
%      |:     bottom     ::     bottom     :|
%      |....................................|
% -------------------------------------------------
%                      BOTTOM
% -------------------------------------------------
%
%
% SEE ALSO: AXESPOS
% (cc) 2019-2024, seung-goo.kim@ae.mpg.de


if ~exist('inset_box','var') || isempty(inset_box)
  inset_box = [.25, .03, .14, .25];  % [left right top bottom]
elseif strcmp(inset_box,'tight')
  inset_box = [.1, .03, .07, .13];  % [left right top bottom]
end
if ~exist('outset_fig','var') || isempty(outset_fig)
  outset_fig = [.02, .02, .02, .02]; % [LEFT RIGHT TOP BOTTOM]
elseif strcmp(outset_fig,'tight')
  outset_fig = [.005 .005 .005 .005]; % [LEFT RIGHT TOP BOTTOM]
end
if numel(layout) < 4, layout = [layout, 1, 1]; end
if ~exist('pagemargin_fig','var') || isempty(pagemargin_fig)
  pagemargin_fig = [0.02*(layout(4)>1), 0.03*(layout(3)>1)];
end
if ~exist('pageboxheight_fig','var') || isempty(pageboxheight_fig)
  pageboxheight_fig = 0.02;
end
if ~exist('is_tightpagebox','var') || isempty(is_tightpagebox)
  is_tightpagebox = false;
end


%% recontruct a grid (rows x cols x page-rows x page-cols) -> (rows* x cols*)
nRowsToDraw = prod(layout([1 3]));
nColsToDraw = prod(layout([2 4]));
nAxesToDraw = prod(layout);

boxWidth_fig  = ( (1-sum(outset_fig(1:2))) - pagemargin_fig(1)*(layout(4)-1) ) / nColsToDraw;
boxHeight_fig = ( (1-sum(outset_fig(3:4))) - (pagemargin_fig(2))*(layout(3)-1) - pageboxheight_fig*layout(3)) / nRowsToDraw;
posX_fig = outset_fig(1) + (0:nColsToDraw-1)*boxWidth_fig;
shiftX_fig = repmat( posX_fig, [1, nRowsToDraw] );

posY_fig = outset_fig(4) + (nRowsToDraw-1:-1:0)*boxHeight_fig;
shiftY_fig = reshape( repmat( posY_fig, [nColsToDraw, 1] ), 1,[]);

%% re-order stuff
orderTensor = permute( reshape(1:nAxesToDraw, layout([2 1 4 3])), [2 1 4 3] );
orderMatrix = [];
for k = 1:layout(3)
  orderSubMatrix = [];
  for l = 1:layout(4)
    orderSubMatrix = [orderSubMatrix, orderTensor(:,:,k,l)];
  end
  orderMatrix = [orderMatrix; orderSubMatrix];
end
orderVector = reshape(orderMatrix',1,[]);
[~,revOrderVector] = sort(orderVector);  % 천재!🤩

%% set page title box
inset_box_true = inset_box;
inset_box = [0 0 0 0];

w = boxWidth_fig * (1-sum(inset_box(1:2)));
h = boxHeight_fig * (1-sum(inset_box(3:4)));
x = boxWidth_fig*inset_box(1) + shiftX_fig(revOrderVector);
y = boxHeight_fig*inset_box(4) + shiftY_fig(revOrderVector);

idxPage = ceil(orderVector/prod(layout([1,2])));
idxPageRow = ceil(idxPage/layout(4));
idxPageCol = mod(idxPage-1, layout(4))+1;

if prod(layout([3 4]))>1
  x = x + (idxPageCol(revOrderVector)-1)*pagemargin_fig(1);
  x = x(1:prod(layout([1 2])):end);
  y = y + (layout(3) - idxPageRow(revOrderVector))*(pagemargin_fig(2)+pageboxheight_fig);
  y = y(1:prod(layout([1 2])):end) + boxHeight_fig;
%   y = y + (layout(3) - idxPageRow(revOrderVector))*pagemargin_fig(2);
%   y = boxHeight_fig + posY_fig(1)*ones(1, layout(3));
  pagebox = struct(x = x, y = y, w = boxWidth_fig*layout(2), h = pageboxheight_fig);
else
  pagebox = [];
end

%%
inset_box = inset_box_true;

w = boxWidth_fig * (1-sum(inset_box(1:2)));
h = boxHeight_fig * (1-sum(inset_box(3:4)));
x = boxWidth_fig*inset_box(1) + shiftX_fig(revOrderVector);
y = boxHeight_fig*inset_box(4) + shiftY_fig(revOrderVector);

idxPage = ceil(orderVector/prod(layout([1,2])));
idxPageRow = ceil(idxPage/layout(4));
idxPageCol = mod(idxPage-1, layout(4))+1;

if prod(layout([3 4]))>1
  x = x + (idxPageCol(revOrderVector)-1)*pagemargin_fig(1);
  y = y + (layout(3) - idxPageRow(revOrderVector))*(pagemargin_fig(2)+pageboxheight_fig);
end



%% output
ax = struct(x=x, y=y, w=w, h=h, pagebox=pagebox);

%%
if is_tightpagebox
  ax.pagebox.x = ax.x(1:prod(layout([1 2])):end);
  ax.pagebox.w = ax.pagebox.w - boxWidth_fig*inset_box(1);
end

end



%%
function TEST()
axes = axeslayout([2 4]);
figure
for i = 1:8
  axespos(axes, i)
  title(i)
end
%%
axes = axeslayout([3 4 2]);
figure
for i = 1:(3*4*2)
  axespos(axes, i)
  title(i)
end
%%
for kPage = 1:10
  clf
  layout = [3 2 kPage];
  axes = axeslayout(layout, [0 0 0 0], [.02, .02, .02, .02], 1, .02);
  for i = 1:prod(layout)
    axespos(axes, i)
    title(i); box on
  end
  drawnow; pause(1)
end
%%
clf;
axesLayout = axeslayout([2 3 3 4],[0 0 0 0]);
for i = 1:numel(axesLayout.x)
  axespos(axesLayout, i)
  text(0.5, 0.5, num2str(i))
  box on
end
for j = 1:numel(axesLayout.pagebox.x)
  axespagebox(axesLayout,j, num2str(j))
end
%%
clf;
axesLayout = axeslayout([2 3 3 4]);
for i = 1:numel(axesLayout.x)
  axespos(axesLayout, i)
  text(0.5, 0.5, num2str(i))
  box on
end
for j = 1:numel(axesLayout.pagebox.x)
  axespagebox(axesLayout,j, num2str(j))
end

%%
clf;
axesLayout = axeslayout([2 3 3 4],[],[],[],[],1);
for i = 1:numel(axesLayout.x)
  axespos(axesLayout, i)
  text(0.5, 0.5, num2str(i))
  box on
end
for j = 1:numel(axesLayout.pagebox.x)
  axespagebox(axesLayout, j)
  axespageannot(axesLayout, j)
end


end
