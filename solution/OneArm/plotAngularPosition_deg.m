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
set(gcf, 'PaperUnits','centimeters', ...
         'PaperPosition',[0 0 10 8], ...
         'Renderer','painters');

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
xLast  = ceil(xMax  / xStep) * xStep;
xt = xFirst:xStep:xLast; xt = sort(unique([xt 0]));
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

%% ===== Inset zoom (opaque white background) =====
addZoom = true;
if addZoom
    % choose window to zoom
    t0 = 5.8;          % start time of zoom window
    t1 = 9.2;          % end time of zoom window
    idx = (t >= t0) & (t <= t1);

    % compute y range inside window based on data
    yMinZ = min([A1(idx); A2(idx)]);
    yMaxZ = max([A1(idx); A2(idx)]);
    pad   = 0.05 * max(yMaxZ - yMinZ, eps);
    yMinZ = yMinZ - pad;
    yMaxZ = yMaxZ + pad;

    % red rectangle on main axes
    rectangle(ax, 'Position',[t0, yMinZ, (t1 - t0), (yMaxZ - yMinZ)], ...
        'EdgeColor',[1 0 0], 'LineStyle',':', 'LineWidth',1.2);

    % inset axes (position in normalized figure units)
    axInset = axes('Position',[0.66 0.7 0.25 0.2]); hold(axInset,'on');

    % opaque white background with red frame
    set(axInset, 'Color','white', ...
                 'XColor',[1 0 0], 'YColor',[1 0 0], ...
                 'LineWidth',1.2, ...
                 'Box','on');

    % plot zoomed region
    plot(axInset, t(idx), A1(idx), 'LineWidth',1.2, 'Color', colors(1,:));
    plot(axInset, t(idx), A2(idx), 'LineWidth',1.2, 'Color', colors(2,:));
    xlim(axInset, [t0 t1]); ylim(axInset, [yMinZ yMaxZ]);

    % inset formatting
    set(axInset, 'FontSize',11);
    axInset.XMinorTick = 'on'; axInset.YMinorTick = 'on';
    grid(axInset,'on'); axInset.GridAlpha = 0.10; axInset.MinorGridAlpha = 0.10;
    xlabel(axInset,' ','Interpreter','latex','FontSize',6);
    ylabel(axInset,' ','Interpreter','latex','FontSize',6);
end

hold off;
print -depsc2 AngularPositionComparison.eps

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
