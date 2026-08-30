class_name AnchoredPopupMenu
extends Control

const VIEWPORT_MARGIN := 12.0
const ANCHOR_GAP := 4.0

@export_node_path("PanelContainer") var menu_panel_path: NodePath
@export_node_path("Button") var dismiss_button_path: NodePath

@onready var menu_panel: PanelContainer = get_node(menu_panel_path)
@onready var dismiss_button: Button = get_node(dismiss_button_path)


func _ready() -> void:
	dismiss_button.pressed.connect(dismiss)


func open_at(anchor: Control) -> void:
	show()
	menu_panel.reset_size()
	_position_at(anchor)


func dismiss() -> void:
	hide()


func _position_at(anchor: Control) -> void:
	var anchor_rect := _control_rect_in_overlay(anchor)
	var menu_size := menu_panel.get_combined_minimum_size()
	menu_panel.size = menu_size
	var menu_position := Vector2(
		anchor_rect.end.x - menu_size.x,
		anchor_rect.end.y + ANCHOR_GAP
	)
	menu_position.x = clampf(
		menu_position.x,
		VIEWPORT_MARGIN,
		size.x - menu_size.x - VIEWPORT_MARGIN
	)
	if menu_position.y + menu_size.y > size.y - VIEWPORT_MARGIN:
		menu_position.y = anchor_rect.position.y - menu_size.y - ANCHOR_GAP
	menu_position.y = clampf(
		menu_position.y,
		VIEWPORT_MARGIN,
		size.y - menu_size.y - VIEWPORT_MARGIN
	)
	menu_panel.position = menu_position


func _control_rect_in_overlay(control: Control) -> Rect2:
	var control_to_overlay := (
		get_global_transform().affine_inverse()
		* control.get_global_transform()
	)
	var local_position := control_to_overlay * Vector2.ZERO
	var end := control_to_overlay * control.size
	return Rect2(local_position, end - local_position)
