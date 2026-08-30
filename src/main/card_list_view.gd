class_name CardListView
extends VBoxContainer

# 카드 목록 화면의 골격. 받은 카드를 그리고 행 입력과 순서 변경 요청을 올린다.
# 저장과 학습 기록 무효화 같은 해석은 main.gd가 맡는다.

signal back_pressed
signal add_card_pressed
signal card_selected(index: int)
signal card_menu_requested(index: int, anchor: Control)
signal card_move_requested(index: int, target: int)

const CARD_ROW_SCENE := preload("res://src/main/card_collection_row.tscn")

var _reordering := false
var _reordering_index := -1

@onready var back_button: Button = $Header/LeftActions/BackFromCardListButton
@onready var deck_name_label: Label = $Header/TitleSlot/CardListDeckLabel
@onready var rows: VBoxContainer = $ContentBounds/Content/CardListScroll/Rows
@onready var add_card_button: Button = $ContentBounds/Content/AddCardButton


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	add_card_button.pressed.connect(func() -> void: add_card_pressed.emit())


func render(deck_name: String, cards: Array[FlashCard]) -> void:
	_reordering = false
	_reordering_index = -1
	deck_name_label.text = deck_name
	for child in rows.get_children():
		child.free()

	for index in cards.size():
		var row := CARD_ROW_SCENE.instantiate() as CardCollectionRow
		rows.add_child(row)
		row.setup(index, cards[index])
		row.selected.connect(_on_row_selected)
		row.menu_requested.connect(_on_row_menu_requested)
		row.reorder_started.connect(_on_row_reorder_started)
		row.reorder_ended.connect(_on_row_reorder_ended)


func _on_row_selected(index: int) -> void:
	card_selected.emit(index)


func _on_row_menu_requested(index: int, anchor: Control) -> void:
	card_menu_requested.emit(index, anchor)


func _on_row_reorder_started(index: int) -> void:
	_reordering = true
	_reordering_index = index


# 놓기 전에는 원래 차례를 유지하고, 손을 뗀 경계로 한 번만 옮긴다.
func _on_row_reorder_ended(index: int, pointer_y: float) -> void:
	if not _reordering or index != _reordering_index:
		return
	_reordering = false
	_reordering_index = -1
	var target := _drop_target_at(index, pointer_y)
	if target < 0 or target == index:
		return

	rows.move_child(rows.get_child(index), target)
	for row_index in rows.get_child_count():
		(rows.get_child(row_index) as CardCollectionRow).set_index(row_index)
	card_move_requested.emit(index, target)


func _drop_target_at(moving_index: int, pointer_y: float) -> int:
	var closest_row: CardCollectionRow
	var closest_after := false
	var closest_distance := INF
	for row_index in rows.get_child_count():
		if row_index == moving_index:
			continue
		var row := rows.get_child(row_index) as CardCollectionRow
		var rect := row.get_global_rect()
		for after in [false, true]:
			var edge_y := rect.end.y if after else rect.position.y
			var distance := absf(pointer_y - edge_y)
			if distance < closest_distance:
				closest_distance = distance
				closest_row = row
				closest_after = after

	if closest_row == null:
		return -1
	var target := ListInsertion.target_index(
		rows.get_child_count(),
		moving_index,
		closest_row.get_index(),
		closest_after
	)
	return -1 if target == moving_index else target
