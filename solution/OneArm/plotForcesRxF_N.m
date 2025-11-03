clear; clc; close all;

% 1) Select one data file MAT CSV or TXT
[fn, fp] = uigetfile({'*.mat;*.txt;*.csv','Data Files (*.mat, *.txt, *.csv)'}, ...
                     'Select one data file', 'MultiSelect','off');
if isequal(fn,0)
    disp('User cancelled file selection.');
    return;
end
fpath = fullfile(fp, fn);

% 2) Load data supports MAT TXT CSV
[t, F1, F2] = local_load_time_and_two_cols(fpath);

% Remove first sample
t(1)  = [];
F1(1) = [];
F2(1) = [];

% 3) Publication quality figure
figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(gcf, 'PaperUnits','centimeters', ...
         'PaperPosition',[0 0 10 8], ...
         'Renderer','painters');
hold on;

% --- Colors (Rigid = green, Flexible = blue) ---
colorRigid = [0 0.6 0];      % green
colorFlexible = [0 0.45 0.74]; % blue (same as MATLAB lines default)
plot(t, F1, 'LineWidth',1.5, 'Color', colorRigid);
plot(t, F2, 'LineWidth',1.5, 'Color', colorFlexible);

% 4) Axes labels limits
ax = gca;
xlabel('Time (s)',  'Interpreter','latex', 'FontSize',24);
ylabel('Force (N)', 'Interpreter','latex', 'FontSize',24);
set(ax, 'LineWidth',1.5, 'FontSize',10, 'Box','on');

% === Legend in upper-left corner ===
legend({'Rigid','Flexible'}, ...
       'FontName','Times New Roman', ...
       'FontSize',10, ...
       'Location','northwest', ...
       'Interpreter','latex', ...
       'Box','on');

% X ticks every 2 s always include zero
xStep = 2;
xMin  = min(t);
xMax  = max(t);
xMinR = floor(xMin / xStep) * xStep;
xMaxR = ceil (xMax / xStep) * xStep;
if xMinR > 0, xMinR = 0; end
if xMaxR < 0, xMaxR = 0; end
xlim([xMinR, xMaxR]);

xt = round(xMinR:xStep:xMaxR, 3);
if ~ismember(0, xt), xt = sort([xt 0]); end
set(ax, 'XTick', xt, ...
         'XTickLabel', arrayfun(@(x) sprintf('$%.0f$', x), xt, 'UniformOutput', false));

% Y ticks step of 20000 shown with ×10^4 exponent
yMin = min([F1; F2]);
yMax = max([F1; F2]);
yRange = max(yMax - yMin, eps);
yPad = 0.08 * yRange;
yLowP  = yMin - yPad;
yHighP = yMax + yPad;

stepY = 20000;
yLow  = floor(yLowP  / stepY) * stepY;
yHigh = ceil (yHighP / stepY) * stepY;
ylim([yLow, yHigh]);

set(ax, 'YTick', yLow:stepY:yHigh);
ax.YAxis.Exponent = 4;

% 5) Minor ticks and grid
if numel(xt) >= 2
    dx = xt(2) - xt(1);
    ax.XAxis.MinorTickValues = (xt(1)+dx/2):dx:(xt(end)-dx/2);
end
ax.YAxis.MinorTickValues = (yLow + stepY/2):stepY:(yHigh - stepY/2);

ax.XMinorTick = 'on';
ax.YMinorTick = 'on';
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
grid on;

ax.GridAlpha = 0.1;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.1;

%% Smaller inset zoom starting near 5.9 s in left bottom corner
t0 = max(5.9, min(t));
win = 1;                 % narrow window for tighter zoom
t1 = min(t0 + win, max(t));
idx = (t >= t0) & (t <= t1);

% y range inside window with padding
if any(idx)
    yMinZ = min([F1(idx); F2(idx)]);
    yMaxZ = max([F1(idx); F2(idx)]);
else
    yMinZ = yLow; yMaxZ = yHigh;
end
padZ = 0.06 * max(yMaxZ - yMinZ, eps);
yMinZ = yMinZ - padZ;
yMaxZ = yMaxZ + padZ;

% red rectangle on main axes
rectangle(ax, 'Position',[t0, yMinZ, (t1 - t0), (yMaxZ - yMinZ)], ...
    'EdgeColor',[1 0 0], 'LineStyle',':', 'LineWidth',1.2);

% inset axes in left bottom corner made smaller
axInset = axes('Position',[0.19 0.20 0.20 0.23]); hold(axInset,'on');

% opaque white background and red frame
set(axInset, 'Color','white', ...
             'XColor',[1 0 0], 'YColor',[1 0 0], ...
             'LineWidth',1.2, ...
             'Box','on');

% plot zoomed data (same colors)
plot(axInset, t(idx), F1(idx), 'LineWidth',1.2, 'Color', colorRigid);
plot(axInset, t(idx), F2(idx), 'LineWidth',1.2, 'Color', colorFlexible);
xlim(axInset, [t0 t1]); ylim(axInset, [yMinZ yMaxZ]);

% inset ticks fewer on x
nTicksInset = 3;                                    
xTicksInset = linspace(t0, t1, nTicksInset);
set(axInset, 'XTick', xTicksInset, 'XMinorTick','off');   
set(axInset, 'XTickLabel', arrayfun(@(x) sprintf('%.1f', x), xTicksInset, 'UniformOutput', false));

% inset formatting
set(axInset, 'FontSize',10);
axInset.YMinorTick = 'on';
grid(axInset,'on'); axInset.GridAlpha = 0.10; axInset.MinorGridAlpha = 0.10;
xlabel(axInset,' ','Interpreter','latex','FontSize',6);
ylabel(axInset,' ','Interpreter','latex','FontSize',6);
axInset.YAxis.Exponent = 4;

hold off;

% Optional export
print -depsc2 ForceRxFComparison.eps

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
            t = M(:,1);
            c2 = M(:,2);
            c3 = M(:,3);
        otherwise
            error('Unsupported file type: %s', ext);
    end
    t = t(:); c2 = c2(:); c3 = c3(:);
end

% -------- local helper 1 2 5 step rounding --------
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
