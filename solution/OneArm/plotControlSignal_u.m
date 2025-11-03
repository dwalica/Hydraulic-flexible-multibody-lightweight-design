clear; clc; close all;

% 1) Select one data file (MAT, CSV or TXT)
[fn, fp] = uigetfile({'*.mat;*.txt;*.csv','Data Files (*.mat, *.txt, *.csv)'}, ...
                     'Select one data file', 'MultiSelect','off');
if isequal(fn,0)
    disp('User cancelled file selection.');
    return;
end
fpath = fullfile(fp, fn);

% 2) Load data (supports MAT, TXT, CSV)
[t, U] = local_load_time_and_signal(fpath);   % expects [Time, u]

% 3) Publication-quality figure
figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(gcf, 'PaperUnits','centimeters', ...
         'PaperPosition',[0 0 10 8], ...
         'Renderer','painters');
hold on;

% --- Red line ---
plot(t, U, 'LineWidth',1.5, 'Color', [0.85 0.1 0.1]);

% 4) Axes, labels, limits
ax = gca;
xlabel('Time (s)', 'Interpreter','latex', 'FontSize',24);
ylabel('Control signal (V)', 'Interpreter','latex', 'FontSize',24);
set(ax, 'LineWidth',1.5, 'FontSize',10, 'Box','on');

% ===== X ticks: every 2 s, zero always included =====
xStep = 2;
xMin  = min(t);
xMax  = max(t);
xMinR = floor(xMin / xStep) * xStep;
xMaxR = ceil (xMax / xStep) * xStep;
if xMinR > 0, xMinR = 0; end
if xMaxR < 0, xMaxR = 0; end
xlim([xMinR, xMaxR]);

xt = round(xMinR:xStep:xMaxR, 2);
if ~ismember(0, xt), xt = sort([xt 0]); end
set(ax, 'XTick', xt, ...
         'XTickLabel', arrayfun(@(x) sprintf('$%.0f$', x), xt, 'UniformOutput', false));

% ===== Y limits adaptive for discrete control signals =====
uniqueVals = unique(round(U, 1));  % detect distinct discrete levels
if numel(uniqueVals) <= 5 && all(ismember(uniqueVals, [-10 0 10]))
    % Typical case: {-10, 0, +10}
    yt = uniqueVals(:)';
    yPad = 0.2 * (max(yt) - min(yt));
    ylim([min(yt)-yPad, max(yt)+yPad]);
else
    % fallback to continuous scaling
    yMin = min(U);
    yMax = max(U);
    yRange = max(yMax - yMin, eps);
    yLow  = yMin - 0.1 * yRange;
    yHigh = yMax + 0.1 * yRange;
    ylim([yLow, yHigh]);
    yStep = 2;
    yLowT = ceil(yLow / yStep) * yStep;
    yHighT = floor(yHigh / yStep) * yStep;
    yt = yLowT:yStep:yHighT;
    if isempty(yt)
        yt = yLow:yStep:yHigh;
    end
end

set(ax, 'YTick', yt, ...
         'YTickLabel', arrayfun(@(y) sprintf('$%.0f$', y), yt, 'UniformOutput', false));

% ===== Minor ticks and grid =====
if numel(xt) >= 2
    dx = xt(2) - xt(1);
    ax.XAxis.MinorTickValues = (xt(1)+dx/2):dx:(xt(end)-dx/2);
end
if numel(yt) >= 2
    dy = diff(yt);
    if all(dy > 0)
        dy = dy(1);
        ax.YAxis.MinorTickValues = (yt(1)+dy/2):dy:(yt(end)-dy/2);
    end
end

ax.XMinorTick = 'on';
ax.YMinorTick = 'on';
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
grid on;
ax.GridAlpha = 0.1;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.1;

hold off;

% Optional export
print -depsc2 ControlSignal.eps


% ------- local loader for [Time, u] -------
function [t, u] = local_load_time_and_signal(fpath)
    [~,~,ext] = fileparts(fpath);
    switch lower(ext)
        case {'.csv','.txt'}
            T = readtable(fpath);
            if any(strcmp(T.Properties.VariableNames,'Time'))
                t = T.Time;
            else
                t = T{:,1};
            end
            if size(T,2) < 2
                error('File "%s" has fewer than 2 columns.', fpath);
            end
            u = T{:,2};

        case '.mat'
            S = load(fpath);
            M = [];
            fn = fieldnames(S);
            for i = 1:numel(fn)
                v = S.(fn{i});
                if isnumeric(v) && ismatrix(v) && size(v,2) >= 2
                    M = v; break;
                end
            end
            if isempty(M)
                error('MAT file does not contain a numeric matrix with at least two columns.');
            end
            t = M(:,1);
            u = M(:,2);

        otherwise
            error('Unsupported file type: %s', ext);
    end
    t = t(:); u = u(:);
end
