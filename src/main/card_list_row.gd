class_name CardListRow
extends PanelContainer

signal selected(index: int)
signal reorder_started
signal reorder_moved(viewport_position: Vector2)
signal reorder_finished

const FALLBACK_DRAG_THRESHOLD := 12.0

var card_index: int
var _pointer_down := false
var _dragged := false
var _scrolling := false
var _drag_distance := Vector2.ZERO
var _scroll_start := 0
var _scroll_container: ScrollContainer

@onready var question_label: Label = $Margin/Content/QuestionLabel
@onready var answer_label: Label = $Margin/Content/AnswerLabel
@onready var reorder_handle: Node = %ReorderHandle


func _ready() -> void:
	_scroll_container = _find_scroll_container()
	if _scroll_container != null:
		_scroll_container.scroll_started.connect(_on_scroll_started)
		_scroll_container.scroll_ended.connect(_on_scroll_ended)
	reorder_handle.connect("drag_started", _on_reorder_started)
	reorder_handle.connect("drag_moved", _on_reorder_moved)
	reorder_handle.connect("drag_finished", _on_reorder_finished)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func activate() -> void:
	selected.emit(card_index)


func set_reordering(active: bool) -> void:
	z_index = 5 if active else 0
	self_modulate = Color(0.9, 0.9, 0.9, 1.0) if active else Color.WHITE


func setup(index: int, card: FlashCard) -> void:
	card_index = index
	question_label.text = card.question
	answer_label.text = "답 없음" if card.answer.is_empty() else card.answer.replace("\n", "  ·  ")


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_pointer_down = true
		_dragged = _scrolling
		_drag_distance = Vector2.ZERO
		_scroll_start = _scroll_container.scroll_vertical if _scroll_container != null else 0
		grab_focus()
		return
	if not _pointer_down:
		return
	_pointer_down = false
	if not _dragged:
		activate()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _pointer_down or (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		return
	_drag_distance += event.relative
	if _drag_distance.length() >= _drag_threshold():
		_dragged = true
	if _dragged and _scroll_container != null and not DisplayServer.is_touchscreen_available():
		_scroll_container.scroll_vertical = _scroll_start - roundi(_drag_distance.y)


func _handle_key(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		activate()
		accept_event()


func _find_scroll_container() -> ScrollContainer:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			return ancestor as ScrollContainer
		ancestor = ancestor.get_parent()
	return null


func _drag_threshold() -> float:
	if _scroll_container != null and _scroll_container.scroll_deadzone > 0:
		return float(_scroll_container.scroll_deadzone)
	return FALLBACK_DRAG_THRESHOLD


func _on_scroll_started() -> void:
	_scrolling = true
	if _pointer_down:
		_dragged = true


func _on_scroll_ended() -> void:
	_scrolling = false


func _on_reorder_started() -> void:
	set_reordering(true)
	reorder_started.emit()


func _on_reorder_moved(viewport_position: Vector2) -> void:
	reorder_moved.emit(viewport_position)


func _on_reorder_finished() -> void:
	set_reordering(false)
	reorder_finished.emit()
