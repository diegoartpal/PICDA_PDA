clear; clc; close all;

%% ================= USER SETTINGS =================
filename = "DC_kappa_eme2.txt";

% Enter [] if you want MATLAB to ask you in the command window
target_K = [];

% Example:
% target_K = 0.5;   % 50/50 coupler
% target_K = 0.1;   % 90/10 coupler
% target_K = 0.9;   % 10/90 coupler

%% ================= READ DATA FILE =================

lines = readlines(filename);

dataBlocks = {};
currentBlock = [];

for i = 1:length(lines)
    line = strtrim(lines(i));

    % Skip empty lines
    if line == ""
        if ~isempty(currentBlock)
            dataBlocks{end+1} = currentBlock;
            currentBlock = [];
        end
        continue;
    end

    % Try to read numeric line of the form: number, number
    nums = sscanf(line, '%f, %f');

    if length(nums) == 2
        currentBlock = [currentBlock; nums'];
    end
end

% Add final block if file does not end with empty line
if ~isempty(currentBlock)
    dataBlocks{end+1} = currentBlock;
end

if length(dataBlocks) < 2
    error("Could not find two data blocks. Check the file format.");
end

% First block: abs(S31)^2
% Second block: abs(S41)^2
data31 = dataBlocks{1};
data41 = dataBlocks{2};

L31 = data31(:,1);      % meters
P31 = data31(:,2);      % abs(S31)^2

L41 = data41(:,1);      % meters
P41 = data41(:,2);      % abs(S41)^2

% Safety check
if length(L31) ~= length(L41) || max(abs(L31 - L41)) > 1e-15
    error("Length vectors of S31 and S41 do not match.");
end

L = L31;
L_um = L * 1e6;

%% ================= CALCULATE POWER COUPLING K =================

Ptot = P31 + P41;

K = P41 ./ Ptot;        % normalized power coupling coefficient

%% ================= PLOT DATA =================

figure;

plot(L_um, P31, 'o-', 'LineWidth', 1.5); hold on;
plot(L_um, P41, 's-', 'LineWidth', 1.5);
plot(L_um, K, '^-', 'LineWidth', 1.5);

grid on;
xlabel('Coupling length L (\mum)');
ylabel('Power / coupling coefficient');
title('Directional coupler length sweep');

legend('|S_{31}|^2', '|S_{41}|^2', 'K = |S_{41}|^2 / (|S_{31}|^2 + |S_{41}|^2)', ...
       'Location', 'best');

%% ================= ASK FOR TARGET COUPLING =================

if isempty(target_K)
    target_K = input('Enter target power coupling K, for example 0.5 for 50/50: ');
end

% Allow user to enter percentage, e.g. 50 instead of 0.5
if target_K > 1
    target_K = target_K / 100;
end

if target_K < min(K) || target_K > max(K)
    fprintf('\nTarget K = %.4f is outside the simulated range.\n', target_K);
    fprintf('Available K range: %.4f to %.4f\n', min(K), max(K));
    return;
end

%% ================= FIND CORRESPONDING LENGTH =================

% Find all places where K crosses target_K
crossing_lengths = [];

for i = 1:length(K)-1

    K1 = K(i);
    K2 = K(i+1);

    L1 = L_um(i);
    L2 = L_um(i+1);

    % Check if target_K lies between K1 and K2
    if (target_K - K1) * (target_K - K2) <= 0

        % Avoid duplicate if exactly equal
        if K1 == K2
            continue;
        end

        % Linear interpolation
        L_target = L1 + (target_K - K1) * (L2 - L1) / (K2 - K1);

        crossing_lengths = [crossing_lengths; L_target];
    end
end

% Remove nearly repeated crossings
crossing_lengths = unique(round(crossing_lengths, 6));

%% ================= PRINT RESULT =================

fprintf('\nTarget power coupling:\n');
fprintf('K = %.4f\n', target_K);

fprintf('\nCorresponding coupling length(s):\n');

for i = 1:length(crossing_lengths)
    fprintf('L = %.4f um\n', crossing_lengths(i));
end

%% ================= MARK RESULT ON PLOT =================

for i = 1:length(crossing_lengths)
    xline(crossing_lengths(i), '--', sprintf('L = %.2f um', crossing_lengths(i)), ...
          'LabelVerticalAlignment', 'bottom');
end

yline(target_K, '--', sprintf('K = %.2f', target_K));
