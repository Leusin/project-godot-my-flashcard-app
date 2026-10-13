class_name CardListView
extends VBoxContainer

# 카드 목록 화면의 골격. 받은 카드를 그리고 행 입력과 순서 변경 요청을 올린다.
# 저장과 학습 기록 무효화 같은 해석은 main.gd가 맡는다.

signal back_pressed
signal add_card_pressed
signal card_selected(index: int)
signal card_menu_requested(index: int, anchor: Control)
signal sort_changed(mode: int)

const CARD_ROW_SCENE := preload("res://src/main/card_collection_row.tscn")

var _sort_mode := 0
var _progress: Progress
var _cards: Array[FlashCard] = []

@onready var sort_button: MenuButton = $Header/RightActions/CardSortButton
@onready var back_button: Button = $Header/LeftActions/BackFromCardListButton
@onready var deck_name_label: Label = $Header/TitleSlot/CardListDeckLabel
@onready var search_field: LineEdit = $ContentBounds/Content/SearchField
@onready var search_status: Label = $ContentBounds/Content/SearchStatus
@onready var rows: VBoxContainer = $ContentBounds/Content/CardListScroll/Rows
@onready var add_card_button: Button = $Header/RightActions/AddCardButton


func _ready() -> void:
	var popup := sort_button.get_popup()
	for caption in ["기본 순서", "질문 오름차순", "오답 많은 순"]:
		popup.add_radio_check_item(caption)
	popup.id_pressed.connect(_on_sort_selected)
	set_sort(0)
	search_field.text_changed.connect(_apply_search)
	search_field.text_submitted.connect(func(_text: String) -> void: search_field.release_focus())
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	add_card_button.pressed.connect(func() -> void: add_card_pressed.emit())


func render(deck_name: String, cards: Array[FlashCard], progress: Progress = null) -> void:
	if deck_name_label.text != deck_name:
		search_field.text = ""
	_cards = cards.duplicate()
	_progress = progress
	deck_name_label.text = deck_name
	for child in rows.get_children():
		child.free()

	for index in cards.size():
		var row := CARD_ROW_SCENE.instantiate() as CardCollectionRow
		rows.add_child(row)
		row.setup(index, cards[index])
		row.show_learning_record(progress.get_wrong_count(cards[index].question) if progress != null else 0)
		row.selected.connect(_on_row_selected)
		row.menu_requested.connect(_on_row_menu_requested)
	_sort_rows()
	_apply_search(search_field.text)


func _on_row_selected(index: int) -> void:
	card_selected.emit(index)


func _on_row_menu_requested(index: int, anchor: Control) -> void:
	card_menu_requested.emit(index, anchor)


func set_sort(mode: int) -> void:
	_sort_mode = clampi(mode, 0, 2)
	var popup := sort_button.get_popup()
	for index in popup.item_count:
		popup.set_item_checked(index, index == _sort_mode)
	_sort_rows()


func _on_sort_selected(mode: int) -> void:
	set_sort(mode)
	sort_changed.emit(_sort_mode)


func _sort_rows() -> void:
	var ordered := rows.get_children()
	ordered.sort_custom(func(a: CardCollectionRow, b: CardCollectionRow) -> bool:
		if _sort_mode == 2 and _progress != null:
			var a_count := _progress.get_wrong_count(_cards[a.card_index].question)
			var b_count := _progress.get_wrong_count(_cards[b.card_index].question)
			if a_count != b_count:
				return a_count > b_count
		if _sort_mode == 1:
			var comparison := _cards[a.card_index].question.naturalnocasecmp_to(_cards[b.card_index].question)
			if comparison != 0:
				return comparison < 0
		return a.card_index < b.card_index
	)
	for index in ordered.size():
		rows.move_child(ordered[index], index)
	(rows.get_parent() as ScrollContainer).scroll_vertical = 0


func _apply_search(text: String) -> void:
	var query := text.strip_edges()
	add_card_button.visible = query.is_empty()
	var count := 0
	for index in rows.get_child_count():
		var row := rows.get_child(index) as CardCollectionRow
		var card := _cards[row.card_index]
		row.visible = query.is_empty() or card.question.findn(query) >= 0 or card.answer.findn(query) >= 0
		if row.visible:
			count += 1
	search_status.visible = count == 0
	if _cards.is_empty():
		search_status.text = "아직 카드가 없어요. 첫 카드를 추가해 보세요."
	elif count == 0:
		search_status.text = "검색 결과가 없어요."
	else:
		search_status.text = ""
