extends Node


func _ready() -> void:
	print("Phase 0 ready")
	print("res:// = ", ProjectSettings.globalize_path("res://"))
	print("user:// = ", ProjectSettings.globalize_path("user://"))
	# get_tree().quit() # 출력 결과를 읽기 위해 임시로 비활성화 함.
