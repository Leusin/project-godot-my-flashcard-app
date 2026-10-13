class_name CardCollectionRow
extends PanelContainer

signal selected(index: int)
signal menu_requested(index: int, anchor: Control)

const FALLBACK_DRAG_THRESHOLD := 12.0

@export var good_badge_style: StyleBoxFlat
@export var again_badge_style: StyleBoxFlat
@export var skip_badge_style: StyleBoxFlat

var card_index := -1
var _pointer_down := false
var _dragged := false
var _scrolling := false
var _drag_distance := Vector2.ZERO
var _scroll_start := 0
var _scroll_container: ScrollContainer

@onready var question_label: Label = $Margin/Row/Content/Top/QuestionLabel
@onready var answer_label: Label = $Margin/Row/Content/AnswerRow/AnswerLabel
@onready var outcome_badge: PanelContainer = $Margin/Row/Content/Top/OutcomeBadge
@onready var outcome_label: Label = $Margin/Row/Content/Top/OutcomeBadge/Margin/OutcomeLabel
@onready var menu_button: Button = $Margin/Row/RowMenuButton
func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)
	_scroll_container = _find_scroll_container()
	if _scroll_container != null:
		_scroll_container.scroll_started.connect(_on_scroll_started)
		_scroll_container.scroll_ended.connect(_on_scroll_ended)


func set_row_actions_visible(actions_visible: bool) -> void:
	menu_button.visible = actions_visible


func _on_menu_pressed() -> void:
	menu_requested.emit(card_index, menu_button)


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
	($Margin/Row/Content/Top as Container).queue_sort()
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


# 목록에서만 누적 오답 표식을 표시한다. 결과 화면의 판정 배지와는 별개다.
func show_learning_record(count: int) -> void:
	var summary := $Margin/Row/Content/Top/WrongSummary as HBoxContainer
	var tally := summary.get_node("WrongTally") as WrongTallyView
	var count_label := summary.get_node("WrongCountLabel") as Label
	summary.visible = count > 0
	summary.tooltip_text = "오답 %d회" % count
	tally.set_count(mini(count, 5))
	tally.visible = count <= 5
	tally.tooltip_text = summary.tooltip_text
	count_label.visible = count > 5
	count_label.text = str(count)
	($Margin/Row/Content/Top as Container).queue_sort()
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 1)
	add_theme_stylebox_override("panel", style)
