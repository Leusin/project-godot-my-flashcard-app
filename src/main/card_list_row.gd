class_name CardListRow
extends Button

signal selected(index: int)

var card_index: int

@onready var question_label: Label = $Margin/Content/QuestionLabel
@onready var answer_label: Label = $Margin/Content/AnswerLabel
@onready var wrong_tally: WrongTallyView = %ListWrongTally
@onready var status_label: Label = %ListStatusLabel


func _ready() -> void:
	pressed.connect(func() -> void: selected.emit(card_index))


func setup(
	index: int,
	card: FlashCard,
	wrong_count: int = 0,
	status: CardStatus.Value = CardStatus.Value.NEW
) -> void:
	card_index = index
	question_label.text = card.question
	answer_label.text = "답 없음" if card.answer.is_empty() else card.answer.replace("\n", "  ·  ")
	wrong_tally.set_count(wrong_count)
	status_label.text = _status_text(status)


static func _status_text(status: CardStatus.Value) -> String:
	match status:
		CardStatus.Value.LEARNING:
			return "LEARNING"
		CardStatus.Value.MASTERED:
			return "MASTERED"
		_:
			return "NEW"
