function mysystem(cmd)
[stdout,stderr] = system(cmd);
disp(stderr)
assert(not(stdout), 'CMD FAILED: %s', cmd)
end