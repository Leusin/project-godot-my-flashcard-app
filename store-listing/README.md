# 스토어 이미지

현재 스크린샷은 이전 UI를 담고 있어 배포 전에 다시 캡처해야 합니다.

| 이미지 | 경로 | 규격 |
| --- | --- | --- |
| 앱 아이콘 | `ko-KR/app-icon-512.png` | 512×512, RGBA PNG |
| 그래픽 이미지 | `ko-KR/feature-graphic-1024x500.png` | 1024×500, RGB PNG |
| 스크린샷 | `ko-KR/phone/01`부터 `04` | 1080×1920, RGB PNG |

## 다시 캡처하기

프로젝트 복사본의 `project.godot`에서 `application/config/name`을 다른 이름으로 바꾼 뒤, 복사본 폴더에서 실행합니다.

```sh
godot --path . --script res://tools/capture_store_listing.gd
```

생성된 이미지는 `store-listing/ko-KR/`에 저장됩니다.

| 순서 | 화면 |
| --- | --- |
| 01 | 덱 목록 |
| 02 | 학습 준비 |
| 03 | 카드 답 |
| 04 | 학습 결과 |
