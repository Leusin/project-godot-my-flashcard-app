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

var _reorder := ListReorder.new()
var _cards: Array[FlashCard] = []

@onready var back_button: Button = $Header/LeftActions/BackFromCardListButton
@onready var deck_name_label: Label = $Header/TitleSlot/CardListDeckLabel
@onready var search_field: LineEdit = $ContentBounds/Content/SearchField
@onready var search_status: Label = $ContentBounds/Content/SearchStatus
@onready var rows: VBoxContainer = $ContentBounds/Content/CardListScroll/Rows
@onready var add_card_button: Button = $ContentBounds/Content/AddCardButton


func _ready() -> void:
	_reorder.items = rows
	add_child(_reorder)
	_reorder.reordered.connect(_on_reordered)
	search_field.text_changed.connect(_apply_search)
	search_field.text_submitted.connect(func(_text: String) -> void: search_field.release_focus())
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	add_card_button.pressed.connect(func() -> void: add_card_pressed.emit())


func render(deck_name: String, cards: Array[FlashCard]) -> void:
	_reorder.cancel()
	if deck_name_label.text != deck_name:
		search_field.text = ""
	_cards = cards.duplicate()
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
		row.reorder_canceled.connect(_reorder.cancel)
	_apply_search(search_field.text)


func _on_row_selected(index: int) -> void:
	card_selected.emit(index)


func _on_row_menu_requested(index: int, anchor: Control) -> void:
	card_menu_requested.emit(index, anchor)


func _on_row_reorder_started(index: int) -> void:
	if search_field.text.strip_edges().is_empty() and index >= 0 and index < rows.get_child_count():
		_reorder.begin(rows.get_child(index) as Control)


func _on_row_reorder_ended(index: int, pointer_y: float) -> void:
	if search_field.text.strip_edges().is_empty() and index >= 0 and index < rows.get_child_count():
		_reorder.finish(rows.get_child(index) as Control, Vector2(0, pointer_y))


func _on_reordered(from_index: int, to_index: int) -> void:
	_cards.assign(ArrayOrder.moved(_cards, from_index, to_index))
	for row_index in rows.get_child_count():
		(rows.get_child(row_index) as CardCollectionRow).set_index(row_index)
	card_move_requested.emit(from_index, to_index)


func _apply_search(text: String) -> void:
	_reorder.cancel()
	var query := text.strip_edges()
	var count := 0
	for index in rows.get_child_count():
		var row := rows.get_child(index) as CardCollectionRow
		var card := _cards[index]
		row.visible = query.is_empty() or card.question.findn(query) >= 0 or card.answer.findn(query) >= 0
		row.set_reorder_enabled(query.is_empty())
		if row.visible:
			count += 1
	search_status.visible = not query.is_empty() or _cards.is_empty()
	if _cards.is_empty():
		search_status.text = "아직 카드가 없어요. 첫 카드를 추가해 보세요."
	elif count == 0:
		search_status.text = "검색 결과가 없어요. 다른 단어를 입력해 보세요."
	else:
		search_status.text = "%d / %d장 · 순서를 바꾸려면 검색을 지우세요." % [count, _cards.size()]
