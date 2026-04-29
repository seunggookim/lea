function map = linspacevec(X,Y,N)

map = [];
for j = 1:size(X,2)
  map = [map, linspace(X(j), Y(j), N)'];
end
end
