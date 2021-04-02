clear;
rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'DBLP_A';

samplingMethods = {'adamic','uniform','random'};

linkPredictionMethods = {'line','laplacian','deepwalk','adamicadar', 'proddegree'};


adjustTrainingTopology = false;
maxPredictedEdges = Inf;
metric = 'auroc';
seed = 2;


nSamplingMethod = length(samplingMethods);
nLinkPredictionMethod = length(linkPredictionMethods);

timestart = tic();
Results = cell(nSamplingMethod, nLinkPredictionMethod);
for iSamplingMethod = 1:nSamplingMethod
    
    sampling = samplingMethods{iSamplingMethod};
    
    % Step 1: load saved predictions
    load(strcat('savedresults_dblp/10-90/', sampling, '.mat'));
    nLinkPredictionMethod = length(linkPredictionMethods);
    % Step 2: Link Prediction
    for iMethod = 1:nLinkPredictionMethod
        method = linkPredictionMethods{iMethod};
        
        tic
        fprintf('[Running] %s - %s\n', sampling, method);
        sortedEdges = saved_methods{iMethod}.sortedEdges;
        sortedWeights = saved_methods{iMethod}.sortedWeights;
        
        Wtest = W - Wtrain;
        
         % Step 3: Evaluation
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
gbarfigure(AUC, zeros(size(AUC)), samplingMethods, linkPredictionTitles, 'YLim', [0 1], 'LegendLocation', 'northeast')
hold('on');
plot(xlim(), [0.5 0.5], '--k');
hold('off');
ylabel('node based top hits k =1000');
xlabel('Legend shows the sampling type');
if(~exist(outPath, 'dir')); mkdir(outPath); end
export_fig(sprintf('%s/sampling_analysis_%s_AUC_p%.2f_st%d', ...
    outPath, network, edgeSamplingPercentage, adjustTrainingTopology), '-m2');

