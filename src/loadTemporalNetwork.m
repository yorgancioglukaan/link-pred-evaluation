function [ W, nNode, W_real, W_temporal, test_ratio] = loadTemporalNetwork( dataset)
    if ~exist('complete', 'var')
        complete = false;
    end
    switch(dataset)
        case 'DBLP_A'
            load(['in/', dataset, '.mat']);
            W = Net;
            nNode = size(W, 1);
            W_temporal = sparse(TestLink(:, 1), TestLink(:, 2), true, nNode, nNode);
        case 'biogrid_human'
            load(['out/biogrid/processed_Homo_sapiens_3.0.68_4.0.189.mat']);
            W = W1;
            W_temporal = W2;
            W_temporal(logical(W)) = false;
        case 'biogrid_drosophila'
            load(['out/biogrid/processed_Drosophila_melanogaster_3.0.68_4.0.189.mat']);
            W = W1;
            W_temporal = W2;
            W_temporal(logical(W)) = false;
        otherwise
            error('Invalid dataset.');
    end
    
    W = W - diag(diag(W));                              % Remove self edges
    W = logical(W);                                     % Remove weights
    W = W | W';                                         % Make symmetric
    W_temporal = W_temporal - diag(diag(W_temporal));   % Remove self edges
    W_temporal = logical(W_temporal);                   % Remove weights
    W_temporal = W_temporal | W_temporal';              % Make symmetric
    validNodes = sum(W, 1) >= 1;
    W = W(validNodes, validNodes);
    W_temporal = W_temporal(validNodes, validNodes);
    W_real = W;
    W = W_real | W_temporal;
    test_ratio = nnz(W_temporal)/nnz(W);
    nNode = size(W, 1);
end

