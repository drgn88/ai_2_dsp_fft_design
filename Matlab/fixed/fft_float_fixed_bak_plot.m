function [fft_out, module2_out] = fft_float_fixed_bak(fft_mode, fft_in)
% Added on 2025/07/01 by jihan
 shift = 0; % 이 변수는 현재 코드에서 사용되지 않는 것 같습니다.
 SIM_FIX = 1; % 0: float, 1: fixed - 현재 코드에서는 fixed-point 연산만 수행
 
 if (fft_mode==1) % fft
	din = fft_in;
 else % ifft
	din = conj(fft_in); % IFFT의 경우 입력에 켤레 복소수 적용 (전통적인 방식)
 end
 
% 고정 소수점 변환방식: 반올림/ 오버플로우 - Saturation
fim = fimath('RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
% 소수부 절사를 위한 fimath 정의
fim_trunc = fimath('RoundingMethod', 'Zero', 'OverflowAction', 'Saturate');
% Twiddle Factor 고정 소수점 포맷 정의 <2.7>
TOTAL_TWF = 9; % Total bits: 1 sign + 1 integer + 7 fractional
FRAC_TWF = 7; % Fractional bits
STF_twf = numerictype('Signed', true, 'WordLength', TOTAL_TWF, 'FractionLength', FRAC_TWF);
% twiddle factor (double 타입으로 정의)
fac8_0 = [1, 1, 1, -1j]; % -j 대신 -1j 사용 권장 (복소수 리터럴)
fac8_1 = [1, 1, 1, -1j, 1, 0.7071-0.7071j, 1, -0.7071-0.7071j];
% Twiddle Factor: Convert Fixed Point (fi 객체로 변환)
fac8_0_real = fi(real(fac8_0), STF_twf, fim);
fac8_0_imag = fi(imag(fac8_0), STF_twf, fim);
fac8_0_fixed = complex(fac8_0_real, fac8_0_imag);
fac8_1_real = fi(real(fac8_1), STF_twf, fim);
fac8_1_imag = fi(imag(fac8_1), STF_twf, fim);
fac8_1_fixed = complex(fac8_1_real, fac8_1_imag);
 %-----------------------------------------------------------------------------
 % Module 0
 %-----------------------------------------------------------------------------
 % step0_0
 % 512 --> 256
 % Define Input Fixed Point <3.6>
 TOTAL_INPUT = 9;
 FRAC_INPUT = 6;
 STF_INPUT = numerictype('Signed', true, 'WordLength', TOTAL_INPUT, 'FractionLength', FRAC_INPUT);
 
 % din이 float이므로 fi 객체로 변환
 % --- 이 부분을 수정해야 합니다. ---
 if isa(din, 'fi') % din이 이미 fi 객체인지 확인
     din_fixed = din; % 이미 fi 객체라면 그대로 사용
 else
     % din이 float이므로 fi 객체로 변환 (기존 로직)
     din_real = fi(real(din), STF_INPUT, fim);
     din_imag = fi(imag(din), STF_INPUT, fim);
     din_fixed = complex(din_real, din_imag);
 end
 % ---------------------------------

 % Define BF_out Fixed Point <4.6> (정수부 1비트 증가)
 TOTAL_BF_ST_0 = 10;
 FRAC_BF_ST_0 = 6;
 STF_BF_ST_0 = numerictype('Signed', true, 'WordLength', TOTAL_BF_ST_0, 'FractionLength', FRAC_BF_ST_0);
 
 % 실수/허수부 배열 초기화
 % bfly00_out0_fixed 등을 직접 초기화하여 fi 객체를 포함하도록 합니다.
 bfly00_out0_fixed = fi(zeros(1, 256), STF_BF_ST_0, fim);
 bfly00_out1_fixed = fi(zeros(1, 256), STF_BF_ST_0, fim);
 
 % Even+Odd 버터플라이 연산
 for i = 1:256
     % fi 객체 간의 덧셈/뺄셈은 fimath에 따라 자동 처리됩니다.
     % 결과는 STF_BF_ST_0 포맷으로 저장됩니다.
     bfly00_out0_fixed(i) = din_fixed(i) + din_fixed(i+256);
     bfly00_out1_fixed(i) = din_fixed(i) - din_fixed(i+256);
 end
 
 bfly00_tmp = [bfly00_out0_fixed, bfly00_out1_fixed]; % 배열 연결 (concatenate)
 % Define BF_mul_TWF Fixed Point <4.6> * fac8_0 (bit 유지)
 bfly00_fixed = fi(zeros(1, 512), STF_BF_ST_0, fim); % fi 객체로 초기화
 
for nn = 1:512
    current_twf_index = ceil(nn/128); % 1, 2, 3, 4 중 하나
    
    current_bfly_tmp = bfly00_tmp(nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    switch current_twf_index
        case {1, 2, 3} % fac8_0의 [1, 1, 1] 부분: 값 그대로 유지 (포맷 변환)
            % fi 객체를 STF_BF_ST_0 포맷으로 다시 할당 (이미 해당 포맷이면 변화 없음)
            bfly00_fixed(nn) = fi(current_bfly_tmp, STF_BF_ST_0, fim); 
        case 4 % fac8_0의 [-j] 부분: (a + bj) * (-j) = b - aj (포맷 변환)
            % 실수부와 허수부를 바꾸고 부호만 변경 (fi 객체로 재구성)
            bfly00_fixed(nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF_ST_0, fim);
        otherwise
            error('Unexpected twiddle factor index.');
    end
end
 % step0_1
 % 256 --> 128 DFT
 % <4.6> 끼리의 합 --> <5.6> (정수부 1비트 증가)
 TOTAL_BF01_TMP = 11;
 FRAC_BF01_TMP = 6;
 STF_BF01_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF01_TMP, 'FractionLength', FRAC_BF01_TMP);
 
 bfly01_tmp_fixed = fi(zeros(1, 512), STF_BF01_TMP, fim); % fi 객체로 초기화
 
for kk = 1:2
    for nn = 1:128
        bfly01_tmp_fixed((kk-1)*256+nn) = bfly00_fixed((kk-1)*256+nn) + bfly00_fixed((kk-1)*256+128+nn);
        bfly01_tmp_fixed((kk-1)*256+128+nn) = bfly00_fixed((kk-1)*256+nn) - bfly00_fixed((kk-1)*256+128+nn);
    end
end
% <5.6> * <2.7> --> <7.13> (5+2=7, 6+7=13, 총 7+13=20비트)
TOTAL_BF01 = 20;
FRAC_BF01 = 13;
STF_BF01 = numerictype('Signed', true, 'WordLength', TOTAL_BF01, 'FractionLength', FRAC_BF01);
bfly01_fixed = fi(zeros(1, 512), STF_BF01, fim); % fi 객체로 초기화
% fac8_1 곱셈 (switch 문으로 분류하지만, 실제 곱셈은 fi '*' 연산자를 사용)
for nn = 1:512
    current_twf_index = ceil(nn/64); % fac8_1의 인덱스는 nn/64로 결정
    
    current_twf_value = fac8_1_fixed(current_twf_index); % fi 객체 트위들 팩터 값
    
    % float 값으로 실제 값이 1 또는 -j인지 확인 (미세한 고정소수점 오차 감안)
    % current_twf_value는 이미 fi 객체이므로, real()/imag()로 값 비교
    is_one = (abs(real(current_twf_value) - 1) < 1e-6) && (abs(imag(current_twf_value)) < 1e-6);
    is_neg_j = (abs(real(current_twf_value)) < 1e-6) && (abs(imag(current_twf_value) - (-1)) < 1e-6);
    
    current_bfly_tmp = bfly01_tmp_fixed(nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    if is_one % 값이 1인 경우
        % (a + bj) * 1 = a + bj
        % bfly01_tmp_fixed (<5.6>)의 값을 bfly01_fixed (<7.13>)로 캐스팅
        bfly01_fixed(nn) = fi(current_bfly_tmp, STF_BF01, fim); % 수정: fi 객체로 전체 할당
            
    elseif is_neg_j % 값이 -j인 경우
        % (a + bj) * (-j) = b - aj
        % 실수부와 허수부를 바꾸고 부호만 변경 (fi 객체로 재구성)
        bfly01_fixed(nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF01, fim); % 수정: fi 객체로 전체 할당
            
    else % 그 외의 복소수 값인 경우 (0.7071 등)
        % 복소수 fi 곱셈 (STF_BF01 포맷으로 결과가 생성됨)
        bfly01_fixed(nn) = current_bfly_tmp * current_twf_value; % 수정: fi 객체끼리 곱셈
    end
end
% 곱셈 결과 <7.13> -> <6.6>으로 변환 (정수부 1비트 감소, 소수부 7비트 절사)
TOTAL_BF01_RESIZE = 12;
FRAC_BF01_RESIZE = 6;
STF_BF01_RESIZE = numerictype('Signed', true, 'WordLength', TOTAL_BF01_RESIZE, 'FractionLength', FRAC_BF01_RESIZE);
bfly01_resize_fixed = fi(zeros(size(bfly01_fixed)), STF_BF01_RESIZE, fim_trunc); % fi 객체로 초기화
for n = 1:numel(bfly01_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    bfly01_resize_fixed(n) = fi(bfly01_fixed(n), STF_BF01_RESIZE, fim_trunc); % 수정: fi 객체로 전체 할당
end
 % step0_2
 % 128 --> 64 DFT
 % <6.6> 끼리의 합 --> <7.6> (정수부 1비트 증가)
 TOTAL_BF02_TMP = 13;
 FRAC_BF02_TMP = 6;
 STF_BF02_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF02_TMP, 'FractionLength', FRAC_BF02_TMP);
 
 bfly02_tmp_fixed = fi(zeros(1,512), STF_BF02_TMP, fim); % fi 객체로 초기화
 
for kk = 1:4
    for nn = 1:64
        bfly02_tmp_fixed((kk-1)*128+nn) = bfly01_resize_fixed((kk-1)*128+nn) + bfly01_resize_fixed((kk-1)*128+64+nn);
        bfly02_tmp_fixed((kk-1)*128+64+nn) = bfly01_resize_fixed((kk-1)*128+nn) - bfly01_resize_fixed((kk-1)*128+64+nn);
    end
end
 % Data rearrangement (Module 0의 Twiddle Factor for 64-point DFT)
 K3 = [0, 4, 2, 6, 1, 5, 3, 7];
 
 % 고정소수점 변환 <2.7> (STF_twf 사용)
 twf_m0_fixed = fi(zeros(1,512), STF_twf, fim); % fi 객체로 초기화
 
% 변환 Twiddle Factor 미리 계산
for kk = 1:8
    for nn = 1:64
        % 트위들 팩터 W_N^k = exp(-1j*2*pi*k/N)
        % 여기서는 k = (nn-1)*(K3(kk)), N = 512
        tw_val = exp(-1j*2*pi*(nn-1)*(K3(kk))/512);
        twf_m0_fixed((kk-1)*64+nn) = fi(complex(real(tw_val), imag(tw_val)), STF_twf, fim); % fi 객체로 전체 할당
    end
end
 % <7.6> * <2.7> = <9.13> (7+2=9, 6+7=13, 총 9+13=22비트)
 TOTAL_BF02 = 22;
 FRAC_BF02 = 13;
 STF_BF02 = numerictype('Signed', true, 'WordLength', TOTAL_BF02, 'FractionLength', FRAC_BF02);
 
 bfly02_fixed = fi(zeros(1,512), STF_BF02, fim); % fi 객체로 초기화
 
 for nn = 1:512
	bfly02_fixed(nn) = bfly02_tmp_fixed(nn)*twf_m0_fixed(nn);
 end
 % <9.13> --> <7.6>으로 변환 (정수부 2비트 감소, 소수부 7비트 절사)
TOTAL_BF02_RESIZE = 13;
FRAC_BF02_RESIZE = 6;
STF_BF02_RESIZE = numerictype('Signed', true, 'WordLength', TOTAL_BF02_RESIZE, 'FractionLength', FRAC_BF02_RESIZE);
bfly02_resize_fixed = fi(zeros(size(bfly02_fixed)), STF_BF02_RESIZE, fim_trunc); % fi 객체로 초기화
for n = 1:numel(bfly02_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    bfly02_resize_fixed(n) = fi(bfly02_fixed(n), STF_BF02_RESIZE, fim_trunc); % 수정: fi 객체로 전체 할당
end

 % Plot and save Module 0 output
 figure;
 subplot(2,1,1);
 plot(real(bfly02_resize_fixed));
 title('Module 0 Output - Real Part (Fixed Point)');
 subplot(2,1,2);
 plot(imag(bfly02_resize_fixed));
 title('Module 0 Output - Imaginary Part (Fixed Point)');
 saveas(gcf, 'fixed_module0_output.png'); % Save the plot as a PNG file

 fid_mod0 = fopen('fixed_mod0.txt', 'w');
 for n = 1:length(bfly02_resize_fixed)
     fprintf(fid_mod0, '%f + j%f\n', real(bfly02_resize_fixed(n)), imag(bfly02_resize_fixed(n)));
 end
 fclose(fid_mod0);

 %-----------------------------------------------------------------------------
 % Module 1
 %-----------------------------------------------------------------------------
 % step1_0
 % 64 --> 32
 % <7.6>끼리의 합 --> <8.6> (정수부 1비트 증가)
 TOTAL_BF10_TMP = 14;
 FRAC_BF10_TMP = 6;
 STF_BF10_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF10_TMP, 'FractionLength', FRAC_BF10_TMP);
 
 bfly10_tmp_fixed = fi(zeros(1, 512), STF_BF10_TMP, fim); % fi 객체로 초기화
 
 for kk = 1:8
  for nn = 1:32
	bfly10_tmp_fixed((kk-1)*64+nn) = bfly02_resize_fixed((kk-1)*64+nn) + bfly02_resize_fixed((kk-1)*64+32+nn);
	bfly10_tmp_fixed((kk-1)*64+32+nn) = bfly02_resize_fixed((kk-1)*64+nn) - bfly02_resize_fixed((kk-1)*64+32+nn);
  end
 end
 
 % <8.6>에 fac8_0를 곱하면 비트 유지
 TOTAL_BF10 = TOTAL_BF10_TMP; % 포맷 유지
 FRAC_BF10 = FRAC_BF10_TMP;   % 포맷 유지
 STF_BF10 = numerictype('Signed', true, 'WordLength', TOTAL_BF10, 'FractionLength', FRAC_BF10);
 
 bfly10_fixed = fi(zeros(1, 512), STF_BF10, fim); % fi 객체로 초기화
 
for kk = 1:8
  for nn = 1:64
    % fac8_0의 인덱스는 ceil(nn/16)으로 결정됩니다. (1, 2, 3, 4 중 하나)
    current_twf_index = ceil(nn/16);
    
    current_bfly_tmp = bfly10_tmp_fixed((kk-1)*64+nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    switch current_twf_index
        case {1, 2, 3} % fac8_0의 [1, 1, 1] 부분: 값 그대로 유지 (포맷 변환)
            bfly10_fixed((kk-1)*64+nn) = fi(current_bfly_tmp, STF_BF10, fim);
            
        case 4 % fac8_0의 [-j] 부분: (a + bj) * (-j) = b - aj (포맷 변환)
            bfly10_fixed((kk-1)*64+nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF10, fim);
            
        otherwise
            error('Invalid twiddle factor index for fac8_0 in step1_0.');
    end
  end
end
 % step1_1
 %32 -->16
 %<8.6>끼리의 합 --> <9.6> (정수부 1비트 증가)
TOTAL_BF11_TMP = 15;
FRAC_BF11_TMP = 6;
STF_BF11_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF11_TMP, 'FractionLength', FRAC_BF11_TMP);
bfly11_tmp_fixed = fi(zeros(1, 512), STF_BF11_TMP, fim); % fi 객체로 초기화
 for kk = 1:16
  for nn = 1:16
	bfly11_tmp_fixed((kk-1)*32+nn) = bfly10_fixed((kk-1)*32+nn) + bfly10_fixed((kk-1)*32+16+nn);
	bfly11_tmp_fixed((kk-1)*32+16+nn) = bfly10_fixed((kk-1)*32+nn) - bfly10_fixed((kk-1)*32+16+nn);
  end
 end
 %<9.6> * <2.7> --> <11.13> (9+2=11, 6+7=13, 총 11+13=24비트)
TOTAL_BF11 = 24;
FRAC_BF11 = 13;
STF_BF11 = numerictype('Signed', true, 'WordLength', TOTAL_BF11, 'FractionLength', FRAC_BF11);
bfly11_fixed = fi(zeros(1, 512), STF_BF11, fim); % fi 객체로 초기화
for kk = 1:8
  for nn = 1:64
    % fac8_1의 인덱스는 ceil(nn/8)으로 결정됩니다. (1부터 8까지)
    current_twf_index = ceil(nn/8);
    
    current_twf_value = fac8_1_fixed(current_twf_index); % fac8_1_fixed에서 값을 가져옴
    
    % float 값으로 실제 값이 1 또는 -j인지 확인 (미세한 고정소수점 오차 감안)
    is_one = (abs(real(current_twf_value) - 1) < 1e-6) && (abs(imag(current_twf_value)) < 1e-6);
    is_neg_j = (abs(real(current_twf_value)) < 1e-6) && (abs(imag(current_twf_value) - (-1)) < 1e-6);
    
    current_bfly_tmp = bfly11_tmp_fixed((kk-1)*64+nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    if is_one % 값이 1인 경우
        % (a + bj) * 1 = a + bj
        % bfly11_tmp_fixed (<9.6>)의 값을 bfly11_fixed (<11.13>)로 캐스팅
        bfly11_fixed((kk-1)*64+nn) = fi(current_bfly_tmp, STF_BF11, fim);
            
    elseif is_neg_j % 값이 -j인 경우
        % (a + bj) * (-j) = b - aj
        % 실수부와 허수부를 바꾸고 부호만 변경 (캐스팅만 발생)
        bfly11_fixed((kk-1)*64+nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF11, fim);
            
    else % 그 외의 복소수 값인 경우 (0.7071 등)
        % 복소수 fi 곱셈 (이 경우는 실제 곱셈이 필요하며, STF_BF11 포맷으로 결과가 생성됨)
        bfly11_fixed((kk-1)*64+nn) = current_bfly_tmp * current_twf_value;
    end
  end
end
% <11.13> --> <8.6>으로 변환 (정수부 3비트 감소, 소수부 7비트 절사)
TOTAL_BF11_RESIZE = 14;
FRAC_BF11_RESIZE = 6;
STF_BF11_RESIZE = numerictype('Signed', true, 'WordLength', TOTAL_BF11_RESIZE, 'FractionLength', FRAC_BF11_RESIZE);
bfly11_resize_fixed = fi(zeros(size(bfly11_fixed)), STF_BF11_RESIZE, fim_trunc); % fi 객체로 초기화
for n = 1:numel(bfly11_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    bfly11_resize_fixed(n) = fi(bfly11_fixed(n), STF_BF11_RESIZE, fim_trunc);
end
 % step1_2
 %16 -->8
% <8.6>끼리의 합 --> <9.6> (정수부 1비트 증가)
TOTAL_BF12_TMP = 15;
FRAC_BF12_TMP = 6;
STF_BF12_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF12_TMP, 'FractionLength', FRAC_BF12_TMP);
bfly12_tmp_fixed = fi(zeros(1,512), STF_BF12_TMP, fim); % fi 객체로 초기화
 
 for kk = 1:32
  for nn = 1:8
	bfly12_tmp_fixed((kk-1)*16+nn) = bfly11_resize_fixed((kk-1)*16+nn) + bfly11_resize_fixed((kk-1)*16+8+nn);
	bfly12_tmp_fixed((kk-1)*16+8+nn) = bfly11_resize_fixed((kk-1)*16+nn) - bfly11_resize_fixed((kk-1)*16+8+nn);
  end
 end
% fft_float_fixed.m 파일 내에서 Module 1, step1_2 부분입니다.
% 기존 코드를 아래 코드로 대체하세요.

% Data rearrangement (K2) - fft_float.m과 동일한 정의
K2 = [0, 4, 2, 6, 1, 5, 3, 7];

% Twiddle Factor for Module 1, step 2 (twf_m1) - fft_float.m과 동일한 방식으로 64개 생성
% twf_m1_fixed는 64개의 요소만 가지도록 정의합니다.
twf_m1_fixed = fi(zeros(1,64), STF_twf, fim); % <-- fft_float.m의 twf_m1과 크기 일치 (64개)

% 변환 Twiddle Factor 미리 계산
for kk = 1:8 % fft_float.m과 동일
    for nn = 1:8 % fft_float.m과 동일
        % Twiddle Factor (W_N^k) 계산 - fft_float.m과 동일한 공식 (K2(kk) 및 /64)
        tw_val = exp(-1j*2*pi*(nn-1)*(K2(kk))/64); % <-- K2(kk) 사용, /64 사용
        
        % twf_m1_fixed에 트위들 팩터 저장 - fft_float.m과 동일한 인덱싱
        twf_m1_fixed((kk-1)*8+nn) = fi(complex(real(tw_val), imag(tw_val)), STF_twf, fim); % <-- (kk-1)*8+nn 인덱싱으로 64개 연속 저장
    end
end

% bfly12_fixed (이전 단계에서 계산된 bfly12_tmp_fixed를 사용)
% <9.6> * <2.7> = <11.13> (9+2=11, 6+7=13, 총 11+13=24비트)
TOTAL_BF12 = 24;
FRAC_BF12 = 13;
STF_BF12 = numerictype('Signed', true, 'WordLength', TOTAL_BF12, 'FractionLength', FRAC_BF12);
bfly12_fixed = fi(zeros(1,512), STF_BF12, fim); % fi 객체로 초기화 (크기는 512로 동일)

% twf_m1_fixed 곱셈 (fft_float.m과 동일한 루프 구조 및 트위들 팩터 재사용)
for kk = 1:8 % fft_float.m과 동일
    for nn = 1:64 % fft_float.m과 동일
        % twf_m1_fixed에서 트위들 팩터 가져오기 - fft_float.m의 twf_m1(nn) 방식과 동일하게 재사용
        current_twf_value = twf_m1_fixed(nn); % <-- twf_m1_fixed(nn)으로 64개 재사용
        
        current_bfly_tmp = bfly12_tmp_fixed((kk-1)*64+nn); % 복소수 fi 객체 자체를 가져옴
        current_bfly_tmp_real = real(current_bfly_tmp);
        current_bfly_tmp_imag = imag(current_bfly_tmp);
        
        % 특수 트위들 팩터 (1 또는 -j) 처리 로직 - 이 부분은 기존과 동일하게 유지
        is_one = (abs(real(current_twf_value) - 1) < 1e-6) && (abs(imag(current_twf_value)) < 1e-6);
        is_neg_j = (abs(real(current_twf_value)) < 1e-6) && (abs(imag(current_twf_value) - (-1)) < 1e-6);
        
        if is_one % 값이 1인 경우
            bfly12_fixed((kk-1)*64+nn) = fi(current_bfly_tmp, STF_BF12, fim);
            
        elseif is_neg_j % 값이 -j인 경우
            bfly12_fixed((kk-1)*64+nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF12, fim);
            
        else % 그 외의 복소수 값인 경우 (0.7071 등)
            bfly12_fixed((kk-1)*64+nn) = current_bfly_tmp * current_twf_value;
        end
    end
end
%<11.13> --> <7.6>으로 변환 (정수부 4비트 감소, 소수부 7비트 절사)
TOTAL_BF12_RESIZE = 13;
FRAC_BF12_RESIZE = 6;
STF_BF12_RESIZE = numerictype('Signed', true, 'WordLength', TOTAL_BF12_RESIZE, 'FractionLength', FRAC_BF12_RESIZE);
bfly12_resize_fixed = fi(zeros(size(bfly12_fixed)), STF_BF12_RESIZE, fim_trunc); % fi 객체로 초기화
for n = 1:numel(bfly12_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    bfly12_resize_fixed(n) = fi(bfly12_fixed(n), STF_BF12_RESIZE, fim_trunc);
end

 % Plot and save Module 1 output
 figure;
 subplot(2,1,1);
 plot(real(bfly12_resize_fixed));
 title('Module 1 Output - Real Part (Fixed Point)');
 subplot(2,1,2);
 plot(imag(bfly12_resize_fixed));
 title('Module 1 Output - Imaginary Part (Fixed Point)');
 saveas(gcf, 'fixed_module1_output.png'); % Save the plot as a PNG file

 fid_mod1 = fopen('fixed_mod1.txt', 'w');
 for n = 1:length(bfly12_resize_fixed)
     fprintf(fid_mod1, '%f + j%f\n', real(bfly12_resize_fixed(n)), imag(bfly12_resize_fixed(n)));
 end
 fclose(fid_mod1);

 %-----------------------------------------------------------------------------
 % Module 2
 %-----------------------------------------------------------------------------
 % step2_0
 % 8--> 4
%<7.6>끼리의 합 --> <8.6> (정수부 1비트 증가)
TOTAL_BF20_TMP = 14;
FRAC_BF20_TMP = 6;
STF_BF20_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF20_TMP, 'FractionLength', FRAC_BF20_TMP);
bfly20_tmp_fixed = fi(zeros(1, 512), STF_BF20_TMP, fim); % fi 객체로 초기화
 
 for kk = 1:64
  for nn = 1:4
	bfly20_tmp_fixed((kk-1)*8+nn) = bfly12_resize_fixed((kk-1)*8+nn) + bfly12_resize_fixed((kk-1)*8+4+nn);
	bfly20_tmp_fixed((kk-1)*8+4+nn) = bfly12_resize_fixed((kk-1)*8+nn) - bfly12_resize_fixed((kk-1)*8+4+nn);
  end
 end
 % fac8_0 곱하기 (bit 유지)
TOTAL_BF20 = TOTAL_BF20_TMP;
FRAC_BF20 = FRAC_BF20_TMP;
STF_BF20 = numerictype('Signed', true, 'WordLength', TOTAL_BF20, 'FractionLength', FRAC_BF20);
bfly20_fixed = fi(zeros(1, 512), STF_BF20, fim); % fi 객체로 초기화
for kk = 1:64
  for nn = 1:8
    % fac8_0의 인덱스는 ceil(nn/2)으로 결정됩니다. (1, 2, 3, 4 중 하나)
    current_twf_index = ceil(nn/2);
    
    current_bfly_tmp = bfly20_tmp_fixed((kk-1)*8+nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    switch current_twf_index
        case {1, 2, 3} % fac8_0의 [1, 1, 1] 부분: 값 그대로 유지 (포맷 변환)
            bfly20_fixed((kk-1)*8+nn) = fi(current_bfly_tmp, STF_BF20, fim);
            
        case 4 % fac8_0의 [-j] 부분: (a + bj) * (-j) = b - aj (포맷 변환)
            bfly20_fixed((kk-1)*8+nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF20, fim);
            
        otherwise
            error('Invalid twiddle factor index for fac8_0 in step2_0.');
    end
  end
end
 % step2_1
 % 4 --> 2
% <8.6>끼리의 합 --> <9.6> (정수부 1비트 증가)
TOTAL_BF21_TMP = 15;
FRAC_BF21_TMP = 6;
STF_BF21_TMP = numerictype('Signed', true, 'WordLength', TOTAL_BF21_TMP, 'FractionLength', FRAC_BF21_TMP);
bfly21_tmp_fixed = fi(zeros(1, 512), STF_BF21_TMP, fim); % fi 객체로 초기화
 
 for kk = 1:128
  for nn = 1:2
	bfly21_tmp_fixed((kk-1)*4+nn) = bfly20_fixed((kk-1)*4+nn) + bfly20_fixed((kk-1)*4+2+nn);
	bfly21_tmp_fixed((kk-1)*4+2+nn) = bfly20_fixed((kk-1)*4+nn) - bfly20_fixed((kk-1)*4+2+nn);
  end
 end
 %<9.6> * <2.7> = <11.13> (9+2=11, 6+7=13, 총 11+13=24비트)
 TOTAL_BF21 = 24;
 FRAC_BF21 = 13;
 STF_BF21 = numerictype('Signed', true, 'WordLength', TOTAL_BF21, 'FractionLength', FRAC_BF21);
 
 bfly21_fixed = fi(zeros(1, 512), STF_BF21, fim); % fi 객체로 초기화
for kk = 1:64
  for nn = 1:8
    % fac8_1의 인덱스는 nn으로 결정됩니다. (1부터 8까지)
    current_twf_index = nn; % 인덱스는 1부터 8까지 직접 사용
    
    current_twf_value = fac8_1_fixed(current_twf_index); % fac8_1_fixed에서 값을 가져옴
    
    % float 값으로 실제 값이 1 또는 -j인지 확인 (미세한 고정소수점 오차 감안)
    is_one = (abs(real(current_twf_value) - 1) < 1e-6) && (abs(imag(current_twf_value)) < 1e-6);
    is_neg_j = (abs(real(current_twf_value)) < 1e-6) && (abs(imag(current_twf_value) - (-1)) < 1e-6);
    
    current_bfly_tmp = bfly21_tmp_fixed((kk-1)*8+nn); % 복소수 fi 객체 자체를 가져옴
    current_bfly_tmp_real = real(current_bfly_tmp);
    current_bfly_tmp_imag = imag(current_bfly_tmp);

    if is_one % 값이 1인 경우
        % (a + bj) * 1 = a + bj
        % bfly21_tmp_fixed (<9.6>)의 값을 bfly21_fixed (<11.13>)로 캐스팅
        bfly21_fixed((kk-1)*8+nn) = fi(current_bfly_tmp, STF_BF21, fim);
        
    elseif is_neg_j % 값이 -j인 경우
        % (a + bj) * (-j) = b - aj
        % 실수부와 허수부를 바꾸고 부호만 변경 (캐스팅만 발생)
        bfly21_fixed((kk-1)*8+nn) = fi(complex(current_bfly_tmp_imag, -current_bfly_tmp_real), STF_BF21, fim);
            
    else % 그 외의 복소수 값인 경우 (0.7071 등)
        % 복소수 fi 곱셈 (이 경우는 실제 곱셈이 필요하며, STF_BF21 포맷으로 결과가 생성됨)
        bfly21_fixed((kk-1)*8+nn) = current_bfly_tmp * current_twf_value;
    end
  end
end
%<11.13> --> <8.6>으로 변환 (정수부 4비트 감소, 소수부 7비트 절사)
TOTAL_BF21_RESIZE = 14;
FRAC_BF21_RESIZE = 6;
STF_BF21_RESIZE = numerictype('Signed', true, 'WordLength', TOTAL_BF21_RESIZE, 'FractionLength', FRAC_BF21_RESIZE);
bfly21_resize_fixed = fi(zeros(size(bfly21_fixed)), STF_BF21_RESIZE, fim_trunc); % fi 객체로 초기화
for n = 1:numel(bfly21_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    bfly21_resize_fixed(n) = fi(bfly21_fixed(n), STF_BF21_RESIZE, fim_trunc);
end
 % step2_2
 %2 --> 1
% <8.6>끼리의 합 --> <9.6> (정수부 1비트 증가)
TOTAL_BF22 = 15;
FRAC_BF22 = 6;
STF_BF22 = numerictype('Signed', true, 'WordLength', TOTAL_BF22, 'FractionLength', FRAC_BF22);
bfly22_fixed = fi(zeros(1, 512), STF_BF22, fim); % fi 객체로 초기화
 
 for kk = 1:256
	bfly22_fixed((kk-1)*2+1) = bfly21_resize_fixed((kk-1)*2+1) + bfly21_resize_fixed((kk-1)*2+2);
	bfly22_fixed((kk-1)*2+2) = bfly21_resize_fixed((kk-1)*2+1) - bfly21_resize_fixed((kk-1)*2+2);
 end
 % <9.6> --> <9.4> 변환: 최종 출력 (정수부 1비트 증가, 소수부 2비트 절사)
 TOTAL_OUTPUT = 13;
 FRAC_OUTPUT = 4;
 STF_OUTPUT = numerictype('Signed', true, 'WordLength', TOTAL_OUTPUT, 'FractionLength', FRAC_OUTPUT);
 
 output_fixed = fi(zeros(size(bfly22_fixed)), STF_OUTPUT, fim_trunc); % fi 객체로 초기화
 for n = 1:numel(bfly22_fixed) % numel gets total number of elements in the array
    % 실수부 캐스팅
    output_fixed(n) = fi(bfly22_fixed(n), STF_OUTPUT, fim_trunc);
end
 
 % Plot and save Module 2 output
 figure;
 subplot(2,1,1);
 plot(real(output_fixed));
 title('Module 2 Output - Real Part (Fixed Point)');
 subplot(2,1,2);
 plot(imag(output_fixed));
 title('Module 2 Output - Imaginary Part (Fixed Point)');
 saveas(gcf, 'fixed_module2_output.png'); % Save the plot as a PNG file

 fid_mod2 = fopen('fixed_mod2.txt', 'w');
 for n = 1:length(output_fixed)
     fprintf(fid_mod2, '%f + j%f\n', real(output_fixed(n)), imag(output_fixed(n)));
 end
 fclose(fid_mod2);

 %-----------------------------------------------------------------------------
 % Index 
 %-----------------------------------------------------------------------------
 % dout 변수를 output_fixed와 동일한 STF_OUTPUT 타입으로 정의합니다.
 % FFT 결과는 복소수이므로 complex 타입으로 정의합니다.
dout = fi(zeros(size(output_fixed)), STF_OUTPUT, fim); % fi 객체로 초기화
% 파일 열기 (파일 이름 변경: reorder_fixed_index.txt로 더 명확하게)
fp = fopen('reorder_fixed_index.txt','w');
for jj = 1:512
    % 비트 반전 인덱스 (bit-reversal index) 계산
    % MATLAB의 bitget은 LSB가 1번째 비트이므로, 9번째 비트는 2^0, 1번째 비트는 2^8이 됩니다.
    kk = bitget(jj-1,9)*1 + bitget(jj-1,8)*2 + bitget(jj-1,7)*4 + bitget(jj-1,6)*8 + ...
         bitget(jj-1,5)*16 + bitget(jj-1,4)*32 + bitget(jj-1,3)*64 + bitget(jj-1,2)*128 + ...
         bitget(jj-1,1)*256;
    
    % 재정렬된 인덱스에 맞춰 최종 고정소수점 데이터를 저장
    % output_fixed는 이미 fi 객체이므로, 대입 시 STF_OUTPUT 타입으로 자동 변환됩니다.
    dout(kk+1) = output_fixed(jj); % dout에 output_fixed 값을 재정렬하여 할당
    
    % 파일에 결과 출력
    % fi 객체의 실수부/허수부 값은 real() / imag() 함수로 접근합니다.
    fprintf(fp, 'jj=%d, kk=%d, dout(%d)=%f+j%f\n', jj, kk, (kk+1), real(dout(kk+1)), imag(dout(kk+1)));
end
% 파일 닫기
fclose(fp);
% FFT/IFFT 모드에 따른 최종 출력 처리
if (fft_mode == 1) % FFT 모드 (일반적인 FFT 출력)
    fft_out = dout;
    module2_out = output_fixed; % FFT 중간 결과 (재정렬 전)
else % IFFT 모드
    % 켤레 복소수 취하고 512로 나누기
    % conj() 함수는 fi 객체에 대해서도 작동하며, 나눗셈은 fimath에 따라 처리됩니다.
    fft_out = conj(dout) / 512; 
    module2_out = conj(output_fixed) / 512; % FFT 중간 결과 (재정렬 전)
end
end % function end