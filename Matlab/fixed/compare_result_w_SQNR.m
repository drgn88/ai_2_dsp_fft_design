% Compare results of floating-point FFT (fft_float) and fixed-point FFT (fft_float_fixed)
% Plot the error, identify indices where real parts have different signs, and calculate SQNR.

clear; % Clear workspace
close all; % Close all figures

% --- Configuration ---
fft_mode = 1; % '0': IFFT, '1': FFT
N = 512; % FFT length

% --- Generate input data ---
[cos_float_in, cos_fixed_in] = cos_in_gen(fft_mode, N); % We only need float input here

% --- Run FFTs ---
fprintf('--- Running Floating-Point FFT (fft_float) ---\n');
[fft_out_float, ~] = fft_float(fft_mode, cos_float_in); % Use float input for float FFT
fprintf('Floating-point FFT calculation complete.\n\n');

fprintf('--- Running Fixed-Point FFT (fft_float_fixed) ---\n');
% fft_float_fixed internally converts input to fi object based on STF_INPUT
[fft_out_fixed, module2_out_fixed_before_reorder] = fft_float_fixed_bak(fft_mode, cos_float_in);
fprintf('Fixed-point FFT calculation complete.\n\n');

% --- Convert fixed-point output to double for comparison ---
% The output from fft_float_fixed is a fi object. We need its double value for comparison.
fft_out_fixed_double = double(fft_out_fixed);
module2_out_fixed_double = double(module2_out_fixed_before_reorder); % Module 2 output (before final reorder)

% --- Calculate Errors (Plots remain the same) ---
error_complex = fft_out_float - fft_out_fixed_double;
error_abs = abs(error_complex);
error_real = real(error_complex);
error_imag = imag(error_complex);

% --- Plot Error Graphs ---
figure;

subplot(3,1,1);
plot(error_abs);
title('Absolute Error |Float FFT - Fixed-Point FFT|');
xlabel('Frequency Bin');
ylabel('Absolute Error');
grid on;

subplot(3,1,2);
plot(error_real);
title('Real Part Error (Float FFT - Fixed-Point FFT)');
xlabel('Frequency Bin');
ylabel('Error (Real)');
grid on;

subplot(3,1,3);
plot(error_imag);
title('Imaginary Part Error (Float FFT - Fixed-Point FFT)');
xlabel('Frequency Bin');
ylabel('Error (Imaginary)');
grid on;

sgtitle('FFT Output Error Comparison'); % Super title for the figure

% --- Calculate SQNR (Signal-to-Quantization Noise Ratio) - Adapted from test_512p_sqnr_cal_stu.m ---
fprintf('--- Signal-to-Quantization Noise Ratio (SQNR) ---\n');

% Apply the 1/16 scaling to the fixed-point output as in test_512p_sqnr_cal_stu.m
fft_out_fixed_scaled = fft_out_fixed_double / 16;

sig_pow = zeros(1, N); % Pre-allocate for efficiency
noise_re = zeros(1, N);
noise_im = zeros(1, N);
noise_pow = zeros(1, N);

for ii = 1:N
    sig_pow(ii) = power(real(fft_out_float(ii)), 2) + power(imag(fft_out_float(ii)), 2);
    noise_re(ii) = real(fft_out_float(ii)) - real(fft_out_fixed_scaled(ii));
    noise_im(ii) = imag(fft_out_float(ii)) - imag(fft_out_fixed_scaled(ii));
    noise_pow(ii) = power(noise_re(ii), 2) + power(noise_im(ii), 2);
end

% Sum total signal and noise power
tot_sig_pow = sum(sig_pow);
tot_noise_pow = sum(noise_pow);

% Convert tot_noise_pow to double to avoid embedded.fi type error with log10
tot_noise_pow_double = double(tot_noise_pow);

% Calculate SNR
if tot_noise_pow_double > 0
    SQNR_dB = 10 * log10(tot_sig_pow / tot_noise_pow_double);
    fprintf('Signal Power (Total): %g\n', tot_sig_pow);
    fprintf('Noise Power (Total): %g\n', tot_noise_pow_double);
    fprintf('SQNR: %.4f dB\n', SQNR_dB);
else
    fprintf('Noise Power is zero. SQNR is infinite (perfect match).\n');
end
fprintf('---------------------------------------------------\n\n');


% --- Identify and tabulate sign differences in Real Part ---
fprintf('--- Real Part Sign Differences ---\n');
fprintf('Index\tFloat Sign\tFixed Sign\tModule 2 Fixed Sign (Before Reorder)\n');
fprintf('--------------------------------------------------------------------\n');

sign_diff_count = 0;
for i = 1:N
    float_real_val = real(fft_out_float(i));
    % Use the scaled fixed-point output for sign comparison as well for consistency
    fixed_real_val = real(fft_out_fixed_scaled(i)); 

    float_real_sign = sign(float_real_val);
    fixed_real_sign = sign(fixed_real_val);
    module2_real_sign = sign(real(module2_out_fixed_double(i))); % Sign of Module 2 output (pre-reorder)

    % A small tolerance for comparing signs around zero
    tolerance = 1e-6; % Adjust this value as needed based on expected noise floor

    % Check for actual sign difference, considering values very close to zero
    % If both are very close to zero, or one is zero and the other is very close, don't count as sign difference
    if (abs(float_real_val) < tolerance && abs(fixed_real_val) < tolerance)
        continue;
    end
    
    % If signs are different AND at least one of them is not extremely close to zero
    if float_real_sign ~= fixed_real_sign
         sign_diff_count = sign_diff_count + 1;
         fprintf('%d\t%d\t\t%d\t\t%d\n', i-1, float_real_sign, fixed_real_sign, module2_real_sign);
    end
end

if sign_diff_count == 0
    fprintf('No significant real part sign differences found.\n');
else
    fprintf('\nTotal real part sign differences: %d\n', sign_diff_count);
end
fprintf('--------------------------------------------------------------------\n');

% Optional: Plot magnitude comparison for visual inspection
figure;
plot(abs(fft_out_float), 'b', 'DisplayName', 'Float FFT');
hold on;
plot(abs(fft_out_fixed_scaled), 'r--', 'DisplayName', 'Fixed-Point FFT (Scaled)'); % Label changed
legend show;
title('Magnitude Comparison: Float vs. Fixed-Point FFT');
xlabel('Frequency Bin');
ylabel('Magnitude');
grid on;

% Optional: Plot phase comparison for visual inspection
figure;
plot(angle(fft_out_float), 'b', 'DisplayName', 'Float FFT');
hold on;
plot(angle(fft_out_fixed_scaled), 'r--', 'DisplayName', 'Fixed-Point FFT (Scaled)'); % Label changed
legend show;
title('Phase Comparison: Float vs. Fixed-Point FFT');
xlabel('Frequency Bin');
ylabel('Phase (radians)');
grid on;