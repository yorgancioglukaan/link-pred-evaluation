function [] = gbarfigure( M, S, itemLabels, groupLabels, varargin)
    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'Ylimits', [], @isnumeric);
    addParameter(p, 'LegendFontSize', 15, @isnumeric);
    addParameter(p, 'GroupTextVshift', 0, @isnumeric);
    addParameter(p, 'GroupTextVgap', 0, @isnumeric);
    addParameter(p, 'SoftYMax', true, @islogical);
    addParameter(p, 'LegendLocation', 'northeast', @ischar);
    addParameter(p, 'MaximizeFigure', true, @islogical);
    addParameter(p, 'ClearFigure', true, @islogical);
    parse(p, varargin{:});
    param = p.Results;
    
%     defaultColors = [0 0 1; 1 0 0];
%     defaultColors = [0 0.447 0.741; 0.85 0.325 0.098; ...
%         0.929 0.694 0.125; 0.466 0.674 0.188; 0.301 0.745 0.933];
    defaultColors = [0 0.447 0.741; 0.85 0.325 0.098; ...
        0.929 0.694 0.125; 0.466 0.674 0.188; 0.301 0.745 0.933; ...
        0.494 0.184 0.556; 0.635 0.078 0.184];
    
    


    nItem = size(M, 1);
    nGroup = size(M, 2);
    
    clr = distinguishable_colors(nItem - size(defaultColors, 1), [defaultColors; 0 0 0; 1 1 1], @(x) colorspace('RGB->HSV',x));
    defaultColors = [defaultColors; clr];
    
    vals = reshape(M, 1, [], nGroup);
    y = vals(:)';
    err = S(:)';
    yupper = y + err;
    ylower = y - err;

    [~, mi] = max(yupper);
    ylimmax = yupper(mi) + 2*err(mi)*0.02;
    [~, mi] = min(ylower);
    ylimmin = ylower(mi);
    yrange = ylimmax - min(ylimmin, 0);
    ylimmax = ylimmax + yrange * 0.35;
    
    if(~isempty(param.Ylimits))
       ylimmin = min(ylimmin, param.Ylimits(1));
       ylimmax = max(ylimmax, param.Ylimits(2));
    end  
    
    gbarplotOpts = struct();
    gbarplotOpts.AxisOpts.FontSize = 16;
    gbarplotOpts.GroupLabels = groupLabels;
    gbarplotOpts.ItemLabels = itemLabels;
    gbarplotOpts.Legend = true;
    gbarplotOpts.XTickLabels = false;
    gbarplotOpts.Ylims = [ylimmin ylimmax];
    gbarplotOpts.GroupTextFontSize = 15;
    gbarplotOpts.LegendFontSize = param.LegendFontSize;
    gbarplotOpts.GroupTextVgap = param.GroupTextVgap;
    gbarplotOpts.AxisLineY = false;
    gbarplotOpts.LegendLocation = param.LegendLocation;
    
    if(nItem <= size(defaultColors, 1))
        gbarplotOpts.Colors = defaultColors;
    end
    
%     figure(2);
    if(param.ClearFigure)
        clf();
    end
    if(param.MaximizeFigure)
        set(gcf, 'Position', get(0, 'Screensize'));
    end
    hold('on');
    plot([0], [ylimmin]);
%     if(param.ManualYMax)
%         plot([0], param.Ylimits(2));
%     end
    if(param.SoftYMax)
        plot([0], [ylimmax]);
    end
    info = gbarplot(vals, gbarplotOpts);
    x = 0.5 * (info.ItemXstart(:) + info.ItemXend(:))';

    for iGroup = 1:nGroup
        ydif = -min(min(M(:, iGroup)), 0);
        yupper = max(max(M(:, iGroup) + S(:, iGroup), 0));
        ylower = max(max(M(:, iGroup),  0));
        ydif2 = yupper - ylower;
    %     ydif = 0;
        info.GroupTextHandles{iGroup}.Position(2) = ...
            info.GroupTextHandles{iGroup}.Position(2) + ydif + ydif2 + param.GroupTextVshift;
    end

    errorbar(x, y, err, '.', ...
        'LineWidth', 2, 'Color', [0 0 0]);
    hold('off');

    set(gcf, 'Color', [1 1 1]);
end

