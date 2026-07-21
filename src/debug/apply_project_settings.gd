extends SceneTree

## 프로젝트 설정을 project.godot에 일괄 적용한다. `./apply_settings.ps1`로 실행.
## project.godot을 손으로 편집하는 대신 여기에 선언한다 — 값의 근거가 주석으로 남고, 깨져도 복구된다.
##
## 관리하지 않는 것: config/features의 "C#". 비-.NET 에디터(Steam 표준 빌드)로 프로젝트를 열면
## 이 항목이 지워지는데, 그때는 project.godot을 직접 되돌려야 한다.

# ── 애플리케이션 / 윈도우 ────────────────────────────────────────────
const PROJECT_SETTINGS: Dictionary = {
	"application/config/name": "MyFlashCard",
	"application/config/version": "0.1.0",
	"application/run/main_scene": "res://src/study.tscn",

	# 최종 타깃이 Android라 모바일 세로 해상도를 기준으로 잡는다
	"display/window/size/viewport_width": 720,
	"display/window/size/viewport_height": 1280,
	"display/window/stretch/mode": "canvas_items",
	# expand = 화면을 해상도만큼 다 쓴다 (레터박스 없음). 뷰포트 비율이 함께 변하지만,
	# 개별 요소의 비율은 각자 지키므로 여기서 막지 않는다.
	"display/window/stretch/aspect": "expand",
	"display/window/handheld/orientation": 1,

	# 실제 창 크기(window_*_override)는 여기서 관리하지 않는다.
	# 테스트하며 자주 바꾸는 값이라, 스크립트가 되돌려놓으면 방해가 된다.
	# 필요하면 에디터 Project Settings > Display > Window > Size에서 직접 조정한다.

	# 카드 내용이 대부분 한글이라 기본 폰트로는 렌더링이 아쉽다
	"gui/theme/custom_font": "res://assets/fonts/PretendardVariable.ttf",
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
