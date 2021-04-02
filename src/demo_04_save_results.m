clear;
rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'biogrid_drosophila';

samplingMethods = {'real','sim','uniform','random'};

linkPredictionMethods = {'line_corr','line_class','laplacian_corr','laplacian_class','deepwalk_corr','deepwalk_class','adamicadar', 'proddegree'};


adjustTrainingTopology = false;
maxPredictedEdges = 100000;
metric = 'nb_tophit1000';
seed = 2;



%% Load/Preprocess Dataset

[W, nNode, realTrain, realTest, edgeSamplingPercentage] = loadTemporalNetwork(network);

%% Centrality Analysis
nSamplingMethod = length(samplingMethods);
nLinkPredictionMethod = length(linkPredictionMethods);

timestart = tic();
Results = cell(nSamplingMethod, nLinkPredictionMethod);
for iSamplingMethod = 1:nSamplingMethod
    
    sampling = samplingMethods{iSamplingMethod};
    
    %Step 2: Prepare training/test sets
    Wtrain = logical(load_edgelist(strcat('savedsets/', network, '_', sampling, '.txt'), nNode));
    Wtest = logical(W - Wtrain);

    
    saved_methods = cell(nLinkPredictionMethod,1);

    % Step 3: Link Prediction
    for iMethod = 1:nLinkPredictionMethod
        method = linkPredictionMethods{iMethod};
        saved_predictions = struct();
        tic
        fprintf('[Running] %s - %s\n', sampling, method);
        if startsWith(method, 'deepwalk')
            emb_file = strcat(network,'_', sampling, '_deepwalk');
            emb = load_embedding('savedembeds',emb_file,nNode);
            if(strcmp(method(end), 's'))
                flag = true;
            else
                flag = false;
            end
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            'deepwalk', Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', flag);
        elseif startsWith(method, 'laplacian')
            emb_file = strcat(network,'_', sampling, '_laplacian');
            emb = load_embedding('savedembeds',emb_file,nNode);
            if(strcmp(method(end), 's'))
                flag = true;
            else
                flag = false;
            end
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            'laplacian', Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', flag);
        elseif startsWith(method, 'line')
            emb_file = strcat(network,'_', sampling, '_r1_line');
            emb = load_embedding('savedembeds',emb_file,nNode);
            if(strcmp(method(end), 's'))
                flag = true;
            else
                flag = false;
            end
            [sortedEdges, sortedWeights] = runLinkPrediction(...
            'line', Wtrain, 'MaxEdges', maxPredictedEdges, 'Embedding', emb, 'Classifier', flag);
        else
        [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges);
        end
        % Step 4: Save predictions
        saved_predictions.sortedEdges = sortedEdges;
        saved_predictions.sortedWeights = sortedWeights;
        saved_methods{iMethod} = saved_predictions;

        toc
    end
    save(strcat('savedresults_dblp_a/',sampling,'.mat'), 'W', 'Wtrain', 'linkPredictionMethods', 'saved_methods', '-v7.3');
end
toc(timestart);
