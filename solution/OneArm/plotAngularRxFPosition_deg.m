clear; clc; close all;

% 1) Select one data file MAT CSV or TXT
[fn, fp] = uigetfile({'*.mat;*.txt;*.csv','Data Files (*.mat, *.txt, *.csv)'}, ...
                     'Select one data file', 'MultiSelect','off');
if isequal(fn,0), return; end
fpath = fullfile(fp, fn);

% 2) Load data
[t, A1, A2] = local_load_time_and_two_cols(fpath);

% 3) Figure
figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(gcf, 'PaperUnits','centimeters', 'PaperPosition',[0 0 10 8], 'Renderer','painters');

% Main axes
ax = axes('Position',[0.12 0.12 0.80 0.80]); hold(ax,'on');

% Colors
colors = flipud(lines(2));
plot(ax, t, A1, 'LineWidth',1.5, 'Color', colors(1,:));
plot(ax, t, A2, 'LineWidth',1.5, 'Color', colors(2,:));

% Labels and styling
xlabel(ax,'Time (s)', 'Interpreter','latex', 'FontSize',12);
ylabel(ax,'Angular position ($^\circ$)', 'Interpreter','latex', 'FontSize',12);
set(ax, 'LineWidth',1.5, 'FontSize',10, 'Box','on');

% X ticks each 2 seconds
xStep = 2;
xMin = min(t);
xMax = max(t);
if 0 < xMin && 0 >= xMin - xStep, xMin = 0; end
if 0 > xMax && 0 <= xMax + xStep, xMax = 0; end
xlim(ax, [xMin, xMax]);
xFirst = floor(xMin / xStep) * xStep;
xLast  = ceil (xMax  / xStep) * xStep;
xt = sort(unique([xFirst:xStep:xLast 0]));
set(ax, 'XTick', xt, 'XTickLabel', arrayfun(@(x) sprintf('$%.0f$', x), xt, 'UniformOutput', false));

% Fixed Y limits 0–50
ylim(ax, [0, 50]);
yStep = 10; yt = 0:yStep:50;
set(ax, 'YTick', yt, 'YTickLabel', arrayfun(@(y) sprintf('$%d$', y), yt, 'UniformOutput', false));

% Minor ticks and grid
if numel(xt) >= 2
    dx = xt(2) - xt(1);
    ax.XAxis.MinorTickValues = (xt(1)+dx/2):dx:(xt(end)-dx/2);
end
ax.YAxis.MinorTickValues = (yt(1)+yStep/2):yStep:(yt(end)-yStep/2);
ax.XMinorTick = 'on'; ax.YMinorTick = 'on';
ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on'; grid(ax,'on');
ax.GridAlpha = 0.1; ax.MinorGridLineStyle = ':'; ax.MinorGridAlpha = 0.1;

%% ===== Inset zoom (same time window, manually defined Y range 46–47) =====
t0 = 5.8;
t1 = 6.8;
idx = (t >= t0) & (t <= t1);

% manually set Y zoom range
yMinZ = 46;
yMaxZ = 47;

% red rectangle on main axes
rectangle(ax, 'Position',[t0, yMinZ, (t1 - t0), (yMaxZ - yMinZ)], ...
    'EdgeColor',[1 0 0], 'LineStyle',':', 'LineWidth',1.2);

% inset axes (same position)
axInset = axes('Position',[0.68 0.68 0.20 0.2]); hold(axInset,'on');
set(axInset, 'Color','white', ...
             'XColor',[1 0 0], 'YColor',[1 0 0], ...
             'LineWidth',1.2, 'Box','on');

% plot zoomed data
plot(axInset, t(idx), A1(idx), 'LineWidth',1.2, 'Color', colors(1,:));
plot(axInset, t(idx), A2(idx), 'LineWidth',1.2, 'Color', colors(2,:));
xlim(axInset, [t0 t1]);
ylim(axInset, [yMinZ yMaxZ]);

% inset ticks (few on x)
nTicksInset = 3;
xTicksInset = linspace(t0, t1, nTicksInset);
set(axInset, 'XTick', xTicksInset, 'XMinorTick','off');
set(axInset, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), xTicksInset, 'UniformOutput', false));

set(axInset, 'FontSize',10);
axInset.YMinorTick = 'on';
grid(axInset,'on'); axInset.GridAlpha = 0.10; axInset.MinorGridAlpha = 0.10;
xlabel(axInset,' ','Interpreter','latex','FontSize',6);
ylabel(axInset,' ','Interpreter','latex','FontSize',6);

hold off;
print -depsc2 AngularRxFPositionComparison.eps

% ---------------- Local loader ----------------
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
                error('MAT file does not contain a numeric matrix with >=3 columns.');
            end
            t = M(:,1); c2 = M(:,2); c3 = M(:,3);
        otherwise
            error('Unsupported file type: %s', ext);
    end
    t = t(:); c2 = c2(:); c3 = c3(:);
end
