class_name LibraryContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal settings_requested

@onready var settings_button: Button = %OpenSettingsButton


func _ready() -> void:
	super()
	settings_button.pressed.connect(_on_settings_button_pressed)


func _on_settings_button_pressed() -> void:
	dismiss()
	settings_requested.emit()
