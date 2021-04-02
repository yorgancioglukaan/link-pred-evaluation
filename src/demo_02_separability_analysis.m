rng(1, 'twister'); % For reproducibility
addpath(genpath('util/'));
outPath = 'out/';
%% Options
network = 'DBLP_A';
sampling = 'real';
metric = 'proddegree';
%% Load/Preprocess Dataset

[W, nNode, Wreal, Wtemporal, edgeSamplingPercentage] = loadTemporalNetwork(network);

if(~strcmpi(sampling, 'real'))
    opts = struct();
    opts.Sampling = sampling;
    opts.SamplingPercentage = 0.2;
    opts.AdjustTrainingTopology = false;
    [W, Wtemporal] = prepareTrainingSets(W, opts);
end

%%
Wtemporal(W) = false;

degree1 = sum(W, 1);
degree2 = sum(W, 2);

nNode = size(W, 1);

nNegativeSample = 100000;

subs = randi([1 nNode], nNegativeSample, 2);
indices = unique(sub2ind([nNode nNode], subs(:, 1), subs(:, 2)));
positives = find(Wtemporal);
negatives = setdiff(indices, positives);
negatives = setdiff(negatives, find(W));

[rPos, cPos] = ind2sub([nNode nNode], positives);
degree2Pos = full(degree2(rPos));
degree1Pos = full(degree1(cPos));
proddegPos = sqrt(degree1Pos .* degree2Pos');

[rNeg, cNeg] = ind2sub([nNode nNode], negatives);
degree2Neg = full(degree2(rNeg));
degree1Neg = full(degree1(cNeg));
proddegNeg = sqrt(degree1Neg .* degree2Neg');
%%
defaultColors = [0 0.447 0.741; 0.85 0.325 0.098; ...
    0.929 0.694 0.125; 0.466 0.674 0.188; 0.301 0.745 0.933; ...
    0.494 0.184 0.556; 0.635 0.078 0.184];

switch(metric)
    case 'proddegree'
        metricPos = proddegPos;
        metricNeg = proddegNeg;
        xaxistext = 'Product of degrees';
    case 'degree'
        metricPos = degree1Pos;
        metricNeg = degree1Neg;
        xaxistext = 'Node Degree';
    case 'adamicadar'
        D = full(sum(W, 1));
        A = W * diag(1./log(D)) * W;
        A(isinf(A)) = 0;
        metricPos = A(positives);
        metricNeg = A(negatives);
        xaxistext = 'Adamic Adar';
    case 'eigenvalue5'
        A = W;
        A = A + diag(sum(A, 1));
        [V, ~] = eigs(A, 5);
        d = sqrt(squareform(pdist(V, 'euclidean')));
        metricPos = d(positives);
        metricNeg = d(negatives);
        xaxistext = 'EigenVector5';
        clear d;
    case 'vonnneumann5'
        alpha = 0.5;
        S = 1./sqrt(sum(W, 1)) .* W .* 1./sqrt(sum(W, 2));
%             I = speye(size(W));
        S2 = S;
        A = alpha*S;
        alpha2 = alpha;
        for i = 1:4
           S2 = S2*S;
           alpha2 = alpha2*alpha;
           A = A + alpha2*S2;
        end   
        metricPos = A(positives);
        metricNeg = A(negatives);
        xaxistext = 'VonnNeumann5';
    otherwise
        error('Invalid metric.');
end
%%
v = max(prctile(metricNeg, 95), prctile(metricPos, 95));

tic
[sep, cutoff] = computeSeparability(metricPos, metricNeg);
toc

figure(1);
clf();
set(gcf, 'Position', [266 117 710 495]);
set(gca, 'FontSize', 13);
hold('on');
h1 = histogram(metricPos, 'FaceColor', [0.2 0.2 0.9], ...
    'Normalization', 'pdf');
h2 = histogram(metricNeg, 50, 'FaceAlpha', 0.6, 'FaceColor', [0.925 0.67 0.55], ...
    'Normalization', 'pdf', 'EdgeColor', 'none');
plot([1 1] * cutoff, ylim(), '--k', 'LineWidth', 1.25);
plot([1 1] * mean(metricPos), ylim(), 'Color', defaultColors(1, :), 'LineWidth', 2.5);
plot([1 1] * mean(metricNeg), ylim(), 'Color', defaultColors(2, :), 'LineWidth', 2.5);
hold('off');
xlabel(xaxistext);
ylabel('PDF');

networkTitle = strrep(network, '_', '-');
title(sprintf('Network: %s, Sampling: %s, Separability: %.1f%%', networkTitle, sampling, 100*sep));
if(v > 0)
    xlim([0 v]);
end
% set(gca, 'XScale', 'log');

legend([h1 h2], {'Positives', 'Negatives'});
grid();
set(gcf, 'Color', [1 1 1]);
outPath = ['out/separability_analysis/', network, '/'];
if(~exist(outPath, 'dir')); mkdir(outPath); end
% export_fig(sprintf('%sseparability_%s_degree.png', outPath, network), '-m2');
export_fig(sprintf('%sseparability_%s_%s_%s.png', outPath, network, metric, sampling), '-m2');







