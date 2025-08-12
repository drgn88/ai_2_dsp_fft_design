# 🙋‍♂️Who Made?

|                                                                                                    **Hyenwoo Choi**                                                                                                    |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| [<img src="https://img1.daumcdn.net/thumb/R720x0.q80/?scode=mtistory2&fname=https%3A%2F%2Ft1.daumcdn.net%2Fcfile%2Ftistory%2F20675B4C50BA149F1B" width=200 height=150> </br> @HyenWoo Choi](https://github.com/drgn88) |
- 전체 아키텍쳐 설계
- Control Logic 설계
- Synthesis & Gate Simulation
  

## 🧑‍💻Co-Work
|                                                                                                                                                                                          **HeeJae Jang**                                                                                                                                                                                           |                    **SeungBum Park**                     |                     **Jiwon Jung**                     |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------: | :----------------------------------------------------: |
| <img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2Fxv8Ol%2Fbtq0c3ce6AI%2FAAAAAAAAAAAAAAAAAAAAAEEF-lWZpykloAGcFVsvmI2FYh_tPWHo9a4wk0m4hwLH%2Fimg.jpg%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1753973999%26allow_ip%3D%26allow_referer%3D%26signature%3DEZICGQh%252FbYCbWDjqYgtgpdmIll8%253D" width=150 height=150> | <img src="./img/프로필/호랑이.jpg" width=150 height=150> | <img src="./img/프로필/stop.png" width=150 height=150> |

### 🙎HeeJae Jang
- Verification
- Debuggin
- CBFP 설계 및 검증
- Reordering Index 모듈 개발

### 🙎‍♂️SeungBum Park
- CBFP 검증
- Mag & Min Detection 모듈 개발
- Index Memory 설계

### 🙎‍♀️Jiwon Jung
- Data Path 설계 검증
  - 각 Step의 ButterFly, Multiplication Twiddle Factor 개발
- VCS 테스트벤치 작성

# 🏕️Development Environment

Language
- System Verilog(Design & Verification)
- Verilog
- Matlab(Algorithm Verification)


Tool
- VCS & Verdi
- Design Compiler
- Matlab
- Vivado
  - FPGA 검즘
  - VCS 시뮬레이션 비교

# 1. Floating Point Design

> 논문참고: [A new approach to pipeline FFT processor](./논문/A%20new%20approach%20to%20pipeline%20FFT%20processor.pdf)

## Code 참고

[Matlab: Floating Point Design](./Matlab/floating/fft_float.m)

## 🦋Butterfly 구조 

|                    Mod0                    |                    Mod1                    |                    Mod2                    |
| :----------------------------------------: | :----------------------------------------: | :----------------------------------------: |
| <img src="./img/floating/mod0_butter.png"> | <img src="./img/floating/mod1_butter.png"> | <img src="./img/floating/mod2_butter.png"> |

- 논문에서 제공하는 2^2 Radix를 따라가고 있음
- 먼저 ButterFly 연산을 수행하고 다음 스테이지로 넘어가기 전, Twiddle Factor를 곱함

## ❓How to Pipeline

|                  **논문 발췌**                  |
| :---------------------------------------------: |
| <img src="./img/floating/pipeline_circuit.png"> |

- 각 Stage마다 앞에 Shift Register를 둠
- 처음 N/2 Cycle동안에 대기
  - Shift Register를 채움
- N/2+1 Cycle부터 레지스터에서 나오는 값과 들어오는 값을 버터플라이 연산을 수행해줌

|   reg[0]   |   reg[1]   |  ---  | reg[N/2-1] |
| :--------: | :--------: | :---: | :--------: |
| val[N/2-1] | val[N/2-2] |  ---  |   val[0]   |

- N/2 사이클이후부터 shift register에서 나오는 값은 처음 들어온 값
- shift register에 들어오는 값은 첫 인덱스에 N/2를 더해준 값이 들어온다
- ⭐Pipeline의 핵심 회로 구조

### 💭제어는 어떻게?
- N/2 Cycle인 경우 $log_2(N/2) + 1$만큼의 Counter를 만듦
- MSB를 Valid Signal로 사용
- Ex) 128 Cycle인 경우 --> 8bit Counter

|  MSB  |   6   |  ---  |   0   |
| :---: | :---: | :---: | :---: |
| valid |  num  |  ---  |  num  |

- 첫 128사이클 동안(000_0000~111_1111)은 MSB가 0
  - 첫 128사이클동안 Valid = 0이므로 버터플라이 연산 휴무
- 다음 128부터 MSB = 1
  - 그 다음 128사이클동안 Valid = 1이므로 버터플라이 연산 시작

# 2. Fixed Point Design

## Fixed Point 정의

- 입력: Q<3.6>
- Twiddle Factor: Q<2.7>
- 출력: Q<9.4>

| Module0 | step0_0 | step0_1 | step0_2 |
| :-----: | :-----: | :-----: | :-----: |
| &nbsp;  | Q<4.6>  | Q<6.6>  | Q<7.6>  |

| Module1 | step1_0 | step1_1 | step1_2 |
| :-----: | :-----: | :-----: | :-----: |
| &nbsp;  | Q<8.6>  | Q<8.6>  | Q<7.6>  |

| Module2 | step2_0 | step2_1 | step2_2 |
| :-----: | :-----: | :-----: | :-----: |
| &nbsp;  | Q<8.6>  | Q<8.6>  | Q<9.4>  |

> 최대 비트가 15비트를 넘지않도록 설정

## Round Saturation 방식
- 소수부: Truncation
  - fi: RoundingMethod = Zero
- Overflow: Saturation
  - fi: OverflowAction = Saturation

## 🥊결과 비교: Floating Vs Fixed

### 1️⃣Floating

|                     Mod0                     |                     Mod1                     |                     Mod2                     |
| :------------------------------------------: | :------------------------------------------: | :------------------------------------------: |
| <img src="./img/floating/floating_mod0.png"> | <img src="./img/floating/floating_mod1.png"> | <img src="./img/floating/floating_mod2.png"> |

### 2️⃣Fixed

|                  Mod0                  |                  Mod1                  |                  Mod2                  |
| :------------------------------------: | :------------------------------------: | :------------------------------------: |
| <img src="./img/fixed/fixed_mod0.png"> | <img src="./img/fixed/fixed_mod1.png"> | <img src="./img/fixed/fixed_mod2.png"> |

> Mod1까지는 비슷한 양상으로 가다, Mode2의 허수부에서 차이가 보이기 시작한다

### 🔎Detail

|                 Magnitude Compare                 |
| :-----------------------------------------------: |
| <img src="./img/fixed/magnitude_compare.png"><br> |

> 비슷한 양상을 보이며 겹치는 것을 확인

|        Error Between Floating Vs Fixed        |
| :-------------------------------------------: |
| <img src="./img/fixed/error_compare.png"><br> |

> Absolute Error가 평균 0.5이하로 존재하는 것을 확인할 수 있다.


## SQNR

> SQNR = $10log(P_Signal/P_Noise)$
> > SQNR이 클수록 신호의 세기가 크다

### 📈Cosine

|                 SQNR_Cosine                 |
| :-----------------------------------------: |
| <img src="./img/fixed/SQNR_cosine.png"><br> |
|                   45.34dB                   |

### 🔢Random

|                 SQNR_Random                 |
| :-----------------------------------------: |
| <img src="./img/fixed/SQNR_random.png"><br> |
|                 mean = 38dB                 |

> Random의 경우 38dB에서 왔다갔다 하는 정도

## 🚀TroubleShooting
- [cos fixed 입력]()
- [fi 출력은 실수]()

## ⚠️Notice - Fixed Point Problem

- Fixed Point로 그냥 처리하게 되면 오차가 커짐
  - Truncation으로 절삭하면 정밀도에서 손해를 본다
- 지금은 N의 사이즈가 작고, Stage가 2단으로 적기에 고정소수점 정밀도 손해가 적음
  - 그래서 SQNR이 쓸만하게 나옴
- N이 커지고, 연산이 길어질 것을 대비해 해결방안이 필요하다
- Solution: CBFP⬇️

# 3. CBFP -  Fixed Point SQNR Solution
> 논문참고: [A_Fast_Single-Chip_Implementation_of_8192_Complex_Point_FFT](./논문/A_Fast_Single-Chip_Implementation_of_8192_Complex_Point_FFT.pdf)


## 기존: 단계별 Fixed Point
- 기존 FFT에 고정소수점 연산 경우
  - 단계별로 고정소수점 비트를 증가시킴(단계별 Scaling)
  - 무한정 비트수를 증가시킬 수 없음
  - 예를 들어 연산과정이 길어질 수록 비트 수를 계속 증가시킬 수 없음
    - ⚠️HW Resource 문제

## Block Floating Point(BFP)

- 각 FFT 스테이지에서 전체 블록(N개)의 최대값 계산
  - 공통 스케일을 적용
  - 각 스테이지에서의 최대값을 먼저 계산해서 최대의 고정소수점 비트를 미리 계산함
- ⚠️ 고정 소수점 방식으로 연산 진행시
  - 연산을 진행할수록 오버플로우 방지 위해 비트수 계속 증가
  - 연산 스테이지가 길면? ➡️ 비트수가 무한정 증가
- BFP 사용시
  - 출력의 결과들 중에서 가장 큰 값에 맞추어 스케일링
  - 비트수를 연산 때마다 늘리지말고
  - 결과 중에 가장 큰 값에 맞추어 scaling해줌
  - 그러면 비트 수를 무한정 늘리지 않아도 됨


### 문제: PipeLine Problem

- 전체 블록의 최대값을 알아야함
  - 전체 출력이 나올때까지 기다려야함
- 하지만 파이프라이닝은 모든 스테이지가 동시에 진행됨
  - 우리 FFT 코드만 보더라도
    - shift reg에서 나오는 값과 들어오는 값이 연속적으로 처리되어서 그게 바로 다음 스테이지로 넘어감
  - 한 스테이지의 모든 출력이 나올때까지 기다리지 않음
  - ❗파이프라인이 안되는 이유

## CBFP(Convergent Block Floating Point)
> 수렴형 BFP

- 파이프라인 구조에 적합하게 BFP를 수정
- BFP는 하나의 스테이지에서 모든 출력이 나올때까지 대기
- 예를 들어 512 포인트면, 512개의 출력이 나올때까지 대기
  - 512 클럭 사이클동안 대기해야함

- CBFP
  - N point를 여러개의 블럭으로 나눔
  - N point를 예를 들어 N/4블록으로 나누면
  - N/4사이클만 대기하면됨
  - 그러고 다음 스테이지로 파이프라인해서 넘김
  
- 대신 각 블럭에 대해서 exponent가 달라짐
  - 오히려 각 블럭에 대해 exponent설정하는게 정밀도 ⬆️
  - 모든 출력에 대해 exponent를 적용하는 것보다 블록별 exponent가 국소적 최적화 좋음

### ❓BFP에서 정밀도 손실 발생 이유

[예시]
- 8비트 고정소수점
  - -128~127까지 표현
- X = [1.0, 0.1, 0.01, 0.001]

| 실제 값 | 스케일링 후 값 (127x) | 정수 표현 | 오차   |
| ------- | --------------------- | --------- | ------ |
| 1.0     | 127                   | 127       | 0      |
| 0.1     | 12.7                  | 13        | +0.3   |
| 0.01    | 1.27                  | 1         | -0.27  |
| 0.001   | 0.127                 | 0         | -0.127 |

- 작은 값들은 정수표현에서 잘려나감
  - ⚠️**Underflow**

### Summary

| 방식                         | 큰 값                  | 작은 값                               |
| ---------------------------- | ---------------------- | ------------------------------------- |
| 전체 기준으로 스케일링 (BFP) | 👍 정확함               | ❌ 비트 손실로 부정확                  |
| 블록 기준 스케일링 (CBFP)    | ✅ 블록 안에서만 정규화 | ✅ 작은 값도 상대적으로 크게 표현 가능 |


## 비교) BFP Vs CBFP

| 항목            | BFP            | CBFP                   | Floating Point |
| --------------- | -------------- | ---------------------- | -------------- |
| 스케일 단위     | 전체 블록(N개) | 블록당 (ex: N/4)       | 샘플당         |
| 정밀도(SNR)     | 보통           | 더 좋음 (최대 +3\~5dB) | 최고           |
| 연산 복잡도     | 낮음           | 약간 증가 (+4%)        | 높음           |
| 하드웨어 적합성 | 배치형         | 파이프라인 최적        | 부적합         |
| 메모리 효율     | 좋음           | 좋음                   | 나쁨           |


## 매트랩 아이디어
- Q<8.6> --> 13비트로 saturation하면 Q<7.6>이 됨
  - 소수부를 늘리게 되면(예를 들어 Q<5.8>) 그만큼 스케일 다운(2^8)
  - 오차가 더 커진다

Q. MSB연속 비트 수만큼 좌측 shift를 하는 이유가 뭘까

```matlab
 % bitshift(X, N, 'int32')
 % X를 Nbit shift(N>0: 왼쪽 , N<0: 오른쪽)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THIS PART %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 % 실수부 비트 shift
 for ii=1:8
  for jj=1:64
      % 최종 12비트의 결과 얻기위해 12사용
   if (cnt1_re(ii)>12)
	re_bfly02(64*(ii-1)+jj)=bitshift(bitshift(real(pre_bfly02(64*(ii-1)+jj)),cnt1_re(ii), 'int32'),-12, 'int32');
   else
	re_bfly02(64*(ii-1)+jj)=bitshift(real(pre_bfly02(64*(ii-1)+jj)),(-12+cnt1_re(ii)), 'int32');
   end
  end
 end


 % 허수부 비트 shift
 for ii=1:8
  for jj=1:64
   if (cnt1_im(ii)>12)
	im_bfly02(64*(ii-1)+jj)=bitshift(bitshift(imag(pre_bfly02(64*(ii-1)+jj)),cnt1_im(ii), 'int32'),-12, 'int32');
   else
	im_bfly02(64*(ii-1)+jj)=bitshift(imag(pre_bfly02(64*(ii-1)+jj)),(-12+cnt1_im(ii)), 'int32');
   end
  end
 end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fp_2=fopen('cbfp_0.txt','w');
 for nn=1:512
	bfly02(nn) = re_bfly02(nn) + j*im_bfly02(nn);  
	fprintf(fp_2, 'twf_m0(%d)=%d+j%d, pre_bfly02(%d)=%d+j%d, index1_re(%d)=%d, index1_im(%d)=%d, bfly02(%d)=%d+j%d\n',nn, real(twf_m0(nn)), imag(twf_m0(nn)), nn, real(pre_bfly02(nn)), imag(pre_bfly02(nn)), nn, index1_re(nn), nn, index1_im(nn), nn, real(bfly02(nn)), imag(bfly02(nn)));
 end
 fclose(fp_2);
```
- 비트 확장을 다 같이 증가함(cnt1_real, cnt1_img --> 연속된 MSB 최솟값 ---> 값의 최대값)
- 스케일링 인자를 블록별로 적용
- 전체에 대해 Scaling 필요 X
  - 파이프라인 가능
  - 연산 블록별 Fixed Point 최적화 가능 --> 양자화 손실 적어짐

## FFT with CBFP(512-Point)
<img src="./img/HW_architecture/FFT_다이어그램.png"><br>

# 4. RTL Design

## 🏛️전체 아키텍쳐

> 모듈 0, 1, 2의 각 step은 뺄셈부 저장을 위한 메모리를 제외하고 Flow가 동일

> 각 모듈별로 Control Unit 존재
> > 제어신호는 앞단이 뒷단한테 연산을 시작함을 알리는 릴레이 형식으로 구성

Step0
---
<img src="./img/HW_architecture/step0.png" width=70%>

- 데이터 스트림은 16개(실수부 허수부 각각)로 진행
- 버터플라이 연산을 위해 이후 입력 대기 필요
  - Shift Register에서 Offset Clk만큼 저장
  - Reg에 들어오는 데이터와 나가는 데이터를 ButterFly 연산 수행
- Step0의 Twiddle Factor의 경우, 1아니면 -j밖에 없음
  - 곱셈 연산 대신 wire reverse 방식 채택
  - Circuit Size 및 Speed 향상⬆️


Step1
---
<img src="./img/HW_architecture/step1.png" width=70%><br>

- Butter Fly 연산 후, 덧셈부 + 뻴셈부 총 32개의 데이터 스트림 발생
- 파이프라이닝을 위해 뺄셈부를 Shift Register에 저장
  - 덧셈부 먼저 처리 후, 이후에 뺄셈부 처리
- Twiddle Factor
  - Case문을 사용해 해당 데이터 스트림에 맞는 Twiddle Factor를 곱하게 만듦

Step2
---
<img src="./img/HW_architecture/step2.png" width=70%><br>
- Step 2에서는 512-point에 대한 Twiddle Factor를 각각 곱함
- 512개의 Tiwddle Factor를 ROM으로 관리
- Control Logic에서 Address로 Twiddle Factor를 관리

CBFP
---
<img src="./img/HW_architecture/cbfp.png" width=70%><br>
- Module0의 경우 64개에 대한 Scaling Factor를 구함
  - 데이터 스트림은 16개이므로 4개씩 Min값을 구한 후 Shift Reg(Depth=4)에 저장 후 한 번에 처리
- Magnitude Detection
  - 연속되는 MSB의 개수가 적다 == 값의 크기가 크다
  - 각 Data의 Mag값을 구한 후 이 중에 Min값을 찾음

### ⭐Min 값 비교
- N개의 최솟값을 구할 때
  - 2개씩 비교 --> $N-1$stage
  - 2개씩 짝지어서 비교 --> $log_2N$ Stage
    - Min 모듈을 만들어 병렬로 처리하여 Stage를 줄임

### ⭐Pipe Register
- Stage의 수가 2~3개 이상이 되는 경우 Pipe Register를 사용
- Negative Slack 방지

Module 0이후의 CBFP
---
<img src="./img/HW_architecture/CBFP_0_after.png" width=70%><br>

- 모듈 1부터는 한번에 처리하는 데이터의 단위가 16개 이하임
  - 병렬로 처리 가능
- 서브 모듈을 만들어 Parallel하게 구성
  - 매 클럭마다 데이터 처리 가능

## VCS RTL Simulation

### 1️⃣Module0 시뮬레이션 결과

<img src="./img/RTL_SIM/module0.png"><br>

- 첫 입력이 들어가고 첫 출력이 나오기까지 40Clk 소요
- Shift Register에 쌓는데 클럭 소모
- Data Path의 연산부 파이프 레지스터
  - Butterfly Module
  - Twiddle Factor Multiplication
- CBFP Min, Mag Pipe Register

### 2️⃣Module1 시뮬레이션 결과

<img src="./img/RTL_SIM/module1.png"><br>

- 첫 입력 들어가고 첫 출력 나오기까지 12clk 소요
- step0에서 shift register에 뺄셈부 쌓는데 클럭 소요 
  - 이후단계부터는 데이터 스트림이 16개 이하로 한번에 처리 가능
  - Shift Register에 쌓을 필요 없음
- Data Path의 연산부에 pipe register에서 1clk씩 소모


### 3️⃣Module2 시뮬레이션 결과

<img src="./img/RTL_SIM/module2.png"><br>

- 첫 입력이 들어가고 첫 출력 나오기까지 5Clk 소모

### 4️⃣Reordering 시뮬레이션결과

<img src="./img/RTL_SIM/reordering.png"><br>

- Index Memory
  - 각 CBFP의 Min 모듈의 제어신호를 FIFO Push 신호로 사용
  - 이후 CBFP2의 alert signal을 Pop 신호로 사용
  - 512 Depth의 메모리 2개를 사용하여 CBFP2 구현

### FFT 1Cyle 소요 클럭

<img src="./img/RTL_SIM/total_clk_consume.png"><br>

- 첫 입력이 들어가고 첫 출력이 나오기까지 총 **88Clk** 소요

# 5. Synthesis

## AREA 🌍

### Total Area

<img src="./img/Synthesis/Total_Area.png"><br>

### Module별 Area

<img src="./img/Synthesis/Area_module.png" width=70%><br>

- Module 0가 가장 많은 면적 차지
  - 뺄셈부 저장을 위한 Shift Register 사용
  - 데이터 스트림 16개보다 크고, 비트 사이즈도 큼
  - 연산부(Butterfly, Multiplication)의 사이즈 큼
- 뒷 단으로 갈 수록 한번에 처리하는 데이터 사이즈 감소
- 데이터 스트림이 16개이하로 매클럭마다 처리가능
  - Shift Register 필요 없음

## Timing Check⌛

### Timing Max Report (SetUp Violation)
<img src="./img/Synthesis/setup_time_violation.png"><br>

[조건]
- Clk 500MHZ
- 마진 0.7

[결과]
- 0.35: Positive Slack
- 기준에 부합

> Slack의 여유가 많다고 무조건 좋은건 아님 --> 그만큼 Combinational Logic을 Tight하게 사용한 것이 아님
> > 필요없는 Pipe Register를 많이 사용한 경우일 수도 있음 


## Simulation Result (Vs RTL) 🥊

### 소요 클럭

<img src="./img/Synthesis/simulation_clk.png" width=70%><br>

- 첫 입력이 들어가고 첫 출력이 나오기까지
  - RTL과 동일하게 88Clk 소요

### 출력 결과

<img src="./img/Synthesis/simulation_result.png" width=70%><br>

- Cosine Test Input 기준 RTL과 동일한 결과 출력


# 6. FPGA

검증보드
---
|                   **Avnet-Tria UltraZed-7EV**                   |
| :-------------------------------------------------------------: |
| <img src="./img/FPGA_verification/avnet-tria_ultrazed_7ev.jpg"> |

## Verification🔍

- Cosine Generator를 만들어 FFT에 연결한 후 나오는 출력을 VIO로 확인
- Cosine Generator는 32clk동안 값 출력 후, 8clk 쉬고 이를 반복
  - FFT의 PipeLining 확인

## FPGA: Block Diagram

<img src="./img/FPGA_verification/FPGA_block_diagram.png"><br>

> Clk Wizard 사용 이유

- 사용 보드가 clk_p, clk_n으로 들어옴
- HW가 사용하는 clk은 1개
  - 이를 통합할 필요있음
- Vivado Clk Wizard IP로 합침

## Simulation 결과

<img src="./img/FPGA_verification/simulation.png" width=70%><br>

- 연속해서 입력을 넣어줄 때
  - 첫 출력이 나오고 40clk 뒤에 다음 출력 나옴

## Resource & Timing Result

### Resource⛏️

<img src="./img/FPGA_verification/resource.png"><br>

- DSP Resource를 눈에 띄게 많이 사용하는 것을 확인
- ButterFly Module, TWF Multiplier에 의해 이러한 결과 나온 것으로 보임

### Timing⌚

<img src="./img/FPGA_verification/timing.png"><br>

- Setup & Hold time 시간 내에 들어오는 것을 확인
> Clk Speed는 100MHz

