function segs = extractsurfaceplaneintersection(vertices, faces, p0, n)
% vertices: Nx3
% faces:    Mx3
% p0:       1x3 point on plane
% n:        1x3 plane normal
%
% segs: Kx6, each row = [x1 y1 z1 x2 y2 z2]
% chatGPT-5

n = n(:)' / norm(n);
eps0 = 1e-8;
segs = {[]};

for i = 1:size(faces,1)
    tri = faces(i,:);
    V = vertices(tri,:);                 % 3x3
    d = (V - p0) * n.';                  % 3x1 signed distances

    % snap near-zero distances to zero
    d(abs(d) < eps0) = 0;

    % no cut if strictly same side
    if all(d > 0) || all(d < 0)
        continue;
    end

    pts = [];

    % check each triangle edge
    edges = [1 2; 2 3; 3 1];
    for e = 1:3
        a = edges(e,1);
        b = edges(e,2);

        va = V(a,:); vb = V(b,:);
        da = d(a);   db = d(b);

        if da == 0 && db == 0
            % whole edge lies in plane: ambiguous for contouring
            % you can keep it or skip it; here skip
            continue;
        elseif da == 0
            pts = [pts; va];
        elseif db == 0
            pts = [pts; vb];
        elseif da * db < 0
            t = da / (da - db);
            p = va + t * (vb - va);
            pts = [pts; p];
        end
    end

    % remove duplicate points
    if ~isempty(pts)
        pts = uniquetol(pts, 1e-10, 'ByRows', true);
    end

    % a proper triangle-plane cut gives 2 points
    if size(pts,1) == 2
      if isempty(segs{end}) || (vecnorm(segs{end}(end,:)-pts(1,:), 2, 2) < 1)
        segs{end} = [segs{end}; pts([1; 2],:)];
      else
        segs = [segs; pts([1; 2],:)];
      end
    end
end
end