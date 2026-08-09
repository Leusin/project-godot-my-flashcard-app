class_name MvpApp
extends Control

const BASE_PAGE_MARGIN := 32.0

@export var auto_start := true

@onready var page_margin: MarginContainer = $Margin
@onready var library_container: VBoxContainer = %LibraryContainer
@onready var deck_list: VBoxContainer = %DeckList
@onready var empty_decks_label: Label = %EmptyDecksLabel
@onready var import_status_label: Label = %ImportStatusLabel
@onready var import_dialog: FileDialog = %ImportDialog
@onready var header: HBoxContainer = %Header
@onready var deck_label: Label = %DeckLabel
@onready var remaining_label: Label = %RemainingLabel
@onready var question_label: Label = %QuestionLabel
@onready var answer_label: Label = %AnswerLabel
@onready var reveal_button: Button = %RevealButton
@onready var study_container: VBoxContainer = %StudyContainer
@onready var done_container: VBoxContainer = %DoneContainer
@onready var done_label: Label = %DoneLabel
@onready var restart_button: Button = %RestartButton

var _deck_file := ""
var _order := DeckOrdering.StudyOrder.SEQUENTIAL
var _session: StudySession
var _progress := Progress.new()
var _source_cards: Array[FlashCard] = []


func _ready() -> void:
	get_tree().root.size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")
	%ImportButton.pressed.connect(_on_import_pressed)
	import_dialog.file_selected.connect(import_deck_from_path)
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.use_native_dialog = true
	import_dialog.clear_filters()
	import_dialog.add_filter("*.md", "Markdown", "text/markdown,text/plain")
	%BackToLibraryButton.pressed.connect(show_library)
	reveal_button.pressed.connect(_on_reveal_pressed)
	%AgainButton.pressed.connect(_on_again_pressed)
	%GoodButton.pressed.connect(_on_good_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	if auto_start:
		show_library()


static func safe_insets_in_viewport(
	safe_area: Rect2i,
	window_size: Vector2i,
	viewport_size: Vector2
) -> Vector4:
	if window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO

	var scale := Vector2(
		viewport_size.x / float(window_size.x),
		viewport_size.y / float(window_size.y)
	)
	return Vector4(
		maxi(safe_area.position.x, 0) * scale.x,
		maxi(safe_area.position.y, 0) * scale.y,
		maxi(window_size.x - safe_area.end.x, 0) * scale.x,
		maxi(window_size.y - safe_area.end.y, 0) * scale.y
	)


func _apply_safe_area() -> void:
	var safe_insets := Vector4.ZERO
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		safe_insets = safe_insets_in_viewport(
			DisplayServer.get_display_safe_area(),
			DisplayServer.window_get_size(),
			get_viewport_rect().size
		)

	page_margin.offset_left = BASE_PAGE_MARGIN + safe_insets.x
	page_margin.offset_top = BASE_PAGE_MARGIN + safe_insets.y
	page_margin.offset_right = -(BASE_PAGE_MARGIN + safe_insets.z)
	page_margin.offset_bottom = -(BASE_PAGE_MARGIN + safe_insets.w)


func start_default_deck() -> void:
	show_library()


func show_library() -> void:
	DeckStorage.seed_sample_if_empty()
	_session = null
	_deck_file = ""
	import_status_label.visible = false
	library_container.visible = true
	header.visible = false
	study_container.visible = false
	done_container.visible = false
	_refresh_deck_list()


func start_deck(
	deck_file: String,
	order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
) -> void:
	var cards := DeckParser.parse(DeckStorage.read_deck(deck_file))
	_start_cards(deck_file, cards, order)


func start_sample_deck(
	order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
) -> void:
	var cards := DeckParser.parse(
		FileAccess.get_file_as_string(DeckStorage.SAMPLE_DECK_PATH)
	)
	_start_cards(DeckStorage.SAMPLE_DECK_PATH.get_file(), cards, order)


func _start_cards(
	deck_file: String,
	cards: Array[FlashCard],
	order: DeckOrdering.StudyOrder
) -> void:
	_deck_file = deck_file
	_order = order
	_progress = DeckStorage.load_progress(deck_file)
	_source_cards = cards.duplicate()
	library_container.visible = false
	header.visible = true
	_restart_session()


func _refresh_deck_list() -> void:
	for child in deck_list.get_children():
		child.free()

	var deck_files := DeckStorage.list_deck_files()
	empty_decks_label.visible = deck_files.is_empty()

	for deck_file in deck_files:
		var deck_button := Button.new()
		deck_button.name = "Deck_%s" % deck_file.validate_node_name()
		deck_button.text = DeckNaming.display_name(deck_file)
		deck_button.custom_minimum_size = Vector2(0, 84)
		deck_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deck_button.add_theme_font_size_override("font_size", 22)
		deck_button.pressed.connect(_on_deck_selected.bind(deck_file))
		deck_list.add_child(deck_button)


func _on_deck_selected(deck_file: String) -> void:
	start_deck(deck_file)


func _on_import_pressed() -> void:
	import_status_label.visible = false
	import_dialog.popup_file_dialog()


func import_deck_from_path(source_path: String) -> bool:
	var imported: Variant = DeckStorage.import_deck(source_path)
	if imported is not String:
		import_status_label.text = "덱을 가져오지 못했습니다."
		import_status_label.visible = true
		return false

	_refresh_deck_list()
	import_status_label.text = "'%s' 가져오기 완료" % DeckNaming.display_name(imported)
	import_status_label.visible = true
	return true


func _restart_session() -> void:
	var ordered_cards := DeckOrdering.apply(_order, _source_cards)
	_session = StudySession.new(ordered_cards)
	deck_label.text = DeckNaming.display_name(_deck_file)
	_show_current()


func _show_current() -> void:
	if _session == null or _session.is_finished():
		_show_message("학습 완료!", true)
		return

	var card := _session.current()
	study_container.visible = true
	done_container.visible = false
	question_label.text = card.question
	answer_label.text = card.answer
	answer_label.visible = false
	reveal_button.visible = true
	remaining_label.text = "%d장 남음" % _session.remaining()


func _show_message(message: String, can_restart: bool) -> void:
	study_container.visible = false
	done_container.visible = true
	done_label.text = message
	restart_button.visible = can_restart
	remaining_label.text = "0장 남음"


func _on_reveal_pressed() -> void:
	if _session == null or _session.is_finished():
		return

	answer_label.visible = true
	reveal_button.visible = false


func _on_again_pressed() -> void:
	if _session == null or _session.is_finished():
		return

	_progress.add_wrong(_session.current().question)
	DeckStorage.save_progress(_deck_file, _progress)
	_session.next()
	_show_current()


func _on_good_pressed() -> void:
	if _session == null or _session.is_finished():
		return

	_session.next()
	_show_current()


func _on_restart_pressed() -> void:
	if _deck_file.is_empty():
		return

	_progress = DeckStorage.load_progress(_deck_file)
	_restart_session()
