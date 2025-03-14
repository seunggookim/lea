

function [data, cmap] = helper_readfslatlas(atlasdescp)
% Blame windows users:
if ~isunix && ~ismac, error('Why Windows?'), end 

%--- FSL Harvard-Oxford Cort+Subcort --------------------------------------

% Find filenames
fslpath = getenv('FSLDIR');
str = strsplit(atlasdescp,'-');
if numel(str)>1
  suffix = str{2};
else
  suffix = 'thr25';
end
fn_atl{1} = [fslpath,'/data/atlases/HarvardOxford/',...
  'HarvardOxford-cort-maxprob-',suffix,'-1mm.nii.gz'];
fn_xml{1} = [fslpath,'/data/atlases/HarvardOxford-Cortical.xml'];
fn_atl{2} = [fslpath,'/data/atlases/HarvardOxford/',...
  'HarvardOxford-sub-maxprob-',suffix,'-1mm.nii.gz'];
fn_xml{2} = [fslpath,'/data/atlases/HarvardOxford-Subcortical.xml'];
fn = dir([fslpath,'/fslpython/envs/fslpython/lib/python*/',...
  'site-packages/fsleyes/assets/luts/harvard-oxford-cortical.lut']);
assert(numel(fn)==1)
fn_lut{1} = fullfile(fn.folder, fn.name);
fn = dir([fslpath,'/fslpython/envs/fslpython/lib/python*/',...
  'site-packages/fsleyes/assets/luts/harvard-oxford-subcortical.lut']);
assert(numel(fn)==1)
fn_lut{2} = fullfile(fn.folder, fn.name);
for i = 1:2
  assert(isfile(fn_atl{i}), 'file "%s" NOT FOUND!', fn_atl{i})
  assert(isfile(fn_xml{i}), 'file "%s" NOT FOUND!', fn_xml{i})
  assert(isfile(fn_lut{i}), 'file "%s" NOT FOUND!', fn_lut{i})
end

% Read files
nctx = 48;
nstx = 21;
ctx = helper_read(fn_atl{1});
assert(max(ctx.vol(:))==nctx)
stx = helper_read(fn_atl{2});
assert(max(stx.vol(:))==nstx)
% remove large masks (cortical-WM, cortcial-GM, CSF)
lbl2remove = [1 2 3 12 13 14];
stx.vol(ismember(stx.vol, lbl2remove)) = 0;

% Combine CORTICAL + SUBCORTICAL
data = ctx;
data.vol(stx.vol>0) = nctx+stx.vol(stx.vol>0);
data.vol(data.vol==0) = nan;

% Read lookup table:
tbl_ctx = myfsl_readlut(fn_lut{1});
assert(size(tbl_ctx,1) == nctx)
tbl_stx = myfsl_readlut(fn_lut{2});
assert(size(tbl_stx,1) == nstx)

cmap_ctx = [tbl_ctx.r, tbl_ctx.g, tbl_ctx.b];
cmap_stx = [tbl_stx.r, tbl_stx.g, tbl_stx.b];
cmap = [cmap_ctx; cmap_stx];



end
