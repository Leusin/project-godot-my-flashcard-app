# MEMORY

## 프로젝트 목표

원하는 경험

- Markdown 문서 하나만 편집하면 바로 복습할 수 있는 낮은 작성 마찰
- 버튼과 스와이프를 함께 지원하는 손맛 있는 복습
- PC와 Android에서 같은 덱 형식 사용

익히고 싶은 것

- Godot 4 GDScript의 Scene, signal, input, Tween 구조
- Android export와 실기기 배포
- 작은 씬으로 나눈 UI를 에디터에서 직접 조정하는 workflow

현재 원칙

- 순수 로직은 `src/core/`, 파일 IO는 `src/storage/`, 화면 조정은 `src/main/main.gd`에 둔다.
- 조작감 수치는 자동 테스트만으로 확정하지 않고 실제 마우스와 터치로 확인한다.
- 화면 위 장식보다 카드 내용과 다음 행동을 우선한다.
- 완벽한 미래 구조보다 지금 실행되는 작은 기능을 먼저 완성한다.

## 회고

- GDScript 전환과 .NET 의존성 제거 완료: 2026-08-13
