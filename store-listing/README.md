# Google Play 스토어 등록정보 에셋

## 한국어 (`ko-KR`)

- 앱 아이콘: `ko-KR/app-icon-512.png`
- 그래픽 이미지: `ko-KR/feature-graphic-1024x500.png`
- 휴대전화 스크린샷: `ko-KR/phone/01`부터 `04`까지 순서대로 업로드

그래픽 이미지 대체 텍스트:

> 세 장의 플래시카드가 차례로 넘어가며 학습 진행을 나타내는 일러스트

스크린샷 구성:

1. 카드 덱 목록과 덱 추가
2. 덱별 학습 진행상황
3. 카드를 탭해 답 확인
4. GOOD, AGAIN, SKIP 학습 결과

## 다시 캡처하기

Godot 프로젝트에서 `tools/capture_store_listing.gd`를 실행하면 현재 UI로 규격에 맞는 에셋을 다시 생성한다.

- 앱 아이콘: 512×512, RGBA PNG
- 그래픽 이미지: 1024×500, RGB PNG
- 휴대전화 스크린샷: 1080×1920, RGB PNG
