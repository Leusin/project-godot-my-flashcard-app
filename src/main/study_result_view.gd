class_name StudyResultView
extends VBoxContainer

# 학습 결과의 집계와 카드 행 렌더링을 소유한다.
# 결과 카드의 원본 위치 해석과 재학습 세션 생성은 main.gd가 맡는다.

signal card_selected(index: int)
signal retry_requested
signal return_requested

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
		row.set_row_actions_visible(false)
		row.selected.connect(_on_row_selected)

	good_count_label.text = str(good_count)
	again_count_label.text = str(again_count)
	skip_count_label.text = str(skip_count)
	retry_button.disabled = again_count == 0
	retry_button.text = (
		"AGAIN 카드 없음"
		if again_count == 0
		else "AGAIN 카드 다시 학습"
	)
	(rows.get_parent() as ScrollContainer).scroll_vertical = 0


func _on_row_selected(index: int) -> void:
	card_selected.emit(index)
