# MyFlashCard App

Markdown 덱을 앱에서 만들고 편집하며, 스와이프와 버튼으로 복습하는 Godot 4.7.1 GDScript 앱이다. 기획은 [docs/DESIGN.md](docs/DESIGN.md), 현재 구조는 [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md), 이정표는 [docs/ROADMAP.md](docs/ROADMAP.md)를 참고한다.

## 개발 환경

- 일반 Godot 4.7.1 에디터를 사용한다. .NET/Mono 에디터와 .NET SDK는 필요 없다.
- Main Scene은 `src/main/main.tscn`이다.
- 프로젝트 설정의 출처는 [src/debug/apply_project_settings.gd](src/debug/apply_project_settings.gd)다. 설정을 바꿀 때 스크립트와 `project.godot`이 일치하는지 함께 확인한다.
- 들여쓰기는 탭이며 [.editorconfig](.editorconfig)를 따른다.
- 외부에서 씬을 편집할 때 같은 씬을 Godot 에디터에 열어 두면 F5/F6 시 오래된 에디터 버퍼가 파일을 덮어쓸 수 있다. 작업 중에는 해당 씬 탭을 닫거나 외부 변경을 다시 불러온다.
- 창 크기와 모바일 비율은 에디터 내 Game 탭뿐 아니라 별도 실행 창에서도 확인한다.

## 설계 규칙

[docs/CONVENTIONS.md](docs/CONVENTIONS.md)가 기준이다.

- 하위 데이터·입력 컴포넌트는 상위 화면 전환과 저장 흐름을 직접 호출하지 않는다.
- 하위는 탭, 드래그 방향, 파싱 결과 같은 사실을 노출하고 `main.gd`가 의미를 해석한다.
- `src/core/`의 순수 로직은 `RefCounted`로 유지하고 Scene Tree와 파일 IO에 의존하지 않는다.
- 저장 경로와 파일 IO는 `src/storage/deck_storage.gd`에 모은다.
- 조작감에 영향을 주는 임계값과 애니메이션 시간은 자동 테스트뿐 아니라 실제 마우스·터치로 확인한다.

## 협업 규칙

- AI는 파서·런타임 오류, 헤드리스 테스트, export 검증을 맡고 화면의 최종 감각은 사람이 판단한다.
- 씬 노드 이름을 바꾸거나 제거하면 `main.gd`의 노드 경로와 `tests/main_smoke.gd`를 같은 변경에서 갱신한다.
- 기능 묶음이 끝나면 관련 코드와 테스트를 함께 커밋한다.
- 역사적 결정은 [docs/DEVLOG.md](docs/DEVLOG.md), 현재 구조는 [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md)에 기록한다.

## 테스트

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

- 중앙 실행기는 `tests/test_runner.gd`다.
- 새 검증은 책임에 따라 `phase*_smoke.gd` 또는 `main_smoke.gd`에 추가한다.
- core 테스트는 씬 없이 검증하고, UI 배선은 실제 버튼 signal과 pointer input 경로를 우선 검증한다.
- 테스트가 멈추면 재시도만 하지 말고 로그의 parse error, 잘못된 노드 경로, 실패 전에 발생한 예외부터 확인한다.

## 문서 체계

- [docs/DESIGN.md](docs/DESIGN.md) — 제품과 데이터 규칙
- [docs/ROADMAP.md](docs/ROADMAP.md) — 완료 항목과 다음 목표
- [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md) — 현재 코드 구조와 데이터 흐름
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md) — 설계·GDScript 규칙
- [docs/DEVLOG.md](docs/DEVLOG.md) — 변경 이력과 결정 이유
- [docs/MIGRATION_GDSCRIPT.md](docs/MIGRATION_GDSCRIPT.md) — 완료된 C# → GDScript 전환 기록
