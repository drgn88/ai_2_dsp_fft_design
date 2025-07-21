% 파일 이름
filename = 'reorder_fixed_index.txt';

% dout 값을 저장할 배열 초기화
dout_values = [];

% 파일 열기
fid = fopen(filename, 'r');

% 파일이 성공적으로 열렸는지 확인
if fid == -1
    error('파일을 열 수 없습니다. 파일 경로 및 이름을 확인하세요.');
end

% 한 줄씩 읽어서 데이터 추출
tline = fgetl(fid); % 첫 줄 읽기
while ischar(tline)
    % 'dout(X)=real+jimag' 형식의 문자
    % 열 찾기
    % 정규 표현식을 사용하여 숫자 부분 추출
    tokens = regexp(tline, 'dout\(\d+\)=(-?\d+\.?\d*)\+j(-?\d+\.?\d*)', 'tokens');

    if ~isempty(tokens)
        real_part = str2double(tokens{1}{1});
        imag_part = str2double(tokens{1}{2});
        dout_values = [dout_values; complex(real_part, imag_part)];
    end

    tline = fgetl(fid); % 다음 줄 읽기
end

% 파일 닫기
fclose(fid);

% 추출된 dout 값 확인 (선택 사항)
disp('추출된 dout 값의 개수:');
disp(length(dout_values));
% disp(dout_values); % 모든 값 보려면 주석 해제

% 파형 플로팅

% 1. 실수부 플로팅
figure;
plot(real(dout_values));
title('dout 값의 실수부');
xlabel('인덱스');
ylabel('실수 값');
grid on;

% 2. 허수부 플로팅
figure;
plot(imag(dout_values));
title('dout 값의 허수부');
xlabel('인덱스');
ylabel('허수 값');
grid on;

% 3. 크기(Magnitude) 플로팅
figure;
plot(abs(dout_values));
title('dout 값의 크기');
xlabel('인덱스');
ylabel('크기');
grid on;

% 4. 위상(Phase) 플로팅 (라디안)
figure;
plot(angle(dout_values));
title('dout 값의 위상 (라디안)');
xlabel('인덱스');
ylabel('위상 (라디안)');
grid on;

% 5. 위상(Phase) 플로팅 (도)
figure;
plot(rad2deg(angle(dout_values)));
title('dout 값의 위상 (도)');
xlabel('인덱스');
ylabel('위상 (도)');
grid on;