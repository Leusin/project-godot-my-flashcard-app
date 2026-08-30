class_name CardEditorView
extends KeyboardAvoider

# 카드 편집 화면의 입력 상태와 학습 필드 UI를 소유한다.
# Markdown 저장은 CardWorkspace, 학습 세션 갱신은 MainApp이 맡는다.

signal cancel_requested
signal save_requested

var _original_question := ""
var _original_answer := ""
var _original_wrong_count := 0
var _original_status: CardStatus.Value = CardStatus.Value.NEW
var _wrong_count := 0

@onready var cancel_button: Button = $Header/LeftActions/CancelCardEditButton
@onready var title_label: Label = $Header/TitleSlot/CardEditorTitle
@onready var save_button: Button = $Header/RightActions/SaveCardButton
@onready var wrong_minus_button: Button = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardEditorProperties/WrongCountFrame/WrongCountControls/WrongMinusButton
)
@onready var wrong_count_label: Label = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardEditorProperties/WrongCountFrame/WrongCountControls/EditorWrongCountLabel
)
@onready var wrong_plus_button: Button = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardEditorProperties/WrongCountFrame/WrongCountControls/WrongPlusButton
)
@onready var reset_progress_button: Button = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardEditorProperties/ResetCardProgressButton
)
@onready var status_option: OptionButton = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardEditorProperties/CardStatusOption
)
@onready var question_input: SingleLineTextEdit = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardQuestionInput
)
@onready var answer_input: TextEdit = (
	$CardEditorStage/CardEditorFrame/CardMargin/CardContent/CardAnswerInput
)


func _ready() -> void:
	super()
	_setup_status_options()
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	save_button.pressed.connect(func() -> void: save_requested.emit())
	wrong_minus_button.pressed.connect(_on_wrong_minus_pressed)
	wrong_plus_button.pressed.connect(_on_wrong_plus_pressed)
	reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	status_option.item_selected.connect(_on_status_selected)
	question_input.submitted.connect(_on_question_submitted)


func begin_edit(
	title: String,
	question: String,
	answer: String,
	wrong_count: int,
	status: CardStatus.Value
) -> void:
	_original_question = question
	_original_answer = answer
	_original_wrong_count = wrong_count
	_original_status = status
	_wrong_count = wrong_count
	title_label.text = title
	question_input.text = question
	answer_input.text = answer
	_select_status(status)
	_update_learning_fields()
	question_input.call_deferred("grab_focus")


func has_changes() -> bool:
	return (
		question_input.text != _original_question
		or answer_input.text != _original_answer
		or _wrong_count != _original_wrong_count
		or selected_status() != _original_status
	)


func question_text() -> String:
	return question_input.text


func answer_text() -> String:
	return answer_input.text


func wrong_count() -> int:
	return _wrong_count


func selected_status() -> CardStatus.Value:
	return status_option.get_selected_id() as CardStatus.Value


func _setup_status_options() -> void:
	status_option.clear()
	status_option.add_item("NEW", CardStatus.Value.NEW)
	status_option.add_item("LEARNING", CardStatus.Value.LEARNING)
	status_option.add_item("MASTERED", CardStatus.Value.MASTERED)


func _select_status(status: CardStatus.Value) -> void:
	var item_index := status_option.get_item_index(status)
	if item_index >= 0:
		status_option.select(item_index)


func _on_wrong_minus_pressed() -> void:
	_wrong_count = maxi(_wrong_count - 1, 0)
	_update_learning_fields()


func _on_wrong_plus_pressed() -> void:
	_wrong_count += 1
	_update_learning_fields()


func _on_reset_progress_pressed() -> void:
	_wrong_count = 0
	_select_status(CardStatus.Value.NEW)
	_update_learning_fields()


func _on_status_selected(_index: int) -> void:
	_update_learning_fields()


func _update_learning_fields() -> void:
	wrong_count_label.text = str(_wrong_count)
	wrong_count_label.tooltip_text = "오답 %d회" % _wrong_count
	wrong_minus_button.disabled = _wrong_count == 0
	reset_progress_button.disabled = (
		_wrong_count == 0
		and selected_status() == CardStatus.Value.NEW
	)


func _on_question_submitted() -> void:
	answer_input.grab_focus()
