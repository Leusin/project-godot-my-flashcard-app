# My Simple Flash Card

Markdown으로 카드를 작성하고, 스와이프와 버튼으로 복습하는 모바일 중심 플래시카드 앱. Google Play 테스트 배포 버전은 0.9.2이다 (패키지 `com.leusin.mysimpleflashcard`).

- Engine: Godot 4.7.1
- Language: GDScript
- Data: Markdown (`.md`), JSON
- Main scene: `src/main/main.tscn`
- 기획서: [docs/DESIGN.md](docs/DESIGN.md)
- 코드 가이드: [docs/CODE_GUIDE.md](docs/CODE_GUIDE.md)
- GDScript 전환 기록: [docs/MIGRATION_GDSCRIPT.md](docs/MIGRATION_GDSCRIPT.md)

## 실행과 테스트

일반 Godot 에디터에서 프로젝트를 열고 F6가 아니라 F5로 Main Scene을 실행한다.

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --log-file .godot/latest-test.log res://tests/tests.tscn
```

별도 .NET SDK나 `dotnet build`는 필요하지 않다.

## Android 배포 (Google Play)

앱 이름과 버전의 원본은 `project.godot`(+ [src/debug/apply_project_settings.gd](src/debug/apply_project_settings.gd))와 `export_presets.cfg`다.

| 프리셋 | 용도 | 출력 |
| --- | --- | --- |
| Android | 개발용 debug APK (기기 설치 테스트) | `build/android/my-simple-flash-card-debug.apk` |
| Android Release AAB | Play 업로드용 release AAB, target SDK 36 | `build/android/my-simple-flash-card-0.9.2.aab` |

- 앱 이름 **My Simple Flash Card**, 패키지 `com.leusin.mysimpleflashcard`, versionName `0.9.2`, versionCode `3`.
- `package/unique_name`은 첫 Play Console 업로드 후 바꿀 수 없다. 업로드 전에 반드시 최종 확인한다.
- target SDK 36은 2026-08-31부터 Play 신규 제출에 필요한 기준이다.
- AAB export는 Gradle 빌드를 쓴다. Godot Editor에서 **Project > Install Android Build Template**을 한 번 실행하고, Editor Settings에 Android SDK/JDK 경로가 설정되어 있어야 한다.

### Release 키스토어 (업로드 키)

키스토어 파일과 비밀번호는 절대 저장소에 커밋하지 않는다. Editor의 Export 창에 입력한 값은 `export_credentials.cfg`에 저장되며 이 파일은 `.gitignore`에 있다.

업로드 키 생성 (저장소 밖 경로에서 한 번만):

```powershell
keytool -genkeypair -v -keystore my-simple-flash-card-upload.jks -alias my-simple-flash-card-upload -keyalg RSA -keysize 2048 -validity 10000
```

- 보관: 키스토어는 저장소 밖(예: 클라우드 드라이브 + 로컬 백업 2곳), 비밀번호는 패스워드 매니저에 둔다. Play App Signing 사용 시 이 키는 업로드 키이므로 분실해도 Play Console에서 재설정할 수 있지만, 백업이 원칙이다.
- Editor 입력: Export 창 → Android Release AAB 프리셋 → Keystore 섹션의 Release / Release User / Release Password.
- CLI/CI 주입: 프리셋 값 대신 환경 변수를 쓸 수 있다.
  - `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`
  - debug 서명용: `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER`, `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`

### CLI export

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --export-debug "Android" build/android/my-simple-flash-card-debug.apk
& $godot --headless --path . --export-release "Android Release AAB" build/android/my-simple-flash-card-0.9.2.aab
```

debug 빌드는 `tools\deploy_android_debug.bat` 한 번 실행으로 export, 연결된 폰 설치, 앱 실행까지 끝낼 수 있다.

### 버전 올릴 때 함께 바꾸는 곳

1. `project.godot`의 `config/version`과 `apply_project_settings.gd` (같은 값 유지)
2. `export_presets.cfg`의 두 Android 프리셋 `version/name`, 그리고 `version/code`는 Play 업로드마다 +1
3. Android Release AAB 프리셋의 `export_path` 파일명 (`…-<버전>.aab`)
