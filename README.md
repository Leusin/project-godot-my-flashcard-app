# My Simple Flash Card

Markdown으로 카드를 작성하고 버튼과 스와이프로 복습하는 모바일 중심 앱이다. Godot 4.7 / GDScript를 사용하며 .NET SDK는 필요하지 않다.

| 문서 | 내용 |
| --- | --- |
| [DESIGN](docs/DESIGN.md) | 현재 제품 동작과 데이터 규칙 |
| [CODE_GUIDE](docs/CODE_GUIDE.md) | 코드 책임과 기능별 수정 위치 |
| [CONVENTIONS](docs/CONVENTIONS.md) | 구현 규칙 |
| [DEVLOG](docs/DEVLOG.md) | 재사용할 시행착오와 판단 근거 |
| [MEMORY](docs/MEMORY.md) | 프로젝트 동기와 장기 방향 |
| [GDScript 전환 기록](docs/MIGRATION_GDSCRIPT.md) | 완료된 언어 전환과 호환성 계약 |

## 실행과 검증

일반 Godot 에디터에서 `project.godot`을 열고 F5로 실행한다. 진입점은 `src/main/main.tscn`이다. 아래 `godot`은 설치한 실행 파일의 경로로 바꿔도 된다.

```sh
# 전역 클래스와 리소스 등록
godot --headless --path . --import
# core·storage·앱 smoke test
godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

로그의 `RESULT: N checks, 0 failures`를 확인한다. 테스트 수 자체는 고정하지 않는다.

포인터 검증은 실제 앱 데이터와 분리한 프로젝트 복사본에서 `application/config/name`을 별도 이름으로 바꾸고 실행한다. 렌더링 프레임을 기다리므로 아래 명령에는 `--headless`를 붙이지 않는다.

```sh
godot --path . --script res://tests/ui_interaction.gd
# 캡처도 저장하려면
godot --path . --script res://tests/ui_interaction.gd -- --capture
```

## Android 빌드

저장소에 설정된 버전은 `0.10.3` / versionCode `7`, 패키지는 `com.leusin.mysimpleflashcard`다. 실제 Play 배포 상태는 Console에서 확인한다.

| 프리셋 | 용도 |
| --- | --- |
| Android | 기기 확인용 debug APK |
| Android Release AAB | Play 업로드용 release AAB |

에디터에 Android SDK/JDK 경로를 설정하고 Android Build Template을 설치한다. AAB는 Gradle 빌드를 사용한다. SDK 값은 `export_presets.cfg`가 기준이며, 제출 시점의 Play 요구사항은 별도로 확인한다.

```sh
godot --headless --path . --export-debug "Android" build/android/my-simple-flash-card-debug.apk
godot --headless --path . --export-release "Android Release AAB" build/android/my-simple-flash-card-0.10.3.aab
```

Windows에서는 `tools/deploy_android_debug.bat`로 debug export·기기 설치·실행을 연결할 수 있다. 스토어 이미지 재생성은 [store-listing](store-listing/README.md)을 참고한다.

### 업로드 서명

기존 업로드 키를 사용한다. 키스토어와 비밀번호는 저장소 밖에 보관하고 커밋하지 않는다. Export 창의 Android Release AAB → Keystore에서 설정하거나 아래 환경 변수로 주입한다.

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

에디터 자격 증명 파일 `export_credentials.cfg`는 gitignore 대상이다. 새 키 생성이나 분실 키 교체는 일반 버전 빌드와 별도 작업이다.

### 버전 변경

1. `project.godot`의 `config/version`과 `src/debug/apply_project_settings.gd`를 같은 값으로 바꾼다.
2. `export_presets.cfg`의 두 Android 프리셋 `version/name`을 맞추고, 업로드할 `version/code`를 이전보다 높인다.
3. release 프리셋의 `export_path`와 이 문서의 버전·예시 파일명을 맞춘다.

프로젝트 설정을 바꿀 때는 `apply_project_settings.gd`와 실제 `project.godot`을 함께 확인한다. 스크립트에서 제거한 설정도 기존 파일에는 남아 있을 수 있다.
