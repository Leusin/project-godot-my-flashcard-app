class_name AddDeckMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal create_requested
signal import_requested
signal clipboard_requested

@onready var create_button: Button = %CreateNewDeckButton
@onready var import_button: Button = %ImportMarkdownButton
@onready var clipboard_button: Button = %CreateFromClipboardButton


func _ready() -> void:
	super()
	create_button.pressed.connect(_on_create_button_pressed)
	import_button.pressed.connect(_on_import_button_pressed)
	clipboard_button.pressed.connect(_on_clipboard_button_pressed)


func _on_create_button_pressed() -> void:
	dismiss()
	create_requested.emit()


func _on_import_button_pressed() -> void:
	dismiss()
	import_requested.emit()


func _on_clipboard_button_pressed() -> void:
	dismiss()
	clipboard_requested.emit()
