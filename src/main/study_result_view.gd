class_name StudyResultView
extends VBoxContainer

# 학습 결과의 집계와 카드 행 렌더링을 소유한다.
# 결과 카드의 원본 위치 해석과 재학습 세션 생성은 main.gd가 맡는다.

signal card_selected(index: int)
signal retry_requested
signal return_requested

const OUTCOME_LABELS := {
	StudyOutcome.Value.GOOD: "기억나요",
	StudyOutcome.Value.AGAIN: "다시 볼게요",
	StudyOutcome.Value.SKIP: "건너뜀",
}

var _primary_styles: Dictionary = {}
var _secondary_styles: Dictionary = {}

const CARD_ROW_SCENE := preload("res://src/main/card_collection_row.tscn")

@onready var good_count_label: Label = (
	$ResultSummary/Good/Margin/Content/ResultGoodCountLabel
)
@onready var again_count_label: Label = (
	$ResultSummary/Again/Margin/Content/ResultAgainCountLabel
)
@onready var skip_count_label: Label = (
	$ResultSummary/Skip/Margin/Content/ResultSkipCountLabel
)
@onready var rows: VBoxContainer = $ResultListScroll/Rows
@onready var retry_button: Button = $Actions/RetryAgainButton
@onready var return_button: Button = $Actions/ReturnToReadyButton


func _ready() -> void:
	for state in ["normal", "hover", "pressed"]:
		_primary_styles[state] = retry_button.get_theme_stylebox(state)
		_secondary_styles[state] = return_button.get_theme_stylebox(state)
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	return_button.pressed.connect(func() -> void: return_requested.emit())


func render(cards: Array[FlashCard], outcomes: Array[int]) -> void:
	for child in rows.get_children():
		child.free()

	var good_count := 0
	var again_count := 0
	var skip_count := 0
	for index in cards.size():
		var outcome := (
			outcomes[index]
			if index < outcomes.size()
			else StudyOutcome.Value.PENDING
		)
		match outcome:
			StudyOutcome.Value.GOOD:
				good_count += 1
			StudyOutcome.Value.AGAIN:
				again_count += 1
			StudyOutcome.Value.SKIP:
				skip_count += 1

		var row := CARD_ROW_SCENE.instantiate() as CardCollectionRow
		rows.add_child(row)
		row.setup(index, cards[index], StudyOutcome.display_text(outcome))
		row.outcome_label.text = OUTCOME_LABELS.get(outcome, "—")
		row.set_row_actions_visible(false)
		row.selected.connect(_on_row_selected)

	good_count_label.text = str(good_count)
	again_count_label.text = str(again_count)
	skip_count_label.text = str(skip_count)
	retry_button.disabled = again_count == 0
	retry_button.visible = again_count > 0
	retry_button.text = "다시 복습 (%d장)" % again_count
	_set_primary(retry_button, again_count > 0)
	_set_primary(return_button, false)
	(rows.get_parent() as ScrollContainer).scroll_vertical = 0


func _on_row_selected(index: int) -> void:
	card_selected.emit(index)


func _set_primary(button: Button, primary: bool) -> void:
	var styles := _primary_styles if primary else _secondary_styles
	for state in styles:
		button.add_theme_stylebox_override(state, styles[state])
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE if primary else Color.BLACK)
