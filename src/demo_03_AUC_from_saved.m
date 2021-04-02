clear;
rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'DBLP_A';

samplingMethods = {'real','sim','uniform','random'};

linkPredictionMethods = {'line','laplacian','deepwalk','adamicadar', 'proddegree'};


adjustTrainingTopology = false;
maxPredictedEdges = Inf;
metric = 'auroc';
seed = 1;



%% Load/Preprocess Dataset

[W, nNode, realTrain, realTest, edgeSamplingPercentage] = loadTemporalNetwork(network);

%% Centrality Analysis
nSamplingMethod = length(samplingMethods);
nLinkPredictionMethod = length(linkPredictionMethods);

timestart = tic();
AucResults = zeros(nSamplingMethod, nLinkPredictionMethod);
NbTophit100 = zeros(nSamplingMethod, nLinkPredictionMethod);
NbTophit1000 = zeros(nSamplingMethod, nLinkPredictionMethod);
NbTophit10000 = zeros(nSamplingMethod, nLinkPredictionMethod);

for iSamplingMethod = 1:nSamplingMethod
    
    sampling = samplingMethods{iSamplingMethod};
    
    % Step 2: Prepare training/test sets
    Wtrain = logical(load_edgelist(strcat('savedsets/', network, '_', sampling, '.txt'), nNode));
    Wtest = logical(W - Wtrain);

    
    % Step 3: Link Prediction
    for iMethod = 1:nLinkPredictionMethod
        method = linkPredictionMethods{iMethod};
        
        tic
        fprintf('[Running] %s - %s\n', sampling, method);
        if strcmp(method, 'node2vec')
            emb_file = strcat(network,'_', sampling, '_node2vec');
            emb = load_embedding('savedembeds',emb_file,nNode);
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', true);
        elseif strcmp(method, 'deepwalk')
            emb_file = strcat(network,'_', sampling, '_deepwalk');
            emb = load_embedding('savedembeds',emb_file,nNode);
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', true);
        elseif strcmp(method, 'laplacian')
            emb_file = strcat(network,'_', sampling, '_laplacian');
            emb = load_embedding('savedembeds',emb_file,nNode);
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', true);
        elseif strcmp(method, 'line')
            emb_file = strcat(network,'_', sampling, '_r2_line');
            emb = load_embedding('savedembeds',emb_file,nNode);
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', true);
        else
        [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges);
        end
        % Step 4: Evaluation
        [~, stats] = evaluateLinkPrediction(...
            Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'auroc');
        AucResults(iSamplingMethod, iMethod) = stats.auroc;
        [~, stats] = evaluateLinkPrediction(...
            Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'nb_tophit100');
        NbTophit100(iSamplingMethod, iMethod) = stats.nb_tophit100;
        [~, stats] = evaluateLinkPrediction(...
            Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'nb_tophit1000');
        NbTophit1000(iSamplingMethod, iMethod) = stats.nb_tophit1000;
        [~, stats] = evaluateLinkPrediction(...
            Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', 'nb_tophit10000');
        NbTophit10000(iSamplingMethod, iMethod) = stats.nb_tophit10000;
        toc
    end
end
toc(timestart);

save("out/dblp_repeat.mat", "NbTophit1000", "NbTophit10000", "AucResults", "samplingMethods", "linkPredictionMethods","network")

