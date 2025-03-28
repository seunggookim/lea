function Job = myspm_cntrst (Job)
% creates CON and SPM images, to be used by MYSPM_GLM and MYSPM_FMRIGLM
% and calls MYSPM_RESULT
%
% JOB = myspm_cntrst (JOB)
%
%
% JOB requires:
%  .dir_glm
%  .cntrstMtx  (for T-contrasts)
%  .titlestr   (for T-contrasts)
%  .effectOfInterest [1x1] 0 | 1 (default=1)
%  .FcntrstMtx (for F-contrasts)
%  .Ftitlestr  (for F-contrasts)
%
% (cc) 2018, 2019, sgKIM. solleo@gmail.com


spm('defaults','fmri');
if ~isfield(Job,'effectOfInterest')
  Job.effectOfInterest = 1;
end
load([Job.dir_glm,'/SPM.mat'],'SPM')
if ~isfield(Job,'isfmri')
  Job.isfmri = isfield(SPM,'Sess');
end

%% SET DEFAULT CONTRASTS (all regressors):
if ~isfield(Job,'cntrstMtx')
  if Job.isfmri % 1-level fmri GLM:
    nRegInt = [];
    for j = 1:numel(SPM.Sess)
      nRegInt(j) = numel(SPM.Sess(j).U);
    end
    if any(nRegInt~=nRegInt(1))
      error(['# of regressors of interest are various across sessions!'])
    end
    k = length(SPM.Sess(1).U);
    Job.cntrstMtx = [ones(1,k); -ones(1,k);
      kron(eye(k),[1 -1]')];
    if ~isfield(Job,'titlestr')
      varnames = [SPM.Sess(1).U(:).name];
      Job.titlestr = {'+All','-All'};
      for i=1:numel(varnames)
        Job.titlestr = [Job.titlestr, ['+',varnames{i}]];
        Job.titlestr = [Job.titlestr, ['-',varnames{i}]];
      end
    end
  else % 2-level GLM:

    if numel(SPM.xX.iH)==2 % paired t-test
      Job.cntrstMtx = [1 -1; -1 1];
      Job.titlestr = {'Cnt1>Cnt2', 'Cnt1<Cnt2'};
    else
      [n, k] = size(SPM.xX.X);
      Job.cntrstMtx = kron([zeros(k-1,1) eye(k-1)],[1 -1]');
      if ~isfield(Job,'titlestr')
        if ~isempty(SPM.xC)
          varnames = {SPM.xC.rcname};
        else
          varnames= {'1'};
        end
        Job.titlestr = {};
        for i=1:numel(varnames)
          Job.titlestr = [Job.titlestr, ['+',varnames{i}]];
          Job.titlestr = [Job.titlestr, ['-',varnames{i}]];
        end
      end
    end
  end
end

%% SET T-contrasts:
matlabbatch={};
con=[];
con.spmmat = {fullfile(Job.dir_glm, 'SPM.mat')};
if ~isfield(Job,'NumSess')
  try
    Job.NumSess = numel(SPM.Sess);
  catch
    Job.NumSess = 1;
  end
end
NumSess = Job.NumSess;
if isfield(Job,'cntrstMtx')
  NumCnt = size(Job.cntrstMtx,1);
  for k=1:NumCnt
    if isfield(Job,'titlestr')
      con.consess{k}.tcon.name = Job.titlestr{k};
    else
      con.consess{k}.tcon.name = ['Contrast#',num2str(k)];
    end
    con.consess{k}.tcon.convec = Job.cntrstMtx(k,:);
    if NumSess>1
      con.consess{k}.tcon.sessrep = 'repl';
    else
      con.consess{k}.tcon.sessrep = 'none';
    end
    if isfield(Job,'sessrep')
      con.consess{k}.tcon.sessrep=Job.sessrep;
    end
  end
end


%% Effect of interest
if Job.effectOfInterest
  if ~isfield(Job,'FcntrstMtx')
    Job.FcntrstMtx={};
    Job.Ftitlestr={};
  end
  Job.Ftitlestr = [Job.Ftitlestr 'Effect of interest'];
  if Job.isfmri
    for j = 1:numel(SPM.Sess)
      nRegInt(j) = numel(SPM.Sess(j).U); % number of regressors of interest
      nxBForder = size(SPM.xBF.bf,2); % order of the response function
%       nRegNsn(j) = size(SPM.Sess(j).C.C,2); % number of regressors of nuisance
    end
%     % SANITY CHECK:
%     if sum(nRegInt)*nxBForder+sum(nRegNsn)+numel(SPM.Sess) ~= size(SPM.xX.X,2)
%       error('# of regressors does not fit! CANNOT set up Effect of Interest contrast!')
%     end
%     eoicont = zeros(nRegInt(j)*nxBForder, size(SPM.xX.X,2));
%     idxRows = [0 cumsum(nRegInt*nxBForder)];
%     idxCols = [0 cumsum(nRegInt*nxBForder + nRegNsn)];
%     for j = 1:numel(SPM.Sess)
%       eoicont(1+idxRows(j):idxRows(j+1), 1+idxCols(j):idxCols(j+1)) ...
%         = [eye(nRegInt(j)*nxBForder) zeros(nRegInt(j)*nxBForder,nRegNsn(j))];
%     end
    eoicont = eye(nRegInt(j)*nxBForder);
    Job.FcntrstMtx = [Job.FcntrstMtx; eoicont];
  else % 2nd-level or higher
    warning('THINK ABOUT EFFECT of INTEREST for 2-level ANALYSIS is USEFUL!')
  end
end


%% SET F-contrasts
if isfield(Job,'FcntrstMtx')
  k = NumCnt;
  for j=1:numel(Job.FcntrstMtx)
    k = k + 1;
    con.consess{k}.fcon.name = Job.Ftitlestr{j};
    con.consess{k}.fcon.convec = Job.FcntrstMtx{j};
    if NumSess>1
      con.consess{k}.fcon.sessrep = 'repl';
    else
      con.consess{k}.fcon.sessrep = 'none';
    end
    if isfield(Job,'sessrep')
      con.consess{k}.fcon.sessrep=Job.sessrep;
    end
  end
end


%% CLEAR previous results:
if isfield(Job,'newContrast')
  con.delete = Job.newContrast;
else
  con.delete = 1;
end
if con.delete == 1
  unix(['rm -f ',Job.dir_glm,'/con*']);
  unix(['rm -f ',Job.dir_glm,'/sigclus*']);
end
matlabbatch{1}.spm.stats.con = con;


%% RUN:
spm_jobman('initcfg')
spm_jobman('run', matlabbatch)


%% Now create result reports
Job.mygraph.y_name = 'y';
Job.mygraph.x_name = 'x';
if ~isfield(Job,'thres')
  Job.thres.desc  = 'cluster';
  Job.thres.alpha = 0.05;
end
if ~isfield(Job,'NOREPORT') && ~isfield(Job,'noreport')
  Job = myspm_result(Job);
else
%   myps2pdf(JOB.fname_spm_fig)
end


end
