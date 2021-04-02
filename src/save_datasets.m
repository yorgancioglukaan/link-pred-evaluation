clear;
rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
network = 'DBLP_A';
samplingMethods = {'real','sim','uniform', 'random'};

adjustTrainingTopology = false;
maxPredictedEdges = Inf;
seed = 5;



%% Load/Preprocess Dataset
    
[W, nNode, realTrain, realTest, edgeSamplingPercentage] = loadTemporalNetwork(network);

nSamplingMethod = length(samplingMethods);


save_edgelist(W, 'savedsets', network);
%% Generate And Save datasets
for iSamplingMethod = 1:nSamplingMethod
    rng(seed, 'twister'); % For reproducibility
    sampling = samplingMethods{iSamplingMethod};
    
    if strcmpi(sampling, 'real')
        Wtrain = realTrain;
        Wtest = realTest;
    elseif strcmpi(sampling, 'sim')
        [ Wtrain, Wtest] = simulated_sampling(W, realTrain, edgeSamplingPercentage);    
    else
        opts = struct();
        opts.Sampling = sampling;
        opts.SamplingPercentage = edgeSamplingPercentage;
        opts.AdjustTrainingTopology = adjustTrainingTopology;
        [Wtrain, Wtest] = prepareTrainingSets(W, opts);
    end
    
    %% Step 3:Save to edgelist
    
    fprintf('Saving %s: , nnz train: %d\n', sampling, nnz(Wtrain))
    save_edgelist(Wtrain, 'savedsets', strcat(network, '_',sampling, '_r2'));

end