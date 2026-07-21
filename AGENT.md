# MyFlashCard App

Markdown으로 카드를 작성하고 Reigns 스타일 스와이프로 복습하는 플래시카드 앱 (Godot 4 .NET, C#). 기획은 [docs/DESIGN.md](docs/DESIGN.md), 이정표는 [docs/ROADMAP.md](docs/ROADMAP.md) 참고.

## 개발 환경

- **반드시 .NET 에디터로 열 것**: `../tools/Godot_v4.7.1-stable_mono_win64/` (바탕화면 바로가기 "Godot 4.7.1 (.NET)"). Steam의 표준 빌드는 C#을 지원하지 않아 씬이 열리지 않고, 여는 것만으로 `project.godot`의 `config/features`에서 `"C#"`이 지워진다.
- **프로젝트 설정의 출처는 [src/debug/apply_project_settings.gd](src/debug/apply_project_settings.gd)**. `project.godot`을 손으로 고치지 말고 이 스크립트를 고친 뒤 `& $godot --headless --path . --script res://src/debug/apply_project_settings.gd`로 반영한다. 선언에서 뺀 설정은 지워지지 않으니, 뺄 때는 `project.godot`도 함께 확인한다.
- 들여쓰기는 탭 ([.editorconfig](.editorconfig)). 내장 에디터가 어차피 탭으로 되돌려놓기 때문.
- **에디터를 열어둔 채 파일을 편집하면 실행(F5/F6) 시 에디터가 오래된 버퍼로 덮어쓴다.** 에디터 설정 `run/auto_save/save_before_running`이 기본 `true`라, 실행할 때마다 열린 씬이 전부 저장되기 때문. 실제로 리팩터한 `StudyView.cs`가 되돌아가 앱이 깨진 적이 있다. AI가 파일을 고치는 동안에는 에디터를 닫아두고, 작업 후 아래 테스트 명령으로 확인한다.
- **에디터에서 실행한 화면과 에디터 밖에서 직접 실행한 화면이 다를 수 있다.** Godot 4.4+는 게임을 에디터 안의 Game 탭에 끼워 실행하는 게 기본(`run/window_placement/game_embed_mode`)이라 창 크기가 `window_*_override` 대신 패널 크기를 따른다. 창 크기·비율을 확인할 때는 에디터 밖에서 실행할 것.

## 설계 규칙

[docs/CONVENTIONS.md](docs/CONVENTIONS.md)가 규칙의 기준이다. 특히:

- **의존 방향**: 하위(카드·파서·입력)는 상위(세션 규칙·저장 관리)를 호출하지 않는다. 상위가 하위를 구독한다.
- **사실 vs 해석**: 하위는 사실(스와이프 방향, 파싱 결과)만 노출하고, Again/Good 처리나 진행도 갱신 같은 해석은 세션 관리자가 한다.
- **뷰는 읽기만**: 카드 UI·목록 UI는 상태를 읽어 표시만 한다.
- 새 시스템을 시작할 때는 패턴 이름만으로 구조를 잡지 말 것. **참조 가능/불가 대상과 의존 방향을 먼저 확인**하고 시작한다.

## 협업 규칙

- 조작감에 영향 주는 값(스와이프 임계값, 애니메이션 시간)은 구조 개선이 목적이라도 **사람의 사용 확인 전에는 확정하지 않는다.**
- 검증 분담: AI는 헤드리스 실행(빌드·테스트, 파서/런타임 에러 확인)을 맡고, 화면에 보이는 것의 최종 판정은 사람이 한다.
- 아트는 시안부터 사람이 판정한다.
- 기능 묶음이 끝나면 정리 리뷰 → MINOR 버전 올리고 `git tag vX.Y.Z` → 사이클이 끝나면 회고(docs/MEMORY.md).

## 문서 체계

- [docs/DESIGN.md](docs/DESIGN.md) — 기획서. 데이터 규칙(카드 식별, 학습 규칙, Import)의 기준.
- [docs/ROADMAP.md](docs/ROADMAP.md) — 버전별 목표와 완료/예정 항목.
- [docs/DEVLOG.md](docs/DEVLOG.md) — 결정·교훈을 그날 기록. 세션 시작 시 최근 엔트리를 읽으면 맥락이 잡힌다.
- [docs/MEMORY.md](docs/MEMORY.md) — 프로젝트 목표·가설·회고.
- [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md) — 코드 읽는 순서와 데이터 흐름. 코드를 처음 볼 때 여기부터.
- ARCHITECTURE / TESTING 문서는 구조가 커지면 분리한다. 지금은 CODE_GUIDE로 충분.

## 테스트

```powershell
$godot = "..\tools\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe"
dotnet build
& $godot --headless --path . res://tests/tests.tscn   # 실패 개수 = 종료 코드
```

`_console.exe` 쪽을 써야 출력이 콘솔에 보인다. C# 코드를 고쳤으면 `dotnet build`를 먼저 해야 반영된다.

새 테스트는 `tests/TestRunner.cs`의 `_Ready()`에 함수로 등록한다. 순수 로직(`src/core/`의 파서·세션 큐·진행도)이 단위 테스트 1순위 대상이고, 이들은 `Node`를 상속하지 않아 씬 없이 검증된다. 씬 배선은 `SceneSmokeTest()`가 시그널을 직접 발신해 확인한다.
