extends Node


func _ready() -> void:
	print("# Phase 0 ready")
	
	print("res:// = ", ProjectSettings.globalize_path("res://"))
	print("user:// = ", ProjectSettings.globalize_path("user://"))
	
	print("\n")
