class_name StudyGestureSurface
extends PanelContainer

signal swiped(direction: int)
signal tapped
signal judgment_threshold_crossed(direction: int)

@export var animations_enabled := true
@export var haptics_enabled := true
@export var action_active_style: StyleBoxFlat
@export var again_active_color := Color.BLACK
@export var good_active_color := Color.BLACK

enum DragAxis {
	UNDECIDED,
	HORIZONTAL,
	VERTICAL_NAVIGATION,
	VERTICAL_SCROLL,
}

const AGAIN := -1
const GOOD := 1
const PREVIOUS := -2
const SKIP := 2
const TAP_MAX_DISTANCE := 12.0
const DRAG_THRESHOLD := 90.0
const VERTICAL_DRAG_THRESHOLD := 110.0
const DIRECTION_LOCK_DISTANCE := 14.0
const HORIZONTAL_DOMINANCE := 1.15
const VERTICAL_DOMINANCE := 1.15
const PREVIEW_FOLLOW_RATIO := 0.65
const PREVIEW_MAX_OFFSET_RATIO := 0.42
const PREVIEW_MAX_ROTATION_DEGREES := 8.0
const VERTICAL_PREVIEW_FOLLOW_RATIO := 0.35
const VERTICAL_PREVIEW_MAX_OFFSET_RATIO := 0.16
const EXIT_ROTATION_DEGREES := 15.0
const EXIT_DURATION := 0.2
const ENTER_OVERSHOOT_DISTANCE := 12.0
const ENTER_ROTATION_DEGREES := 4.0
const ENTER_DURATION := 0.28
const ENTER_SETTLE_DURATION := 0.08
const FLIP_LIFT_DURATION := 0.06
const FLIP_HALF_DURATION := 0.14
const FLIP_OPEN_DURATION := 0.16
const FLIP_SETTLE_DURATION := 0.06
const FLIP_LIFT_OFFSET := 7.0
const FLIP_EDGE_SCALE_X := 0.035
const FLIP_PEAK_SCALE_Y := 1.035
const FLIP_OVERSHOOT_SCALE_X := 1.025
const HINT_ACTIVE_COLOR := Color(0.0, 0.0, 0.0, 0.9)
const HINT_MIN_SCALE := 0.88
const HINT_MIN_ALPHA := 0.32
const HINT_PULL_PADDING := 24.0
const HINT_DRAG_DISTANCE_MULTIPLIER := 3.6
const HINT_PULL_EXPONENT := 1.6
const HINT_REVEAL_START := 0.12
const HINT_COMPLETE_DURATION := 0.4
const CARD_ASPECT_RATIO := 2.0 / 3.0
const HAPTIC_DURATION_MS := 15
const HAPTIC_AMPLITUDE := 0.25

@onready var card_slot: Control = get_parent() as Control
@onready var card_stage: Control = card_slot.get_parent() as Control
@onready var again_button: Button = $"../../../Actions/AgainButton"
@onready var good_button: Button = $"../../../Actions/GoodButton"
@onready var question_scroll: ScrollContainer = $CardMargin/CardContent/QuestionScroll
@onready var answer_scroll: ScrollContainer = $CardMargin/CardContent/AnswerScroll
@onready var skip_hint: Label = $"../../GestureHints/SkipHint"
@onready var previous_hint: Label = $"../../GestureHints/PreviousHint"

var input_enabled := true:
	set(value):
		input_enabled = value
		if not value and _dragging:
			cancel_drag()
		_set_animation_controls_disabled(_animating)
var previous_enabled := false

var _dragging := false
var _pointer_id := -1
var _drag_axis := DragAxis.UNDECIDED
var _drag_start := Vector2.ZERO
var _drag_position := Vector2.ZERO
var _animating := false
var _motion_tween: Tween
var _active_hint_action := 0
var _hint_rest_positions: Dictionary = {}
var _hint_motion_tween: Tween
var _haptic_action := 0
var _held_action_buttons: Dictionary = {}


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	judgment_threshold_crossed.connect(_vibrate_for_judgment_threshold)
	card_stage.resized.connect(_on_stage_resized)
	for button in [again_button, good_button]:
		button.button_down.connect(_on_action_button_down.bind(button))
		button.button_up.connect(_on_action_button_up.bind(button))
	_fit_to_stage()
	_set_active_hint(0)


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
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


static func drag_direction(delta: Vector2) -> int:
	if (
		absf(delta.x) >= DRAG_THRESHOLD
		and absf(delta.x) > absf(delta.y) * HORIZONTAL_DOMINANCE
	):
		return GOOD if delta.x > 0.0 else AGAIN
	if (
		absf(delta.y) >= VERTICAL_DRAG_THRESHOLD
		and absf(delta.y) > absf(delta.x) * VERTICAL_DOMINANCE
	):
		return PREVIOUS if delta.y > 0.0 else SKIP
	return 0


static func action_vector(action: int) -> Vector2:
	match action:
		AGAIN:
			return Vector2.LEFT
		GOOD:
			return Vector2.RIGHT
		PREVIOUS:
			return Vector2.DOWN
		SKIP:
			return Vector2.UP
		_:
			return Vector2.ZERO


static func key_direction(keycode: int) -> int:
	match keycode:
		KEY_LEFT:
			return AGAIN
		KEY_RIGHT:
			return GOOD
		KEY_UP:
			return SKIP
		KEY_DOWN:
			return PREVIOUS
		_:
			return 0


static func fitted_card_rect(
	available_size: Vector2,
	aspect_ratio: float = CARD_ASPECT_RATIO
) -> Rect2:
	if available_size.x <= 0.0 or available_size.y <= 0.0 or aspect_ratio <= 0.0:
		return Rect2()

	var card_size := Vector2(available_size.x, available_size.x / aspect_ratio)
	if card_size.y > available_size.y:
		card_size = Vector2(available_size.y * aspect_ratio, available_size.y)
	return Rect2((available_size - card_size) * 0.5, card_size)


func commit(direction: int) -> void:
	if (
		not input_enabled
		or _animating
		or action_vector(direction) == Vector2.ZERO
	):
		return

	pivot_offset = size * 0.5
	if not animations_enabled:
		swiped.emit(direction)
		return
	_play_swipe_exit(direction)


func _handle_key(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	var direction := key_direction(event.keycode)
	if direction == 0:
		direction = key_direction(event.physical_keycode)
	if direction == 0:
		return
	get_viewport().set_input_as_handled()
	if direction == PREVIOUS and not previous_enabled:
		return
	commit(direction)


func flip(midpoint: Callable, finished: Callable = Callable()) -> void:
	if not input_enabled or _animating or not midpoint.is_valid():
		return
	if not animations_enabled:
		midpoint.call()
		if finished.is_valid():
			finished.call()
		return

	_animating = true
	pivot_offset = size * 0.5
	_set_animation_controls_disabled(true)
	_motion_tween = create_tween()
	_motion_tween.tween_property(
		self,
		"position",
		Vector2(0.0, -FLIP_LIFT_OFFSET),
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
	_motion_tween.finished.connect(_on_flip_midpoint.bind(midpoint, finished))


func cancel_drag() -> void:
	if _motion_tween != null:
		_motion_tween.kill()
		_motion_tween = null
	_reset_visual()
	_dragging = false
	_animating = false
	_pointer_id = -1
	_drag_axis = DragAxis.UNDECIDED
	_haptic_action = 0
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
	return (
		_held_action_buttons.is_empty()
		and get_global_rect().has_point(at_position)
	)


func _on_action_button_down(button: Button) -> void:
	_held_action_buttons[button] = true
	if _dragging:
		cancel_drag()


func _on_action_button_up(button: Button) -> void:
	_held_action_buttons.erase(button)


func _begin_drag(at_position: Vector2, pointer_id: int) -> void:
	_dragging = true
	_pointer_id = pointer_id
	_drag_axis = DragAxis.UNDECIDED
	_drag_start = at_position
	_drag_position = at_position
	_haptic_action = 0
	pivot_offset = size * 0.5


func _update_drag(at_position: Vector2) -> void:
	_drag_position = at_position
	var delta := _drag_position - _drag_start
	if _drag_axis == DragAxis.UNDECIDED and delta.length() >= DIRECTION_LOCK_DISTANCE:
		if absf(delta.x) > absf(delta.y) * HORIZONTAL_DOMINANCE:
			_drag_axis = DragAxis.HORIZONTAL
		elif absf(delta.y) > absf(delta.x) * VERTICAL_DOMINANCE:
			_drag_axis = (
				DragAxis.VERTICAL_SCROLL
				if _scroll_can_consume_vertical_drag(delta.y)
				else DragAxis.VERTICAL_NAVIGATION
			)

	if _drag_axis == DragAxis.HORIZONTAL:
		_show_horizontal_preview(delta.x)
	elif _drag_axis == DragAxis.VERTICAL_NAVIGATION:
		_show_vertical_preview(delta.y)
	elif _drag_axis == DragAxis.VERTICAL_SCROLL:
		_reset_visual()


func _finish_drag(at_position: Vector2) -> void:
	_drag_position = at_position
	var delta := _drag_position - _drag_start
	var direction := (
		drag_direction(delta)
		if _drag_axis == DragAxis.HORIZONTAL
		or _drag_axis == DragAxis.VERTICAL_NAVIGATION
		else 0
	)
	var is_tap := (
		_drag_axis == DragAxis.UNDECIDED
		and delta.length() <= TAP_MAX_DISTANCE
	)
	if direction == PREVIOUS and not previous_enabled:
		direction = 0
	_dragging = false
	_pointer_id = -1
	_drag_axis = DragAxis.UNDECIDED
	if is_tap:
		_reset_visual()
		tapped.emit()
		return
	if direction == 0:
		_reset_visual()
		return
	if animations_enabled:
		_play_swipe_exit(direction)
	else:
		_reset_visual()
		swiped.emit(direction)


func _show_horizontal_preview(horizontal_delta: float) -> void:
	_update_judgment_haptic(horizontal_delta)
	var max_offset := size.x * PREVIEW_MAX_OFFSET_RATIO
	var preview_offset := clampf(
		horizontal_delta * PREVIEW_FOLLOW_RATIO,
		-max_offset,
		max_offset
	)
	position = Vector2(preview_offset, 0.0)
	var width := maxf(size.x, 1.0)
	var preview_rotation_degrees := clampf(
		horizontal_delta / width * PREVIEW_MAX_ROTATION_DEGREES * 2.0,
		-PREVIEW_MAX_ROTATION_DEGREES,
		PREVIEW_MAX_ROTATION_DEGREES
	)
	rotation = deg_to_rad(preview_rotation_degrees)
	var action := GOOD if horizontal_delta > 0.0 else AGAIN
	var feedback_strength := clampf(
		absf(preview_rotation_degrees) / PREVIEW_MAX_ROTATION_DEGREES,
		0.0,
		1.0
	)
	_set_active_action_button(action, feedback_strength)
	_set_active_hint(0)


func _show_vertical_preview(vertical_delta: float) -> void:
	_haptic_action = 0
	_set_active_action_button(0)
	var max_offset := size.y * VERTICAL_PREVIEW_MAX_OFFSET_RATIO
	var preview_offset := clampf(
		vertical_delta * VERTICAL_PREVIEW_FOLLOW_RATIO,
		-max_offset,
		max_offset
	)
	position = Vector2(0.0, preview_offset)
	rotation = 0.0
	_set_active_hint(
		PREVIOUS if vertical_delta > 0.0 else SKIP,
		absf(vertical_delta)
		/ (VERTICAL_DRAG_THRESHOLD * HINT_DRAG_DISTANCE_MULTIPLIER)
	)


func _scroll_can_consume_vertical_drag(vertical_delta: float) -> bool:
	var scrolls: Array[ScrollContainer] = [question_scroll, answer_scroll]
	for scroll in scrolls:
		if not scroll.visible or not scroll.get_global_rect().has_point(_drag_start):
			continue
		var scroll_bar: VScrollBar = scroll.get_v_scroll_bar()
		if vertical_delta < 0.0:
			return scroll_bar.value < scroll_bar.max_value - scroll_bar.page - 0.5
		if vertical_delta > 0.0:
			return scroll_bar.value > scroll_bar.min_value + 0.5
	return false


func _update_judgment_haptic(horizontal_delta: float) -> void:
	var action := 0
	if absf(horizontal_delta) >= DRAG_THRESHOLD:
		action = GOOD if horizontal_delta > 0.0 else AGAIN
	if action == _haptic_action:
		return
	_haptic_action = action
	if action != 0:
		judgment_threshold_crossed.emit(action)


func _vibrate_for_judgment_threshold(_direction: int) -> void:
	if not haptics_enabled:
		return
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		return
	Input.vibrate_handheld(HAPTIC_DURATION_MS, HAPTIC_AMPLITUDE)


func _play_swipe_exit(direction: int) -> void:
	_animating = true
	_set_animation_controls_disabled(true)
	_set_active_action_button(direction if direction == AGAIN or direction == GOOD else 0)
	_complete_active_hint(direction)
	var direction_vector := action_vector(direction)
	var exit_distance := _travel_distance(direction_vector)
	var target_position := direction_vector * exit_distance
	_motion_tween = create_tween()
	_motion_tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(self, "position", target_position, EXIT_DURATION)
	_motion_tween.tween_property(
		self,
		"rotation",
		deg_to_rad(direction_vector.x * EXIT_ROTATION_DEGREES),
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

	var direction_vector := action_vector(direction)
	var enter_distance := _travel_distance(direction_vector)
	position = -direction_vector * enter_distance
	rotation = deg_to_rad(-direction_vector.x * ENTER_ROTATION_DEGREES)
	scale = Vector2(0.97, 0.97)
	modulate.a = 0.25
	var overshoot_position := direction_vector * ENTER_OVERSHOOT_DISTANCE
	_motion_tween = create_tween()
	_motion_tween.tween_property(
		self,
		"position",
		overshoot_position,
		ENTER_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"rotation",
		0.0,
		ENTER_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"scale",
		Vector2(1.01, 1.01),
		ENTER_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"modulate:a",
		1.0,
		ENTER_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		self,
		"position",
		Vector2.ZERO,
		ENTER_SETTLE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(
		self,
		"scale",
		Vector2.ONE,
		ENTER_SETTLE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.finished.connect(_on_swipe_enter_finished)


func _on_swipe_enter_finished() -> void:
	_motion_tween = null
	_animating = false
	_set_active_hint(0)
	_set_active_action_button(0)
	_set_animation_controls_disabled(false)


func _on_flip_midpoint(midpoint: Callable, finished: Callable) -> void:
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
		Vector2.ZERO,
		FLIP_OPEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		FLIP_SETTLE_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.finished.connect(_on_flip_finished.bind(finished))


func _on_flip_finished(finished: Callable) -> void:
	_motion_tween = null
	scale = Vector2.ONE
	_animating = false
	_set_animation_controls_disabled(false)
	if finished.is_valid():
		finished.call()


func _set_animation_controls_disabled(disabled: bool) -> void:
	var controls_disabled := disabled or _animating or not input_enabled
	again_button.disabled = controls_disabled
	good_button.disabled = controls_disabled


func _travel_distance(direction: Vector2) -> float:
	var viewport_size := get_viewport_rect().size
	if direction.x != 0.0:
		return maxf(size.x, viewport_size.x) + size.x * 0.25
	return maxf(size.y, viewport_size.y) + size.y * 0.25


func _set_active_hint(action: int, drag_strength: float = 0.0) -> void:
	if action != _active_hint_action:
		if _hint_motion_tween != null:
			_hint_motion_tween.kill()
			_hint_motion_tween = null
		_remember_hint_rest_positions()
		_active_hint_action = action
		var hints: Array[Label] = [skip_hint, previous_hint]
		for hint in hints:
			hint.hide()
			if _hint_rest_positions.has(hint):
				hint.position = _hint_rest_positions[hint] as Vector2
			hint.scale = Vector2.ONE
			hint.modulate.a = 1.0

	var active_hint: Label = _hint_for_action(action)
	if active_hint == null:
		return

	var reveal_strength := smoothstep(
		HINT_REVEAL_START,
		1.0,
		clampf(drag_strength, 0.0, 1.0)
	)
	var pull_strength := pow(reveal_strength, HINT_PULL_EXPONENT)
	var hint_scale := lerpf(HINT_MIN_SCALE, 1.0, reveal_strength)
	var rest_position := _hint_rest_positions[active_hint] as Vector2
	var entry_offset := _hint_entry_offset(action, active_hint, rest_position)
	active_hint.add_theme_color_override("font_color", HINT_ACTIVE_COLOR)
	active_hint.pivot_offset = active_hint.size * 0.5
	active_hint.position = rest_position + entry_offset * (1.0 - pull_strength)
	active_hint.scale = Vector2(hint_scale, hint_scale)
	active_hint.modulate.a = lerpf(HINT_MIN_ALPHA, 1.0, reveal_strength)
	active_hint.show()


func _complete_active_hint(action: int) -> void:
	if action != _active_hint_action:
		_set_active_hint(action, 0.0)
	var active_hint: Label = _hint_for_action(action)
	if active_hint == null:
		return
	if _hint_motion_tween != null:
		_hint_motion_tween.kill()
	_hint_motion_tween = create_tween()
	_hint_motion_tween.set_parallel(true)
	_hint_motion_tween.tween_property(
		active_hint,
		"position",
		_hint_rest_positions[active_hint] as Vector2,
		HINT_COMPLETE_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hint_motion_tween.tween_property(
		active_hint,
		"scale",
		Vector2.ONE,
		HINT_COMPLETE_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hint_motion_tween.tween_property(
		active_hint,
		"modulate:a",
		1.0,
		HINT_COMPLETE_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hint_motion_tween.finished.connect(_on_hint_motion_finished)


func _hint_for_action(action: int) -> Label:
	match action:
		SKIP:
			return skip_hint
		PREVIOUS:
			return previous_hint
		_:
			return null


func _remember_hint_rest_positions() -> void:
	if not _hint_rest_positions.is_empty():
		return
	var hints: Array[Label] = [skip_hint, previous_hint]
	for hint in hints:
		_hint_rest_positions[hint] = hint.position


func _hint_entry_offset(
	action: int,
	hint: Label,
	rest_position: Vector2
) -> Vector2:
	var stage_size := card_stage.size
	match action:
		SKIP:
			return Vector2(
				0.0,
				stage_size.y - rest_position.y + HINT_PULL_PADDING
			)
		PREVIOUS:
			return Vector2(
				0.0,
				-(rest_position.y + hint.size.y + HINT_PULL_PADDING)
			)
		_:
			return Vector2.ZERO


func _on_stage_resized() -> void:
	_fit_to_stage()
	if _active_hint_action == 0:
		_hint_rest_positions.clear()


func _fit_to_stage() -> void:
	var card_rect := fitted_card_rect(card_stage.size)
	card_slot.position = card_rect.position
	card_slot.size = card_rect.size
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pivot_offset = size * 0.5


func _on_hint_motion_finished() -> void:
	_hint_motion_tween = null


func _reset_visual() -> void:
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_haptic_action = 0
	_set_active_action_button(0)
	_set_active_hint(0)


func _set_active_action_button(action: int, strength: float = 1.0) -> void:
	var buttons: Array[Button] = [again_button, good_button]
	for button in buttons:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.remove_theme_stylebox_override(state)
		for color_name in [
			"font_color",
			"font_hover_color",
			"font_pressed_color",
			"font_focus_color",
			"font_hover_pressed_color",
			"font_disabled_color",
		]:
			button.remove_theme_color_override(color_name)

	var active_button: Button
	if action == AGAIN:
		active_button = again_button
	elif action == GOOD:
		active_button = good_button
	else:
		return
	if action_active_style == null:
		return
	var feedback_strength := clampf(strength, 0.0, 1.0)
	var active_color := again_active_color if action == AGAIN else good_active_color
	var feedback_style := action_active_style.duplicate() as StyleBoxFlat
	feedback_style.bg_color = Color.WHITE.lerp(active_color, feedback_strength)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		active_button.add_theme_stylebox_override(state, feedback_style)
	var feedback_font_color := Color.BLACK.lerp(Color.WHITE, feedback_strength)
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color",
		"font_hover_pressed_color",
		"font_disabled_color",
	]:
		active_button.add_theme_color_override(color_name, feedback_font_color)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_held_action_buttons.clear()
		cancel_drag()
