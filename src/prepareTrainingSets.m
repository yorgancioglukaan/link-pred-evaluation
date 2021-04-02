function [ Wtrain, Wtest, C ] = prepareTrainingSets( W, varargin)
    p = inputParser;
    validNetwork = @(x) validateattributes(x, {'numeric', 'logical'}, ...
        {'2d', 'nonnan', 'square', 'nonempty'});
    validSamplingMethod = @(x) any(validatestring(x, ...
        {'maxflow', 'random', 'degree', 'betweenness', 'pagerank', ...
        'eigenvector', 'closeness', 'uniform'}));
    validSamplingPercentage = @(x) validateattributes(x, {'numeric'}, ...
        {'scalar', 'nonnan', 'finite', 'nonempty', 'positive', '<', 1});
    validCentrality = @(x) any(validatestring(x, ...
        {'uniform', 'degree', 'betweenness', 'pagerank', 'eigenvector', 'closeness'}));
    addRequired(p, 'W', validNetwork);
    addParameter(p, 'MaxEdges', Inf, @isnumeric);
    addParameter(p, 'Sampling', 'maxflow', @ischar);
%     addParameter(p, 'Sampling', 'maxflow', validSamplingMethod);
    addParameter(p, 'SamplingPercentage', 0.5, validSamplingPercentage);
    addParameter(p, 'Centrality', 'uniform', validCentrality);
    addParameter(p, 'AdjustTrainingTopology', true, @islogical);
    parse(p, W, varargin{:});
    param = p.Results;
    
    switch(lower(param.Sampling))
        case 'maxflow'
            [edgeSubset] = maxflowSampling(W, ...
                param.Centrality, param.SamplingPercentage);
        case 'uniform'
            [edgeSubset] = maxflowSampling(W, ...
                'uniform', param.SamplingPercentage);
        case 'degree'
            [edgeSubset] = maxflowSampling(W, ...
                'degree', param.SamplingPercentage);
        case 'closeness'
            [edgeSubset] = maxflowSampling(W, ...
                'closeness', param.SamplingPercentage);
        case 'betweenness'
            [edgeSubset] = maxflowSampling(W, ...
                'betweenness', param.SamplingPercentage);
        case 'pagerank'
            [edgeSubset] = maxflowSampling(W, ...
                'pagerank', param.SamplingPercentage);
        case 'eigenvector'
            [edgeSubset] = maxflowSampling(W, ...
                'eigenvector', param.SamplingPercentage);
        case 'adamic'
            D = full(sum(W, 1));
            A = W * diag(1./log(D)) * W;
            edges = find(triu(W, 1));
            weights = A(edges);
            edgeSubset = sampleWeighted(edges, weights, param.SamplingPercentage);
        case 'random'
            % Only edges (i, j) with i < j
            edges = find(triu(W, 1));       
            nEdge = length(edges);
            k = round(nEdge * param.SamplingPercentage);
            edgeSubset = datasample(edges, k, ...
                'Replace', false);
        case 'proddegree'
            D = full(sum(W, 1));
            edges = find(triu(W, 1));
            [i1, i2] = ind2sub(size(W), edges);
            weights = D(i1) .* D(i2);
            edgeSubset = sampleWeighted(edges, weights, param.SamplingPercentage);
        otherwise
            error('Invalid sampling method.');
    end
    nNode = size(W, 1);
    [rows, columns] = ind2sub([nNode nNode], edgeSubset);
    Wtrain = sparse(rows, columns, true, nNode, nNode);
    Wtrain = Wtrain | Wtrain';
    Wtest = logical(W - Wtrain);
    
    if(~param.AdjustTrainingTopology) 
        % Swap train and test
        temp = Wtrain;
        Wtrain = Wtest;
        Wtest = temp;
    end
    
end

function [edgeSubset] = maxflowSampling(W, centrality, samplingPercentage)
    C = computeNodeCentrality(centrality, W);
    Wprob = quadSolver(W, C);
%     Wprob = maxflowSolver(W, C);

    % Only edges (i, j) with i < j
    edges = find(triu(W, 1));       
    weights = full(Wprob(edges));

    edgeSubset = sampleWeighted(edges, weights, samplingPercentage);
    
%     % Filter edges with zero weight
%     validEdges = weights >= 0;
%     edges = edges(validEdges);
%     weights = weights(validEdges);
% 
%     nEdge = length(edges);
%     k = round(nEdge * samplingPercentage);
% 
%     edgeSubset = datasample(edges, k, ...
%         'Replace', false, ...
%         'Weights', weights);         
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





