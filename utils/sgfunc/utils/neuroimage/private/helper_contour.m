function Hc = helper_contour(Ha, Vi, u, w, cfg)
if not(isfield(cfg,'ncontourlevels'))
  cfg.ncontourlevels = 1;
end
if not(isfield(cfg,'contoursmoothing'))
  cfg.contoursmoothing = 3;
end
hold on
if cfg.contoursmoothing % slight smoothing?
[~,Hc] = contour(Ha, u.axis, w.axis, convn(Vi,ones(cfg.contoursmoothing),'same'), cfg.ncontourlevels); 
else % no smoothing
  [~,Hc] = contour(Ha, u.axis, w.axis, Vi, cfg.ncontourlevels);
end
hold off
end

