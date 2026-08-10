class_name StudyGestureSurface
extends PanelContainer

signal swiped(direction: int)

@export var animations_enabled := true

enum DragAxis {
	UNDECIDED,
	HORIZONTAL,
	VERTICAL,
}

const AGAIN := -1
const GOOD := 1
const DRAG_THRESHOLD := 90.0
const DIRECTION_LOCK_DISTANCE := 14.0
const HORIZONTAL_DOMINANCE := 1.15
const PREVIEW_FOLLOW_RATIO := 0.65
const PREVIEW_MAX_OFFSET_RATIO := 0.42
const PREVIEW_MAX_ROTATION_DEGREES := 8.0
const EXIT_ROTATION_DEGREES := 15.0
const EXIT_DURATION := 0.2
const ENTER_OFFSET := 54.0
const ENTER_ROTATION_DEGREES := 3.0
const ENTER_DURATION := 0.14
const FLIP_LIFT_DURATION := 0.08
const FLIP_HALF_DURATION := 0.18
const FLIP_OPEN_DURATION := 0.21
const FLIP_SETTLE_DURATION := 0.08
const FLIP_LIFT_OFFSET := 7.0
const FLIP_EDGE_SCALE_X := 0.035
const FLIP_PEAK_SCALE_Y := 1.035
const FLIP_OVERSHOOT_SCALE_X := 1.025

@onready var reveal_button: Button = $"../RevealButton"
@onready var again_button: Button = $"../Actions/AgainButton"
@onready var good_button: Button = $"../Actions/GoodButton"

var input_enabled := true:
	set(value):
		input_enabled = value
		if not value:
			cancel_drag()

var _dragging := false
var _pointer_id := -1
var _drag_axis := DragAxis.UNDECIDED
var _drag_start := Vector2.ZERO
var _drag_position := Vector2.ZERO
var _rest_position := Vector2.ZERO
var _animating := false
var _motion_tween: Tween


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


func _input(event: InputEvent) -> void:
	if not input_enabled or _animating or not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


static func drag_direction(delta: Vector2) -> int:
	if absf(delta.x) < DRAG_THRESHOLD:
		return 0
	if absf(delta.x) <= absf(delta.y) * HORIZONTAL_DOMINANCE:
		return 0
	return GOOD if delta.x > 0.0 else AGAIN


func commit(direction: int) -> void:
	if (
		not input_enabled
		or _animating
		or (direction != AGAIN and direction != GOOD)
	):
		return

	_rest_position = position
	pivot_offset = size * 0.5
	if not animations_enabled:
		swiped.emit(direction)
		return
	_play_swipe_exit(direction)


func flip(midpoint: Callable) -> void:
	if not input_enabled or _animating or not midpoint.is_valid():
		return
	if not animations_enabled:
		midpoint.call()
		return

	_animating = true
	_rest_position = position
	pivot_offset = size * 0.5
	_set_animation_controls_disabled(true)
	_motion_tween = create_tween()
	_motion_tween.tween_property(
		self,
		"position",
		_rest_position + Vector2(0.0, -FLIP_LIFT_OFFSET),
		FLIP_LIFT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"scale",
		Vector2(1.015, 1.015),
		FLIP_LIFT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		self,
		"scale",
		Vector2(FLIP_EDGE_SCALE_X, FLIP_PEAK_SCALE_Y),
		FLIP_HALF_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_motion_tween.parallel().tween_property(
		self,
		"modulate",
		Color(0.76, 0.76, 0.76, 1.0),
		FLIP_HALF_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_motion_tween.finished.connect(_on_flip_midpoint.bind(midpoint))


func cancel_drag() -> void:
	if _motion_tween != null:
		_motion_tween.kill()
		_motion_tween = null
	_reset_visual()
	_dragging = false
	_animating = false
	_pointer_id = -1
	_drag_axis = DragAxis.UNDECIDED
	_set_animation_controls_disabled(false)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if not _dragging and _can_start_drag(event.position):
			_begin_drag(event.position, event.index)
		return

	if _dragging and _pointer_id == event.index:
		_finish_drag(event.position)


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if _dragging and _pointer_id == event.index:
		_update_drag(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if not _dragging and _can_start_drag(event.position):
			_begin_drag(event.position, -1)
		return

	if _dragging and _pointer_id == -1:
		_finish_drag(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _dragging and _pointer_id == -1:
		_update_drag(event.position)


func _can_start_drag(at_position: Vector2) -> bool:
	return get_global_rect().has_point(at_position)


func _begin_drag(at_position: Vector2, pointer_id: int) -> void:
	_dragging = true
	_pointer_id = pointer_id
	_drag_axis = DragAxis.UNDECIDED
	_drag_start = at_position
	_drag_position = at_position
	_rest_position = position
	pivot_offset = size * 0.5


func _update_drag(at_position: Vector2) -> void:
	_drag_position = at_position
	var delta := _drag_position - _drag_start
	if _drag_axis == DragAxis.UNDECIDED and delta.length() >= DIRECTION_LOCK_DISTANCE:
		_drag_axis = (
			DragAxis.HORIZONTAL
			if absf(delta.x) > absf(delta.y) * HORIZONTAL_DOMINANCE
			else DragAxis.VERTICAL
		)

	if _drag_axis == DragAxis.HORIZONTAL:
		_show_horizontal_preview(delta.x)
	elif _drag_axis == DragAxis.VERTICAL:
		_reset_visual()


func _finish_drag(at_position: Vector2) -> void:
	_drag_position = at_position
	var delta := _drag_position - _drag_start
	var direction := drag_direction(delta) if _drag_axis == DragAxis.HORIZONTAL else 0
	_dragging = false
	_pointer_id = -1
	_drag_axis = DragAxis.UNDECIDED
	if direction == 0:
		_reset_visual()
		return
	if animations_enabled:
		_play_swipe_exit(direction)
	else:
		_reset_visual()
		swiped.emit(direction)


func _show_horizontal_preview(horizontal_delta: float) -> void:
	var max_offset := size.x * PREVIEW_MAX_OFFSET_RATIO
	var preview_offset := clampf(
		horizontal_delta * PREVIEW_FOLLOW_RATIO,
		-max_offset,
		max_offset
	)
	position = _rest_position + Vector2(preview_offset, 0.0)
	var width := maxf(size.x, 1.0)
	var rotation_degrees := clampf(
		horizontal_delta / width * PREVIEW_MAX_ROTATION_DEGREES * 2.0,
		-PREVIEW_MAX_ROTATION_DEGREES,
		PREVIEW_MAX_ROTATION_DEGREES
	)
	rotation = deg_to_rad(rotation_degrees)


func _play_swipe_exit(direction: int) -> void:
	_animating = true
	_set_animation_controls_disabled(true)
	var viewport_width := get_viewport_rect().size.x
	var exit_distance := maxf(size.x, viewport_width) + size.x * 0.25
	var target_position := _rest_position + Vector2(direction * exit_distance, 0.0)
	_motion_tween = create_tween()
	_motion_tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(self, "position", target_position, EXIT_DURATION)
	_motion_tween.tween_property(
		self,
		"rotation",
		deg_to_rad(direction * EXIT_ROTATION_DEGREES),
		EXIT_DURATION
	)
	_motion_tween.tween_property(self, "modulate:a", 0.15, EXIT_DURATION)
	_motion_tween.finished.connect(_on_swipe_exit_finished.bind(direction))


func _on_swipe_exit_finished(direction: int) -> void:
	_motion_tween = null
	swiped.emit(direction)
	_set_animation_controls_disabled(false)
	if not is_visible_in_tree():
		_reset_visual()
		_animating = false
		return

	position = _rest_position + Vector2(-direction * ENTER_OFFSET, 0.0)
	rotation = deg_to_rad(-direction * ENTER_ROTATION_DEGREES)
	scale = Vector2(0.985, 0.985)
	modulate.a = 0.55
	_motion_tween = create_tween()
	_motion_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "position", _rest_position, ENTER_DURATION)
	_motion_tween.tween_property(self, "rotation", 0.0, ENTER_DURATION)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, ENTER_DURATION)
	_motion_tween.tween_property(self, "modulate:a", 1.0, ENTER_DURATION)
	_motion_tween.finished.connect(_on_swipe_enter_finished)


func _on_swipe_enter_finished() -> void:
	_motion_tween = null
	_animating = false


func _on_flip_midpoint(midpoint: Callable) -> void:
	_motion_tween = null
	midpoint.call()
	_motion_tween = create_tween()
	_motion_tween.tween_property(
		self,
		"scale",
		Vector2(FLIP_OVERSHOOT_SCALE_X, 1.01),
		FLIP_OPEN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"position",
		_rest_position,
		FLIP_OPEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"modulate",
		Color.WHITE,
		FLIP_OPEN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		FLIP_SETTLE_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.finished.connect(_on_flip_finished)


func _on_flip_finished() -> void:
	_motion_tween = null
	scale = Vector2.ONE
	_animating = false
	_set_animation_controls_disabled(false)


func _set_animation_controls_disabled(disabled: bool) -> void:
	reveal_button.disabled = disabled
	if disabled:
		again_button.disabled = true
		good_button.disabled = true
	elif input_enabled:
		again_button.disabled = false
		good_button.disabled = false


func _reset_visual() -> void:
	position = _rest_position
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		cancel_drag()
