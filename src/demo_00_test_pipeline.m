rng(1, 'twister'); % For reproducibility
%% Options
network = 'DBLP_A';

samplingMethod = 'maxflow';
maxflowCentrality = 'degree';
edgeSamplingPercentage = 0.5;
adjustTrainingTopology = false;

linkPredictionMethod = 'prodpagerank';
linkPredictionCentrality = 'closeness'; % Used for 'prodcentrality'
maxPredictedEdges = Inf;

%% Step 1: Load/Preprocess Dataset
[W, nNode] = loadStaticNetwork(network);

%% Step 2: Prepare train/test sets (with MaxFlow algorithm)
opts = struct();
opts.Sampling = samplingMethod;
opts.SamplingPercentage = edgeSamplingPercentage;
opts.Centrality = maxflowCentrality;
opts.AdjustTrainingTopology = adjustTrainingTopology;

[Wtrain, Wtest] = prepareTrainingSets(W, opts);
%% Step 3: Link Prediction
tic
[sortedEdges, sortedWeights] = runLinkPrediction(...
        linkPredictionMethod, Wtrain, ...
        'MaxEdges', maxPredictedEdges, ...
        'Centrality', linkPredictionCentrality);
nPrediction = length(sortedEdges);
toc

%% Step 4: Evaluation
tic
[AUROC, stats] = evaluateLinkPrediction(Wtrain, Wtest, ...
    sortedEdges, sortedWeights, ...
    'Metric', 'auroc');
toc

disp(stats);







