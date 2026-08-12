class_name CardListRow
extends Button

signal selected(index: int)

var card_index: int

@onready var question_label: Label = $Margin/Content/QuestionLabel
@onready var answer_label: Label = $Margin/Content/AnswerLabel


func _ready() -> void:
	pressed.connect(func() -> void: selected.emit(card_index))


func setup(index: int, card: FlashCard) -> void:
	card_index = index
	question_label.text = card.question
	answer_label.text = "답 없음" if card.answer.is_empty() else card.answer.replace("\n", "  ·  ")
