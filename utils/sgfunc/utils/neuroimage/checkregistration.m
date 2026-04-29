function checkregistration(fnamesImages, fnamePdf)
%CHECKREGISTRATION creates orthogonal slices to check registration of multiple images
% checkregistration(fnamesImages, [fnamePdf])
%
%   FNAMEIMAGES is a cell array or a string array of NIFTI images
%
%   (FNAMEPDF) is a character array of a PDF to save if given
%
% (CC4-BY) 2024, seung-goo.kim@ae.mpg.de

if iscell(fnamesImages)
  fnamesImages = string(fnamesImages);
end
fnamesImages = reshape(fnamesImages, 1, []);
for fname = fnamesImages
  assert(isfile(fname))
end

nImages = numel(fnamesImages);
info = niftiinfo(fnamesImages(1));
ijk = round(xyz2ijk([0 0 0], info));

slices = {
  zeros([info.ImageSize([2,3]), nImages])
  zeros([info.ImageSize([1,3]), nImages])
  zeros([info.ImageSize([1,2]), nImages])
  };

for iImg = 1:nImages
  fname = fnamesImages(iImg);
  mri = helper_conform(helper_read(fname));

  slices{1}(:,:,iImg) = squeeze(mri.vol(ijk(1),:,:));
  slices{2}(:,:,iImg) = squeeze(mri.vol(:,ijk(2),:));
  slices{3}(:,:,iImg) = squeeze(mri.vol(:,:,ijk(3)));
end

%%
FIG_POSITION = [1 1 700 700];
if exist('fnamePdf','var')
  FIG_VISIBLE = false;
else
  FIG_VISIBLE = true;
end

figure(Color='w', ColorMap=bone, Position=FIG_POSITION, visible=FIG_VISIBLE)
colormap = get_colormap(nImages,1);
layout = axeslayout([3,3], 'tight', 'tight');
for jDim = 1:3
  axespos(layout, jDim); hold on
  for iImg = 1:nImages
    contour(slices{jDim}(:,:,iImg)', 1, EdgeColor=colormap(iImg,:), LineWidth=0.5);
  end
  axis image xy; grid on
  if jDim == 1, title(sprintf('#images=%i',nImages)); end
  
end
for jDim = 1:3
  axespos(layout, jDim+3); imagesc(mean(slices{jDim},3)'); axis image xy;
  if jDim == 1, title('Mean'); end
end
for jDim = 1:3
  axespos(layout, jDim+6); imagesc(std(slices{jDim},[],3)'); axis image xy;
  if jDim == 1, title('Std'); end
end
%%

if exist('fnamePdf','var')
%   exportgraphics(gcf, fnamePdf, 'ContentType', 'vector')
  export_fig(fnamePdf)
  close(gcf)
end

end
