class_name CardDetailSurface
extends PanelContainer

signal tapped

@export var animations_enabled := true

const CARD_ASPECT_RATIO := 2.0 / 3.0
const FLIP_HALF_DURATION := 0.14
const FLIP_OPEN_DURATION := 0.16
const FLIP_SETTLE_DURATION := 0.06
const FLIP_EDGE_SCALE_X := 0.035
const FLIP_PEAK_SCALE_Y := 1.035
const FLIP_OVERSHOOT_SCALE_X := 1.025

@onready var question_scroll: ScrollContainer = $CardMargin/CardContent/DetailQuestionScroll
@onready var answer_scroll: ScrollContainer = $CardMargin/CardContent/DetailAnswerScroll

var _flip_tween: Tween
var _animating := false
var _dragging := false
var _pointer_id := -1
var _drag_start := Vector2.ZERO
var _drag_scroll: ScrollContainer
var _scroll_start := 0
var _moved := false


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	(get_parent() as Control).resized.connect(_fit_to_stage)
	_fit_to_stage()


func _input(event: InputEvent) -> void:
	if _animating or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position, event.index)
		elif _dragging and _pointer_id == event.index:
			_finish_drag(event.position)
	elif event is InputEventScreenDrag:
		if _dragging and _pointer_id == event.index:
			_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position, -1)
		elif _dragging and _pointer_id == -1:
			_finish_drag(event.position)
	elif event is InputEventMouseMotion and _dragging and _pointer_id == -1:
		_update_drag(event.position)


func _begin_drag(point: Vector2, pointer_id: int) -> void:
	if _dragging or not get_global_rect().has_point(point):
		return
	_dragging = true
	_pointer_id = pointer_id
	_drag_start = point
	_drag_scroll = null
	_moved = false


func _update_drag(point: Vector2) -> void:
	var delta := point - _drag_start
	if not _moved and delta.length() >= StudyGestureSurface.DIRECTION_LOCK_DISTANCE:
		_moved = true
		if absf(delta.y) > absf(delta.x) * StudyGestureSurface.VERTICAL_DOMINANCE:
			var scrolls: Array[ScrollContainer] = [question_scroll, answer_scroll]
			for scroll in scrolls:
				if not scroll.visible or not scroll.get_global_rect().has_point(_drag_start):
					continue
				if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
					continue
				if scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page:
					continue
				_drag_scroll = scroll
				_scroll_start = scroll.scroll_vertical
				break
	if _drag_scroll != null:
		_drag_scroll.scroll_vertical = _scroll_start - roundi(delta.y)
		get_viewport().set_input_as_handled()


func _finish_drag(point: Vector2) -> void:
	_dragging = false
	_pointer_id = -1
	_drag_scroll = null
	if not _moved and point.distance_to(_drag_start) <= StudyGestureSurface.TAP_MAX_DISTANCE:
		tapped.emit()


func flip(midpoint: Callable, finished: Callable = Callable()) -> void:
	if _animating or not midpoint.is_valid():
		return
	if not animations_enabled:
		midpoint.call()
		if finished.is_valid():
			finished.call()
		return

	_animating = true
	pivot_offset = size * 0.5
	_flip_tween = create_tween()
	_flip_tween.tween_property(
		self,
		"scale",
		Vector2(FLIP_EDGE_SCALE_X, FLIP_PEAK_SCALE_Y),
		FLIP_HALF_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_flip_tween.finished.connect(_on_flip_midpoint.bind(midpoint, finished))


static func fitted_card_rect(available_size: Vector2) -> Rect2:
	return AspectFit.centered_rect(
		Rect2(Vector2.ZERO, available_size),
		CARD_ASPECT_RATIO
	)


func _on_flip_midpoint(midpoint: Callable, finished: Callable) -> void:
	_flip_tween = null
	midpoint.call()
	_flip_tween = create_tween()
	_flip_tween.tween_property(
		self,
		"scale",
		Vector2(FLIP_OVERSHOOT_SCALE_X, 1.01),
		FLIP_OPEN_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_flip_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		FLIP_SETTLE_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flip_tween.finished.connect(_on_flip_finished.bind(finished))


func _on_flip_finished(finished: Callable) -> void:
	_flip_tween = null
	scale = Vector2.ONE
	_animating = false
	if finished.is_valid():
		finished.call()


func _fit_to_stage() -> void:
	var card_rect := fitted_card_rect((get_parent() as Control).size)
	position = card_rect.position
	size = card_rect.size
	pivot_offset = size * 0.5


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		return
	if _flip_tween != null:
		_flip_tween.kill()
		_flip_tween = null
	_animating = false
	_dragging = false
	_pointer_id = -1
	_drag_scroll = null
	scale = Vector2.ONE
