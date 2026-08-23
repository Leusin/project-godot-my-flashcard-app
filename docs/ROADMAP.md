# ROADMAP

| 버전 | 이름 | 목표 (완료 기준) |
| --- | --- | --- |
| v0.1 | 최소 루프 | md 파일 하나로 데스크톱에서 복습이 한 바퀴 돈다 |
| v0.2 | 여러 덱 | 아무 md 파일이나 가져와서 덱으로 골라 복습할 수 있다 |
| v0.3 | 편집 | 카드 작성/수정을 앱 안에서 끝낼 수 있다 |
| v1.0 | 게임 느낌 + Android | 폰에서 스와이프로 복습한다 — 기획서의 핵심 경험 완성 |

## v0.1 - 최소 루프
목표: 하드코딩된 md 파일 하나를 읽어서, 데스크톱에서 복습이 한 바퀴 도는 것.

- [x] Godot 4 GDScript 프로젝트 구성, 데스크톱 실행 확인
- [x] Markdown 파서: `# 질문` + 다음 줄들 = 답 → `Array[FlashCard]`
- [x] Study 화면: 질문 표시 → 탭하면 답 공개
- [x] `Again` / `Got it` 버튼 2개 (스와이프 아님, 그냥 버튼)
  - Again: WrongCount +1 후 다음 카드로
  - Got it: 다음 카드로
  - 어느 쪽이든 카드는 이번 세션에 다시 나오지 않는다
- [x] 모든 카드 완료 시 "끝" 화면
- [x] 진행도 JSON 저장/로드 (키: Question, 값: WrongCount)

## v0.2 - 여러 덱

목표: PC에서 만든 md 파일을 가져와서(Import), 여러 덱 중 골라 복습할 수 있다.

- [x] 덱 목록 화면 (내부 저장소의 md 파일 나열)
- [x] Import: 파일 선택 → 내부 저장소로 복사
- [x] 마지막 사용 덱 기억 (시작 화면)
- [x] 새 덱 생성 (덱 목록 ＋ 새 덱 타일 → 이름 입력 → 빈 덱 → 카드 목록으로 이동, 2026-07-22 폴리싱 세션에서 추가)

## v0.3 - 편집

목표: **PC 없이도 카드 작성/수정을 앱 안에서 끝낼 수 있다.**
"앱에서 수정한 내용은 Markdown에도 반영된다" 원칙이 실제로 검증되는 버전.

- [x] Card List 화면 (목록 보기만, WrongCount 표시) — Study의 ✏로 진입, ←로 복귀
- [x] Card Editor (질문/답 수정 → md 재저장, 진행도가 카드를 따라옴 — 모델 A). ←로 나가면 자동 저장
- [x] 카드 상태 라벨 (NEW/LEARNING/MASTERED — 수동, 표시용. Study에 표시·Editor에서 편집) + WrongCount 수동 수정
- [x] 카드 추가/삭제 (목록 ＋ 카드 추가 = 빈 편집기, 편집기 삭제 = 제거 + 진행도 정리)
- [x] Export (카드 목록 📝 내보내기 → 지금 덱을 고른 위치로 한 부 복사)
- [x] 클립보드 Markdown으로 덱 생성 (복사 → 이름 입력 → 원문 저장 → 카드 목록)

## v1.0 — 게임 느낌 + Android

목표: "폰에서 스와이프로 복습한다." 가 완성되는 버전.

- [x] 네 방향 스와이프 제스처 (← AGAIN / → GOOD / ↑ SKIP / ↓ PREV)
- [x] 카드 퇴장·등장·앞뒤 플립 애니메이션
- [x] Safe Area와 Android 뒤로가기 처리
- [x] Android APK export, 실제 기기 설치·실행 확인
- [x] GDScript 전환과 .NET 의존성 제거
- [x] 배포 브랜드 확정 — 앱 이름 My Simple Flash Card, 패키지 `com.leusin.mysimpleflashcard`, 첫 테스트 버전 0.9.0 (versionCode 1)
- [x] Play 업로드용 AAB export 프리셋 (Android Release AAB, target SDK 36)
- [ ] 업로드 키스토어 생성·등록과 release 서명 (절차는 README의 "Android 배포" 참고)
- [ ] Play Console 앱 등록과 스토어 등록 정보(512px 아이콘, 스크린샷, 설명) 준비
  - Android는 기본 `user://decks`를 사용한다.
  - 시스템 폴더를 덱 폴더로 직접 지정하려면 SAF 플러그인 또는 네이티브 연동이 필요하다.

## 보류

v1.0 이후, 실제로 써보면서 필요한 것만 꺼내온다.

- 덱/카드 드래그 순서 변경, 검색
- 카드 상태 자동 전이, MASTERED Study 제외
- 덱별 UI 테마와 유료 스킨 가능성 검토
