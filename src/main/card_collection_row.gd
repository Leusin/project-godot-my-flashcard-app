class_name CardCollectionRow
extends PanelContainer

signal selected(index: int)
signal menu_requested(index: int, anchor: Control)
signal reorder_started(index: int)
signal reorder_moved(index: int, pointer_y: float)
signal reorder_ended(index: int)

const FALLBACK_DRAG_THRESHOLD := 12.0
const LONG_PRESS_SECONDS := 0.45
const PICKED_SCALE := 1.03
const PICK_TWEEN_SECONDS := 0.12

@export var good_badge_style: StyleBoxFlat
@export var again_badge_style: StyleBoxFlat
@export var skip_badge_style: StyleBoxFlat

var card_index := -1
var _reordering := false
var _press_generation := 0
var _pointer_down := false
var _dragged := false
var _scrolling := false
var _drag_distance := Vector2.ZERO
var _scroll_start := 0
var _scroll_container: ScrollContainer

@onready var question_label: Label = $Margin/Row/Content/Top/QuestionLabel
@onready var answer_label: Label = $Margin/Row/Content/AnswerLabel
@onready var outcome_badge: PanelContainer = $Margin/Row/Content/Top/OutcomeBadge
@onready var outcome_label: Label = $Margin/Row/Content/Top/OutcomeBadge/Margin/OutcomeLabel
@onready var menu_button: Button = $Margin/Row/RowMenuButton
# 손잡이를 잡고 위아래로 끌면 카드 자리가 바뀐다. 어디로 옮길지는 App이 정한다.
@onready var reorder_handle: Button = $Margin/Row/RowReorderHandle


func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	reorder_handle.gui_input.connect(_on_reorder_handle_input)
	_scroll_container = _find_scroll_container()
	if _scroll_container != null:
		_scroll_container.scroll_started.connect(_on_scroll_started)
		_scroll_container.scroll_ended.connect(_on_scroll_ended)


func set_row_actions_visible(actions_visible: bool) -> void:
	menu_button.visible = actions_visible
	reorder_handle.visible = actions_visible


func _on_menu_pressed() -> void:
	menu_requested.emit(card_index, menu_button)


func set_index(index: int) -> void:
	card_index = index


func _arm_long_press() -> void:
	_press_generation += 1
	var generation := _press_generation
	get_tree().create_timer(LONG_PRESS_SECONDS).timeout.connect(
		func() -> void: _on_long_press(generation)
	)


func _on_long_press(generation: int) -> void:
	# 길게 누르는 동안 스크롤이나 드래그가 시작됐다면 집지 않는다.
	if generation != _press_generation:
		return
	if not _pointer_down or _reordering or _dragged:
		return
	_reordering = true
	_apply_pick_visual(true)
	reorder_started.emit(card_index)


func _on_reorder_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if button_event.pressed:
			_reordering = true
			_apply_pick_visual(true)
			reorder_started.emit(card_index)
		elif _reordering:
			_reordering = false
			_apply_pick_visual(false)
			reorder_ended.emit(card_index)
		accept_event()
		return

	if event is InputEventMouseMotion and _reordering:
		reorder_moved.emit(card_index, (event as InputEventMouseMotion).global_position.y)
		accept_event()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func activate() -> void:
	selected.emit(card_index)


func setup(index: int, card: FlashCard, outcome: String = "") -> void:
	card_index = index
	question_label.text = card.question
	answer_label.text = (
		"답 없음"
		if card.answer.is_empty()
		else card.answer.replace("\n", ", ")
	)
	outcome_badge.visible = not outcome.is_empty()
	if outcome.is_empty():
		return
	outcome_label.text = outcome
	match outcome:
		"GOOD":
			_apply_badge(good_badge_style, Color.WHITE)
		"AGAIN":
			_apply_badge(again_badge_style, Color.BLACK)
		_:
			_apply_badge(skip_badge_style, Color(0.25, 0.25, 0.25, 1))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_pointer_down = true
		_dragged = _scrolling
		_drag_distance = Vector2.ZERO
		_scroll_start = _scroll_container.scroll_vertical if _scroll_container != null else 0
		grab_focus()
		_arm_long_press()
		return
	if not _pointer_down:
		return
	_pointer_down = false
	if _reordering:
		_reordering = false
		_apply_pick_visual(false)
		reorder_ended.emit(card_index)
		return
	if not _dragged:
		activate()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _pointer_down or (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		return

	# 집어 올린 뒤에는 목록을 스크롤하지 않고 카드 자리만 옮긴다.
	if _reordering:
		reorder_moved.emit(card_index, event.global_position.y)
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


func _apply_badge(style: StyleBoxFlat, text_color: Color) -> void:
	if style != null:
		outcome_badge.add_theme_stylebox_override("panel", style)
	outcome_label.add_theme_color_override("font_color", text_color)


func _on_scroll_started() -> void:
	_scrolling = true
	if _pointer_down:
		_dragged = true


func _on_scroll_ended() -> void:
	_scrolling = false


# 집어 올린 항목은 살짝 커지고 다른 항목 위로 떠서, 지금 무엇을 옮기는지 보이게 한다.
func _apply_pick_visual(picked: bool) -> void:
	pivot_offset = size * 0.5
	z_index = 1 if picked else 0
	var target := Vector2.ONE * PICKED_SCALE if picked else Vector2.ONE
	create_tween().set_ease(Tween.EASE_OUT).tween_property(
		self, "scale", target, PICK_TWEEN_SECONDS
	)
