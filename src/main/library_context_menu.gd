class_name LibraryContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal settings_requested
signal sort_requested(mode: String)

@onready var settings_button: Button = %OpenSettingsButton


func _ready() -> void:
	super()
	%SortNameButton.pressed.connect(func() -> void: _choose_sort("name"))
	%SortRecentButton.pressed.connect(func() -> void: _choose_sort("recent"))
	settings_button.pressed.connect(_on_settings_button_pressed)


func _on_settings_button_pressed() -> void:
	dismiss()
	settings_requested.emit()


func set_sort(mode: String) -> void:
	%SortNameButton.text = ("✓  " if mode == "name" else "     ") + "이름 오름차순"
	%SortRecentButton.text = ("✓  " if mode == "recent" else "     ") + "최근 학습순"


func _choose_sort(mode: String) -> void:
	dismiss()
	sort_requested.emit(mode)
