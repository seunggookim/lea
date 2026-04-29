function Job = helper_spm_smriprep(Job)
%HELPER_SPM_SMRIPREP
%   Job = helper_spm_smriprep(Job)
%
%     {'FnameAnat', 'IsEastern', 'IsMp2rage'}
%
% REF: http://www.fil.ion.ucl.ac.uk/spm/data/auditory/
% Many parameters can be simply default!

validatefields(Job, {'FnameAnat', 'IsEastern', 'IsMp2rage'})

% reorder images
if Job.IsMp2rage
  IdxUni = find(contains(Job.FnameAnat,'uni'));
  assert(numel(IdxUni)==1, 'For MP2RAGE image set, only one filename should include "uni"!')
  Job.FnameAnat = Job.FnameAnat([IdxUni setdiff(1:numel(Job.FnameAnat), IdxUni)]);
end


matlabbatch = {};
% Segment: Anatomical
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.spatial.preproc.channel    = arrayfun(@(x) struct(vols={x}, write=[0 1]), Job.FnameAnat);
matlabbatch{end}.spm.spatial.preproc.warp.write = [0 1]; % save the forward warping field
if Job.IsEastern
  matlabbatch{end}.spm.spatial.preproc.warp.affreg = 'eastern';
end

% Create skull-stripped images
%--------------------------------------------------------------------------
matlabbatch = [matlabbatch, struct()];
matlabbatch{end}.spm.util.imcalc.input = [ ...
  spm_file(Job.FnameAnat{1}, 'prefix', 'm'); ...
  cellfun(@(x) spm_file(Job.FnameAnat{1}, 'prefix', ['c',num2str(x)]), num2cell(1:3)', Uni=0) ...
  ];
matlabbatch{end}.spm.util.imcalc.output = spm_file(Job.FnameAnat{1}, 'prefix', 'bm');
matlabbatch{end}.spm.util.imcalc.expression = 'i1 .* (i2>.95 | i3>.95 | i4>.95)';

% RUN them all
spm('Defaults','fMRI');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

slices(Job.FnameAnat{1}, spm_file(Job.FnameAnat{1}, 'prefix', 'bm'), ...
  struct(fname_png=strrep(Job.FnameAnat{1}, '.nii', '.png'), layout=[3 7], xyz=['sag7';'cor7';'axi7']))

end
