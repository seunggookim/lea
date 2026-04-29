function fn_t1w_coreg = myfsl_prept1wcoreg(fn_t1w, fn_epi)
fnMeanEpi = [tempname,'.nii'];
fnT1w = [tempname,'.nii'];
system(sprintf('FSLOUTPUTTYPE=NIFTI; fslmaths %s -add 0 %s;', fn_t1w, fnT1w));
system(sprintf('FSLOUTPUTTYPE=NIFTI; fslmaths %s -Tmean %s;', fn_epi, fnMeanEpi));
myspm_coreg(struct(prefix='o', interp=1, fname_moving=fnT1w, fname_fixed=fnMeanEpi));
[f_,n_,e_] = fileparts(fnT1w);
fn_t1w_coreg = [f_,'/o',n_,e_];
end