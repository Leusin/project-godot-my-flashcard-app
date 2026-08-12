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

@onready var tap_button: Button = $CardTapButton

var _flip_tween: Tween
var _animating := false


func _ready() -> void:
	tap_button.pressed.connect(func() -> void: tapped.emit())
	visibility_changed.connect(_on_visibility_changed)
	(get_parent() as Control).resized.connect(_fit_to_stage)
	_fit_to_stage()


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
	tap_button.disabled = true
	_flip_tween = create_tween()
	_flip_tween.tween_property(
		self,
		"scale",
		Vector2(FLIP_EDGE_SCALE_X, FLIP_PEAK_SCALE_Y),
		FLIP_HALF_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_flip_tween.finished.connect(_on_flip_midpoint.bind(midpoint, finished))


static func fitted_card_rect(available_size: Vector2) -> Rect2:
	if available_size.x <= 0.0 or available_size.y <= 0.0:
		return Rect2()

	var card_size := Vector2(
		available_size.x,
		available_size.x / CARD_ASPECT_RATIO
	)
	if card_size.y > available_size.y:
		card_size = Vector2(
			available_size.y * CARD_ASPECT_RATIO,
			available_size.y
		)
	return Rect2((available_size - card_size) * 0.5, card_size)


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
	tap_button.disabled = false
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
	scale = Vector2.ONE
	if is_instance_valid(tap_button):
		tap_button.disabled = false
