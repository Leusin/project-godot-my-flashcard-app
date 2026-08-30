class_name StudyFlowView
extends VBoxContainer

# 학습 카드와 결과 화면의 표시 상태를 소유한다.
# 학습 판정, 진행도 저장, 다음 카드 선택은 main.gd가 맡는다.

signal back_pressed
signal action_committed(direction: int)
signal result_card_selected(index: int)
signal retry_requested
signal return_requested

@onready var back_button: Button = $Header/LeftActions/BackToReadyButton
@onready var deck_name_label: Label = $Header/TitleSlot/DeckLabel
@onready var remaining_label: Label = $Header/RightActions/RemainingLabel
@onready var current_view: VBoxContainer = (
	$ContentBounds/Content/StudyContainer
)
@onready var gesture_surface: StudyGestureSurface = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame
)
@onready var card_properties: HBoxContainer = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/CardProperties
)
@onready var wrong_tally: WrongTallyView = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/CardProperties/WrongTally
)
@onready var status_badge: Label = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/CardProperties/StatusBadge
)
@onready var question_scroll: ScrollContainer = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/QuestionScroll
)
@onready var question_label: Label = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/QuestionScroll/QuestionLabel
)
@onready var answer_scroll: ScrollContainer = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/AnswerScroll
)
@onready var answer_label: Label = (
	$ContentBounds/Content/StudyContainer/CardStage/CardSlot/CardFrame/CardMargin/CardContent/AnswerScroll/AnswerLabel
)
@onready var actions: HBoxContainer = (
	$ContentBounds/Content/StudyContainer/Actions
)
@onready var again_button: Button = (
	$ContentBounds/Content/StudyContainer/Actions/AgainButton
)
@onready var good_button: Button = (
	$ContentBounds/Content/StudyContainer/Actions/GoodButton
)
@onready var result_view: StudyResultView = (
	$ContentBounds/Content/StudyResultView
)


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	gesture_surface.swiped.connect(
		func(direction: int) -> void: action_committed.emit(direction)
	)
	gesture_surface.tapped.connect(_on_card_tapped)
	again_button.pressed.connect(_on_again_pressed)
	good_button.pressed.connect(_on_good_pressed)
	result_view.card_selected.connect(
		func(index: int) -> void: result_card_selected.emit(index)
	)
	result_view.retry_requested.connect(func() -> void: retry_requested.emit())
	result_view.return_requested.connect(func() -> void: return_requested.emit())


func set_deck_name(deck_name: String) -> void:
	deck_name_label.text = deck_name


func set_haptics_enabled(enabled: bool) -> void:
	gesture_surface.haptics_enabled = enabled


func show_card(
	card: FlashCard,
	wrong_count: int,
	status_text: String,
	remaining: int,
	previous_enabled: bool
) -> void:
	remaining_label.get_parent().show()
	current_view.show()
	result_view.hide()
	wrong_tally.set_count(wrong_count)
	status_badge.text = status_text
	question_label.text = card.question
	answer_label.text = card.answer
	question_scroll.scroll_vertical = 0
	answer_scroll.scroll_vertical = 0
	set_answer_visible(false)
	gesture_surface.previous_enabled = previous_enabled
	remaining_label.text = "%d장 남음" % remaining


func show_results(cards: Array[FlashCard], outcomes: Array[int]) -> void:
	remaining_label.get_parent().hide()
	current_view.hide()
	result_view.show()
	remaining_label.text = "0장 남음"
	result_view.render(cards, outcomes)


func reset_view() -> void:
	gesture_surface.cancel_drag()
	current_view.hide()
	result_view.hide()


func is_answer_visible() -> bool:
	return answer_scroll.visible


func set_answer_visible(show_answer: bool) -> void:
	answer_scroll.visible = show_answer
	card_properties.visible = show_answer
	if show_answer:
		question_scroll.scroll_vertical = 0
		question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		question_scroll.custom_minimum_size.y = 150.0
		question_scroll.size_flags_vertical = Control.SIZE_FILL
		question_label.max_lines_visible = 2
		question_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		question_label.add_theme_color_override(
			"font_color",
			Color(0.56, 0.56, 0.56, 1)
		)
	else:
		question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		question_scroll.custom_minimum_size.y = 0.0
		question_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		question_label.max_lines_visible = -1
		question_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		question_label.remove_theme_color_override("font_color")
	actions.show()


func set_input_enabled(enabled: bool) -> void:
	again_button.disabled = not enabled
	good_button.disabled = not enabled
	gesture_surface.input_enabled = enabled


func cancel_drag() -> void:
	gesture_surface.cancel_drag()


func _on_card_tapped() -> void:
	if not current_view.visible:
		return
	gesture_surface.flip(set_answer_visible.bind(not answer_scroll.visible))


func _on_again_pressed() -> void:
	gesture_surface.commit(StudyGestureSurface.AGAIN)


func _on_good_pressed() -> void:
	gesture_surface.commit(StudyGestureSurface.GOOD)
