class_name CardContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal edit_requested
signal delete_requested

var edit_button: Button
var delete_button: Button


func _ready() -> void:
	super()
	edit_button = add_item("EditCardActionButton", "수정하기")
	delete_button = add_item("DeleteCardActionButton", "카드 삭제")
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
