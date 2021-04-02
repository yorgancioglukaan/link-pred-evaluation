function [ info ] = gbarplot( X, varargin )
    [nStack, nItem, nGroup] = size(X);
    defaultGroupLabels = cell(1, nGroup);
%     for i = 1:nGroup; defaultGroupLabels{i} = ['Group', num2str(i)]; end
    for i = 1:nGroup; defaultGroupLabels{i} = ['']; end
    defaultItemLabels = cell(1, nItem);
    for i = 1:nItem; defaultItemLabels{i} = [num2str(i)]; end
    defaultStackLabels = cell(1, nStack);
    for i = 1:nStack; defaultStackLabels{i} = ['Stack', num2str(i)]; end
    if(nStack ~= 1)
        defaultColors = distinguishable_colors(nStack, [0 0 0; 1 1 1]);
    else
        if(nItem ~= 1)
            defaultColors = distinguishable_colors(nItem, [0 0 0; 1 1 1]);
        else
            defaultColors = distinguishable_colors(nGroup, [0 0 0; 1 1 1]);
        end
    end
    p = inputParser;
    p.CaseSensitive = false;
    check_pos_numeric = @(x) (isnumeric(x) && x>0);
    check_nn_numeric = @(x) (isnumeric(x) && x>=0);
    check_plot_text = @(x) isempty(x) || ischar(x) || iscell(x);
    addParameter(p, 'Colors', defaultColors, @isnumeric);
    addParameter(p, 'ItemLabels', defaultItemLabels, @iscell);
    addParameter(p, 'GroupLabels', defaultGroupLabels, @iscell);
    addParameter(p, 'StackLabels', defaultStackLabels, @iscell);
    addParameter(p, 'GroupGap', 0.2, check_nn_numeric);
    addParameter(p, 'GroupTextVgap', 0.2, check_nn_numeric);
    addParameter(p, 'GroupTextDynamic', true, @islogical);
    addParameter(p, 'GroupTextFontSize', 16, check_pos_numeric);
    addParameter(p, 'ItemTextVgap', 0.2, check_nn_numeric);
    addParameter(p, 'ItemTextDynamic', true, @islogical);
    addParameter(p, 'ItemTextEnabled', false, @islogical);
    addParameter(p, 'ItemTextFontSize', 12, check_nn_numeric);
    addParameter(p, 'ItemTextRotate', false, @islogical);
    addParameter(p, 'ItemGap', 0.2, check_nn_numeric);
    addParameter(p, 'Grid', true, @islogical);
    addParameter(p, 'Legend', false, @islogical);
    addParameter(p, 'LegendMixedColoring', false, @islogical);
    addParameter(p, 'LegendReserveAxis', 'none', @ischar);
    addParameter(p, 'LegendLocation', 'northeast', @ischar);
    addParameter(p, 'LegendFontSize', 16, check_pos_numeric);
    addParameter(p, 'LegendHgap', 0.1, check_nn_numeric);
    addParameter(p, 'LegendVgap', 0.1, check_nn_numeric);
    addParameter(p, 'LegendItemHgap', 0.1, check_nn_numeric);
    addParameter(p, 'LegendItemVgap', 0.2, check_nn_numeric);
    addParameter(p, 'LegendOrdering', 'FIFO', @ischar);
    addParameter(p, 'LegendBoxRatio', 1, check_pos_numeric);
    addParameter(p, 'LegendBoxHeightRatio', 1, check_pos_numeric);
    addParameter(p, 'Hgap', 0.02, check_nn_numeric);
    addParameter(p, 'MaximizeFigure', false, @islogical);
    addParameter(p, 'Position', get(0, 'Screensize'), @isnumeric);
    addParameter(p, 'XTickAngle', 0, @isnumeric);
    addParameter(p, 'AxisOpts', struct(), @isstruct);
    addParameter(p, 'XLabel', [], check_plot_text);
    addParameter(p, 'YLabel', [], check_plot_text);
    addParameter(p, 'Title', [], check_plot_text);
    addParameter(p, 'Ylims', [0 Inf], @isnumeric);
    addParameter(p, 'ForceYlims', false, @islogical);
    addParameter(p, 'AxisLineX', true, @islogical);
    addParameter(p, 'AxisLineY', true, @islogical);
    addParameter(p, 'AxisLineWidth', NaN, @isnumeric);
    addParameter(p, 'StartFromZero', true, @islogical);
    addParameter(p, 'XTickLabels', true, @islogical);
    addParameter(p, 'ClearFigure', false, @islogical);
    parse(p, varargin{:});
    alphaGroup = p.Results.GroupGap;
    alphaItem = p.Results.ItemGap;
    colors = p.Results.Colors;
    ItemLabels = p.Results.ItemLabels;
    if((size(ItemLabels, 1) == 1 && size(ItemLabels, 2) == nItem) ...
        || (size(ItemLabels, 1) == nItem && size(ItemLabels, 2) == 1))
        ItemLabels = repmat(reshape(ItemLabels, 1, nItem), nGroup, 1);
%         if(~(p.Results.Legend && nStack == 1 && nItem ~= 1))
%             ItemLabels = repmat(reshape(ItemLabels, 1, nItem), nGroup, 1);
%         end
    else
        if((p.Results.Legend && nStack == 1 && nItem ~= 1))
            error('Item labels must be a vector to be used with legend.');
        end
        if(size(ItemLabels, 1) ~= nGroup || size(ItemLabels, 2) ~= nItem)
           error('Item Labels should either be 1 x nItems vector or a matrix sized nGroups x nItems.');
        end
    end
    if(~ishold(gca))
        cla();
        initiallyHolded = false;
        hold('on');
    else
        initiallyHolded = true;
    end
    if(p.Results.ClearFigure)
        clf();
    end
    xlim([0 1]);
    ymin = p.Results.Ylims(1);
    ymax = max(max(max(X)));
%     ylim([ymin ymax]);

    if(p.Results.MaximizeFigure)
        set(gcf, 'Position', p.Results.Position);
    end
    if(~isempty(p.Results.XLabel)); xlabel(p.Results.XLabel); end
    if(~isempty(p.Results.YLabel)); ylabel(p.Results.YLabel); end
    if(~isempty(p.Results.Title)); title(p.Results.Title); end
    set(gca, p.Results.AxisOpts);
    
    optGroupText.FontSize = p.Results.GroupTextFontSize;
    optGroupText.HorizontalAlignment = 'center';
    optGroupText.VerticalAlignment = 'bottom';
    optItemText.FontSize = p.Results.ItemTextFontSize;
    if(p.Results.ItemTextRotate)
        optItemText.HorizontalAlignment = 'left';
        optItemText.VerticalAlignment = 'middle';
        optItemText.Rotation = 90;
    else
        optItemText.HorizontalAlignment = 'center';
        optItemText.VerticalAlignment = 'bottom';
        optItemText.Rotation = 0;
    end
    groupTextSizes = zeros(nGroup, 2);
    itemTextSizes = zeros(nItem, nGroup, 2);
    optGroupTextMeasurement = optGroupText;
    optGroupTextMeasurement.Units = 'normalized';
    optItemTextMeasurement = optItemText;
    optItemTextMeasurement.Units = 'normalized';
    for iGroup = 1:nGroup
        [groupTextSizes(iGroup, 1), groupTextSizes(iGroup, 2)] = measureText(p.Results.GroupLabels{iGroup}, optGroupTextMeasurement);
    end
    maxGroupTextHeight = max(groupTextSizes(:, 2)) * (1 + p.Results.GroupTextVgap);
    for iGroup = 1:nGroup
        for iItem = 1:nItem
        [itemTextSizes(iItem, iGroup, 1), itemTextSizes(iItem, iGroup, 2)] = measureText(ItemLabels{iGroup, iItem}, optItemTextMeasurement);
        end
    end
    maxItemTextHeight = max(max(itemTextSizes(:,:, 2))) * (1 + p.Results.ItemTextVgap);
    drawableHeight = (ymax - ymin) / (1 -  maxGroupTextHeight - maxItemTextHeight);
%     dataBox = [0, ymin, 1, drawableHeight]; % [xmin, ymin, width, height]
    xStart = p.Results.Hgap * 0.5;
    xEnd = 1 - p.Results.Hgap * 0.5;
    LegendEnabled = p.Results.Legend;
    if(LegendEnabled)
        if(nStack ~= 1)
           nLegendElement = nStack;
           LegendLabels = p.Results.StackLabels;
        else
            if(nItem ~= 1)
                nLegendElement = nItem;
                LegendLabels = p.Results.ItemLabels;
            else
                nLegendElement = nGroup;
                LegendLabels = p.Results.GroupLabels;
            end
        end
        if(isempty(LegendLabels))
            warning('Legend Labels are left empty. Legend is disabled.');
            LegendEnabled = false;
        end
    end
    if(LegendEnabled)
        optLegend.FontSize = p.Results.LegendFontSize;
        optLegend.HorizontalAlignment = 'left';
        optLegend.VerticalAlignment = 'middle';
        optLegend.Units = 'normalized';
        legendTextSizes = zeros(nStack, 2);
        for iElement = 1:nLegendElement
            [legendTextSizes(iElement, 1), legendTextSizes(iElement, 2)] = measureText(LegendLabels{iElement}, optLegend);
        end
        legendItemTextWidth = max(legendTextSizes(:,1));
        legendItemTextHeight = max(legendTextSizes(:,2));
        legendItemBoxHeight = legendItemTextHeight * p.Results.LegendBoxHeightRatio;
        legendItemBoxWidth = legendItemBoxHeight * p.Results.LegendBoxRatio;
        legendItemWidth = (1 + p.Results.LegendItemHgap) * (legendItemTextWidth + legendItemBoxWidth);
        legendItemHeight = (1 + p.Results.LegendItemVgap) * legendItemBoxHeight;
        legendInnerWidth = legendItemWidth;
        legendInnerHeight = legendItemHeight * nLegendElement;
        legendWidth = (1 + p.Results.LegendHgap) * legendInnerWidth;
        legendHeight = (1 + p.Results.LegendVgap) * legendInnerHeight;
        switch(lower(p.Results.LegendLocation))
            case 'northwest'
                legendXmin = 0;
                legendYmin = 1 - legendHeight;
            case 'northeast'
                legendXmin = 1 - legendWidth;
                legendYmin = 1 - legendHeight;
            case 'southwest'
                legendXmin = 0;
                legendYmin = 0;
            case 'southeast'
                legendXmin = 1 - legendWidth;
                legendYmin = 0;
            otherwise
                error('Invalid legend location.');
        end
        switch(lower(p.Results.LegendReserveAxis))
            case 'none'
            case 'x'
                if(legendXmin == 0)
                    xStart = xStart + legendWidth;
                else
                    xEnd = xEnd - legendWidth;
                end
            case 'y'
                if(legendYmin == 0)
                    error('It is not possible reserve legend location for southwest or southeast.');
                else
                    drawableHeight = (ymax - ymin) / (1 -  maxGroupTextHeight - legendHeight);
%                     drawableHeight = drawableHeight + legendHeight;
                end
            otherwise
                error('Invalid legend reserve axis');
        end
        LegendMixedColoring = p.Results.LegendMixedColoring;
        LegendOrdering = p.Results.LegendOrdering;
        if(nStack == 1 &&( strcmpi(LegendOrdering, 'ascend') || strcmpi(LegendOrdering, 'descend')))
            warning('Legend ordering ascend and descend are not allowed when number of stacks is 1. Legend ordering is set to FIFO.');
            LegendOrdering = 'FIFO';
        end
        if(LegendMixedColoring || strcmpi(LegendOrdering, 'ascend') || strcmpi(LegendOrdering, 'descend'))
            initial = true;
            isOrdered = true;
            for iGroup = 1:nGroup
                for iItem = 1:nItem
                    [sv, si] = sort(X(:, iItem, iGroup), 'ascend');
                    if(initial)
                        initial = false;
                        stackOrderingAscending = si;
                        stackValues = sv;
                    else
                        if(sum(stackOrderingAscending ~= si) ~= 0 && sum(stackValues ~= sv) ~= 0)
%                             iGroup
%                             iItem
                            isOrdered = false;
                            if(LegendMixedColoring)
                                warning('All stack elements are not ordered. Mixed Legend Coloring option is disabled.');
                                LegendMixedColoring = false;
                            end
                            if(strcmpi(LegendOrdering, 'ascend') || strcmpi(LegendOrdering, 'descend'))
                                warning('All stack elements are not ordered. Legend ordering is set to FIFO.');
                                LegendOrdering = 'FIFO';
                            end
                            break;
                        end
                    end
                end
                if(~isOrdered); break; end
            end
        end
    end
    lMax = (ymin + drawableHeight);
    if(~isinf(p.Results.Ylims(2)))
        lMax = max(lMax, p.Results.Ylims(2));
    end
%     plot([0], [ymin]);
%     plot([0], [ymax]);
    h = line([0, 0], [ymin, lMax], 'Color', [0 0 0], 'LineWidth', 0.01);
    drawnow;
    YaxisLimits = ylim;
    if(p.Results.ForceYlims)
        ylims = p.Results.Ylims;
        if(isinf(p.Results.Ylims(1)))
             ylims(1) = 0;
        end
        if(isinf(p.Results.Ylims(2)))
             ylims(2) = YaxisLimits(2);
        end
        ylim(ylims);
        YaxisLimits = ylim;
        clear('ylims');
    end
    ymin = YaxisLimits(1);
    if(p.Results.StartFromZero)
        ybarmin = 0;
    else
        ybarmin = YaxisLimits(1);
    end
    delete(h);
    height = YaxisLimits(2) - YaxisLimits(1);
    xDrawableLength = xEnd - xStart;
    limitsUI = [0, YaxisLimits(1), 1, height];
    groupLength = xDrawableLength / (alphaGroup * (nGroup - 1) + nGroup);
    groupGapLength = alphaGroup * groupLength;
    itemLength = groupLength / (alphaItem * (nItem - 1) + nItem);
    itemGapLength = alphaItem * itemLength;
    xTicks = zeros(1, nItem * nGroup);
    xTickLabels = cell(1, nItem * nGroup);
    info.ItemXstart = zeros(nItem, nGroup);
    info.ItemXend = zeros(nItem, nGroup);
    info.GroupXstart = zeros(1, nGroup);
    info.GroupXend = zeros(1, nGroup);
    info.GroupTextHandles = cell(1, nGroup);
    for iGroup = 1:nGroup
        if(nItem == 1 && nStack == 1); color = colors(iGroup, :); end
        groupText = p.Results.GroupLabels{iGroup};
        xGroupStart = xStart + (groupLength + groupGapLength) * (iGroup - 1);
        xGroupMid = xGroupStart + groupLength * 0.5;
        info.GroupXstart(iGroup) = xGroupStart;
        info.GroupXend(iGroup) = xGroupStart + groupLength;
        [~, groupTextHeight] = measureText(groupText, optGroupTextMeasurement);
        yGroup = 1 - (height - (ymax - ymin)) / height + ...
            + groupTextHeight * p.Results.GroupTextVgap * 0.5 ...
            + maxItemTextHeight;
        if(p.Results.GroupTextDynamic)
            yGroup = yGroup - (ymax - max(max(X(:, :, iGroup)))) / height;
        end
        [textpos] = norm2data([xGroupMid, yGroup], limitsUI);
        info.GroupTextHandles{iGroup} = ...
            text(textpos(1), textpos(2), groupText, optGroupText);
        for iItem = 1:nItem
            if(nStack == 1 && nItem ~= 1); color = colors(iItem, :); end
            xItemStart = xGroupStart + (itemLength + itemGapLength) * (iItem - 1);
            xItemMid = xItemStart + itemLength * 0.5;
            if(p.Results.ItemTextEnabled)
                itemText = ItemLabels{iGroup, iItem};
                [~, itemTextHeight] = measureText(itemText, optItemTextMeasurement);
                yItem = 1 - (height - (ymax - ymin)) / height + itemTextHeight * p.Results.ItemTextVgap * 0.5; 
                if(p.Results.ItemTextDynamic)
                    yItem = yItem - (ymax - max(max(X(:, iItem, iGroup)))) / height;
                end
                [textpos] = norm2data([xItemMid, yItem], limitsUI);
                text(textpos(1), textpos(2), itemText, optItemText);
            end
            tickIndex = sub2ind([nItem, nGroup], iItem, iGroup);
            xTicks(tickIndex) = xItemStart + itemLength * 0.5;
            xTickLabels{tickIndex} = ItemLabels{iGroup, iItem};
%             xItemEnd = xItemStart + itemLength;
            values = X(:, iItem, iGroup);
            [valuesSorted, si] = sort(values, 'ascend');
            if(nStack ~= 1 && valuesSorted(1) < 0)
                error('Negative stacked bars are not allowed.');
            end
            yPrev = ybarmin;
            
            info.ItemXstart(iItem, iGroup) = xItemStart;
            info.ItemXend(iItem, iGroup) = xItemStart + itemLength;
            for iStack = 1:nStack
                if(valuesSorted(iStack) >= 0)
                    yEnd = valuesSorted(iStack);
                else
                    yEnd = yPrev;
                    yPrev = valuesSorted(iStack);
                end
                if(nStack ~=1); color = colors(si(iStack), :); end
%                 valuesSorted(1)
%                 yPrev = 0;
%                 yVal = y
                recpos = [xItemStart, yPrev, itemLength, yEnd - yPrev];
                rectangle('Position', recpos, 'FaceColor', color, 'EdgeColor', [0 0 0]);
                yPrev = yEnd;
            end
        end
    end
    if(LegendEnabled)
        legendInnerXmin = legendXmin + legendItemWidth * p.Results.LegendHgap * 0.5;
        legendInnerYmin = legendYmin + legendItemHeight * p.Results.LegendVgap * 0.5;
        legendInnerYmax = legendInnerYmin + legendInnerHeight;
        LegendItemBoxXmin  = legendInnerXmin + legendItemBoxWidth * p.Results.LegendItemHgap * 0.5;
        LegendItemBoxXmax = legendInnerXmin + legendItemBoxWidth * (1 + p.Results.LegendItemHgap);
        LegendItemTextXmin = LegendItemBoxXmax + legendItemTextWidth * p.Results.LegendItemHgap * 0.5;
%         xDrawableLength = xDrawableLength - legendWidth;
        recpos = [legendInnerXmin, legendInnerYmin, legendInnerWidth, legendInnerHeight];
        recpos = norm2data(recpos, limitsUI);
        rectangle('Position', recpos, 'FaceColor', [1 1 1], 'EdgeColor', [0 0 0]);
        optLegend.Units = 'data';
%         [~, stackOrderingDescending] = sort(X(:, 1, 1), 'descend');
%         [~, stackOrderingAscending] = sort(X(:, 1, 1), 'ascend');
        if(nStack ~= 1)
            for iStack = 1:nStack
                switch(lower(LegendOrdering))
                    case 'fifo'
                        stackIndex = iStack;
                    case 'filo'
                        stackIndex = nStack - iStack + 1;
                    case 'lifo'
                        stackIndex = nStack - iStack + 1;
                    case 'lilo'
                        stackIndex = iStack;
                    case 'descend'
                        stackOrderingDescending = flip(stackOrderingAscending);
                        stackIndex = stackOrderingDescending(iStack);
                    case 'ascend'
                        stackIndex = stackOrderingAscending(iStack);
                    otherwise
                        error('Invalid legend ordering.');
                end
                legendItemYmin = legendInnerYmax - (iStack - p.Results.LegendItemVgap * 0.5) * legendItemHeight;
                if(LegendMixedColoring)
    %                 stackIndex = stackOrdering(iStack);
                    nBoxs = nStack - iStack + 1;
    %                 nBoxs = iStack;
                    boxYmin = legendItemYmin;
                    boxHeight = legendItemBoxHeight / nBoxs;
                    for iBox = 1:nBoxs
                        boxIndex = stackOrderingAscending(iBox);
                        recpos = [LegendItemBoxXmin, boxYmin, legendItemBoxWidth, boxHeight];
                        recpos = norm2data(recpos, limitsUI);
                        rectangle('Position', recpos, 'FaceColor', colors(boxIndex, :), 'EdgeColor', [0 0 0]);
                        boxYmin = boxYmin + legendItemBoxHeight / nBoxs;
                    end
                else
    %                 stackIndex = iStack;
                    recpos = [LegendItemBoxXmin, legendItemYmin, legendItemBoxWidth, legendItemBoxHeight];
                    recpos = norm2data(recpos, limitsUI);
                    rectangle('Position', recpos, 'FaceColor', colors(stackIndex, :), 'EdgeColor', [0 0 0]);
                end
                legendItemYmid = legendInnerYmax - (iStack - 0.5) * legendItemHeight;
                [textpos] = norm2data([LegendItemTextXmin, legendItemYmid], limitsUI);
                text(textpos(1), textpos(2), p.Results.StackLabels{stackIndex}, optLegend);
            end
        else
            for iLegendElement = 1:nLegendElement
                switch(lower(LegendOrdering))
                    case 'fifo'
                        elementIndex = iLegendElement;
                    case 'filo'
                        elementIndex = nLegendElement - iLegendElement + 1;
                    case 'lifo'
                        elementIndex = nLegendElement - iLegendElement + 1;
                    case 'lilo'
                        elementIndex = iLegendElement;
                    otherwise
                        error('Invalid legend ordering.');
                end
                legendItemYmin = legendInnerYmax - (iLegendElement - p.Results.LegendItemVgap * 0.5) * legendItemHeight;
    %                 stackIndex = iStack;
                recpos = [LegendItemBoxXmin, legendItemYmin, legendItemBoxWidth, legendItemBoxHeight];
                recpos = norm2data(recpos, limitsUI);
                rectangle('Position', recpos, 'FaceColor', colors(elementIndex, :), 'EdgeColor', [0 0 0]);
                legendItemYmid = legendInnerYmax - (iLegendElement - 0.5) * legendItemHeight;
                [textpos] = norm2data([LegendItemTextXmin, legendItemYmid], limitsUI);
                text(textpos(1), textpos(2), LegendLabels{elementIndex}, optLegend);
            end
        end
    end
    if(isnan(p.Results.AxisLineWidth))
        AxisLineWidth = get(gca, 'LineWidth');
    else
        AxisLineWidth = p.Results.AxisLineWidth;
    end
    
    if(p.Results.AxisLineY)
        line([0, 0], [YaxisLimits(1) * 1.0001, YaxisLimits(2) * 0.9999], ...
            'Color', [0 0 0], 'LineWidth', AxisLineWidth);
    end
    if(p.Results.AxisLineX)
        line([0, 1], [ybarmin, ybarmin], 'Color', [0 0 0], 'LineWidth', AxisLineWidth);
    end
    if(p.Results.Grid)
       grid(); 
    end
    set(gca, 'XTick', xTicks); 
    if(p.Results.XTickLabels)
        set(gca, 'XTickLabels', xTickLabels); 
    else
        set(gca, 'XTickLabels', []);
    end
    xtickangle(p.Results.XTickAngle);
    if(~initiallyHolded)
       hold('off');
    end
end

function[recpos] = norm2data(recpos, dataBox)
    recpos(1) = recpos(1) * dataBox(3) + dataBox(1);
    recpos(2) = recpos(2) * dataBox(4) + dataBox(2);
    if(length(recpos) >= 4)
        recpos(3) = recpos(3) * dataBox(3);
        recpos(4) = recpos(4) * dataBox(4);
    end
end

function[x, y] = data2norm(x, y, dataBox)
    x = (x - dataBox(1)) / dataBox(3);
    y = (y - dataBox(2)) / dataBox(4);
end

function[width, height] = measureText(txt, opt)
%     if(isfield(opt, 'Rotate')); opt = rmfield(opt,  'Rotate'); end
    hTest = text(1, 1, txt, opt);
    textExt = get(hTest, 'Extent');
    delete(hTest);
    height = textExt(4);    %Height
    width = textExt(3);     %Width
end

function[h] = drawText(x, y, txt, opt)
    try
        opt.Rotate;
        Rotate = opt.Rotate;
        opt = rmfield(opt,  'Rotate');
    catch
        Rotate = false;
    end
    h = text(x, y, txt, opt);
    if(Rotate)
        %set(h,'Rotation',90);
    end
end







