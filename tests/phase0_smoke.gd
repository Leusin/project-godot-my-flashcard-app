extends TestCase

# Phase 0: 실행 환경 확인. 검사 대상이 아니라 경로 출력만 한다.


func run_tests() -> void:
	print("res:// = ", ProjectSettings.globalize_path("res://"))
	print("user:// = ", ProjectSettings.globalize_path("user://"))
