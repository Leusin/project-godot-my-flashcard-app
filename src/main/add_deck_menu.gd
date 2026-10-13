class_name AddDeckMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal create_requested
signal import_requested
signal clipboard_requested

var create_button: Button
var import_button: Button
var clipboard_button: Button


func _ready() -> void:
	super()
	create_button = add_item("CreateNewDeckButton", "새 덱 만들기")
	import_button = add_item("ImportMarkdownButton", "Markdown 가져오기")
	clipboard_button = add_item("CreateFromClipboardButton", "클립보드에서 만들기")
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
