n = 50;
m = n;
p = 100;
rng(1, 'twister');
W = sparse(n, n);
i1 = randi([1 n], p, 1);
i2 = randi([1 n], p, 1);
W(sub2ind(size(W), i1, i2)) = true;
S = ones(n, 1);
% S = full(sum(W, 2));
% W = W | W';
W = W - diag(diag(W));

indices = find(W);

tic
[Wo, x] = quadSolver(W, S);
Wo = full(Wo);
Wa = zeros(m, n);
Wa(indices) = x;
Wfull = full(W);
toc

tic
xp = maxflowSolver(W, S);
xp = full(xp);
toc