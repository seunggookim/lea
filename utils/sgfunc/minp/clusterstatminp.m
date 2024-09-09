function [stat, cfg] = clusterstatminp(job, statobs, statrnd)
%clusterstatminp Performs cluster-based permutation tests with min(p)
%
%NOTES
% - CURRENTLY tested for: [1] 3-D volumetric or 2-D surface data,
% [2] one-sided or two-sided one-sample tests
% - THIS USES A CUSTOM VERSION of FieldTrip's CLUSTERSTAT(). Runs without a
% FieldTrip installation pathed.
%
%SYNTAX
% [stat, cfg] = clusterstatminp(job, statobs, statrnd)
%
%INPUTS
% job
%  .dim           [1*#dim|num]  # of voxels along x, y, z-directions
%  .inside        [#vox*1:logical]  true=in, false=out
%  .tail          [1*1|num]  1=positive, -1=negative, 0=both
%  .clusteralphas [1*#alphas|num]  clutser-alphas to run
%  .clusterconns  [1*#conn|num]  connectivity criterion
%        2D: 4 (edge), 8 (corner)
%        3D: 6 (surface), 18 (edge) or 26 (corner)
%  .connectivity  [#vox*#vox:sparse-logical]
%
% statobs [#vox*1|num] if this is a GpuArray it will run on GPU.
%
% statrnd [#vox*#rands|num]
%
%OUTPUTS
%
%
%REF: Geerligs, L., & Maris, E. (2021). Improving the sensitivity of
% cluster-based statistics for functional magnetic resonance imaging data.
% Human brain mapping, 42(9), 2746-2765. https://doi.org/10.1002/hbm.25399
%
% Implementing the "min(p)" method combining multiple cluster-defining
% thresholds (CDTs; controlling height) and types of connectivity
% (controlling cluster size).
%
% (cc) 2021, dr.seunggoo.kim@gmail.com

if isa(statobs,'gpuArray')
  arrayclass = 'gpuArray';
else
  arrayclass = 'double';
end

if ~isfield(job,'clusterstatistic')
  job.clusterstatistic = 'maxsum';
end

[nvox, nrnd] = size(statrnd);
posdistributionminp = ones(1,nrnd,arrayclass);
negdistributionminp = ones(1,nrnd,arrayclass);

posobsminp = nan(nvox,1,arrayclass);
negobsminp = nan(nvox,1,arrayclass);

for icdt = 1:numel(job.clusteralphas)
  for icon = 1:numel(job.clusterconns)
    cfg = struct( 'tail',job.tail, 'dim',job.dim, 'inside',job.inside, ...
      'connectivity',job.connectivity, ...
      'orderedstats','no', 'multivariate','no', 'minnbchan',0, ...
      'wcm_weight',1, 'clusterstatistic',job.clusterstatistic, ...
      'clusterthreshold','nonparametric_common',...
      'clusteralpha', job.clusteralphas(icdt), 'clustercritval',[], ...
      'clustertail',job.tail, 'clusterconn', job.clusterconns(icon), ...
      'numrandomization', size(statrnd,2) );

    % Step 1: compute null reference distribution
    [stat1, cfg] = clusterstat(cfg, statrnd, statobs);

    if isfield(stat1,'posdistribution')
      % Step 2: convert to p-values
      [~,idx] = sort(stat1.posdistribution);
      pospvaldistribution = idx/numel(stat1.posdistribution);

      % Step 3: keep the minimal p-values only:
      posdistributionminp = min(...
        [pospvaldistribution; posdistributionminp],[],1);

      % also keep the minimal observed p-values:
      posobsminp = min([stat1.prob, posobsminp],[],2);
    end

    if isfield(stat1,'negdistribution')
      % Step 2: convert to p-values
      [~,idx] = sort(stat1.negdistribution);
      negpvaldistribution = idx/numel(stat1.negdistribution);

      % Step 3: keep the minimal p-values only:
      negdistributionminp = min(...
        [negpvaldistribution; negdistributionminp],[],1);

      % also keep the minimal observed p-values:
      negobsminp = min([stat1.prob, negobsminp],[],2);
    end

  end
end
% output:
cfg.clusterconns = job.clusterconns;
cfg.clusteralphas = job.clusteralphas;

stat = struct( ...
  'posdistributionminp',posdistributionminp, 'posobsminp',posobsminp, ...
  'negdistributionminp',negdistributionminp, 'negobsminp',negobsminp);

% for each voxel? can it be faster?
prb_pos = nan(nvox,1);
prb_neg = nan(nvox,1);
for ivox = 1:nvox
  prb_pos(ivox) = (sum(posdistributionminp <= posobsminp(ivox))+1) ...
    / (nrnd+1);
  prb_neg(ivox) = (sum(negdistributionminp <= negobsminp(ivox))+1) ...
    / (nrnd+1);
end

if cfg.tail==0
  % consider both tails
  % this is the probability for the most unlikely tail:
  stat.prob = min(prb_neg, prb_pos);
elseif cfg.tail==1
  % only consider the positive tail
  stat.prob = prb_pos;
elseif cfg.tail==-1
  % only consider the negative tail
  stat.prob = prb_neg;
end

end


function [stat, cfg] = clusterstat(cfg, statrnd, statobs)
% [stat, cfg] = clusterstat(cfg, statrnd, statobs)
% MODIFIED/SIMPLIFIED VERSION OF FIELDTRIP CLUSTERSTAT.M FOR FMRI
% CLUSTER-BASED PERMUTATION TEST (ONLY FOR 2-D & 3-D DATA)
% (CC) 2021, sgKIM.

% CLUSTERSTAT computers cluster statistic for multidimensional
% channel-freq-time or volumetric source data
%
% See also TFCESTAT, FINDCLUSTER

% Copyright (C) 2005-2020, Robert Oostenveld
% Copyright (C) 2021, Robert Oostenveld and Jan-Mathijs Schoffelen
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

if isa(statobs,'gpuArray')
  arrayclass = 'gpuArray';
else
  arrayclass = 'double';
end

if isempty(cfg.dim)
  error('cfg.dim should be defined and not empty');
end

if cfg.tail~=cfg.clustertail
  error('cfg.tail and cfg.clustertail should be identical')
end

if isempty(cfg.inside)
  cfg.inside = true(cfg.dim);
end
% cfg.inside is set in ft_sourcestatistics, but is also needed for timelock
% and freq

% if isfield(cfg, 'origdim')
%   cfg.dim = cfg.origdim;
% end
% this snippet is to support correct clustering of N-dimensional data,
% not fully tested yet
%
% get connectivity matrix for the spatially neighbouring elements
% connmat = full(ft_getopt(cfg, 'connectivity', false));
connmat = cfg.connectivity;

needpos = cfg.tail==0 || cfg.tail== 1;
needneg = cfg.tail==0 || cfg.tail==-1;

Nsample    = size(statrnd,1);
Nrand      = size(statrnd,2);
prb_pos    = ones(Nsample,     1);
prb_neg    = ones(Nsample,     1);
postailrnd = false(Nsample,Nrand);  % this holds the thresholded values
negtailrnd = false(Nsample,Nrand);  % this holds the thresholded values
Nobspos    = 0;              % number of positive clusters in observed data
Nobsneg    = 0;              % number of negative clusters in observed data

switch cfg.clusterthreshold
  case 'parametric'
    if isempty(cfg.clustercritval)
      error(['with parametric cluster thresholding ',...
        'cfg.clustercritval needs to be defined']);
    end

    % threshold based on the critical value from parametric distribution
    siz = size(cfg.clustercritval);
    if all(siz==1) && cfg.clustertail==0
      %  it only specifies one critical value, assume that the left and
      %  right tail are symmetric around zero
      negtailcritval = -cfg.clustercritval;
      postailcritval =  cfg.clustercritval;
    elseif all(siz==1) && cfg.clustertail==-1
      % it only specifies 1 critical value corresponding to the left tail
      negtailcritval = cfg.clustercritval;
      postailcritval = +inf * ones(size(negtailcritval));
    elseif all(siz==1) && cfg.clustertail==1
      % it only specifies 1 critical value corresponding to the right tail
      postailcritval =  cfg.clustercritval;
      negtailcritval = -inf * ones(size(postailcritval));
    elseif siz(1)==Nsample && siz(2)==1 && cfg.clustertail==0
      %  it specifies a single critical value for each sample, assume that
      %  the left and right tail are symmetric around zero
      negtailcritval = -cfg.clustercritval;
      postailcritval =  cfg.clustercritval;
    elseif siz(1)==Nsample && siz(2)==1 && cfg.clustertail==-1
      % it specifies a critical value for the left tail
      % which is different for each sample (samples have a different df)
      negtailcritval = cfg.clustercritval;
      postailcritval = +inf * ones(size(negtailcritval));
    elseif siz(1)==Nsample && siz(2)==1 && cfg.clustertail==1
      % it specifies a critical value for the right tail
      % which is different for each sample (samples have a different df)
      postailcritval = cfg.clustercritval;
      negtailcritval = +inf * ones(size(postailcritval));
    elseif siz(1)==Nsample && siz(2)==2 && cfg.clustertail==0
      % it specifies a critical value for the left and for the right tail
      % of the distribution which is different for each sample (samples
      % have a different df)
      negtailcritval = cfg.clustercritval(:,1);
      postailcritval = cfg.clustercritval(:,2);
    elseif prod(siz)==2 && cfg.clustertail==0
      % it specifies a critical value for the left and for the right tail
      % of the distribution which is the same for each sample (samples have
      % the same df)
      negtailcritval = cfg.clustercritval(1);
      postailcritval = cfg.clustercritval(2);
    else
      error(['cannot make sense out of the specified parametric ',...
        'critical values']);
    end

  case 'nonparametric_individual'
    if isempty(cfg.clusteralpha)
      error(['with nonparametric_indivdual cluster thresholding ',...
        'cfg.clusteralpha needs to be defined']);
    end

    % threshold based on bootstrap using all other randomizations
    % each voxel will get an individual threshold
    [srt, ind] = sort(statrnd,2);
    if cfg.clustertail==0
      % both tails are needed
      negtailcritval =srt(:,round((  cfg.clusteralpha/2)*size(statrnd,2)));
      postailcritval =srt(:,round((1-cfg.clusteralpha/2)*size(statrnd,2)));
    elseif cfg.clustertail==1
      % only positive tail is needed
      postailcritval = srt(:,round((1-cfg.clusteralpha)*size(statrnd,2)));
      negtailcritval = -inf * ones(size(postailcritval));
    elseif cfg.clustertail==-1
      % only negative tail is needed
      negtailcritval = srt(:,round((  cfg.clusteralpha)*size(statrnd,2)));
      postailcritval = +inf * ones(size(negtailcritval));
    end

  case 'nonparametric_common'
    if isempty(cfg.clusteralpha)
      error(['with nonparametric_common cluster thresholding ',...
        'cfg.clusteralpha needs to be defined']);
    end

    % threshold based on bootstrap using all other randomizations
    % all voxels will get a common threshold
    srt = sort(statrnd(:));
    if cfg.clustertail==0
      % both tails are needed
      negtailcritval = srt(round((  cfg.clusteralpha/2)*numel(statrnd)));
      postailcritval = srt(round((1-cfg.clusteralpha/2)*numel(statrnd)));
    elseif cfg.clustertail==1
      % only positive tail is needed
      postailcritval = srt(round((1-cfg.clusteralpha)*numel(statrnd)));
      negtailcritval = -inf * ones(size(postailcritval));
    elseif cfg.clustertail==-1
      % only negative tail is needed
      negtailcritval = srt(round((  cfg.clusteralpha)*numel(statrnd)));
      postailcritval = +inf * ones(size(negtailcritval));
    end
  case 'none'
    % tfce
    negtailcritval = [];
    postailcritval = [];
  otherwise
    error('no valid threshold for clustering was given')
end % determine clusterthreshold

% these should be scalars or column vectors
negtailcritval = negtailcritval(:);
postailcritval = postailcritval(:);

% remember the critical values
cfg.clustercritval = [negtailcritval postailcritval];

% test whether the observed and the random statistics exceed the threshold
postailobs = (statobs >= postailcritval);
negtailobs = (statobs <= negtailcritval);
for i=1:Nrand
  postailrnd(:,i) = (statrnd(:,i) >= postailcritval);
  negtailrnd(:,i) = (statrnd(:,i) <= negtailcritval);
end

%% first do the clustering on the observed data
spacereshapeable = (numel(connmat)==1 && ~isfinite(connmat));
% spacereshapeable = true;

if needpos
  if spacereshapeable
    % this pertains to data for which the spatial dimension can be reshaped
    % into 3D, i.e. when it is described on an ordered set of positions on
    % a 3D-grid. It deals with the inside dipole positions, and creates a
    % fake extra spatial dimension, so that findcluster can deal with it
    tmp = zeros([1 prod(cfg.dim)]);
    tmp(cfg.inside) = postailobs;  % 1-D array
  else
    tmp = reshape(postailobs, [cfg.dim 1]);
  end

  % identify positive clusters in the observed data
  posclusobs = findcluster(tmp, cfg.dim, cfg.clusterconn);

  if spacereshapeable
    posclusobs = posclusobs(cfg.inside);
  else
    posclusobs = posclusobs(:);
  end
  Nobspos = max(posclusobs); % number of clusters exceeding the threshold
  fprintf('found %d positive clusters in observed data\n', Nobspos);

end % if needpos

if needneg
  if spacereshapeable
    % this pertains to data for which the spatial dimension can be reshaped
    % into 3D, i.e. when it is described on an ordered set of positions on
    % a 3D-grid. It deals with the inside dipole positions, and creates a
    % fake extra spatial dimension, so that findcluster can deal with it
    tmp = zeros([1 prod(cfg.dim)]);
    tmp(cfg.inside) = negtailobs;
  else
    tmp = reshape(negtailobs, [cfg.dim 1]);
  end

  % identify negative clusters in the observed data
  negclusobs = findcluster(tmp, cfg.dim, cfg.clusterconn);

  if spacereshapeable
    negclusobs = negclusobs(cfg.inside);
  else
    negclusobs = negclusobs(:);
  end
  Nobsneg = max(negclusobs); % number of clusters exceeding the threshold
  fprintf('found %d negative clusters in observed data\n', Nobsneg);

end % if needneg

%% catch situation where no clustering of the random data is needed
if (Nobspos+Nobsneg)==0
  warning('no clusters were found in the observed data');
  stat = struct();
  % see http://bugzilla.fieldtriptoolbox.org/show_bug.cgi?id=2972
  stat.stat = statobs;
  stat.prob = ones(Nsample, 1);
  return
end

%% allocate space to hold the rand distributions of the cluster statistic
if strcmp(cfg.multivariate, 'yes') || strcmp(cfg.orderedstats, 'yes')
  fprintf(['allocating space for a %d-multivariate distribution',...
    'of the positive clusters\n'], Nobspos);
  fprintf(['allocating space for a %d-multivariate distribution',...
    'of the negative clusters\n'], Nobsneg);
  % this holds the multivariate randomization distribution of the positive
  % cluster statistics:
  posdistribution = zeros(Nobspos,Nrand);
  % this holds the multivariate randomization distribution of the negative
  % cluster statistics:
  negdistribution = zeros(Nobsneg,Nrand);
else
  % this holds the statistic of the largest positive cluster in each
  % randomization:
  posdistribution = zeros(1,Nrand);
  % this holds the statistic of the largest negative cluster in each
  % randomization:
  negdistribution = zeros(1,Nrand);
end

%% do the clustering on the randomized data
% ft_progress('init', cfg.feedback, 'computing clusters for the thresholded
% test statistic computed from the randomized design');
fprintf(['computing clusters for the thresholded test statistic ',...
  'computed from the randomized design\n'])
for i = 1:Nrand
  %   ft_progress(i/Nrand, 'computing clusters in randomization %d from
  %   %d\n', i, Nrand);
  % fprintf('.')
  if needpos
    if spacereshapeable
      tmp = zeros([1 prod(cfg.dim)]);
      tmp(cfg.inside) = postailrnd(:,i);
    else
      tmp = reshape(postailrnd(:,i), [cfg.dim 1]);
    end
    posclusrnd = findcluster(tmp, cfg.dim, cfg.clusterconn); % 0.003245 sec
    if spacereshapeable
      posclusrnd = posclusrnd(cfg.inside);
    else
      posclusrnd = posclusrnd(:);
    end
    %% FIND cluster-statistics from the random clusters:
    % number of clusters exceeding the threshold:
    Nrndpos = max(posclusrnd(:));
    % this will hold the statistic for each cluster:
    stat    = zeros(1,Nrndpos, arrayclass);
    % fprintf('found %d positive clusters in this randomization\n',
    % Nrndpos);
    statrnd_i = statrnd(:,i);
    if isa(statobs,'gpuArray')
      posclusrnd = gpuArray(posclusrnd);
    end
    for j = 1:Nrndpos
      switch cfg.clusterstatistic
        case 'max'
          stat(j) = max(statrnd_i(posclusrnd==j));
        case 'maxsize' % 0.230 sec
          stat(j) = length(find(posclusrnd==j));
        case 'maxsum'  % 0.303 sec
          stat(j) = sum(bsxfun(@times, statrnd_i, posclusrnd==j));
        case 'wcm'
          if numel(postailcritval)==1
            posthr = postailcritval;
          elseif numel(postailcritval)==numel(posclusrnd)
            posthr = postailcritval(posclusrnd==j);
          end
          stat(j) = sum((statrnd_i(posclusrnd==j)-posthr).^cfg.wcm_weight);
        otherwise
          error('unknown clusterstatistic');
      end
    end % for 1:Nrdnpos

    if strcmp(cfg.multivariate, 'yes') || strcmp(cfg.orderedstats, 'yes')
      % sort them from most positive to most negative:
      stat = sort(stat, 'descend');
      if Nrndpos>Nobspos
        % remember the largest N clusters:
        posdistribution(:,i) = stat(1:Nobspos);
      else
        % remember the largest N clusters:
        posdistribution(1:Nrndpos,i) = stat;
      end
    else
      % univariate -> remember the most extreme cluster
      if ~isempty(stat), posdistribution(i) = max(stat); end
    end
  end % needpos

  if needneg
    if spacereshapeable
      tmp = zeros([1 prod(cfg.dim)]);
      tmp(cfg.inside) = negtailrnd(:,i);
    else
      tmp = reshape(negtailrnd(:,i), [cfg.dim 1]);
    end
    negclusrnd = findcluster(tmp, cfg.dim, cfg.clusterconn);
    if spacereshapeable
      negclusrnd = negclusrnd(cfg.inside);
    else
      negclusrnd = negclusrnd(:);
    end
    % number of clusters exceeding the threshold:
    Nrndneg = max(negclusrnd(:));
    if isa(statobs,'gpuArray')
      negclusrnd = gpuArray(negclusrnd);
    end
    % this will hold the statistic for each cluster:
    stat    = zeros(1,Nrndneg, arrayclass);
    % fprintf('found %d negative clusters in this randomization\n',
    % Nrndneg);
    for j = 1:Nrndneg
      switch cfg.clusterstatistic
        case 'max'
          stat(j) = min(statrnd(negclusrnd==j,i));
        case 'maxsize'
          % encode the size of a negative cluster as a negative value:
          stat(j) = -length(find(negclusrnd==j));
        case 'maxsum'
          %           stat(j) = sum(statrnd(negclusrnd==j,i));
          stat(j) = sum(bsxfun(@times, statrnd_i, negclusrnd==j));
        case 'wcm'
          if numel(negtailcritval)==1
            negthr = negtailcritval;
          elseif numel(negtailcritval)==numel(negclusrnd)
            negthr = negtailcritval(negclusrnd==j);
          end
          % encoded as a negative value:
          stat(j) = -sum((abs(statrnd(negclusrnd==j,i)-negthr)) ...
            .^cfg.wcm_weight);
        otherwise
          error('unknown clusterstatistic');
      end
    end % for 1:Nrndneg
    if strcmp(cfg.multivariate, 'yes') || strcmp(cfg.orderedstats, 'yes')
      % sort them from most negative to most positive:
      stat = sort(stat, 'ascend');
      if Nrndneg>Nobsneg
        % remember the most extreme clusters, i.e. the most negative:
        negdistribution(:,i) = stat(1:Nobsneg);
      else
        % remember the most extreme clusters, i.e. the most negative:
        negdistribution(1:Nrndneg,i) = stat;
      end
    else
      % univariate -> remember the most extreme cluster,
      % which is the most negative
      if ~isempty(stat), negdistribution(i) = min(stat); end
    end
  end % needneg

end % for 1:Nrand
% ft_progress('close');
fprintf('\n')

%% compare the values for the observed clusters with the rand distribution
if needpos
  posclusters = [];
  stat = zeros(1,Nobspos);
  for j = 1:Nobspos
    switch cfg.clusterstatistic
      case 'max'
        stat(j) = max(statobs(posclusobs==j));
      case 'maxsize'
        stat(j) = length(find(posclusobs==j));
      case 'maxsum'
        stat(j) = sum(statobs(posclusobs==j));
      case 'wcm'
        if numel(postailcritval)==1
          posthr = postailcritval;
        elseif numel(postailcritval)==numel(posclusrnd)
          posthr = postailcritval(posclusobs==j);
        end
        stat(j) = sum((statobs(posclusobs==j)-posthr).^cfg.wcm_weight);
      otherwise
        error('unknown clusterstatistic');
    end
  end
  % sort the clusters based on their statistical value
  [stat, indx] = sort(stat, 'descend');
  % reorder the cluster indices in the data
  tmp = zeros(size(posclusobs));
  for j=1:Nobspos
    tmp(posclusobs==indx(j)) = j;
  end
  posclusobs = tmp;
  if strcmp(cfg.multivariate, 'yes')
    % estimate the probability of the mutivariate tail,
    % i.e. one p-value for all clusters
    prob = 0;
    for i=1:Nrand
      % compare all clusters simultaneosuly
      prob = prob + any(posdistribution(:,i)>stat(:));
    end
    if isequal(cfg.numrandomization, 'all')
      prob = prob/Nrand;
    else % the minimum possible p-value should not be 0, but 1/N
      prob = (prob + 1)/(Nrand + 1);
    end
    for j = 1:Nobspos
      % collect a summary of the cluster properties
      posclusters(j).prob = prob;
      posclusters(j).clusterstat = stat(j);
    end
    % collect the probabilities in one large array
    prb_pos(posclusobs~=0) = prob;
  elseif strcmp(cfg.orderedstats, 'yes')
    % compare the Nth ovbserved cluster against the randomization
    % distribution of the Nth cluster:
    prob = zeros(1,Nobspos);
    for j = 1:Nobspos
      if isequal(cfg.numrandomization, 'all')
        prob(j) = sum(posdistribution(j,:)>stat(j))/Nrand;
      else % the minimum possible p-value should not be 0, but 1/N
        prob(j) = (sum(posdistribution(j,:)>stat(j)) + 1)/(Nrand + 1);
      end
      % collect the probabilities in one large array
      prb_pos(posclusobs==j) = prob(j);
    end
    % collect a summary of the cluster properties
    posclusters = struct('prob', num2cell(prob), ...
      'clusterstat', num2cell(stat));
  else
    % univariate -> each cluster has it's own probability
    prob = zeros(1,Nobspos);
    for j = 1:Nobspos
      if isequal(cfg.numrandomization, 'all')
        prob(j) = sum(posdistribution>stat(j))/Nrand;
      else % the minimum possible p-value should not be 0, but 1/N
        prob(j) = (sum(posdistribution>stat(j)) + 1)/(Nrand + 1);
      end
      % collect the probabilities in one large array
      prb_pos(posclusobs==j) = prob(j);
    end
    % collect a summary of the cluster properties
    posclusters = struct('prob', num2cell(prob), ...
      'clusterstat', num2cell(stat));
  end
end

if needneg
  negclusters = [];
  stat = zeros(1,Nobsneg);
  for j = 1:Nobsneg
    switch cfg.clusterstatistic
      case 'max'
        stat(j) = min(statobs(negclusobs==j));
      case 'maxsize'
        % encode the size of a negative cluster as a negative value:
        stat(j) = -length(find(negclusobs==j));
      case 'maxsum'
        stat(j) = sum(statobs(negclusobs==j));
      case 'wcm'
        if numel(negtailcritval)==1
          negthr = negtailcritval;
        elseif numel(negtailcritval)==numel(negclusrnd)
          negthr = negtailcritval(negclusobs==j);
        end
        % encoded as a negative value:
        stat(j) = -sum((abs(statobs(negclusobs==j)-negthr)) ...
          .^cfg.wcm_weight);
      otherwise
        error('unknown clusterstatistic');
    end
  end
  % sort the clusters based on their statistical value
  [stat, indx] = sort(stat,'ascend');
  % reorder the cluster indices in the observed data
  tmp = zeros(size(negclusobs));
  for j=1:Nobsneg
    tmp(negclusobs==indx(j)) = j;
  end
  negclusobs = tmp;
  if strcmp(cfg.multivariate, 'yes')
    % estimate the probability of the mutivariate tail,
    % i.e. one p-value for all clusters
    prob = 0;
    for i=1:Nrand
      % compare all clusters simultaneosuly
      prob = prob + any(negdistribution(:,i)<stat(:));
    end
    if isequal(cfg.numrandomization, 'all')
      prob = prob/Nrand;
    else % the minimum possible p-value should not be 0, but 1/N
      prob = (prob + 1)/(Nrand + 1);
    end
    for j = 1:Nobsneg
      % collect a summary of the cluster properties
      negclusters(j).prob = prob;
      negclusters(j).clusterstat = stat(j);
    end
    % collect the probabilities in one large array
    prb_neg(negclusobs~=0) = prob;
  elseif strcmp(cfg.orderedstats, 'yes')
    % compare the Nth ovbserved cluster against the randomization
    % distribution of the Nth cluster
    prob = zeros(1,Nobsneg);
    for j = 1:Nobsneg
      if isequal(cfg.numrandomization, 'all')
        prob(j) = sum(negdistribution(j,:)<stat(j))/Nrand;
      else % the minimum possible p-value should not be 0, but 1/N
        prob(j) = (sum(negdistribution(j,:)<stat(j)) + 1)/(Nrand + 1);
      end
      % collect the probabilities in one large array
      prb_neg(negclusobs==j) = prob(j);
    end
    % collect a summary of the cluster properties
    negclusters = struct('prob', num2cell(prob), ...
      'clusterstat', num2cell(stat));
  else
    % univariate -> each cluster has its own probability
    prob = zeros(1,Nobsneg);
    for j = 1:Nobsneg
      if isequal(cfg.numrandomization, 'all')
        prob(j) = sum(negdistribution<stat(j))/Nrand;
      else % the minimum possible p-value should not be 0, but 1/N
        prob(j) = (sum(negdistribution<stat(j)) + 1)/(Nrand + 1);
      end
      % collect the probabilities in one large array
      prb_neg(negclusobs==j) = prob(j);
    end
    % collect a summary of the cluster properties
    negclusters = struct('prob', num2cell(prob), ...
      'clusterstat', num2cell(stat));
  end
end

if cfg.tail==0
  % consider both tails
  % this is the probability for the most unlikely tail:
  prob = min(prb_neg, prb_pos);
elseif cfg.tail==1
  % only consider the positive tail
  prob = prb_pos;
elseif cfg.tail==-1
  % only consider the negative tail
  prob = prb_neg;
end

% collect the remaining details in the output structure
% REF: see http://bugzilla.fieldtriptoolbox.org/show_bug.cgi?id=2972
stat = struct();
stat.prob = prob;
if needpos
  stat.posclusters         = posclusters;
  stat.posclusterslabelmat = posclusobs;
  stat.posdistribution     = posdistribution;
end
if needneg
  stat.negclusters         = negclusters;
  stat.negclusterslabelmat = negclusobs;
  stat.negdistribution     = negdistribution;
end
end

function [clus,num] = findcluster(onoff, dim, clusterconn)

if (numel(dim)==2) || (numel(dim)==3)  % 2D images or 3D volumes
  BW = reshape(onoff, dim);
  [L,num] = spm_bwlabel(BW, clusterconn);
  clus = L(:);
else
  % spm_bwlabel yet (feb 2011) supports only 2D/3D data
  % so, we'll use MATLAB image toolbox version:
%   [L,num] = bwlabeln(onoff, clusterconn);
  clus = L(:);
end
end
