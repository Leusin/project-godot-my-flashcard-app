class_name LibraryContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal settings_requested
signal sort_requested(mode: String)

var sort_name_button: Button
var sort_recent_button: Button
var settings_button: Button


func _ready() -> void:
	super()
	sort_name_button = add_item("SortNameButton", "이름 오름차순")
	sort_recent_button = add_item("SortRecentButton", "최근 학습순")
	add_separator()
	settings_button = add_item("OpenSettingsButton", "설정")
	%SortNameButton.pressed.connect(func() -> void: _choose_sort("name"))
	%SortRecentButton.pressed.connect(func() -> void: _choose_sort("recent"))
	settings_button.pressed.connect(_on_settings_button_pressed)


func _on_settings_button_pressed() -> void:
	dismiss()
	settings_requested.emit()


func set_sort(mode: String) -> void:
	set_radio(sort_name_button, mode == "name")
	set_radio(sort_recent_button, mode == "recent")


func _choose_sort(mode: String) -> void:
	dismiss()
	sort_requested.emit(mode)
