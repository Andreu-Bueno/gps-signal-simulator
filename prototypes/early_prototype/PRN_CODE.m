clc; clear; close all;

%% ================================
% 1. PARÁMETROS
% ================================
N = 1023;
fs = 1.023e6;
t = (0:N-1)/fs;

true_delay = 120;
true_fd = 1800;

num_iter = 50;

%% ================================
% 2. GENERAR PRN GOLD
% ================================
G1 = ones(1,10);
G2 = ones(1,10);

gold = zeros(1,N);

tap1 = 2; tap2 = 6;

for i = 1:N
    g1_out = G1(end);
    g2_out = xor(G2(tap1), G2(tap2));
    
    gold(i) = xor(g1_out, g2_out);
    
    fb1 = xor(G1(3), G1(10));
    fb2 = xor(xor(G2(2), G2(3)), ...
          xor(G2(6), xor(G2(8), xor(G2(9), G2(10)))));
    
    G1 = [fb1 G1(1:9)];
    G2 = [fb2 G2(1:9)];
end

gold = 1 - 2*gold;

%% ================================
% 3. SEÑAL RECIBIDA (I/Q)
% ================================
rx = circshift(gold, true_delay) ...
     .* exp(1j*2*pi*true_fd*t);

rx = rx + 0.5*(randn(1,N) + 1j*randn(1,N));

%% ================================
% 4. ACQUISITION (Delay-Doppler)
% ================================
doppler_bins = -5000:500:5000;
lags = -N+1:N-1;

corr_map = zeros(length(doppler_bins), length(lags));

for d = 1:length(doppler_bins)
    
    fd_test = doppler_bins(d);
    
    carrier = exp(-1j*2*pi*fd_test*t);
    rx_mixed = rx .* carrier;
    
    [corr, ~] = xcorr(rx_mixed, gold);
    
    corr_map(d,:) = abs(corr);
end

corr_map = corr_map / max(corr_map(:));

[~, idx] = max(corr_map(:));
[d_idx, tau_idx] = ind2sub(size(corr_map), idx);

chip_delay = lags(tau_idx);
freq = doppler_bins(d_idx);

fprintf('ACQUISITION → delay=%d doppler=%d\n', chip_delay, freq);

%% ================================
% 5. DLL + PLL INIT
% ================================
pll_phase = 0;

delay_hist = zeros(1,num_iter);
freq_hist  = zeros(1,num_iter);

%% ================================
% 6. TRACKING LOOP (DLL + PLL)
% ================================
for k = 1:num_iter
    
    % ----- Code phase -----
    code_phase = mod((0:N-1) - chip_delay, N);
    local_code = interp1(0:N-1, gold, code_phase, 'linear', 'extrap');
    
    % ----- Carrier -----
    carrier = exp(-1j*(2*pi*freq*t + pll_phase));
    
    % ----- Correlation -----
    signal = rx .* carrier;
    
    prompt = sum(signal .* local_code);
    
    early = circshift(local_code, -1);
    late  = circshift(local_code, +1);
    
    E = sum(real(signal .* early));
    P = sum(real(signal .* local_code));
    L = sum(real(signal .* late));
    
    % ----- DLL -----
    dll_err = (E - L) / (E + L + 1e-6);
    chip_delay = chip_delay + 0.5 * dll_err;
    
    % ----- PLL -----
    pll_err = atan2(imag(prompt), real(prompt));
    pll_phase = pll_phase + 0.1 * pll_err;
    freq = freq + 5 * pll_err;
    
    % ----- logs -----
    delay_hist(k) = chip_delay;
    freq_hist(k)  = freq;
    
    fprintf('Iter %d → delay=%.2f freq=%.2f\n', k, chip_delay, freq);
end

%% ================================
% 7. RESULTADOS
% ================================
fprintf('\nFINAL ESTIMATE:\n');
fprintf('Delay: %.2f (real %d)\n', chip_delay, true_delay);
fprintf('Doppler: %.2f (real %d)\n', freq, true_fd);

%% ================================
% 8. PLOTS
% ================================

% --- Acquisition map ---
figure;
imagesc(lags, doppler_bins, corr_map);
axis xy;
xlabel('Delay (chips)');
ylabel('Doppler (Hz)');
title('Acquisition: Delay–Doppler Map');
colorbar;

% --- DLL tracking ---
figure;
plot(delay_hist,'LineWidth',1.5);
hold on;
yline(true_delay,'r--');
grid on;
xlabel('Iteration');
ylabel('Delay (chips)');
title('DLL Tracking');
legend('Estimated','True');

% --- PLL tracking ---
figure;
plot(freq_hist,'LineWidth',1.5);
hold on;
yline(true_fd,'r--');
grid on;
xlabel('Iteration');
ylabel('Doppler (Hz)');
title('PLL Tracking');
legend('Estimated','True');

% --- Error plots ---
figure;

subplot(2,1,1);
plot(delay_hist - true_delay);
grid on;
title('DLL Error');
xlabel('Iteration');
ylabel('Error (chips)');

subplot(2,1,2);
plot(freq_hist - true_fd);
grid on;
title('PLL Error');
xlabel('Iteration');
ylabel('Error (Hz)');