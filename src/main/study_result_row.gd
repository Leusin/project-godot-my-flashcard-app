class_name StudyResultRow
extends PanelContainer

signal selected(index: int)

@export var good_badge_style: StyleBoxFlat
@export var again_badge_style: StyleBoxFlat
@export var skip_badge_style: StyleBoxFlat

@onready var question_label: Label = $Margin/Content/Top/QuestionLabel
@onready var answer_label: Label = $Margin/Content/AnswerLabel
@onready var outcome_badge: PanelContainer = $Margin/Content/Top/OutcomeBadge
@onready var outcome_label: Label = $Margin/Content/Top/OutcomeBadge/Margin/OutcomeLabel
@onready var open_button: Button = $OpenResultCardButton

var result_index := -1


func _ready() -> void:
	open_button.pressed.connect(func() -> void: selected.emit(result_index))


func setup(index: int, card: FlashCard, outcome: String) -> void:
	result_index = index
	question_label.text = card.question
	answer_label.text = (
		"답 없음"
		if card.answer.is_empty()
		else card.answer.replace("\n", "  ·  ")
	)
	outcome_label.text = outcome
	match outcome:
		"GOOD":
			_apply_badge(good_badge_style, Color.WHITE)
		"AGAIN":
			_apply_badge(again_badge_style, Color.BLACK)
		_:
			_apply_badge(skip_badge_style, Color(0.25, 0.25, 0.25, 1))


func _apply_badge(style: StyleBoxFlat, text_color: Color) -> void:
	if style != null:
		outcome_badge.add_theme_stylebox_override("panel", style)
	outcome_label.add_theme_color_override("font_color", text_color)
