class_name MainApp
extends Control

const BASE_PAGE_MARGIN := 32.0
const EMPTY_DECK_MESSAGE := "빈 덱입니다. '# 질문' 형식으로 카드를 추가하세요."
const BROKEN_DECK_MESSAGE := "카드를 찾지 못했습니다. 각 질문을 '# 질문' 형식으로 작성하세요."
const EXPORT_DECK_NOT_FOUND_MESSAGE := "내보낼 덱 파일을 찾을 수 없습니다."
const EXPORT_TARGET_OPEN_FAILED_MESSAGE := "선택한 위치에 파일을 만들 수 없습니다. 저장 권한이나 위치를 확인하세요."
const EXPORT_WRITE_FAILED_MESSAGE := "파일을 저장하지 못했습니다. 저장 공간을 확인하고 다시 시도하세요."
const EXPORT_UNKNOWN_FAILED_MESSAGE := "덱을 내보내지 못했습니다. 다른 위치를 선택해 다시 시도하세요."
const DELETE_DECK_NOT_FOUND_MESSAGE := "삭제할 덱 파일을 찾을 수 없습니다."
const DELETE_DECK_FAILED_MESSAGE := "덱을 삭제하지 못했습니다. 파일이 사용 중인지 확인하고 다시 시도하세요."
const RENAME_EMPTY_MESSAGE := "덱 이름을 입력하세요."
const RENAME_INVALID_MESSAGE := "덱 이름에 < > : \" / \\ | ? * 문자나 끝 마침표를 사용할 수 없습니다."
const RENAME_DUPLICATE_MESSAGE := "같은 이름의 덱이 이미 있습니다."
const RENAME_DECK_NOT_FOUND_MESSAGE := "이름을 변경할 덱 파일을 찾을 수 없습니다."
const RENAME_FAILED_MESSAGE := "덱 이름을 변경하지 못했습니다. 다시 시도하세요."
const DUPLICATE_DECK_NOT_FOUND_MESSAGE := "복제할 덱 파일을 찾을 수 없습니다."
const DUPLICATE_DECK_FAILED_MESSAGE := "덱을 복제하지 못했습니다. 저장 공간을 확인하고 다시 시도하세요."
const DECK_TILE_SCENE := preload("res://src/main/deck_tile.tscn")
const ADD_DECK_TILE_SCENE := preload("res://src/main/add_deck_tile.tscn")

@export var auto_start := true

@onready var page_margin: MarginContainer = $Margin
@onready var library_container: VBoxContainer = $Margin/Page/LibraryContainer
@onready var deck_list: HFlowContainer = $Margin/Page/LibraryContainer/DeckListScroll/DeckList
@onready var empty_decks_label: Label = $Margin/Page/LibraryContainer/EmptyDecksLabel
@onready var library_status_label: Label = $Margin/Page/LibraryContainer/LibraryStatusLabel
@onready var import_dialog: FileDialog = $Margin/Page/LibraryContainer/ImportDialog
@onready var export_dialog: FileDialog = $Margin/Page/LibraryContainer/ExportDialog
@onready var deck_context_menu: Control = $DeckContextMenu
@onready var deck_context_menu_panel: PanelContainer = $DeckContextMenu/DeckContextMenuPanel
@onready var rename_deck_button := (
	deck_context_menu.find_child("RenameDeckButton", true, false) as Button
)
@onready var duplicate_deck_button := (
	deck_context_menu.find_child("DuplicateDeckButton", true, false) as Button
)
@onready var export_deck_button := (
	deck_context_menu.find_child("ExportDeckButton", true, false) as Button
)
@onready var delete_deck_button := (
	deck_context_menu.find_child("DeleteDeckButton", true, false) as Button
)
@onready var rename_deck_overlay: Control = $RenameDeckOverlay
@onready var rename_deck_input: LineEdit = $RenameDeckOverlay/RenameDeckPanel/Margin/Content/RenameDeckInput
@onready var rename_error_label: Label = $RenameDeckOverlay/RenameDeckPanel/Margin/Content/RenameErrorLabel
@onready var delete_confirmation_overlay: Control = $DeleteConfirmationOverlay
@onready var delete_confirmation_title: Label = $DeleteConfirmationOverlay/DeleteConfirmationPanel/Margin/Content/DeleteConfirmationTitle
@onready var exit_confirmation_overlay: Control = $ExitConfirmationOverlay
@onready var study_flow: VBoxContainer = $Margin/Page/StudyFlow
@onready var deck_label: Label = $Margin/Page/StudyFlow/Header/DeckLabel
@onready var remaining_label: Label = $Margin/Page/StudyFlow/Header/RemainingLabel
@onready var question_label: Label = $Margin/Page/StudyFlow/StudyContainer/Card/CardMargin/CardContent/QuestionScroll/QuestionLabel
@onready var answer_label: Label = $Margin/Page/StudyFlow/StudyContainer/Card/CardMargin/CardContent/AnswerScroll/AnswerLabel
@onready var reveal_button: Button = $Margin/Page/StudyFlow/StudyContainer/RevealButton
@onready var study_container: VBoxContainer = $Margin/Page/StudyFlow/StudyContainer
@onready var done_container: VBoxContainer = $Margin/Page/StudyFlow/DoneContainer
@onready var done_label: Label = $Margin/Page/StudyFlow/DoneContainer/DoneLabel
@onready var restart_button: Button = $Margin/Page/StudyFlow/DoneContainer/RestartButton

var _deck_file := ""
var _order := DeckOrdering.StudyOrder.SEQUENTIAL
var _session: StudySession
var _progress := Progress.new()
var _source_cards: Array[FlashCard] = []
var _menu_deck_file := ""


func _ready() -> void:
	get_tree().root.size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")
	import_dialog.file_selected.connect(import_deck_from_path)
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.use_native_dialog = true
	import_dialog.clear_filters()
	import_dialog.add_filter("*.md", "Markdown", "text/markdown,text/plain")
	export_dialog.file_selected.connect(_on_export_file_selected)
	export_dialog.canceled.connect(_on_export_canceled)
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.use_native_dialog = true
	export_dialog.clear_filters()
	export_dialog.add_filter("*.md", "Markdown", "text/markdown,text/plain")
	rename_deck_button.pressed.connect(_on_rename_pressed)
	duplicate_deck_button.pressed.connect(_on_duplicate_pressed)
	export_deck_button.pressed.connect(_on_export_pressed)
	delete_deck_button.pressed.connect(_on_delete_pressed)
	$DeckContextMenu/DismissContextMenuButton.pressed.connect(_on_deck_context_dismissed)
	$RenameDeckOverlay/RenameDeckPanel/Margin/Content/Buttons/CancelRenameButton.pressed.connect(_on_rename_canceled)
	$RenameDeckOverlay/RenameDeckPanel/Margin/Content/Buttons/ConfirmRenameButton.pressed.connect(_on_rename_confirmed)
	rename_deck_input.text_submitted.connect(_on_rename_submitted)
	$DeleteConfirmationOverlay/DeleteConfirmationPanel/Margin/Content/Buttons/CancelDeleteButton.pressed.connect(_on_delete_canceled)
	$DeleteConfirmationOverlay/DeleteConfirmationPanel/Margin/Content/Buttons/ConfirmDeleteButton.pressed.connect(_on_delete_confirmed)
	$ExitConfirmationOverlay/ExitConfirmationPanel/Margin/Content/Buttons/CancelExitButton.pressed.connect(_on_exit_canceled)
	$ExitConfirmationOverlay/ExitConfirmationPanel/Margin/Content/Buttons/ConfirmExitButton.pressed.connect(_on_exit_confirmed)
	$Margin/Page/StudyFlow/Header/BackToLibraryButton.pressed.connect(show_library)
	reveal_button.pressed.connect(_on_reveal_pressed)
	$Margin/Page/StudyFlow/StudyContainer/Actions/AgainButton.pressed.connect(_on_again_pressed)
	$Margin/Page/StudyFlow/StudyContainer/Actions/GoodButton.pressed.connect(_on_good_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	if auto_start:
		show_library()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return

	handle_back_request()


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
	_menu_deck_file = ""
	deck_context_menu.hide()
	rename_deck_overlay.hide()
	delete_confirmation_overlay.hide()
	library_status_label.visible = false
	library_container.visible = true
	study_flow.visible = false
	study_container.visible = false
	done_container.visible = false
	_refresh_deck_list()


func start_deck(
	deck_file: String,
	order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_status("덱 파일을 읽지 못했습니다.")
		return false

	var deck_text := DeckStorage.read_deck(deck_file)
	var error_message := deck_content_error(deck_text)
	if not error_message.is_empty():
		_show_library_status(error_message)
		return false

	var cards := DeckParser.parse(deck_text)
	_start_cards(deck_file, cards, order)
	return true


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
	study_flow.visible = true
	_restart_session()


func _refresh_deck_list() -> void:
	for child in deck_list.get_children():
		child.free()

	var deck_files := DeckStorage.list_deck_files()
	empty_decks_label.visible = deck_files.is_empty()

	for deck_file in deck_files:
		var deck_tile := DECK_TILE_SCENE.instantiate() as DeckTileView
		deck_tile.name = "Deck_%s" % deck_file.validate_node_name()
		deck_list.add_child(deck_tile)
		var card_count := DeckParser.parse(DeckStorage.read_deck(deck_file)).size()
		deck_tile.setup(deck_file, DeckNaming.display_name(deck_file), card_count)
		deck_tile.selected.connect(_on_deck_selected)
		deck_tile.menu_requested.connect(_on_deck_menu_requested)

	var add_deck_tile := ADD_DECK_TILE_SCENE.instantiate() as AddDeckTileView
	deck_list.add_child(add_deck_tile)
	add_deck_tile.pressed.connect(_on_import_pressed)


func _on_deck_selected(deck_file: String) -> void:
	deck_context_menu.hide()
	start_deck(deck_file)


func _on_deck_menu_requested(deck_file: String, anchor: Control) -> void:
	_menu_deck_file = deck_file
	export_dialog.current_file = "%s%s" % [
		DeckNaming.display_name(deck_file),
		DeckNaming.EXTENSION,
	]
	deck_context_menu.show()
	deck_context_menu_panel.reset_size()
	_position_deck_context_menu(anchor)


func _position_deck_context_menu(anchor: Control) -> void:
	var anchor_to_menu := (
		deck_context_menu.get_global_transform().affine_inverse()
		* anchor.get_global_transform()
	)
	var anchor_position := anchor_to_menu * Vector2.ZERO
	var anchor_end := anchor_to_menu * anchor.size
	var anchor_rect := Rect2(anchor_position, anchor_end - anchor_position)
	var menu_size := deck_context_menu_panel.get_combined_minimum_size()
	deck_context_menu_panel.size = menu_size
	var viewport_size := deck_context_menu.size
	var margin := 12.0
	var position := Vector2(
		anchor_rect.end.x - menu_size.x,
		anchor_rect.position.y
	)
	position.x = clampf(position.x, margin, viewport_size.x - menu_size.x - margin)
	if position.y + menu_size.y > viewport_size.y - margin:
		position.y = anchor_rect.end.y - menu_size.y
	position.y = clampf(position.y, margin, viewport_size.y - menu_size.y - margin)
	deck_context_menu_panel.position = position


func _on_deck_context_dismissed() -> void:
	deck_context_menu.hide()
	_menu_deck_file = ""


func handle_back_request() -> bool:
	if rename_deck_overlay.visible:
		_on_rename_canceled()
		return true

	if delete_confirmation_overlay.visible:
		_on_delete_canceled()
		return true

	if deck_context_menu.visible:
		_on_deck_context_dismissed()
		return true

	if exit_confirmation_overlay.visible:
		_on_exit_canceled()
		return true

	if library_container.visible:
		exit_confirmation_overlay.show()
		return true

	show_library()
	return true


func _on_exit_canceled() -> void:
	exit_confirmation_overlay.hide()


func _on_exit_confirmed() -> void:
	get_tree().quit()


func _on_import_pressed() -> void:
	library_status_label.visible = false
	import_dialog.popup_file_dialog()


func _on_export_pressed() -> void:
	if _menu_deck_file.is_empty():
		deck_context_menu.hide()
		_show_library_status(EXPORT_DECK_NOT_FOUND_MESSAGE)
		return

	deck_context_menu.hide()
	export_dialog.popup_file_dialog()


func _on_export_file_selected(target_path: String) -> void:
	export_deck_to_path(_menu_deck_file, target_path)
	_menu_deck_file = ""


func _on_export_canceled() -> void:
	_menu_deck_file = ""


func _on_duplicate_pressed() -> void:
	var deck_file := _menu_deck_file
	deck_context_menu.hide()
	_menu_deck_file = ""
	duplicate_deck_from_library(deck_file)


func duplicate_deck_from_library(deck_file: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_status(DUPLICATE_DECK_NOT_FOUND_MESSAGE)
		return false

	var duplicated: Variant = DeckStorage.duplicate_deck(deck_file)
	if duplicated is not String:
		push_warning("Deck duplicate failed (source=%s)" % deck_file)
		_show_library_status(DUPLICATE_DECK_FAILED_MESSAGE)
		return false

	_refresh_deck_list()
	_show_library_status(
		"'%s' → '%s' 복제 완료"
		% [DeckNaming.display_name(deck_file), DeckNaming.display_name(duplicated)]
	)
	return true


func _on_rename_pressed() -> void:
	deck_context_menu.hide()
	if not DeckStorage.deck_exists(_menu_deck_file):
		_menu_deck_file = ""
		_show_library_status(RENAME_DECK_NOT_FOUND_MESSAGE)
		return

	rename_deck_input.text = DeckNaming.display_name(_menu_deck_file)
	rename_error_label.hide()
	rename_deck_overlay.show()
	rename_deck_input.call_deferred("grab_focus")
	rename_deck_input.call_deferred("select_all")


func _on_rename_canceled() -> void:
	rename_deck_overlay.hide()
	_menu_deck_file = ""


func _on_rename_confirmed() -> void:
	rename_deck_from_library(_menu_deck_file, rename_deck_input.text)


func _on_rename_submitted(_new_name: String) -> void:
	_on_rename_confirmed()


func rename_deck_from_library(deck_file: String, new_display_name: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_rename_error(RENAME_DECK_NOT_FOUND_MESSAGE)
		return false

	var trimmed_name := new_display_name.strip_edges()
	if trimmed_name.is_empty():
		_show_rename_error(RENAME_EMPTY_MESSAGE)
		return false
	if not DeckNaming.is_valid_display_name(trimmed_name):
		_show_rename_error(RENAME_INVALID_MESSAGE)
		return false

	var new_file := DeckNaming.deck_file_name(trimmed_name)
	if new_file.to_lower() == deck_file.to_lower():
		rename_deck_overlay.hide()
		_menu_deck_file = ""
		_show_library_status("이름이 변경되지 않았습니다.")
		return true

	for existing_file in DeckStorage.list_deck_files():
		if existing_file.to_lower() == new_file.to_lower():
			_show_rename_error(RENAME_DUPLICATE_MESSAGE)
			return false

	var old_display_name := DeckNaming.display_name(deck_file)
	if not DeckStorage.rename_deck(deck_file, new_file):
		push_warning("Deck rename failed (source=%s, target=%s)" % [deck_file, new_file])
		_show_rename_error(RENAME_FAILED_MESSAGE)
		return false

	rename_deck_overlay.hide()
	_menu_deck_file = ""
	_refresh_deck_list()
	_show_library_status("'%s' → '%s' 이름 변경 완료" % [old_display_name, trimmed_name])
	return true


func _show_rename_error(message: String) -> void:
	rename_error_label.text = message
	rename_error_label.show()


func _on_delete_pressed() -> void:
	deck_context_menu.hide()
	if not DeckStorage.deck_exists(_menu_deck_file):
		_menu_deck_file = ""
		_show_library_status(DELETE_DECK_NOT_FOUND_MESSAGE)
		return

	delete_confirmation_title.text = "'%s' 덱을 삭제할까요?" % DeckNaming.display_name(
		_menu_deck_file
	)
	delete_confirmation_overlay.show()


func _on_delete_canceled() -> void:
	delete_confirmation_overlay.hide()
	_menu_deck_file = ""


func _on_delete_confirmed() -> void:
	var deck_file := _menu_deck_file
	delete_confirmation_overlay.hide()
	_menu_deck_file = ""
	delete_deck_from_library(deck_file)


func delete_deck_from_library(deck_file: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_status(DELETE_DECK_NOT_FOUND_MESSAGE)
		return false

	var display_name := DeckNaming.display_name(deck_file)
	if not DeckStorage.delete_deck(deck_file):
		push_warning("Deck delete failed (source=%s)" % deck_file)
		_show_library_status(DELETE_DECK_FAILED_MESSAGE)
		return false

	_refresh_deck_list()
	_show_library_status("'%s' 삭제 완료" % display_name)
	return true


func export_deck_to_path(deck_file: String, target_path: String) -> bool:
	var markdown_path := ensure_markdown_extension(target_path)
	var result := DeckStorage.export_deck_result(deck_file, markdown_path)
	if result == DeckStorage.ExportResult.OK:
		_show_library_status("'%s' 내보내기 완료" % markdown_path.uri_decode().get_file())
		return true

	var message := export_error_message(result)
	push_warning(
		"Deck export failed (result=%s, source=%s, target=%s)"
		% [result, deck_file, markdown_path]
	)
	_show_library_status(message)
	return false


static func ensure_markdown_extension(target_path: String) -> String:
	if target_path.to_lower().ends_with(DeckNaming.EXTENSION):
		return target_path
	return "%s%s" % [target_path, DeckNaming.EXTENSION]


static func export_error_message(result: DeckStorage.ExportResult) -> String:
	match result:
		DeckStorage.ExportResult.DECK_NOT_FOUND:
			return EXPORT_DECK_NOT_FOUND_MESSAGE
		DeckStorage.ExportResult.TARGET_OPEN_FAILED:
			return EXPORT_TARGET_OPEN_FAILED_MESSAGE
		DeckStorage.ExportResult.WRITE_FAILED:
			return EXPORT_WRITE_FAILED_MESSAGE
		_:
			return EXPORT_UNKNOWN_FAILED_MESSAGE


func import_deck_from_path(source_path: String) -> bool:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		_show_library_status("덱을 가져오지 못했습니다.")
		return false

	var error_message := deck_content_error(source.get_as_text())
	if not error_message.is_empty():
		_show_library_status(error_message)
		return false

	var imported: Variant = DeckStorage.import_deck(source_path)
	if imported is not String:
		_show_library_status("덱을 가져오지 못했습니다.")
		return false

	_refresh_deck_list()
	_show_library_status("'%s' 가져오기 완료" % DeckNaming.display_name(imported))
	return true


static func deck_content_error(deck_text: String) -> String:
	if deck_text.strip_edges().is_empty():
		return EMPTY_DECK_MESSAGE

	if DeckParser.parse(deck_text).is_empty():
		return BROKEN_DECK_MESSAGE

	return ""


func _show_library_status(message: String) -> void:
	if not library_container.visible:
		show_library()

	library_status_label.text = message
	library_status_label.visible = true


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
