rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'DBLP_A';
% 
samplingMethods = {'uniform', 'real', 'random', 'degree'};

linkPredictionMethods = {'adamicadar', 'jaccardindex', 'proddegree', 'commonneighbors'};


adjustTrainingTopology = false;
maxPredictedEdges = Inf;
metric = 'auroc';
seed = 2;

%% Load/Preprocess Dataset
[W, nNode, realTrain, realTest, edgeSamplingPercentage] = loadTemporalNetwork(network);

%% Centrality Analysis
nSamplingMethod = length(samplingMethods);
nLinkPredictionMethod = length(linkPredictionMethods);

timestart = tic();
Results = cell(nSamplingMethod, nLinkPredictionMethod);
for iSamplingMethod = 1:nSamplingMethod
    rng(seed, 'twister'); % For reproducibility
    sampling = samplingMethods{iSamplingMethod};
    
    % Step 2: Prepare training/test sets
    if ~strcmpi(sampling, 'real')
        opts = struct();
        opts.Sampling = sampling;
        opts.SamplingPercentage = edgeSamplingPercentage;
        opts.AdjustTrainingTopology = adjustTrainingTopology;
        [Wtrain, Wtest] = prepareTrainingSets(W, opts);
    else
        Wtrain = realTrain;
        Wtest = realTest;
    end
    
    % Step 3: Link Prediction
    for iMethod = 1:nLinkPredictionMethod
        method = linkPredictionMethods{iMethod};
        
        tic
        fprintf('[Running] %s - %s\n', sampling, method);
        [sortedEdges, sortedWeights] = runLinkPrediction(...
            method, Wtrain, 'MaxEdges', maxPredictedEdges);
        
        % Step 4: Evaluation
        [~, stats] = evaluateLinkPrediction(...
            Wtrain, Wtest, sortedEdges, sortedWeights, 'Metric', metric);
        Results{iSamplingMethod, iMethod} = stats;
        toc
    end
end
toc(timestart);
%% Figures
AUC = zeros(nSamplingMethod, nLinkPredictionMethod);

for iSamplingMethod = 1:nSamplingMethod
    for iMethod = 1:nLinkPredictionMethod
        auc = Results{iSamplingMethod, iMethod}.(metric);
        AUC(iSamplingMethod, iMethod) = auc;
    end
end

linkPredictionTitles = linkPredictionMethods;

figure(1);
clf();
set(gcf, 'Position', [0 0 1280 720]);
movegui('center');
gbarfigure(AUC, zeros(size(AUC)), samplingMethods, linkPredictionTitles, 'YLim', [0 1], 'LegendLocation', 'southeast')
hold('on');
plot(xlim(), [0.5 0.5], '--k');
hold('off');
ylabel('AUROC');
xlabel('Legend shows the sampling type');
if(~exist(outPath, 'dir')); mkdir(outPath); end
export_fig(sprintf('%s/sampling_analysis_%s_auroc_p%.2f_st%d', ...
    outPath, network, edgeSamplingPercentage, adjustTrainingTopology), '-m2');

figure(2);
clf();
set(gcf, 'Position', [0 0 1280 720]);
movegui('center');
gbarfigure(2*AUC - 1, zeros(size(AUC)), samplingMethods, linkPredictionTitles, 'YLim', [0 1])
ylabel('2*AUROC-1');
xlabel('Legend shows the sampling type');
if(~exist(outPath, 'dir')); mkdir(outPath); end
export_fig(sprintf('%s/sampling_figurealt_%s_auroc_p%.2f_st%d', ...
    outPath, network, edgeSamplingPercentage, adjustTrainingTopology), '-m2');

















