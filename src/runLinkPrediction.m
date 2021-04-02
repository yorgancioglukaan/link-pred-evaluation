function [ sortedEdges, sortedWeights ] = runLinkPrediction(method, W, varargin)
    p = inputParser;
    validNetwork = @(x) validateattributes(x, {'numeric', 'logical'}, ...
        {'2d', 'nonnan', 'square', 'nonempty'});
    validMethod = @(x) any(validatestring(x, ...
        {'proddegree', 'prodcentrality', 'prodeigenvector', ...
        'prodcloseness', 'prodpagerank', 'prodbetweenness', 'adamicadar','node2vec', 'line','laplacian', 'anchor_pr'}));
    validCentrality = @(x) any(validatestring(x, ...
        {'uniform', 'degree', 'betweenness', 'pagerank', 'eigenvector', 'closeness'}));
%     addRequired(p, 'Method', validMethod);
    addRequired(p, 'Method', @ischar);
    addRequired(p, 'W', validNetwork);
    addParameter(p, 'MaxEdges', Inf, @isnumeric);
    addParameter(p, 'Centrality', 'pagerank', validCentrality);
    addParameter(p, 'Embedding', [], @(x) isnumeric(x));
    addParameter(p, 'PresetIndices', [], @(x) isnumeric(x));
    addParameter(p,'Classifier',false, @(x) islogical(x));
    addParameter(p, 'DegreeInteraction', false, @(x) islogical(x));
    parse(p, method, W, varargin{:});
    param = p.Results;
    switch(lower(method))
        case 'prodcentrality'
            [sortedEdges, sortedWeights] = prodCentrality(W, param.Centrality);
        case 'proddegree'
            [sortedEdges, sortedWeights] = prodCentrality(W, 'degree');
        case 'prodeigenvector'
            [sortedEdges, sortedWeights] = prodCentrality(W, 'eigenvector');
        case 'prodcloseness'
            [sortedEdges, sortedWeights] = prodCentrality(W, 'closeness');
        case 'prodpagerank'
            [sortedEdges, sortedWeights] = prodCentrality(W, 'pagerank');
        case 'prodbetweenness'
            [sortedEdges, sortedWeights] = prodCentrality(W, 'betweenness');
        case 'adamicadar'
            D = full(sum(W, 1));
            A = W * diag(1./log(D)) * W;
            Aw = 1 + A;
            Aw(W) = 0;
            edges = find(triu(Aw, 1));
            [sortedWeights, si] = sort(Aw(edges), 'descend');
            sortedEdges = edges(si);
        case 'jaccardindex'
            A = Jaccard(double(W));
            Aw = 1 + A;
            Aw(W) = 0;
            edges = find(triu(Aw, 1));
            [sortedWeights, si] = sort(Aw(edges), 'descend');
            sortedEdges = edges(si);
        case 'commonneighbors'
            A = double(W)*W';
            Aw = 1 + A;
            Aw(W) = 0;
            edges = find(triu(Aw, 1));
            [sortedWeights, si] = sort(Aw(edges), 'descend');
            sortedEdges = edges(si);
        case 'vonnneumann'
            alpha = 0.5;
            S = sqrt(sum(W, 1)) .* W .* sqrt(sum(W, 2));
%             I = speye(size(W));
            S2 = S;
            A = alpha*S;
            alpha2 = alpha;
            for i = 1:5
               S2 = S2*S;
               alpha2 = alpha2 *alpha;
               A = A + alpha2*S2;
            end            
            Aw = 1 + A;
            Aw(W) = 0;
            edges = find(triu(Aw, 1));
            [sortedWeights, si] = sort(Aw(edges), 'descend');
            sortedEdges = edges(si);
        case 'node2vec'
            emb = param.Embedding;
            if param.Classifier
                [neg,pos] = makeSets(W);
                [feats,labs] = trainingSample(neg, pos, W, emb);
                [B,~,~] = mnrfit(feats,categorical(labs));
                if ~isempty(param.PresetIndices)
                    [sortedWeights,sortedEdges] = predict(W,B,emb,param.PresetIndices);
                else
                    [sortedWeights,sortedEdges] = predictAll(W,B,emb);
                end
            else
                sim = corr(emb.');
                sim(isnan(sim)) = 0;
                Aw = 1 + sim;
                Aw(W) = 0;
                edges = find(triu(Aw, 1));
                [sortedWeights, si] = sort(Aw(edges), 'descend');
                sortedEdges = edges(si);
            end
        case 'deepwalk'
            emb = param.Embedding;
            if param.Classifier
                [neg,pos] = makeSets(W);
                if param.DegreeInteraction 
                    [feats,labs] = trainingSample_d(neg, pos, W, emb);
                else
                    [feats,labs] = trainingSample(neg, pos, W, emb);
                end
                [B,~,~] = mnrfit(feats,categorical(labs));
                if ~isempty(param.PresetIndices)
                    [sortedWeights,sortedEdges] = predict(W,B,emb,param.PresetIndices);
                else
                    if param.DegreeInteraction
                        [sortedWeights,sortedEdges] = predictAll_d(W,B,emb);
                    else
                        [sortedWeights,sortedEdges] = predictAll(W,B,emb);
                    end
                end
            else
                sim = corr(emb.');
                sim(isnan(sim)) = 0;
                Aw = 1 + sim;
                Aw(W) = 0;
                edges = find(triu(Aw, 1));
                [sortedWeights, si] = sort(Aw(edges), 'descend');
                sortedEdges = edges(si);
            end
         case 'line'
            emb = param.Embedding;
            if param.Classifier
                [neg,pos] = makeSets(W);
                [feats,labs] = trainingSample(neg, pos, W, emb);
                [B,~,~] = mnrfit(feats,categorical(labs));
                if ~isempty(param.PresetIndices)
                    [sortedWeights,sortedEdges] = predict(W,B,emb,param.PresetIndices);
                else
                    [sortedWeights,sortedEdges] = predictAll(W,B,emb);
                end
            else
                sim = corr(emb.');
                sim(isnan(sim)) = 0;
                Aw = 1 + sim;
                Aw(W) = 0;
                edges = find(triu(Aw, 1));
                [sortedWeights, si] = sort(Aw(edges), 'descend');
                sortedEdges = edges(si);
            end
         case 'laplacian'
            emb = param.Embedding;
            if param.Classifier
                [neg,pos] = makeSets(W);
                [feats,labs] = trainingSample(neg, pos, W, emb);
                [B,~,~] = mnrfit(feats,categorical(labs));
                if ~isempty(param.PresetIndices)
                    [sortedWeights,sortedEdges] = predict(W,B,emb,param.PresetIndices);
                else
                    [sortedWeights,sortedEdges] = predictAll(W,B,emb);
                end
            else
                sim = corr(emb.');
                sim(isnan(sim)) = 0;
                Aw = 1 + sim;
                Aw(W) = 0;
                edges = find(triu(Aw, 1));
                [sortedWeights, si] = sort(Aw(edges), 'descend');
                sortedEdges = edges(si);
            end
          case 'anchor_pr'
            emb = param.Embedding;
            if param.Classifier
                [neg,pos] = makeSets(W);
                [feats,labs] = trainingSample(neg, pos, W, emb);
                [B,~,~] = mnrfit(feats,categorical(labs));
                if ~isempty(param.PresetIndices)
                    [sortedWeights,sortedEdges] = predict(W,B,emb,param.PresetIndices);
                else
                    [sortedWeights,sortedEdges] = predictAll(W,B,emb);
                end
            else
                sim = corr(emb.');
                sim(isnan(sim)) = 0;
                Aw = 1 + sim;
                Aw(W) = 0;
                edges = find(triu(Aw, 1));
                [sortedWeights, si] = sort(Aw(edges), 'descend');
                sortedEdges = edges(si);
            end
        otherwise
            error('Invalid node centrality type.');
    end
    
    if ~isempty(param.PresetIndices) && ~(param.Classifier && any(strcmp(lower(method),{'node2vec','deepwalk'})))
        disp('filtering to presets');
        presets = param.PresetIndices;
        [~, locb] = ismember(presets,sortedEdges);
        weights = sortedWeights(locb);
        [sortedWeights, si] = sort(weights, 'descend');
        sortedEdges = presets(si);
        
    end
    
    if(length(sortedEdges) > param.MaxEdges)
        sortedEdges = sortedEdges(1:param.MaxEdges);
        sortedWeights = sortedWeights(1:param.MaxEdges);
    end
    
end

function [sortedEdges, sortedWeights] = prodCentrality(W, centrality)
    C = computeNodeCentrality(centrality, W);
    Cw = 1 + C .* C';
    Cw(W) = 0;
    edges = find(triu(Cw, 1));
    [sortedWeights, si] = sort(Cw(edges), 'descend');
    sortedEdges = edges(si);
end


function [negativeset,positiveset] = makeSets(W)
    positiveset = find(triu(W,1));
    nOfPos = nnz(positiveset);
    allNegatives = find(triu(~W,1));
    negativeset = datasample(allNegatives, nOfPos, 'replace', false);
end

function [features,labels] = trainingSample(negativeset, positiveset, W, embeddings)    
    setSize = length(positiveset);
    dim = size(embeddings,2);
    [row,col] = ind2sub(size(W),negativeset);
    features = zeros(setSize*4,dim*2);
    for i = 1:setSize
        vector = horzcat(embeddings(row(i),:),embeddings(col(i),:));
        features(i,:) = vector;
        vector = horzcat(embeddings(col(i),:),embeddings(row(i),:));
        features(i*2,:) = vector;
    end
    
    [row,col] = ind2sub(size(W),positiveset);
    for i = 1:setSize
        vector = horzcat(embeddings(row(i),:),embeddings(col(i),:));
        features(i+setSize*2,:) = vector;
        vector = horzcat(embeddings(col(i),:),embeddings(row(i),:));
        features(i*2+setSize*2,:) = vector;
    end
    
    neglabels = false(setSize*2,1);
    poslabels = true(setSize*2,1);
    labels = vertcat(neglabels,poslabels);
end

function [features,labels] = trainingSample_d(negativeset, positiveset, W, embeddings)    
    setSize = length(positiveset);
    dim = size(embeddings,2);
    [row,col] = ind2sub(size(W),negativeset);
    features = zeros(setSize*4,dim*2+1);
    d = sum(W,2);
    for i = 1:setSize
        vector = horzcat(embeddings(row(i),:),embeddings(col(i),:),d(col(i))*d(row(i)));
        features(i,:) = vector;
        vector = horzcat(embeddings(col(i),:),embeddings(row(i),:),d(col(i))*d(row(i)));
        features(i*2,:) = vector;
    end
    
    [row,col] = ind2sub(size(W),positiveset);
    for i = 1:setSize
        vector = horzcat(embeddings(row(i),:),embeddings(col(i),:),d(col(i))*d(row(i)));
        features(i+setSize*2,:) = vector;
        vector = horzcat(embeddings(col(i),:),embeddings(row(i),:),d(col(i))*d(row(i)));
        features(i*2+setSize*2,:) = vector;
    end
    
    neglabels = false(setSize*2,1);
    poslabels = true(setSize*2,1);
    labels = vertcat(neglabels,poslabels);
end


function [sortedWeights,sortedEdges] = predict(W,B,emb,presets)
    edges = presets;
    [row,col] = ind2sub(size(W),edges);
    k = length(row);
    dim = size(emb,2);
    measurements = zeros(k,dim*2);
    for i = 1:k
        vector = horzcat(emb(row(i),:),emb(col(i),:));
        measurements(i,:) = vector;
    end
    pihat = mnrval(B,measurements);
    weights = pihat(:,2);
    [sortedWeights, si] = sort(weights, 'descend');
    sortedEdges = edges(si);
end

function [sortedWeights,sortedEdges] = predictAll(W,B,emb)
    batch_size = 50000;
    Aw = 1 + W;
    Aw(W) = 0;
    edges = find(triu(Aw, 1));
    [row,col] = ind2sub(size(W),edges);
    all = length(row);
    k = floor(all/batch_size);
    surplus = mod(all,batch_size);
    dim = size(emb,2);
    weights = zeros(all,1);
    features = zeros(batch_size,2*dim);
    
    for i = 1:k
        for j = 1:batch_size
            pointer = (i-1)*batch_size + j;
            features(j,:) = horzcat(emb(row(pointer),:),emb(col(pointer),:));
        end
        pihat = mnrval(B,features);
        weights((i - 1)*batch_size +1:i*batch_size) = pihat(:,2);
    end
    features = zeros(surplus,2*dim);
    for j = 1:surplus
        pointer = k*batch_size + j;
        features(j,:) = horzcat(emb(row(pointer),:),emb(col(pointer),:));
    end
    pihat = mnrval(B,features);
    weights(k*batch_size+1:end) = pihat(:,2);
    

    [sortedWeights, si] = sort(weights, 'descend');
    sortedEdges = edges(si);
end

function [sortedWeights,sortedEdges] = predictAll_d(W,B,emb)
    d = sum(W,2);
    batch_size = 50000;
    Aw = 1 + W;
    Aw(W) = 0;
    edges = find(triu(Aw, 1));
    [row,col] = ind2sub(size(W),edges);
    all = length(row);
    k = floor(all/batch_size);
    surplus = mod(all,batch_size);
    dim = size(emb,2);
    weights = zeros(all,1);
    features = zeros(batch_size,2*dim+1);
    
    for i = 1:k
        for j = 1:batch_size
            pointer = (i-1)*batch_size + j;
            features(j,:) = horzcat(emb(row(pointer),:),emb(col(pointer),:),d(col(pointer))*d(row(pointer)));
        end
        pihat = mnrval(B,features);
        weights((i - 1)*batch_size +1:i*batch_size) = pihat(:,2);
    end
    features = zeros(surplus,2*dim+1);
    for j = 1:surplus
        pointer = k*batch_size + j;
        features(j,:) = horzcat(emb(row(pointer),:),emb(col(pointer),:),d(col(pointer))*d(row(pointer)));
    end
    pihat = mnrval(B,features);
    weights(k*batch_size+1:end) = pihat(:,2);
    

    [sortedWeights, si] = sort(weights, 'descend');
    sortedEdges = edges(si);
end


