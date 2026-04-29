function Job = mytedana_proc(Job)
% Job = mytedana_proc(Job)
%
% Job requires:
%  .FnamesNifti
% (.FnamesJson)

Job = defaultjob(struct(DnameTedEnv='~/git/_venvs/tedenv/'), Job, mfilename);
assert(isfolder(Job.DnameTedEnv), 'TedEnv="%s" NOT EXIST!', Job.DnameTedEnv)
[dnProc,name,ext] = myfileparts(Job.FnamesNifti{1});
name_ = strrep(name,'_e1','');
dnOutput = [dnProc,'/',name_,'.tedana'];
if not(isfolder(dnOutput)), mkdir(dnOutput); end
if not(isfield(Job, 'FnamesJson'))
  Job.FnamesJson = cellfun(@(x) strrep(x, ext, '.json'), Job.FnamesNifti, uni=false);
end

%% Read TEs from JSON files
strEchoTimes = '';
for i = 1:numel(Job.FnamesJson)
  Json = jsondecode(fileread(Job.FnamesJson{i}));
  strEchoTimes = [strEchoTimes, sprintf('%.4f ', Json.EchoTime * 1000)];
end

%% Create the brain mask using SYNTHSTRIP!
fnMask = [dnOutput,'/te1_brain_mask.nii.gz'];
if not(isfile(fnMask))
  system(sprintf('FSLOUTPUTTYPE=NIFTI_GZ; fslmaths %s -Tmean %s/te1_mean', Job.FnamesNifti{1}, dnOutput));
  system(sprintf('mri_synthstrip -i %s/te1_mean.nii.gz -o %s', dnOutput, fnMask))
  system(sprintf('FSLOUTPUTTYPE=NIFTI_GZ; fslmaths %s -thr 1 -bin %s', fnMask, fnMask));
end
assert(isfile(fnMask), 'mri_synthstrip FAILED!')

%% RUN it
fnDenoised = [dnOutput,'/desc-denoised_bold.nii.gz'];
if not(isfile(fnDenoised))
  strFnames = sprintf('%s ', string(Job.FnamesNifti));
  cmd = ['module purge; module load Python/3.9.5-GCCcore-10.3.0-bare; ', ...
    sprintf('source %s/bin/activate; ', Job.DnameTedEnv), ...
    sprintf('tedana -d %s -e %s --out-dir %s --mask %s --ica_method robustica --n_robust_runs 100 ', ...
    strFnames, strEchoTimes, dnOutput, fnMask)];
  % cfg = struct(CpuPerTask=8, Mem_GB=16, IsWait=1); %
  % slurmsh(cmd, cfg);
  system(cmd)
end
assert(isfile(fnDenoised), 'denoised-bold NOT CREATED!')

%% UNgzip for SPM
src = [name_,'.tedana/desc-denoised_bold.nii.gz'];
trg = [name_,'_tedana.nii'];
system(sprintf('cd %s; gunzip --stdout %s > %s', dnProc, src, trg));

% copy Json
fnJson = [dnProc,'/',strrep(trg, '.nii', '.json')];
copyfile(Job.FnamesJson{1}, fnJson)
logthis('FILE copied: ')
ls(fnJson)

%% VIEW decomposition and classification
viewtedana(dnOutput)

end

function viewtedana(DnTedana)
pwd0 = pwd;
cd(DnTedana)
Base = 'te1_mean.nii.gz';
[img, info] = niftireadgz('desc-ICA_components.nii.gz');
TblMixing = readtable('desc-ICA_mixing.tsv', FileType='text');
TblTedana = readtable('desc-tedana_metrics.tsv', FileType='text', Delimiter='\t');

idx = ismember(TblTedana.classification, 'accepted');
Accepted = [];
Accepted.vol = img(:,:,:,idx);
Accepted.info = info;
Accepted.ts = TblMixing(:,idx).Variables;
Accepted.expl = TblTedana.normalizedVarianceExplained(idx)*100;

slicespcts(Base, Accepted, struct(fnamePng='components_accepted.png'))
%%

idx = ismember(TblTedana.classification, 'rejected');
Rejected = [];
Rejected.vol = img(:,:,:,idx);
Rejected.info = info;
Rejected.ts = TblMixing(:,idx).Variables;
Rejected.expl = TblTedana.normalizedVarianceExplained(idx)*100;

slicespcts(Base, Rejected, struct(fnamePng='components_rejected.png'))
cd(pwd0)
end