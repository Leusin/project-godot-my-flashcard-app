class_name CardContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal edit_requested
signal delete_requested

@onready var edit_button: Button = %EditCardActionButton
@onready var delete_button: Button = %DeleteCardActionButton


func _ready() -> void:
	super()
	edit_button.pressed.connect(_on_edit_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)


func open_for(anchor: Control, delete_visible: bool) -> void:
	delete_button.visible = delete_visible
	move_to_front()
	open_at(anchor)


func _on_edit_button_pressed() -> void:
	dismiss()
	edit_requested.emit()


func _on_delete_button_pressed() -> void:
	dismiss()
	delete_requested.emit()
