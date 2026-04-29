function myfs_reconall7(Job)
%{
Pial surfaces can be improved using the different contrast in T2 or FLAIR
images. The original pial surfaces without T2/FLAIR data are saved as  
?h.woT2.pial or ?h.woFLAIR.pial, and new ?h.pial surfaces are created.  One 
example where this is useful is when there is dura in the brainmask.mgz that 
isn't removed by skull stripping. The flags for these commands are:

  -T2 <input T2 volume>  or -FLAIR <input FLAIR volume> 
    (Specify the  path to the T2 or FLAIR image to use)
  -T2pial or -FLAIRpial 
    (Create new pial surfaces using T2 or FLAIR images)

An example of running a subject through Freesurfer with a T2 image is:
  
  recon-all -s subjectname -i /path/to/input -T2 /path/to/T2_input -T2pial -all

T2 or FLAIR images can also be used with Freesurfer subjects that have already
been processed without them. Note that autorecon3 should also be re-ran to 
compute statistics based on the new surfaces. For example:
  
  recon-all -s subjectname -T2 /path/to/T2_volume -T2pial -autorecon3

(hmm!)
%}
[~,out] = system('recon-all --version');
assert(contains(out, 'linux-centos8_x86_64-7.4.1')); % MPIEA-HPC.2026-02-05.
system(sprintf('recon-all -all -subjid %s -sd %s -i %s -threads 2', Job.SubjId, Job.SubjDir, Job.FnameT1w))

end