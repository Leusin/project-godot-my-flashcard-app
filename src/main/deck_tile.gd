class_name DeckTileView
extends Control

# 타일 입력은 덱 열기와 목록 스크롤만 처리한다.
signal selected(deck_file: String)

const MOVE_CANCEL_DISTANCE := 16.0

@onready var deck_button: Button = %DeckButton
@onready var name_label: Label = %DeckNameLabel
@onready var count_label: Label = %DeckCountLabel

var _deck_file := ""
var _gesture := ReorderGesture.new()
var _scroll_start := 0
var _scroll_container: ScrollContainer


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	deck_button.gui_input.connect(_on_deck_button_input)
	_scroll_container = DragBounds.clip_ancestor(self) as ScrollContainer
	_gesture.surface = deck_button
	_gesture.hold_seconds = INF
	_gesture.move_cancel_distance = MOVE_CANCEL_DISTANCE
	add_child(_gesture)
	_gesture.scrolled.connect(_on_scrolled)
	if _scroll_container != null:
		_scroll_container.scroll_started.connect(_gesture.scroll_started)


func setup(file_name: String, display_name: String, card_count: int, completed_count: int = 0) -> void:
	_deck_file = file_name
	name_label.text = display_name
	count_label.text = "완료 %d / %d장" % [completed_count, card_count] if card_count > 0 else "카드 없음"


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
	_gesture.feed(event)


func _on_scrolled(offset: Vector2) -> void:
	if _scroll_container != null and not DisplayServer.is_touchscreen_available():
		_scroll_container.scroll_vertical = _scroll_start - roundi(offset.y)
