clear; clc; close all;

% 1) Select one data file MAT CSV or TXT
[fn, fp] = uigetfile({'*.mat;*.txt;*.csv','Data Files (*.mat, *.txt, *.csv)'}, ...
                     'Select one data file', 'MultiSelect','off');
if isequal(fn,0), return; end
fpath = fullfile(fp, fn);

% 2) Load data
[t, W1, W2] = local_load_time_and_two_cols(fpath);   % expects [Time, col2, col3]

% 3) Publication style figure
figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(gcf, 'PaperUnits','centimeters', 'PaperPosition',[0 0 10 8], 'Renderer','painters');
hold on;

% Colors
colors = flipud(lines(2));
plot(t, W1, 'LineWidth',1.5, 'Color', colors(1,:));
plot(t, W2, 'LineWidth',1.5, 'Color', colors(2,:));

% Axes and labels
ax = gca;
xlabel('Time (s)', 'Interpreter','latex','FontSize',24);
ylabel('Angular velocity ($^\circ$/s)', 'Interpreter','latex','FontSize',24);
set(ax, 'LineWidth',1.5, 'FontSize',10, 'Box','on');

% X limits and ticks every 2 s with zero enforced
xMin = min(t);
xMax = max(t);
xStep = 2;
xMinR = floor(xMin / xStep) * xStep;
xMaxR = ceil (xMax / xStep) * xStep;
if xMinR > 0, xMinR = 0; end
if xMaxR < 0, xMaxR = 0; end
xlim([xMinR, xMaxR]);

xt = round(xMinR:xStep:xMaxR, 2);
if ~ismember(0, xt), xt = sort([xt 0]); end
set(ax, 'XTick', xt, 'XTickLabel', arrayfun(@(x) sprintf('$%.0f$', x), xt, 'UniformOutput', false));

% Y limits 1 2 5 rule with margin
yMin = min([W1; W2]);
yMax = max([W1; W2]);
yRange = max(yMax - yMin, eps);
yPad = 0.08 * yRange;
yLowP  = yMin - yPad;
yHighP = yMax + yPad;

targetTicks = 7;
rawStep = (yHighP - yLowP) / targetTicks;
yStep = local_nice_step(rawStep);

yLow  = floor(yLowP  / yStep) * yStep;
yHigh = ceil (yHighP / yStep) * yStep;
ylim([yLow, yHigh]);

yt = yLow:yStep:yHigh;
set(ax, 'YTick', yt, 'YTickLabel', arrayfun(@(y) sprintf('$%g$', y), yt, 'UniformOutput', false));

% ===== Legend now in bottom-left corner =====
legend({'Default','Optimised'}, ...
       'FontName','Times New Roman', ...
       'FontSize',10, ...
       'Location','southwest', ...
       'Interpreter','latex', ...
       'Box','on');

% Minor ticks and grid
if numel(xt) >= 2
    dx = xt(2) - xt(1);
    ax.XAxis.MinorTickValues = (xt(1)+dx/2):dx:(xt(end)-dx/2);
end
if numel(yt) >= 2
    dy = yt(2) - yt(1);
    ax.YAxis.MinorTickValues = (yt(1)+dy/2):dy:(yt(end)-dy/2);
end
ax.XMinorTick = 'on'; ax.YMinorTick = 'on';
ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on'; grid on;
ax.GridAlpha = 0.1; ax.MinorGridLineStyle = ':'; ax.MinorGridAlpha = 0.1;

%% Inset zoom now in top-right corner (opaque white background)
t0 = 5.9;      % start time of zoom window
t1 = 6.8;      % end time of zoom window
idx = (t >= t0) & (t <= t1);

if any(idx)
    yMinZ = min([W1(idx); W2(idx)]);
    yMaxZ = max([W1(idx); W2(idx)]);
else
    yMinZ = yLow; yMaxZ = yHigh;
end
padZ = 0.06 * max(yMaxZ - yMinZ, eps);
yMinZ = yMinZ - padZ;
yMaxZ = yMaxZ + padZ;

% red rectangle on main axes
rectangle(ax, 'Position',[t0, yMinZ, (t1 - t0), (yMaxZ - yMinZ)], ...
    'EdgeColor',[1 0 0], 'LineStyle',':', 'LineWidth',1.2);

% inset axes (top-right corner)
axInset = axes('Position',[0.605 0.65 0.28 0.25]); hold(axInset,'on');

% Opaque background with red frame
set(axInset, 'Color','white', ...         % <== solid white background
             'XColor',[1 0 0], ...
             'YColor',[1 0 0], ...
             'LineWidth',1.2, ...
             'Box','on');

% plot data inside inset
plot(axInset, t(idx), W1(idx), 'LineWidth',1.2, 'Color', colors(1,:));
plot(axInset, t(idx), W2(idx), 'LineWidth',1.2, 'Color', colors(2,:));
xlim(axInset, [t0 t1]); ylim(axInset, [yMinZ yMaxZ]);

set(axInset, 'FontSize',10, 'TickDir','out');
axInset.XMinorTick = 'on'; axInset.YMinorTick = 'on';
grid(axInset,'on'); axInset.GridAlpha = 0.10; axInset.MinorGridAlpha = 0.10;
xlabel(axInset,' ','Interpreter','latex','FontSize',6);
ylabel(axInset,' ','Interpreter','latex','FontSize',6);

hold off;
print -depsc2 AngularVelocityComparison.eps

% ------- local loader for [Time, col2, col3] -------
function [t, c2, c3] = local_load_time_and_two_cols(fpath)
    [~,~,ext] = fileparts(fpath);
    switch lower(ext)
        case {'.csv','.txt'}
            T = readtable(fpath);
            if any(strcmp(T.Properties.VariableNames,'Time'))
                t = T.Time;
            else
                t = T{:,1};
            end
            if size(T,2) < 3
                error('File "%s" has fewer than 3 columns.', fpath);
            end
            c2 = T{:,2};
            c3 = T{:,3};
        case '.mat'
            S = load(fpath);
            M = [];
            fn = fieldnames(S);
            for i = 1:numel(fn)
                v = S.(fn{i});
                if isnumeric(v) && ismatrix(v) && size(v,2) >= 3
                    M = v; break;
                end
            end
            if isempty(M)
                error('MAT file does not contain a numeric matrix with at least three columns.');
            end
            t  = M(:,1); c2 = M(:,2); c3 = M(:,3);
        otherwise
            error('Unsupported file type: %s', ext);
    end
    t = t(:); c2 = c2(:); c3 = c3(:);
end

% ------- local helper 1 2 5 step rounding -------
function s = local_nice_step(x)
    if x <= 0 || ~isfinite(x)
        s = 1; return;
    end
    p = floor(log10(x));
    base = 10^p;
    m = x / base;
    if m <= 1
        s = 1 * base;
    elseif m <= 2
        s = 2 * base;
    elseif m <= 5
        s = 5 * base;
    else
        s = 10 * base;
    end
end
