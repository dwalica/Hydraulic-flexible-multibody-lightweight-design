clear; clc; close all;

% 1) Select one data file (MAT, CSV or TXT)
[fn, fp] = uigetfile({'*.mat;*.txt;*.csv','Data Files (*.mat, *.txt, *.csv)'}, ...
                     'Select one data file', 'MultiSelect','off');
if isequal(fn,0), return; end
fpath = fullfile(fp, fn);

% 2) Load data (time in col 1, sigma [MPa] in col 2)
[t, sigma] = local_load_time_and_second_col(fpath);

% 3) Plot
figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(gcf, 'PaperUnits','centimeters', ...
         'PaperPosition',[0 0 10 8], ...
         'Renderer','painters');
hold on;

plot(t, sigma, 'LineWidth',1.5, 'Color',[0 0.447 0.741]);

xlabel('Time (s)', 'Interpreter','latex', 'FontSize',24);
ylabel('$\sigma$ (MPa)', 'Interpreter','latex', 'FontSize',24);  % Sigma symbol here

ax = gca;
set(ax, 'LineWidth',1.5, 'FontSize',15, 'Box','on');

% ===== X axis =====
xStep = 2;
xMin = min(t);
xMax = max(t);
if 0 < xMin && 0 >= xMin - xStep, xMin = 0; end
if 0 > xMax && 0 <= xMax + xStep, xMax = 0; end
xlim([xMin, xMax]);
xFirst = floor(xMin / xStep) * xStep;
xLast  = ceil(xMax  / xStep) * xStep;
xt = sort(unique([xFirst:xStep:xLast 0]));
set(ax, 'XTick', xt, ...
         'XTickLabel', arrayfun(@(x) sprintf('$%.0f$', x), xt, 'UniformOutput', false));

% ===== Y axis (auto scaling) =====
dataRange = max(sigma) - min(sigma);
if dataRange <= 0
    dataRange = 1;
end

% Add small margin
yMin = min(sigma) - 0.05 * dataRange;
yMax = max(sigma) + 0.05 * dataRange;

% Round limits nicely
roundStep = 10;
if dataRange > 200
    roundStep = 50;
elseif dataRange > 100
    roundStep = 20;
end
yMin = floor(yMin/roundStep)*roundStep;
yMax = ceil(yMax/roundStep)*roundStep;
ylim([yMin, yMax]);

% Y ticks
nTicks = 6;
yStep = round((yMax - yMin)/nTicks / roundStep) * roundStep;
if yStep == 0, yStep = roundStep; end
yt = yMin:yStep:yMax;
set(ax, 'YTick', yt, ...
         'YTickLabel', arrayfun(@(y) sprintf('$%g$', y), yt, 'UniformOutput', false));

% ===== Minor ticks and grid =====
if numel(xt) >= 2
    dx = xt(2) - xt(1);
    ax.XAxis.MinorTickValues = (xt(1)+dx/2):dx:(xt(end)-dx/2);
end
if numel(yt) >= 2
    dy = yt(2) - yt(1);
    ax.YAxis.MinorTickValues = (yt(1)+dy/2):dy:(yt(end)-dy/2);
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

print -depsc2 Sigma_AutoScaled.eps


% ---------------- Local loader ----------------
function [t, c2] = local_load_time_and_second_col(fpath)
    [~,~,ext] = fileparts(fpath);
    switch lower(ext)
        case {'.csv','.txt'}
            data = readmatrix(fpath);
            if size(data,2) < 2
                error('File must have at least two columns: time and stress.');
            end
            t = data(:,1);
            c2 = data(:,2);
        case '.mat'
            S = load(fpath);
            M = [];
            fn = fieldnames(S);
            for i = 1:numel(fn)
                v = S.(fn{i});
                if isnumeric(v) && ismatrix(v) && size(v,2) >= 2
                    M = v;
                    break;
                end
            end
            if isempty(M)
                error('MAT file does not contain a numeric matrix with >=2 columns.');
            end
            t = M(:,1);
            c2 = M(:,2);
        otherwise
            error('Unsupported file type: %s', ext);
    end
    t = t(:);
    c2 = c2(:);
end
