function Str = descstat(X)
if iscategorical(X)
  [counts, labels] = histcounts(X);
  [~,idx] = sort(counts, 'descend');
  counts = counts(idx);
  labels = labels(idx);
  Str = '';
  for i = 1:numel(labels)
    Str = [Str, sprintf('#(%s)=%i, ', labels{i}, counts(i))];
  end
  Str(end-1:end) = '';
else
  X = double(X);
  Str = sprintf('min=%.4f, max=%.4f, mean=%.4f, median=%.4f, mode=%.4f, std=%.4f', ...
    min(X, [], "omitnan"), max(X, [], "omitnan"), mean(X, "omitnan"), median(X, "omitnan"), ...
    mode(X), std(X, [], "omitnan"));
end
end
