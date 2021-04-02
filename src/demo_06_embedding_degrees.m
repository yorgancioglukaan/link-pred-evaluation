clear;
rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'DBLP_A';

samplingMethods = {'real','sim','random','uniform','adamic'};

linkPredictionMethods ={'proddegree'};% {'line','laplacian','deepwalk'};


adjustTrainingTopology = false;
maxPredictedEdges = Inf;
metric = 'auroc';
seed = 2;



%% Load/Preprocess Dataset

[W, nNode, realTrain, realTest, edgeSamplingPercentage] = loadTemporalNetwork(network);

%% Centrality Analysis
nSamplingMethod = length(samplingMethods);
nLinkPredictionMethod = length(linkPredictionMethods);
AucResults = zeros(nSamplingMethod, nLinkPredictionMethod);
AucResults_degree = zeros(nSamplingMethod, nLinkPredictionMethod);
timestart = tic();


for iSamplingMethod = 1:nSamplingMethod
    
    sampling = samplingMethods{iSamplingMethod};
    Wtrain = logical(load_edgelist(strcat('savedsets/', network, '_', sampling, '.txt'), nNode));
    Wtest = logical(W - Wtrain);

    for iMethod = 1:nLinkPredictionMethod
        method = linkPredictionMethods{iMethod};
        
        tic
        fprintf('[Running] %s - %s\n', sampling, method);

        if strcmp(method, 'deepwalk')
            emb_file = strcat(network,'_', sampling, '_deepwalk');
            emb = load_embedding('savedembeds',emb_file,nNode);

        elseif strcmp(method, 'laplacian')
            emb_file = strcat(network,'_', sampling, '_laplacian');
            emb = load_embedding('savedembeds',emb_file,nNode);

        elseif strcmp(method, 'line')
            emb_file = strcat(network,'_', sampling, '_line');
            emb = load_embedding('savedembeds',emb_file,nNode);
        elseif strcmp(method, 'anchor_pr')
            emb = getAnchorEmbedding(Wtrain, 05, 0.3);
        else
        [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges);
        end


%         trainingDegrees = sum(Wtrain,2);
%         [sortedEdges, sortedWeights] = runLinkPrediction(...
%             method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', horzcat(emb,trainingDegrees), 'Classifier', true);
%         [~, stats] = evaluateLinkPrediction(...
%             Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'auroc');
%         AucResults_degree(iSamplingMethod, iMethod) = stats.auroc;
        
        
%         [sortedEdges, sortedWeights] = runLinkPrediction(...
%             method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', true);
         [~, stats] = evaluateLinkPrediction(...
             Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'auroc');
         AucResults(iSamplingMethod, iMethod) = stats.auroc;

        toc
    end
end
toc(timestart);
