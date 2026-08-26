class_name DeckTileView
extends Control

# 짧게 누르면 덱을 열고, 길게 누르면 타일을 집어 자리를 옮긴다.
# 어디로 옮길지와 그 차례를 저장할지는 목록과 App이 정한다.

signal selected(deck_file: String)
signal reorder_started(deck_file: String)
signal reorder_moved(deck_file: String, pointer: Vector2)
signal reorder_ended(deck_file: String)

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
var _press_position := Vector2.ZERO


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	deck_button.gui_input.connect(_on_deck_button_input)


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
		_press_position = event.global_position
		_press_generation += 1
		var generation := _press_generation
		get_tree().create_timer(LONG_PRESS_SECONDS).timeout.connect(
			func() -> void: _on_long_press(generation)
		)
		return

	_pressed = false
	if not _reordering:
		return
	_reordering = false
	_suppress_press = true
	_apply_pick_visual(false)
	reorder_ended.emit(_deck_file)


func _handle_motion(event: InputEventMouseMotion) -> void:
	if not _pressed:
		return

	if _reordering:
		reorder_moved.emit(_deck_file, event.global_position)
		return

	# 집기 전에 움직였다면 스크롤이나 취소로 본다.
	if event.global_position.distance_to(_press_position) > MOVE_CANCEL_DISTANCE:
		_pressed = false


func _on_long_press(generation: int) -> void:
	if generation != _press_generation or not _pressed or _reordering:
		return
	_reordering = true
	_apply_pick_visual(true)
	reorder_started.emit(_deck_file)


# 집어 올린 항목은 살짝 커지고 다른 항목 위로 떠서, 지금 무엇을 옮기는지 보이게 한다.
func _apply_pick_visual(picked: bool) -> void:
	pivot_offset = size * 0.5
	z_index = 1 if picked else 0
	var target := Vector2.ONE * PICKED_SCALE if picked else Vector2.ONE
	create_tween().set_ease(Tween.EASE_OUT).tween_property(
		self, "scale", target, PICK_TWEEN_SECONDS
	)
