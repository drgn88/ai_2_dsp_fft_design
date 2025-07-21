% Test fft function (fft_matlab vs. fft_manual)
% Added on 2025/07/02 by jihan

N = 512;
fft_mode = 1;

% Input signal generation
[ran_float, ran_fixed] = ran_in_gen_stu(fft_mode, N);
% [cos_float, cos_fixed] = cos_in_gen(fft_mode, N); % Cosine input option

% Matlab FFT (Random, Floating-point)
mat_float_fft = fft(ran_float);
%mat_float_fft = fft(cos_float); % Matlab fft (Cosine, Floating-point) option

% Fixed-point FFT (Random/Cosine)
[fft_out_fixed, module2_out_fixed] = fft_float_fixed_bak(1, ran_float); % Fixed-point fft (Random, fft)
 %[fft_out_fixed, module2_out_fixed] = fft_float_fixed_bak(1, cos_fixed); % Fixed-point fft (Cosine, fft)
% [fft_out_fixed, module2_out_fixed] = fft_float_fixed_bak(1, cos_float); % Fixed-point fft (Cosine, fft)

% Calculate Signal Power and Noise Power
fp_1 = fopen('sqnr_fft.txt', 'w');
sig_pow = zeros(1, N); % Pre-allocate for efficiency
noise_re = zeros(1, N);
noise_im = zeros(1, N);
noise_pow = zeros(1, N);

for ii = 1:N
    sig_pow(ii) = power(real(mat_float_fft(ii)), 2) + power(imag(mat_float_fft(ii)), 2);
    noise_re(ii) = real(mat_float_fft(ii)) - real(fft_out_fixed(ii));
    noise_im(ii) = imag(mat_float_fft(ii)) - imag(fft_out_fixed(ii));
    noise_pow(ii) = power(noise_re(ii), 2) + power(noise_im(ii), 2);
    fprintf(fp_1, 'sig_pow(ii)=%f, noise_pow(ii)=%f\n', sig_pow(ii), noise_pow(ii));
end
fclose(fp_1);

% Sum total signal and noise power
tot_sig_pow = sum(sig_pow);
tot_noise_pow = sum(noise_pow);

% Convert tot_noise_pow to double to avoid embedded.fi type error with log10
% This is the key change to fix the error.
tot_noise_pow_double = double(tot_noise_pow);

% Calculate SNR
snr_val = 10 * log10(tot_sig_pow / tot_noise_pow_double);

% Display results
X = sprintf('tot_sig_pow=%f, tot_noise_pow=%f, snr_val=%f\n', tot_sig_pow, tot_noise_pow_double, snr_val);
disp(X);