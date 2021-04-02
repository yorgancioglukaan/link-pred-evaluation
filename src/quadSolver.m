function [ Wout, x] = quadSolver( W, rowSum, columnSum )
    if((nargin < 3) && (size(W,1) == size(W, 2))); columnSum = rowSum; end
%     if(nargin < 3); columnSum  = []; end
    
    rowSum = double(reshape(rowSum, [], 1));
    columnSum = double(reshape(columnSum, [], 1));
    
    p = inputParser;
    validNetwork = @(x) validateattributes(x, {'numeric', 'logical'}, ...
        {'2d', 'nonnan'});
    validVector = @(x) validateattributes(x, {'numeric', 'logical'}, ...
        {'vector', 'nonnan'});
    addRequired(p, 'W', validNetwork);
    addRequired(p, 'rowSum', validVector);
    addRequired(p, 'columnSum', validVector);
    parse(p, W, rowSum, columnSum);
    param = p.Results;
    
    ignoreRowConstraint = isempty(rowSum);
    ignoreColumnConstraint = isempty(columnSum);
    
    if(~ignoreRowConstraint && (length(rowSum) ~= size(W, 1)))
       error('Length of rowSum must match the number of rows in W.');
    end
    
    if(~ignoreColumnConstraint && (length(columnSum) ~= size(W, 2)))
       error('Length of columnSum must match the number of columns in W.');
    end
    
    [m, n] = size(W);
    W = sparse(W);
%     W = W - diag(diag(W));
    indices = find(W);
    p = nnz(indices);
    [r, c] = find(W);
    Aeq1 = sparse(c == sparse(1:n))';
    Aeq2 = sparse(r == sparse(1:m))';
    if(~ignoreColumnConstraint)
        if(~ignoreRowConstraint)
            A = double([Aeq1; Aeq2]);
            Sx = [columnSum; rowSum];
        else
            A = double([Aeq1]);
            Sx = [columnSum];
        end
    else
        if(~ignoreRowConstraint)
            A = double([Aeq2]);
            Sx = [rowSum];
        else
            A = ones(1, p);
            Sx = [p];
        end
    end
%     A = double([Aeq1; Aeq2]);
%     Sx = [columnSum; rowSum];
    H = speye(p, p);
    
    k = size(A, 1);
    Q = [H A'; A sparse(k, k)]; % (p + k) x (p + k)
    Y = [zeros(p, 1); Sx];
    Q = Q + speye(size(Q))*1e-6;
    X = Q \ Y;
    x = X(1:p);
    
    Wout = sparse(r, c, x, m, n);
    
%     Wout = sparse(size(W));
%     Wout(indices) = x;
    
end

