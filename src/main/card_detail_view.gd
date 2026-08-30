class_name CardDetailView
extends VBoxContainer

# 카드 상세 화면의 표시와 앞뒷면 전환을 소유한다.
# 어떤 카드로 이동하거나 수정할지는 main.gd가 결정한다.

signal back_pressed
signal menu_requested(anchor: Control)

@onready var back_button: Button = $Header/LeftActions/BackFromCardDetailButton
@onready var deck_name_label: Label = $Header/TitleSlot/CardDetailDeckLabel
@onready var menu_button: Button = $Header/RightActions/CardDetailMenuButton
@onready var card_surface: CardDetailSurface = $CardDetailStage/CardDetailFrame
@onready var card_properties: HBoxContainer = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailCardProperties
)
@onready var wrong_tally: WrongTallyView = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailCardProperties/DetailWrongTally
)
@onready var status_badge: Label = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailCardProperties/DetailStatusBadge
)
@onready var question_scroll: ScrollContainer = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailQuestionScroll
)
@onready var question_label: Label = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailQuestionScroll/DetailQuestionLabel
)
@onready var answer_scroll: ScrollContainer = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailAnswerScroll
)
@onready var answer_label: Label = (
	$CardDetailStage/CardDetailFrame/CardMargin/CardContent/DetailAnswerScroll/DetailAnswerLabel
)


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit(menu_button))
	card_surface.tapped.connect(_on_card_tapped)


func present(
	deck_name: String,
	card: FlashCard,
	wrong_count: int,
	status_text: String,
	menu_visible: bool,
	back_tooltip: String
) -> void:
	deck_name_label.text = deck_name
	menu_button.visible = menu_visible
	back_button.tooltip_text = back_tooltip
	render_card(card, wrong_count, status_text)


func render_card(card: FlashCard, wrong_count: int, status_text: String) -> void:
	question_label.text = card.question
	answer_label.text = card.answer
	wrong_tally.set_count(wrong_count)
	status_badge.text = status_text
	question_scroll.scroll_vertical = 0
	answer_scroll.scroll_vertical = 0
	_set_answer_visible(false)


func _on_card_tapped() -> void:
	card_surface.flip(_set_answer_visible.bind(not answer_scroll.visible))


func _set_answer_visible(show_answer: bool) -> void:
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
