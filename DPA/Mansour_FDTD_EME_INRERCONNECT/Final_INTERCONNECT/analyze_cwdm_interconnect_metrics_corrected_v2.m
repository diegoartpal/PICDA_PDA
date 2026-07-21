%% ============================================================
% Analyze final CWDM INTERCONNECT spectrum
% Corrected definitions:
%   1) 1-dB bandwidth is measured from each channel peak, not from 0 dB.
%   2) Center crosstalk is measured at the channel center wavelength only:
%          XT_center = wrong_output_dB(lambda_i) - desired_output_dB(lambda_i)
%      This is the vertical difference from the desired channel to the
%      first/highest wrong curve at the same wavelength.
%   3) Worst crosstalk inside +/-6 nm is printed only as a diagnostic.
%   4) Ripple is treated as oscillatory ripple only, not normal passband
%      roll-off. The normal peak-to-edge variation is printed separately
%      as passband variation/droop.
%% ============================================================

clear; clc; close all;

%% ---------------- User settings ----------------
fname = 'interconnect_data.txt';

lambda_ch = [1271 1291 1311 1331];      % channel center wavelengths (nm)
ch_names  = {'1271 nm','1291 nm','1311 nm','1331 nm'};

% Leave empty for automatic output mapping, or set manually.
% Example from your current data: [4 2 3 1]
manual_out_for_channel = [];

pass_half_nm = 6;                        % target passband = lambda_i +/- 6 nm
T_floor = 1e-15;                         % avoids log10(0)

% Moving-average points used only for ripple detection.
% This should be odd. Increase slightly if the data is noisy.
ripple_smooth_points = 21;

%% ---------------- Read repeated wavelength,Y blocks ----------------
raw = fileread(fname);
lines = regexp(raw, '\r\n|\n|\r', 'split');

wl_cell = {};
T_cell  = {};
current_trace = 0;

for ii = 1:numel(lines)
    line = strtrim(lines{ii});

    if isempty(line)
        continue;
    end

    if ~isempty(strfind(line, 'wavelength'))
        current_trace = current_trace + 1;
        wl_cell{current_trace} = [];
        T_cell{current_trace}  = [];
    else
        nums = sscanf(line, '%f,%f');
        if numel(nums) == 2 && current_trace > 0
            wl_cell{current_trace}(end+1,1) = nums(1);
            T_cell{current_trace}(end+1,1)  = nums(2);
        end
    end
end

Nout = numel(wl_cell);
Nch  = numel(lambda_ch);

if Nout < Nch
    error('The file contains only %d traces, but %d channels are expected.', Nout, Nch);
end

% Sort each trace by increasing wavelength and remove repeated wavelength samples if any.
for oo = 1:Nout
    [wl_sorted, idx_sort] = sort(wl_cell{oo});
    T_sorted = T_cell{oo}(idx_sort);

    [wl_unique, idx_unique] = unique(wl_sorted, 'stable');
    T_unique = T_sorted(idx_unique);

    wl_cell{oo} = wl_unique;
    T_cell{oo}  = T_unique;
end

%% ---------------- Put all traces on one common wavelength grid ----------------
lambda_min = -inf;
lambda_max = inf;
for oo = 1:Nout
    lambda_min = max(lambda_min, min(wl_cell{oo}));
    lambda_max = min(lambda_max, max(wl_cell{oo}));
end

lambda = linspace(lambda_min, lambda_max, 5000).';
T_all = zeros(numel(lambda), Nout);

for oo = 1:Nout
    T_all(:,oo) = interp1(wl_cell{oo}, T_cell{oo}, lambda, 'linear', 'extrap');
end

T_all_dB = 10*log10(max(T_all, T_floor));

%% ---------------- Automatic output-channel mapping ----------------
% Tcenter_all(output, channel) = power of each output at each channel center.
Tcenter_all = zeros(Nout, Nch);

for oo = 1:Nout
    for ch = 1:Nch
        Tcenter_all(oo,ch) = interp1(wl_cell{oo}, T_cell{oo}, lambda_ch(ch), 'linear', 'extrap');
    end
end

if isempty(manual_out_for_channel)
    all_maps = perms(1:Nout);
    all_maps = all_maps(:,1:Nch);

    map_score = zeros(size(all_maps,1),1);
    for mm = 1:size(all_maps,1)
        idx = sub2ind(size(Tcenter_all), all_maps(mm,:), 1:Nch);
        map_score(mm) = sum(Tcenter_all(idx));
    end

    [~, best_map_idx] = max(map_score);
    out_for_channel = all_maps(best_map_idx,:);
else
    out_for_channel = manual_out_for_channel;
end

fprintf('\nAutomatic/manual output mapping used:\n');
for ch = 1:Nch
    fprintf('  Channel %s  -->  output trace %d\n', ch_names{ch}, out_for_channel(ch));
end

%% ---------------- Plot final spectrum: linear scale ----------------
figure('Color','w'); hold on; box on;
for ch = 1:Nch
    oo = out_for_channel(ch);
    plot(lambda, T_all(:,oo), 'LineWidth', 2);
end

for ch = 1:Nch
    xline(lambda_ch(ch), '--', ch_names{ch}, 'LabelVerticalAlignment','bottom');
end

xlabel('Wavelength (nm)');
ylabel('Power transmission');
title('Final CWDM output spectrum - linear scale');
grid on;
legend(ch_names, 'Location','best');
xlim([min(lambda_ch)-15, max(lambda_ch)+30]);
ylim([0, 1.05*max(T_all(:))]);
saveas(gcf, 'final_CWDM_linear_corrected.png');

%% ---------------- Plot final spectrum: dB scale ----------------
figure('Color','w'); hold on; box on;
for ch = 1:Nch
    oo = out_for_channel(ch);
    plot(lambda, T_all_dB(:,oo), 'LineWidth', 2);
end

for ch = 1:Nch
    xline(lambda_ch(ch), '--', ch_names{ch}, 'LabelVerticalAlignment','bottom');
end

ylabel('Power transmission (dB)');
xlabel('Wavelength (nm)');
title('Final CWDM output spectrum - dB scale');
grid on;
legend(ch_names, 'Location','best');
xlim([min(lambda_ch)-15, max(lambda_ch)+30]);
ylim([-50, 1]);
saveas(gcf, 'final_CWDM_dB_corrected.png');

%% ---------------- Metric extraction ----------------
Channel_nm = lambda_ch(:);
Output_trace = out_for_channel(:);

Peak_lambda_nm = zeros(Nch,1);
Peak_T = zeros(Nch,1);
Peak_dB = zeros(Nch,1);

Center_T = zeros(Nch,1);
Center_dB = zeros(Nch,1);
InsertionLoss_dB = zeros(Nch,1);

BW_1dB_nm = zeros(Nch,1);
BW_left_nm = zeros(Nch,1);
BW_right_nm = zeros(Nch,1);

PassbandVariation_dB = zeros(Nch,1);     % includes normal filter roll-off/droop
OscillatoryRipple_dB = zeros(Nch,1);     % excludes smooth roll-off as much as possible

CenterXT_dB = zeros(Nch,1);              % wrong - desired, should be <= -15 dB
CenterIsolation_dB = zeros(Nch,1);       % desired - wrong, should be >= +15 dB
WorstXT_pm6_dB = zeros(Nch,1);           % diagnostic only: worst inside +/-6 nm
WorstIsolation_pm6_dB = zeros(Nch,1);    % diagnostic only
WorstXT_lambda_nm = zeros(Nch,1);        % diagnostic only
WorstWrongOutput_center = zeros(Nch,1);

for ch = 1:Nch

    lambda0 = lambda_ch(ch);
    oo_des = out_for_channel(ch);

    wl_des = wl_cell{oo_des};
    T_des_trace = T_cell{oo_des};

    % ---- Use lobe boundaries halfway to the neighboring channels ----
    if ch == 1
        lobe_left = min(wl_des);
    else
        lobe_left = 0.5*(lambda_ch(ch-1) + lambda_ch(ch));
    end

    if ch == Nch
        lobe_right = max(wl_des);
    else
        lobe_right = 0.5*(lambda_ch(ch) + lambda_ch(ch+1));
    end

    idx_lobe = find(wl_des >= lobe_left & wl_des <= lobe_right);
    if isempty(idx_lobe)
        error('No wavelength samples found inside the channel lobe for channel %s.', ch_names{ch});
    end

    [Peak_T(ch), local_idx_peak] = max(T_des_trace(idx_lobe));
    idx_peak = idx_lobe(local_idx_peak);
    Peak_lambda_nm(ch) = wl_des(idx_peak);
    Peak_dB(ch) = 10*log10(max(Peak_T(ch), T_floor));

    % ---- Insertion loss at the specified channel center ----
    Center_T(ch) = interp1(wl_des, T_des_trace, lambda0, 'linear', 'extrap');
    Center_dB(ch) = 10*log10(max(Center_T(ch), T_floor));
    InsertionLoss_dB(ch) = -Center_dB(ch);

    % ---- 1-dB bandwidth from the channel peak, not from 0 dB ----
    T_1dB_threshold = Peak_T(ch) * 10^(-1/10);

    above = (T_des_trace >= T_1dB_threshold);
    in_lobe = false(size(T_des_trace));
    in_lobe(idx_lobe) = true;
    above = above & in_lobe;

    idx_left = idx_peak;
    while idx_left > 1 && above(idx_left-1)
        idx_left = idx_left - 1;
    end

    idx_right = idx_peak;
    while idx_right < numel(wl_des) && above(idx_right+1)
        idx_right = idx_right + 1;
    end

    % Left threshold crossing by linear interpolation.
    if idx_left == 1 || ~in_lobe(idx_left-1)
        lambda_left = wl_des(idx_left);
    else
        x1 = wl_des(idx_left-1); y1 = T_des_trace(idx_left-1);
        x2 = wl_des(idx_left);   y2 = T_des_trace(idx_left);
        lambda_left = x1 + (T_1dB_threshold-y1)*(x2-x1)/(y2-y1);
    end

    % Right threshold crossing by linear interpolation.
    if idx_right == numel(wl_des) || ~in_lobe(idx_right+1)
        lambda_right = wl_des(idx_right);
    else
        x1 = wl_des(idx_right);   y1 = T_des_trace(idx_right);
        x2 = wl_des(idx_right+1); y2 = T_des_trace(idx_right+1);
        lambda_right = x1 + (T_1dB_threshold-y1)*(x2-x1)/(y2-y1);
    end

    BW_left_nm(ch) = lambda_left;
    BW_right_nm(ch) = lambda_right;
    BW_1dB_nm(ch) = lambda_right - lambda_left;

    % ---- Passband variation/droop inside the 1-dB band ----
    idx_1dB = find(wl_des >= lambda_left & wl_des <= lambda_right);
    T_dB_1dB = 10*log10(max(T_des_trace(idx_1dB), T_floor));
    PassbandVariation_dB(ch) = max(T_dB_1dB) - min(T_dB_1dB);

    % ---- Oscillatory ripple only ----
    % This tries to avoid counting the normal smooth roll-off of the filter
    % as ripple. If there are no internal local maxima/minima, ripple is 0.
    y = T_dB_1dB(:);

    if numel(y) < 5
        OscillatoryRipple_dB(ch) = 0;
    else
        Nsmooth = ripple_smooth_points;
        if mod(Nsmooth,2) == 0
            Nsmooth = Nsmooth + 1;
        end
        Nsmooth = min(Nsmooth, 2*floor((numel(y)-1)/2)+1);

        if Nsmooth >= 3
            kernel = ones(Nsmooth,1)/Nsmooth;
            y_smooth = conv(y, kernel, 'same');
            margin = floor(Nsmooth/2);
            y_test = y_smooth(1+margin:end-margin);
        else
            y_test = y;
        end

        dy = diff(y_test);
        sgn = sign(dy);

        % Replace exact zero slopes by the previous nonzero sign.
        for ss = 2:numel(sgn)
            if sgn(ss) == 0
                sgn(ss) = sgn(ss-1);
            end
        end

        extrema_idx = find(diff(sgn) ~= 0) + 1;

        if numel(extrema_idx) >= 2
            OscillatoryRipple_dB(ch) = max(y_test(extrema_idx)) - min(y_test(extrema_idx));
        else
            OscillatoryRipple_dB(ch) = 0;
        end
    end

    % ---- Center crosstalk: vertical difference at lambda_i ----
    desired_center_dB = Center_dB(ch);

    wrong_center_T = zeros(Nout-1,1);
    wrong_center_out = zeros(Nout-1,1);
    kk = 0;
    for oo = 1:Nout
        if oo == oo_des
            continue;
        end
        kk = kk + 1;
        wrong_center_T(kk) = interp1(wl_cell{oo}, T_cell{oo}, lambda0, 'linear', 'extrap');
        wrong_center_out(kk) = oo;
    end

    [T_wrong_max_center, idx_wrong] = max(wrong_center_T);
    wrong_center_dB = 10*log10(max(T_wrong_max_center, T_floor));
    WorstWrongOutput_center(ch) = wrong_center_out(idx_wrong);

    CenterXT_dB(ch) = wrong_center_dB - desired_center_dB;        % negative crosstalk value
    CenterIsolation_dB(ch) = desired_center_dB - wrong_center_dB; % positive isolation value

    % ---- Diagnostic worst crosstalk inside lambda_i +/- 6 nm ----
    idx_pm6 = find(lambda >= lambda0-pass_half_nm & lambda <= lambda0+pass_half_nm);

    desired_pm6_dB = T_all_dB(idx_pm6, oo_des);
    wrong_pm6_dB_matrix = [];
    for oo = 1:Nout
        if oo ~= oo_des
            wrong_pm6_dB_matrix = [wrong_pm6_dB_matrix, T_all_dB(idx_pm6,oo)]; %#ok<AGROW>
        end
    end
    wrong_pm6_max_dB = max(wrong_pm6_dB_matrix, [], 2);

    xt_pm6_vs_lambda = wrong_pm6_max_dB - desired_pm6_dB;
    [WorstXT_pm6_dB(ch), idx_worst] = max(xt_pm6_vs_lambda);
    WorstIsolation_pm6_dB(ch) = -WorstXT_pm6_dB(ch);
    WorstXT_lambda_nm(ch) = lambda(idx_pm6(idx_worst));

end

%% ---------------- Print results ----------------
fprintf('\n============================================================\n');
fprintf('CORRECTED CWDM METRICS\n');
fprintf('============================================================\n');
fprintf('Definitions used:\n');
fprintf('  IL = -10log10(T_desired at channel center)\n');
fprintf('  1-dB BW = width where T >= peak(T)*10^(-1/10)\n');
fprintf('  Center XT = highest wrong curve at lambda_i minus desired curve at lambda_i\n');
fprintf('              target: Center XT <= -15 dB, or isolation >= 15 dB\n');
fprintf('  Worst XT inside +/-6 nm is diagnostic only and is stricter.\n');
fprintf('  Ripple = oscillatory ripple only; normal passband roll-off is reported separately.\n\n');

for ch = 1:Nch
    fprintf('Channel %s, output trace %d:\n', ch_names{ch}, Output_trace(ch));
    fprintf('  Peak wavelength              = %.3f nm\n', Peak_lambda_nm(ch));
    fprintf('  Insertion loss at center      = %.3f dB\n', InsertionLoss_dB(ch));
    fprintf('  1-dB bandwidth from peak      = %.3f nm  [%.3f, %.3f] nm\n', ...
        BW_1dB_nm(ch), BW_left_nm(ch), BW_right_nm(ch));
    fprintf('  Passband variation/droop      = %.3f dB\n', PassbandVariation_dB(ch));
    fprintf('  Oscillatory intra-band ripple = %.3f dB\n', OscillatoryRipple_dB(ch));
    fprintf('  Center XT                     = %.3f dB  (wrong output trace %d)\n', ...
        CenterXT_dB(ch), WorstWrongOutput_center(ch));
    fprintf('  Center isolation              = %.3f dB\n', CenterIsolation_dB(ch));
    fprintf('  Diagnostic worst XT +/-6 nm   = %.3f dB at %.3f nm\n\n', ...
        WorstXT_pm6_dB(ch), WorstXT_lambda_nm(ch));
end

%% ---------------- Save metrics table ----------------
Result = table(Channel_nm, Output_trace, Peak_lambda_nm, Peak_T, Peak_dB, ...
    Center_T, Center_dB, InsertionLoss_dB, ...
    BW_1dB_nm, BW_left_nm, BW_right_nm, ...
    PassbandVariation_dB, OscillatoryRipple_dB, ...
    CenterXT_dB, CenterIsolation_dB, WorstWrongOutput_center, ...
    WorstXT_pm6_dB, WorstIsolation_pm6_dB, WorstXT_lambda_nm);

writetable(Result, 'final_CWDM_metrics_corrected.csv');

fprintf('Saved files:\n');
fprintf('  final_CWDM_linear_corrected.png\n');
fprintf('  final_CWDM_dB_corrected.png\n');
fprintf('  final_CWDM_metrics_corrected.csv\n');
