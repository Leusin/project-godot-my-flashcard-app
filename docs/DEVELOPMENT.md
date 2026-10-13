# 개발 가이드

## 코드 구조

| 위치 | 역할 |
| --- | --- |
| `src/main/main.tscn`, `main.gd` | 앱 진입점과 화면 연결 |
| `src/core/` | 카드 데이터, Markdown 파싱, 학습과 정렬 로직 |
| `src/storage/` | 덱과 기록 저장, 백업과 복원 |
| `src/main/*_view.gd`, `*_view.tscn` | 화면 구성 |
| `src/main/deck_action_service.gd` | 덱 생성, 가져오기, 복제, 이름 변경, 삭제 |
| `src/main/card_workspace.gd`, `card_edit_coordinator.gd` | 카드 편집과 저장 |
| `src/main/study_run.gd`, `study_flow_view.gd` | 학습 진행과 화면 표시 |
| `src/main/study_gesture_surface.gd`, `card_detail_surface.gd` | 카드 탭과 스와이프 |
| `src/main/context_menu.tscn`, `anchored_popup_menu.gd` | 공통 메뉴 |
| `addons/mobile_foundation/` | 공통 입력과 레이아웃 처리 |
| `tests/` | 자동 테스트와 입력 검증 |
| `src/debug/`, `tools/` | 개발 설정, 캡처와 배포 도구 |

## 코딩 컨벤션과 설계 원칙

### 책임과 의존 방향

- core는 `RefCounted` 기반 순수 로직으로 구성, UI와 파일 IO에 의존하지 않고 Scene Tree 없이 테스트 가능하도록 유지
- storage는 파일 읽기와 저장 담당, UI에 의존하지 않고 core 사용
- main은 저장, 학습, 편집 서비스를 연결하고 화면 전환 결정
- 하위 UI는 상위를 직접 찾거나 저장을 호출하지 않고 `tapped`, `swiped` 같은 signal로 입력 전달
- 입력에 따른 동작과 저장 여부는 main에서 결정

### GDScript 스타일

- 파일, 함수, 변수 이름은 `snake_case`, `class_name`과 enum 타입은 `PascalCase` 사용
- 매개변수와 반환값에 타입 명시, 배열도 가능한 곳에는 원소 타입 지정
- 씬 노드 참조는 `@onready`로 보관하고 구체적인 노드 타입 지정
- 경로가 정해진 씬과 리소스는 `preload`, 실행 중 경로를 선택하는 경우에는 `load` 사용
- 들여쓰기는 탭 사용, 공백과 줄바꿈 설정은 `.editorconfig` 기준

### 주석

- 코드만으로 알기 어려운 이유와 제약 기록
- 구현과 맞지 않는 주석은 수정하거나 삭제
- 사용하지 않는 코드는 주석으로 설명을 붙여 남겨 두지 않고 삭제

## 테스트

아래 명령은 프로젝트 폴더에서 실행합니다. `godot`이 PATH에 등록되어 있지 않다면 실행 파일 경로로 바꿔 입력하면 됩니다.

### 자동 테스트

```sh
godot --headless --path . --import
godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

로그에 `RESULT: N checks, 0 failures`가 나오면 통과입니다. 전체 로그는 `.godot/latest-test.log`에서 확인할 수 있습니다.

### 입력 테스트

기존 앱의 저장 데이터와 섞이지 않도록 프로젝트 복사본에서 테스트합니다. 복사본의 `project.godot`에서 `application/config/name`을 다른 이름으로 바꾸면 됩니다.

```sh
godot --path . --script res://tests/ui_interaction.gd
```

`UI RESULT: N checks, 0 failures`가 나오면 통과입니다. 화면 캡처가 필요하면 명령 뒤에 `-- --capture`를 붙입니다.

```sh
godot --path . --script res://tests/ui_interaction.gd -- --capture
```

화면을 렌더링하는 테스트이므로 `--headless` 없이 실행합니다.

## Android 빌드와 배포

빌드 명령도 프로젝트 폴더에서 실행합니다.

### 1. 최초 설정

- Godot 에디터에 Android SDK와 JDK 경로 설정
- Android Build Template 설치
- `export_presets.cfg`에서 빌드 설정 확인

| 프리셋 | 출력 | 용도 |
| --- | --- | --- |
| Android | debug APK | 기기 테스트 |
| Android Release AAB | release AAB, Gradle 빌드 | Play 업로드 |

### 2. 기기 테스트

```sh
godot --headless --path . --export-debug "Android" build/android/my-simple-flash-card-debug.apk
```

Windows에서는 아래 스크립트로 빌드부터 연결된 기기에 설치하고 실행하는 과정까지 진행할 수 있습니다. 처음 사용한다면 스크립트의 `GODOT`과 `ADB` 경로를 확인하면 됩니다.

```bat
tools\deploy_android_debug.bat
```

### 3. 배포 준비

#### 버전 변경

| 파일 | 변경할 값 |
| --- | --- |
| `project.godot` | `config/version` |
| `src/debug/apply_project_settings.gd` | `application/config/version` |
| `export_presets.cfg` | 두 Android 프리셋의 `version/name`, `version/code`와 release 프리셋의 `export_path` |

버전 이름은 같은 값으로 맞추고, Play에 업로드할 `version/code`는 이전보다 높게 지정합니다. 출력 파일명에 버전이 들어 있다면 함께 바꿉니다.

#### 업로드 서명

기존 업로드 키를 사용합니다. Export 창에서 Android Release AAB의 Keystore 항목을 설정하거나 아래 환경 변수로 전달할 수 있습니다.

| 환경 변수 | 값 |
| --- | --- |
| `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` | 키스토어 경로 |
| `GODOT_ANDROID_KEYSTORE_RELEASE_USER` | 키 별칭 |
| `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` | 비밀번호 |

키스토어와 비밀번호는 저장소 밖에 보관합니다. 에디터 자격 증명 파일인 `export_credentials.cfg`도 커밋 대상에서 제외됩니다.

### 4. 배포 빌드

```sh
godot --headless --path . --export-release "Android Release AAB"
```

AAB는 release 프리셋의 `export_path`에 생성됩니다. 스토어 이미지 제작 방법은 [store-listing](../store-listing/README.md)에 있습니다.
