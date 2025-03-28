function tbl = compute_peta2(tbl)
% computes partial eta squared for effect size for a given (R)ANOVA table
%
% tbl = compute_peta2(tbl)
%
% (cc) 2011, 2024, seung-goo.kim@ae.mpg.de.

% (1) PARTIAL ETA^2 = (SS_effect) / (SS_effect + SS_error)

% (2) (equivalent) pETA^2 = (F*df1) / (F*df1 + df2)
% REF: Lakens, 2013, https://doi.org/10.3389/fpsyg.2013.00863



irows_int = find(contains(tbl.Row, '(Intercept)'));
irows_err = find(contains(tbl.Row, 'Error'));

pEta2 = [];
if not(isempty(irows_int))
  % for repeated-measures ANOVA
  for iblck = 1:numel(irows_int)
    SSerr = tbl.SumSq(irows_err(iblck));
    for jrow = irows_int(iblck):(irows_err(iblck)-1)
      SSeff = tbl.SumSq(jrow);
      pEta2 = [pEta2; SSeff/(SSeff+SSerr)];
    end
    pEta2 = [pEta2; nan];
  end
else
  % for ANOVA
  pEta2 = (tbl.F.*tbl.DF) ./ (tbl.F.*tbl.DF + tbl.DF(end));
  pEta2(end) = nan;
end

tbl = addvars(tbl, pEta2);
end

