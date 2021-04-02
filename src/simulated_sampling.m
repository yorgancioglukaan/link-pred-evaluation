function [ Wtrain, Wtest] = simulated_sampling(W, W_real, samplingPercentage)
    W_sum = sum(W,1);
    real_sum = sum(W_real,1);
    C = W_sum - real_sum;
    Wprob = quadSolver(W, C);
    
    edges = find(triu(W, 1));       
    weights = full(Wprob(edges));

    edgeSubset = sampleWeighted(edges, weights, samplingPercentage);
    nNode = size(W, 1);
    [rows, columns] = ind2sub([nNode nNode], edgeSubset);
    Wtrain = sparse(rows, columns, true, nNode, nNode);
    Wtrain = Wtrain | Wtrain';
    Wtest = logical(W - Wtrain);
    
    temp = Wtrain;
    Wtrain = Wtest;
    Wtest = temp;
      
end


function [edgeSubset] = sampleWeighted(edges, weights, samplingPercentage)
    %% This section was moved from location 1 (marked below) to here. 
    %This ensures that we get the desired number of samples
    nEdge = length(edges);
    k = round(nEdge * samplingPercentage);
    %%
    
    % Filter edges with zero weight
    validEdges = weights >= 0;
    edges = edges(validEdges);
    weights = weights(validEdges);

    %Location 1 is here

    edgeSubset = datasample(edges, k, ...
        'Replace', false, ...
        'Weights', weights);     
end