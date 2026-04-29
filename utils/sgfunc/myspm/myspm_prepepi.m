function myspm_prepepi(Job)

% slice timing correction
fn_epi = spm_file(Job.FnameEpi, 'prefix','a');
if not(isfile(fn_epi))
  myspm_slicetiming(Job.FnameEpi);
end

% realignment
Job.FnameEpi = spm_file(fn_epi, 'prefix','r');
if not(isfile(Job.FnameEpi))
  myspm_realign(fn_epi);
  myspm_viewrp(fn_epi);
end

end