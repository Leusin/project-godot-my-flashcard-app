class_name KeyboardAvoider
extends Control

@export var keyboard_padding := 24.0
@export var top_padding := 16.0
# 지정하면 포커스된 입력창 대신 이 노드 전체를 키보드 위로 올린다 (하단 시트용).
@export var avoid_target: NodePath


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		position = Vector2.ZERO
		return
	_apply_shift(_desired_shift(), delta)


func _desired_shift() -> float:
	var focus_owner := get_viewport().gui_get_focus_owner() as Control
	if (
		focus_owner == null
		or not is_ancestor_of(focus_owner)
		or (focus_owner is not LineEdit and focus_owner is not TextEdit)
	):
		return 0.0

	var keyboard_height := DisplayServer.virtual_keyboard_get_height()
	if keyboard_height <= 0:
		return 0.0

	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	var keyboard_height_in_viewport := scaled_keyboard_height(
		keyboard_height,
		window_size,
		viewport_size
	)
	var tracked := focus_owner
	if not avoid_target.is_empty():
		var target_control := get_node_or_null(avoid_target) as Control
		if target_control != null:
			tracked = target_control
	var current_offset := position.y
	var tracked_rect := tracked.get_global_rect()
	return required_shift(
		tracked_rect.end.y - current_offset,
		tracked_rect.position.y - current_offset,
		keyboard_height_in_viewport,
		viewport_size.y,
		keyboard_padding,
		top_padding
	)


func _apply_shift(shift: float, delta: float) -> void:
	var target_y := -shift
	# OS 키보드 등장 높이가 몇 frame 늦게 잡히므로 짧은 따라잡기로 스냅을 감춘다.
	if absf(target_y - position.y) < 1.0:
		position = Vector2(0.0, target_y)
		return
	position = Vector2(0.0, lerpf(position.y, target_y, minf(1.0, delta * 14.0)))


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
