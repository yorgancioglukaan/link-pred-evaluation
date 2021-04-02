function [ M, stats ] = evaluateLinkPrediction(...
        Wtrain, Wtest, sortedEdges, sortedWeights, varargin )    
    p = inputParser;
    validNetwork = @(x) validateattributes(x, {'numeric', 'logical'}, ...
        {'2d', 'nonnan', 'square', 'nonempty'});
    validEdges = @(x) validateattributes(x, {'numeric'}, ...
        {'vector', 'nonnan', 'positive', 'nonempty'});
    validMetric = @(x) startsWith(x, 'nb_tophit') || startsWith(x, 'tophit') || ...
        any(validatestring(x, {'auroc','meanrank'}));
    addRequired(p, 'Wtrain', validNetwork);
    addRequired(p, 'Wtest', validNetwork);
    addRequired(p, 'sortedEdges', validEdges);
    addRequired(p, 'sortedWeights', validEdges);
    addParameter(p, 'Metric', 'tophit1000', validMetric);
    
    parse(p, Wtrain, Wtest, sortedEdges, sortedWeights, varargin{:});
    param = p.Results;
    
    if(length(sortedEdges) ~= length(sortedWeights))
        error('Length of sortedEdges must be equal to the length of sortedWeights');
    end
    
    if  startsWith(param.Metric, 'nb_tophit')
        k = str2double(param.Metric(10:end));
        M = nodeBasedTophit(sortedWeights,sortedEdges,Wtest,k);
        stats = struct();
        stats.(param.Metric) = M;
        return;
    end  
    
    if  strcmp(param.Metric, 'meanrank')
        M = meanRank(sortedWeights,sortedEdges,Wtest);
        stats = struct();
        stats.(param.Metric) = M;
        return;
    end    
    
    nNode = size(Wtrain, 1);
    nMax = nNode*(nNode-1)/2 - nnz(triu(Wtrain, 1));
    param.IsNegativeSetComplete = length(sortedEdges) == nMax;
    
    edgesTest = find(triu(Wtest, 1));
    [sortedLabels] = ismember(sortedEdges, edgesTest);
    M = computeMetric(sortedWeights, sortedLabels, param.Metric, param);
    stats = struct();
    stats.(lower(param.Metric)) = M;
    
    if(nargout >= 2)
        stats = computeAllMetrics(sortedWeights, sortedLabels, stats, param);
    end
end

function [stats] = computeAllMetrics(edge_weights, labels, stats, param)
    metrics_complete = {'auroc'};
    metrics_other = {'tophit10', 'tophit100', 'tophit1000', 'tophit10000'};
    
    if(param.IsNegativeSetComplete)
        metrics = [metrics_complete, metrics_other];
    else
        metrics = [metrics_other];
    end
    
    for iMetric = 1:length(metrics)
        metric = lower(metrics{iMetric});
        if(isfield(stats, metric)); continue; end
        stats.(metric) = computeMetric(edge_weights, labels, metric, param);
    end
end

function [M] = computeMetric(edge_weights, labels, metric, param)
    metric = lower(metric);
    
    if(startsWith(metric, 'tophit'))
        k = str2double(metric(7:end));
        metric = 'tophit';
    end
    
    switch(metric)
        case 'auroc'
%             if(~param.IsNegativeSetComplete)
%                 error('AUROC cannot be computed without a complete negative set.');
%             end
            [auc_p, h, stats] = ranksum(...
                edge_weights(labels==1), edge_weights(labels==0));
            nPositive = nnz(labels==1);
            nNegative = length(labels) - nPositive;
            auc = (stats.ranksum - nPositive * (nPositive/2))/ (nPositive * nNegative);
            M = auc;
        case 'tophit'
            nPrediction = min(k, length(labels));
            precision = nnz(labels(1:nPrediction)) / nPrediction;
            M = precision;
        otherwise
            error('Invalid metric.'); 
    end
end


function [M] = meanRank(sortedWeights,sortedEdges,Wtest)
    %compute mean rank of true positives per node
    predictions = zeros(size(Wtest));
    predictions(sortedEdges) = sortedWeights; %reconstrutc prediction matrix
    predictions = predictions + predictions.'; %make symmetric
    [~,ranks] = sort(predictions, 2, 'descend'); %rank each row internally
    masked_ranks = ranks;
    masked_ranks(Wtest == 0) = nan; %delete the ranks of trivials and true negatives
    M = mean(mean(masked_ranks,'omitnan'),'omitnan');
end

function [M] = nodeBasedTophit(sortedWeights, sortedEdges, Wtest, k)
    predictions = zeros(size(Wtest));
    predictions(sortedEdges) = sortedWeights; %reconstrutc prediction matrix
    predictions = predictions + predictions.'; %make symmetric
    [~,ranks] = sort(predictions, 2, 'descend'); %rank each row internally
    masked_test = double(Wtest);
    masked_test(ranks > k) = 0;
    tp_per_row = sum(masked_test,2);
    hit_ratio_per_row = tp_per_row ./ min(sum(Wtest,2),k);
    M = mean(hit_ratio_per_row, 'omitnan');
end
