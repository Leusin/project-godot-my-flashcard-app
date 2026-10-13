class_name DeckTileView
extends Control

# 짧게 누르면 덱을 열고, 길게 누르면 타일을 집어 옮긴다.
# 집은 타일은 손끝을 따라다니고 다른 타일은 그대로 있는다.
# 어디에 놓였는지 판정하고 그 차례를 저장하는 일은 목록과 App이 맡는다.

signal selected(deck_file: String)
signal reorder_started(deck_file: String)
signal reorder_ended(deck_file: String, pointer: Vector2)
signal reorder_canceled

const LONG_PRESS_SECONDS := 0.45
const MOVE_CANCEL_DISTANCE := 16.0
const PICKED_SCALE := 1.06
const PICK_TWEEN_SECONDS := 0.12

@onready var deck_button: Button = %DeckButton
@onready var name_label: Label = %DeckNameLabel
@onready var count_label: Label = %DeckCountLabel

var _deck_file := ""
var _gesture := ReorderGesture.new()
var _reordering := false
var _pick_tween: Tween
var _scroll_start := 0
var _rest_position := Vector2.ZERO
var _clip: Control
var _scroll_container: ScrollContainer


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	deck_button.gui_input.connect(_on_deck_button_input)
	_clip = DragBounds.clip_ancestor(self)
	_scroll_container = _clip as ScrollContainer
	_gesture.surface = deck_button
	_gesture.hold_seconds = LONG_PRESS_SECONDS
	_gesture.move_cancel_distance = MOVE_CANCEL_DISTANCE
	add_child(_gesture)
	_gesture.picked.connect(_on_picked)
	_gesture.dragged.connect(_on_dragged)
	_gesture.dropped.connect(_finish_reorder)
	_gesture.canceled.connect(_on_canceled)
	_gesture.scrolled.connect(_on_scrolled)
	if _scroll_container != null:
		_scroll_container.scroll_started.connect(_gesture.scroll_started)


func setup(file_name: String, display_name: String, card_count: int) -> void:
	_deck_file = file_name
	name_label.text = display_name
	count_label.text = "%d장" % card_count if card_count > 0 else "카드 없음"


func deck_file() -> String:
	return _deck_file


func _on_deck_pressed() -> void:
	if not _gesture.blocks_selection:
		selected.emit(_deck_file)


func _on_deck_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_scroll_start = _scroll_container.scroll_vertical if _scroll_container != null else 0
	if event is InputEventKey and event.pressed:
		_gesture.cancel()
		_gesture.blocks_selection = false
	var was_dragging := _reordering
	_gesture.feed(event)
	if was_dragging or _reordering:
		deck_button.accept_event()


func _on_picked() -> void:
	_reordering = true
	_pick_visual()
	reorder_started.emit(_deck_file)


func _on_dragged(offset: Vector2) -> void:
	position = DragBounds.clamped(_rest_position + offset, self, _clip)


func _on_scrolled(offset: Vector2) -> void:
	if _scroll_container != null and not DisplayServer.is_touchscreen_available():
		_scroll_container.scroll_vertical = _scroll_start - roundi(offset.y)


func _finish_reorder(pointer: Vector2) -> void:
	_reordering = false
	_release_visual()
	reorder_ended.emit(_deck_file, pointer)


func _on_canceled() -> void:
	_reordering = false
	_release_visual()
	reorder_canceled.emit()


# 집은 타일은 살짝 커지고 다른 타일 위로 떠서, 지금 무엇을 옮기는지 보이게 한다.
func _pick_visual() -> void:
	_rest_position = position
	pivot_offset = size * 0.5
	z_index = 1
	_pick_tween = create_tween().set_ease(Tween.EASE_OUT)
	_pick_tween.tween_property(self, "scale", Vector2.ONE * PICKED_SCALE, PICK_TWEEN_SECONDS)
	# 커지고 나면 가장자리 타일은 프레임 밖으로 삐져나온다. 다 커진 뒤 안으로 들인다.
	await _pick_tween.finished
	if _reordering:
		position = DragBounds.clamped(position, self, _clip)


func _release_visual() -> void:
	if _pick_tween != null:
		_pick_tween.kill()
	z_index = 0
	scale = Vector2.ONE
	position = _rest_position
