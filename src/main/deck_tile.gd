class_name DeckTileView
extends Control

# 짧게 누르면 덱을 열고, 길게 누르면 타일을 집어 옮긴다.
# 집은 타일은 손끝을 따라다니고 다른 타일은 그대로 있는다.
# 어디에 놓였는지 판정하고 그 차례를 저장하는 일은 목록과 App이 맡는다.

signal selected(deck_file: String)
signal reorder_started(deck_file: String)
signal reorder_ended(deck_file: String, pointer: Vector2)

const LONG_PRESS_SECONDS := 0.45
const MOVE_CANCEL_DISTANCE := 16.0
const PICKED_SCALE := 1.06
const PICK_TWEEN_SECONDS := 0.12

@onready var deck_button: Button = %DeckButton
@onready var name_label: Label = %DeckNameLabel
@onready var count_label: Label = %DeckCountLabel

var _deck_file := ""
var _pressed := false
var _reordering := false
var _suppress_press := false
var _press_generation := 0
var _press_pointer := Vector2.ZERO
var _rest_position := Vector2.ZERO
var _clip: Control


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	deck_button.gui_input.connect(_on_deck_button_input)
	_clip = DragBounds.clip_ancestor(self)


func setup(deck_file: String, display_name: String, card_count: int) -> void:
	_deck_file = deck_file
	name_label.text = display_name
	count_label.text = "%d장" % card_count if card_count > 0 else "카드 없음"


func deck_file() -> String:
	return _deck_file


func is_reordering() -> bool:
	return _reordering


func _on_deck_pressed() -> void:
	# 집어 옮긴 뒤 손을 뗀 것은 덱을 여는 신호가 아니다.
	if _suppress_press:
		_suppress_press = false
		return
	selected.emit(_deck_file)


func _on_deck_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_motion(event as InputEventMouseMotion)


func _handle_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_pressed = true
		_press_pointer = event.global_position
		_press_generation += 1
		var generation := _press_generation
		get_tree().create_timer(LONG_PRESS_SECONDS).timeout.connect(
			func() -> void: _on_long_press(generation)
		)
		return

	_pressed = false
	if not _reordering:
		return
	_finish_reorder(event.global_position)


func _finish_reorder(pointer: Vector2) -> void:
	_pressed = false
	_reordering = false
	_suppress_press = true
	_release_visual()
	reorder_ended.emit(_deck_file, pointer)


func _handle_motion(event: InputEventMouseMotion) -> void:
	if not _pressed:
		return

	if _reordering:
		# 손을 뗀 사실이 유실되면 타일이 떠 있는 채로 남는다. 버튼 상태로 확인해 마무리한다.
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_finish_reorder(event.global_position)
			return
		position = DragBounds.clamped(
			_rest_position + (event.global_position - _press_pointer), self, _clip
		)
		return

	# 집기 전에 움직였다면 스크롤이나 취소로 본다.
	if event.global_position.distance_to(_press_pointer) > MOVE_CANCEL_DISTANCE:
		_pressed = false


func _on_long_press(generation: int) -> void:
	if generation != _press_generation or not _pressed or _reordering:
		return
	_reordering = true
	_pick_visual()
	reorder_started.emit(_deck_file)


# 집은 타일은 살짝 커지고 다른 타일 위로 떠서, 지금 무엇을 옮기는지 보이게 한다.
func _pick_visual() -> void:
	_rest_position = position
	pivot_offset = size * 0.5
	z_index = 1
	create_tween().set_ease(Tween.EASE_OUT).tween_property(
		self, "scale", Vector2.ONE * PICKED_SCALE, PICK_TWEEN_SECONDS
	)


func _release_visual() -> void:
	z_index = 0
	scale = Vector2.ONE
	position = _rest_position
