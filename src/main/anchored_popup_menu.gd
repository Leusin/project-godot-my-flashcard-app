class_name AnchoredPopupMenu
extends Control

const VIEWPORT_MARGIN := 12.0
const ANCHOR_GAP := 4.0

@export_node_path("PanelContainer") var menu_panel_path: NodePath
@export_node_path("Button") var dismiss_button_path: NodePath

var _anchor: Control

@onready var menu_panel: PanelContainer = get_node(menu_panel_path)
@onready var dismiss_button: Button = get_node(dismiss_button_path)


func _ready() -> void:
	dismiss_button.pressed.connect(dismiss)
	RenderingServer.frame_pre_draw.connect(_refresh_position)


func add_item(item_name: String, caption: String) -> Button:
	var button := $ItemTemplate.duplicate() as Button
	button.name = item_name
	button.text = caption
	$MenuPanel/Margin/Content.add_child(button)
	button.owner = self
	button.unique_name_in_owner = true
	button.show()
	return button


func add_separator() -> void:
	var separator := $SeparatorTemplate.duplicate() as HSeparator
	$MenuPanel/Margin/Content.add_child(separator)
	separator.show()


func set_radio(button: Button, selected: bool) -> void:
	button.icon = get_theme_icon("radio_checked" if selected else "radio_unchecked", "PopupMenu")


func open_at(anchor: Control) -> void:
	_anchor = anchor
	show()
	menu_panel.reset_size()
	_position_at(anchor)


func dismiss() -> void:
	_anchor = null
	hide()


# 컨테이너 배치가 끝난 뒤 그리기 직전에 기준 버튼을 따라간다.
func _refresh_position() -> void:
	if not is_visible_in_tree():
		return
	if not is_instance_valid(_anchor) or not _anchor.is_visible_in_tree():
		dismiss()
		return
	_position_at(_anchor)


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
		maxf(VIEWPORT_MARGIN, size.x - menu_size.x - VIEWPORT_MARGIN)
	)
	if menu_position.y + menu_size.y > size.y - VIEWPORT_MARGIN:
		menu_position.y = anchor_rect.position.y - menu_size.y - ANCHOR_GAP
	menu_position.y = clampf(
		menu_position.y,
		VIEWPORT_MARGIN,
		maxf(VIEWPORT_MARGIN, size.y - menu_size.y - VIEWPORT_MARGIN)
	)
	menu_panel.position = menu_position


func _control_rect_in_overlay(control: Control) -> Rect2:
	var control_to_overlay := (
		get_global_transform_with_canvas().affine_inverse()
		* control.get_global_transform_with_canvas()
	)
	var local_position := control_to_overlay * Vector2.ZERO
	var end := control_to_overlay * control.size
	return Rect2(local_position, end - local_position)
