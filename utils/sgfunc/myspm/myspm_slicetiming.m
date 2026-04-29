function Job = myspm_slicetiming (Job)
% Job = myspm_slicetiming (Job)
%
% Slice-timing correction before realignment
% (cc0) 2025, seung-goo.kim@ae.mpg.de

if ~isstruct(Job)
  Job = struct('fname_epi',Job);
end
Job.fname_json = strrep(Job.fname_epi, '.nii', '.json');
Json = jsondecode(fileread(Job.fname_json));

[p1,f1,e1] = myfileparts(Job.fname_epi);
fname_in = [p1,'/',f1,e1];
fname_out = [p1,'/a',f1,e1];
if isfile(fname_out)
  logthis('FILE exists: "%s". Exiting.\n', fname_out)
  return
end
assert(isfile(fname_in))
info = niftiinfo([p1,'/',f1,e1]);
scans = cellfun(@(x) [p1,'/',f1,e1,',',num2str(x)], num2cell(1:info.ImageSize(4))', uni=false);

matlabbatch{1}.spm.temporal.st.scans = {scans};
matlabbatch{1}.spm.temporal.st.nslices = numel(Json.SliceTiming*1000);
matlabbatch{1}.spm.temporal.st.tr = Json.RepetitionTime;
matlabbatch{1}.spm.temporal.st.ta = Json.RepetitionTime;
matlabbatch{1}.spm.temporal.st.so = Json.SliceTiming*1000;
matlabbatch{1}.spm.temporal.st.refslice = Json.RepetitionTime/2;
matlabbatch{1}.spm.temporal.st.prefix = 'a';

spm_jobman('run', matlabbatch);
logthis('FILE created: ')
ls(fname_out)
end
