class_name CardCollectionRow
extends PanelContainer

signal selected(index: int)
signal menu_requested(index: int, anchor: Control)
signal reorder_started(index: int)
signal reorder_ended(index: int, pointer_y: float)

const FALLBACK_DRAG_THRESHOLD := 12.0
const PICKED_SHADOW_SIZE := 12
const PICKED_SHADOW_OFFSET := Vector2(0, 6)

@export var good_badge_style: StyleBoxFlat
@export var again_badge_style: StyleBoxFlat
@export var skip_badge_style: StyleBoxFlat

var card_index := -1
var _reordering := false
var _press_pointer := Vector2.ZERO
var _rest_position := Vector2.ZERO
var _rest_style: StyleBox
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
# 손잡이를 잡고 위아래로 끌면 카드 자리가 바뀐다. 어디로 옮길지는 목록 View가 정한다.
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


func _on_reorder_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if button_event.pressed:
			_reordering = true
			_press_pointer = button_event.global_position
			_pick_visual()
			reorder_started.emit(card_index)
		elif _reordering:
			_reordering = false
			_release_visual()
			reorder_ended.emit(card_index, button_event.global_position.y)
		accept_event()
		return

	if event is InputEventMouseMotion and _reordering:
		var motion := event as InputEventMouseMotion
		# 손을 뗀 사실이 유실되면 카드가 떠 있는 채로 남는다. 버튼 상태로 확인해 마무리한다.
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_finish_reorder(motion.global_position.y)
		else:
			position = DragBounds.clamped(
				_rest_position + (motion.global_position - _press_pointer),
				self,
				_scroll_container
			)
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
	answer_label.text = answer_preview(card.answer)
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


static func answer_preview(answer: String) -> String:
	var lines: PackedStringArray = []
	for line in answer.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	return "답 없음" if lines.is_empty() else " ".join(lines)


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


func _finish_reorder(pointer_y: float) -> void:
	_pointer_down = false
	_reordering = false
	_release_visual()
	reorder_ended.emit(card_index, pointer_y)


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


# 행은 프레임 폭을 꽉 채워 키울 수 없다. 그림자를 키워 들어올린 티를 낸다.
func _pick_visual() -> void:
	_rest_position = position
	z_index = 1
	_rest_style = get_theme_stylebox("panel")
	var lifted := _rest_style.duplicate() as StyleBoxFlat
	if lifted == null:
		return
	lifted.shadow_size = PICKED_SHADOW_SIZE
	lifted.shadow_offset = PICKED_SHADOW_OFFSET
	add_theme_stylebox_override("panel", lifted)


func _release_visual() -> void:
	z_index = 0
	position = _rest_position
	# 씬이 이미 override로 스타일을 준다. 지우지 말고 원래 것으로 되돌린다.
	if _rest_style != null:
		add_theme_stylebox_override("panel", _rest_style)
