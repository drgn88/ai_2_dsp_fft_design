% Test fft function (fft_float) 
% Added on 2025/07/02 by jihan 
 fft_mode = 1; % '0': ifft, '1': fft
 N = 512;

 [cos_float, cos_fixed] = cos_in_gen_fixed(fft_mode, N);

 [fft_out, module2_out] = fft_float_fixed_bak_plot(1, cos_fixed); % Floating-point fft (fft) : Cosine 

