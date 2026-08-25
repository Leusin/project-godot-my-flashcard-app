class_name KeyboardAvoider
extends Control

@export var keyboard_padding := 24.0
@export var top_padding := 16.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		position = Vector2.ZERO
		return

	var focus_owner := get_viewport().gui_get_focus_owner() as Control
	if (
		focus_owner == null
		or not is_ancestor_of(focus_owner)
		or (focus_owner is not LineEdit and focus_owner is not TextEdit)
	):
		position = Vector2.ZERO
		return

	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	var keyboard_height := DisplayServer.virtual_keyboard_get_height()
	if keyboard_height <= 0:
		position = Vector2.ZERO
		return

	var keyboard_height_in_viewport := scaled_keyboard_height(
		keyboard_height,
		window_size,
		viewport_size
	)
	var current_offset := position.y
	var focused_rect := focus_owner.get_global_rect()
	var focused_bottom := focused_rect.end.y - current_offset
	var focused_top := focused_rect.position.y - current_offset
	var shift := required_shift(
		focused_bottom,
		focused_top,
		keyboard_height_in_viewport,
		viewport_size.y,
		keyboard_padding,
		top_padding
	)
	position = Vector2(0.0, -shift)


static func scaled_keyboard_height(
	keyboard_height: int,
	window_size: Vector2i,
	viewport_size: Vector2
) -> float:
	if keyboard_height <= 0 or window_size.y <= 0 or viewport_size.y <= 0.0:
		return 0.0
	return float(keyboard_height) * viewport_size.y / float(window_size.y)


static func required_shift(
	focused_bottom: float,
	focused_top: float,
	keyboard_height: float,
	viewport_height: float,
	bottom_padding: float = 24.0,
	minimum_top: float = 16.0
) -> float:
	if keyboard_height <= 0.0 or viewport_height <= 0.0:
		return 0.0
	var visible_bottom := viewport_height - keyboard_height - bottom_padding
	var desired_shift := maxf(focused_bottom - visible_bottom, 0.0)
	var maximum_shift := maxf(focused_top - minimum_top, 0.0)
	return minf(desired_shift, maximum_shift)
