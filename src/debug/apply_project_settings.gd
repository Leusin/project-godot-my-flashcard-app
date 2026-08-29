extends SceneTree

## 프로젝트 설정을 project.godot에 일괄 적용한다. `./apply_settings.ps1`로 실행.
## project.godot을 손으로 편집하는 대신 여기에 선언한다 — 값의 근거가 주석으로 남고, 깨져도 복구된다.

# ── 애플리케이션 / 윈도우 ────────────────────────────────────────────
const PROJECT_SETTINGS: Dictionary = {
	"application/config/name": "My Simple Flash Card",
	"application/config/version": "0.10.2",
	# 진입점은 화면 전환과 앱 상태를 조정하는 Main이다.
	"application/run/main_scene": "res://src/main/main.tscn",

	# 부트 스플래시: Godot 기본 로고 대신 브랜드 심볼. 배경을 default_clear_color와
	# 같은 아이보리로 맞춰 시스템 스플래시 → 부트 스플래시 → 첫 프레임 사이 깜빡임을 없앤다.
	"application/boot_splash/bg_color": Color(0.969, 0.965, 0.949, 1.0),
	"application/boot_splash/image": "res://assets/branding/boot_splash_360.png",
	# 0 = Disabled: 원본 픽셀 크기로 중앙 표시. 기본값 Keep은 여백 포함 이미지를
	# 화면 크기까지 확대해 심볼이 과하게 커진다.
	"application/boot_splash/stretch_mode": 0,

	# 최종 타깃이 Android라 모바일 세로 해상도를 기준으로 잡는다
	"display/window/size/viewport_width": 720,
	"display/window/size/viewport_height": 1280,
	"display/window/stretch/mode": "canvas_items",
	# expand = 화면을 해상도만큼 다 쓴다 (레터박스 없음). 뷰포트 비율이 함께 변하지만,
	# 개별 요소의 비율은 각자 지키므로 여기서 막지 않는다.
	"display/window/stretch/aspect": "expand",
	"display/window/handheld/orientation": 1,

	# 디자인 해상도는 720×1280(모바일 세로)이지만, 데스크톱 창은 그대로 띄우면 화면보다 크다.
	# 창만 작게(9:16 유지) 띄우고 내용은 stretch로 축소한다. 화면이 더 작으면 이 값을 줄인다.
	"display/window/size/window_width_override": 375,
	"display/window/size/window_height_override": 667,

	# 카드 내용이 대부분 한글이라 기본 폰트로는 렌더링이 아쉽다
	"gui/theme/custom_font": "res://assets/fonts/PretendardVariable.ttf",

	# 창 배경. 나머지 색은 main_theme.tres와 각 씬의 style override가 정한다.
	# 컨트롤이 덮지 않는 영역이라 프로젝트 설정에 둔다.
	"rendering/environment/defaults/default_clear_color": Color(0.969, 0.965, 0.949, 1.0),
}

# ── 입력맵 ───────────────────────────────────────────────────────────
# 방향은 사실만 담는다. Again/Good 같은 해석은 여기서 하지 않는다 (CONVENTIONS 3번).
# v0.1은 버튼만 쓰고, 실제 연결은 v1.0(스와이프/방향키)에서 한다.
const INPUT_ACTIONS: Dictionary = {
	"input_left": KEY_LEFT,
	"input_right": KEY_RIGHT,
	"input_up": KEY_UP,
	"input_down": KEY_DOWN,
}

const INPUT_DEADZONE: float = 0.2


func _initialize() -> void:
	_apply_project_settings()
	_apply_input_actions()

	var error: Error = ProjectSettings.save()
	if error == OK:
		print("[apply_project_settings] 완료 — project.godot 저장됨.")
		quit(0)
	else:
		push_error("[apply_project_settings] 저장 실패. Error: " + str(error))
		quit(1)


func _apply_project_settings() -> void:
	for path: String in PROJECT_SETTINGS:
		var value: Variant = PROJECT_SETTINGS[path]
		var before: Variant = ProjectSettings.get_setting(path)
		ProjectSettings.set_setting(path, value)
		var mark: String = "  " if before == value else "→ "
		print("%s%s = %s" % [mark, path, str(value)])


func _apply_input_actions() -> void:
	for action: String in INPUT_ACTIONS:
		var event := InputEventKey.new()
		event.physical_keycode = INPUT_ACTIONS[action]
		ProjectSettings.set_setting("input/" + action, {
			"deadzone": INPUT_DEADZONE,
			"events": [event],
		})
		print("  input/%s = %s" % [action, OS.get_keycode_string(INPUT_ACTIONS[action])])
