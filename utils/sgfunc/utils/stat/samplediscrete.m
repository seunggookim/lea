function randsamples = samplediscrete(observations, nSamplesToDraw)
%SAMPLEDISCRTE randomly samples from a distribution based on given observations.
%
%SYNTAX
%  randsamples = samplediscrete(observations, nSamplesToDraw)
%
%INPUTS
%  observations:    a categorical vector to from an eCDF
%  nSamplesToDraw:  a number of samples to draw
%
%OUTPUT
%  randsamples:     a sampled categorical column vector


% REF: https://en.wikipedia.org/wiki/Categorical_distribution
nObs = numel(observations);
observations = categorical(reshape(observations, [], 1));
[counts, categories] = histcounts(observations);
eCDF = [0, cumsum(counts)];       % create an empirical cumulative distribution function
eCDF = eCDF ./ nObs;

p = rand([nSamplesToDraw, 1]);    % generate uniform random values [0,1]
IsBigger = p >= eCDF;             % broadcast
idxCategory = sum(IsBigger,2);    % find the category indices by summing all categories p <= eCDF
randsamples = categorical(categories(idxCategory));

end