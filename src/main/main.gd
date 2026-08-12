class_name MainApp
extends Control

enum StudyScope {
	ALL,
	INCOMPLETE,
	WRONG,
}

enum CardEditorOrigin {
	CARD_LIST,
	STUDY,
}

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
const CARD_QUESTION_EMPTY_MESSAGE := "질문을 입력하세요."
const CARD_ANSWER_HEADING_MESSAGE := "답의 줄 시작에는 '# '를 사용할 수 없습니다."
const CARD_SAVE_FAILED_MESSAGE := "카드를 저장하지 못했습니다. 저장 공간을 확인하세요."
const LAST_CARD_DELETE_MESSAGE := "덱에는 카드가 최소 1장 필요합니다."
const STUDY_INPUT_LOCK_SECONDS := 0.22
const DECK_TILE_SCENE := preload("res://src/main/deck_tile.tscn")
const ADD_DECK_TILE_SCENE := preload("res://src/main/add_deck_tile.tscn")
const CARD_LIST_ROW_SCENE := preload("res://src/main/card_list_row.tscn")

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
@onready var study_ready_view: VBoxContainer = $Margin/Page/StudyReadyView
@onready var ready_overview: VBoxContainer = $Margin/Page/StudyReadyView/DeckStack/DeckCover/Margin/OverviewContent
@onready var new_study_content: VBoxContainer = $Margin/Page/StudyReadyView/DeckStack/DeckCover/Margin/NewStudyContent
@onready var ready_deck_name_label: Label = ready_overview.get_node("ReadyDeckNameLabel")
@onready var setup_deck_name_label: Label = new_study_content.get_node("SetupDeckNameLabel")
@onready var ready_total_count_label: Label = ready_overview.get_node("Stats/Total/ReadyTotalCountLabel")
@onready var ready_new_count_label: Label = ready_overview.get_node("Stats/New/ReadyNewCountLabel")
@onready var ready_learning_count_label: Label = ready_overview.get_node("Stats/Learning/ReadyLearningCountLabel")
@onready var ready_mastered_count_label: Label = ready_overview.get_node("Stats/Mastered/ReadyMasteredCountLabel")
@onready var mastery_progress: ProgressBar = ready_overview.get_node("MasteryProgress")
@onready var study_scope_option: OptionButton = new_study_content.get_node("StudyScopeOption")
@onready var study_order_option: OptionButton = new_study_content.get_node("StudyOrderOption")
@onready var ready_status_label: Label = new_study_content.get_node("ReadyStatusLabel")
@onready var setup_description: Label = new_study_content.get_node("SetupDescription")
@onready var start_study_button: Button = new_study_content.get_node("StartStudyButton")
@onready var continue_study_button: Button = ready_overview.get_node("ContinueStudyButton")
@onready var card_list_view: VBoxContainer = $Margin/Page/CardListView
@onready var card_list_deck_label: Label = $Margin/Page/CardListView/Header/CardListDeckLabel
@onready var card_list_status_label: Label = $Margin/Page/CardListView/CardListStatusLabel
@onready var card_rows: VBoxContainer = $Margin/Page/CardListView/CardListScroll/CardRows
@onready var card_editor_view: VBoxContainer = $Margin/Page/CardEditorView
@onready var card_editor_title: Label = $Margin/Page/CardEditorView/Header/CardEditorTitle
@onready var delete_card_button: Button = $Margin/Page/CardEditorView/Header/DeleteCardButton
@onready var wrong_minus_button: Button = $Margin/Page/CardEditorView/CardEditorProperties/WrongCountControls/WrongMinusButton
@onready var editor_wrong_count_label: Label = $Margin/Page/CardEditorView/CardEditorProperties/WrongCountControls/EditorWrongCountLabel
@onready var wrong_plus_button: Button = $Margin/Page/CardEditorView/CardEditorProperties/WrongCountControls/WrongPlusButton
@onready var reset_card_progress_button: Button = $Margin/Page/CardEditorView/CardEditorProperties/ResetCardProgressButton
@onready var card_status_option: OptionButton = $Margin/Page/CardEditorView/CardEditorProperties/CardStatusOption
@onready var card_question_input: LineEdit = $Margin/Page/CardEditorView/CardQuestionInput
@onready var card_answer_input: TextEdit = $Margin/Page/CardEditorView/CardAnswerInput
@onready var card_editor_error_label: Label = $Margin/Page/CardEditorView/CardEditorErrorLabel
@onready var card_delete_confirmation_overlay: Control = $CardDeleteConfirmationOverlay
@onready var discard_card_changes_overlay: Control = $DiscardCardChangesOverlay
@onready var study_flow: VBoxContainer = $Margin/Page/StudyFlow
@onready var deck_label: Label = $Margin/Page/StudyFlow/Header/DeckLabel
@onready var edit_study_card_button: Button = $Margin/Page/StudyFlow/Header/EditStudyCardButton
@onready var remaining_label: Label = $Margin/Page/StudyFlow/Header/RemainingLabel
@onready var study_progress_bar: ProgressBar = $Margin/Page/StudyFlow/StudyProgressBar
@onready var study_gesture_surface: StudyGestureSurface = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame
@onready var card_properties: HBoxContainer = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/CardProperties
@onready var card_status_label: Label = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/CardProperties/StatusBadge/Margin/CardStatusLabel
@onready var wrong_tally: WrongTallyView = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/CardProperties/WrongTally
@onready var question_scroll: ScrollContainer = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/QuestionScroll
@onready var question_label: Label = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/QuestionScroll/QuestionLabel
@onready var answer_label: Label = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/AnswerScroll/AnswerLabel
@onready var answer_scroll: ScrollContainer = $Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame/CardMargin/CardContent/AnswerScroll
@onready var study_actions: HBoxContainer = $Margin/Page/StudyFlow/StudyContainer/Actions
@onready var again_button: Button = $Margin/Page/StudyFlow/StudyContainer/Actions/AgainButton
@onready var good_button: Button = $Margin/Page/StudyFlow/StudyContainer/Actions/GoodButton
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
var _ready_deck_file := ""
var _ready_cards: Array[FlashCard] = []
var _ready_deck_hash: int
var _active_card_indices: Array[int] = []
var _active_order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
var _active_scope: StudyScope = StudyScope.ALL
var _editing_deck_file := ""
var _editing_cards: Array[FlashCard] = []
var _editing_card_index := -1
var _editing_original_question := ""
var _editing_original_answer := ""
var _editing_original_wrong_count := 0
var _editing_original_status: CardStatus.Value = CardStatus.Value.NEW
var _editing_wrong_count := 0
var _card_editor_origin: CardEditorOrigin = CardEditorOrigin.CARD_LIST
var _study_edit_source_index := -1
var _study_edit_return_show_answer := false
var _study_input_locked := false
var _study_input_lock_generation := 0


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
	$Margin/Page/StudyReadyView/Header/BackToLibraryButton.pressed.connect(show_library)
	(ready_overview.get_node("OpenStudySetupButton") as Button).pressed.connect(
		_on_open_study_setup
	)
	continue_study_button.pressed.connect(_on_continue_study_pressed)
	start_study_button.pressed.connect(_on_start_study_pressed)
	(new_study_content.get_node("CancelStudySetupButton") as Button).pressed.connect(
		_on_cancel_study_setup
	)
	(ready_overview.get_node("ManageCardsButton") as Button).pressed.connect(
		_on_manage_cards_pressed
	)
	$Margin/Page/CardListView/Header/BackFromCardListButton.pressed.connect(
		_return_to_ready_from_card_list
	)
	$Margin/Page/CardListView/AddCardButton.pressed.connect(_on_add_card_pressed)
	$Margin/Page/CardEditorView/Header/CancelCardEditButton.pressed.connect(
		_request_close_card_editor
	)
	delete_card_button.pressed.connect(_on_delete_card_pressed)
	wrong_minus_button.pressed.connect(_on_wrong_minus_pressed)
	wrong_plus_button.pressed.connect(_on_wrong_plus_pressed)
	reset_card_progress_button.pressed.connect(_on_reset_card_progress_pressed)
	card_status_option.item_selected.connect(_on_card_status_selected)
	$Margin/Page/CardEditorView/SaveCardButton.pressed.connect(_on_save_card_pressed)
	$CardDeleteConfirmationOverlay/Panel/Margin/Content/Buttons/CancelCardDeleteButton.pressed.connect(
		_on_card_delete_canceled
	)
	$CardDeleteConfirmationOverlay/Panel/Margin/Content/Buttons/ConfirmCardDeleteButton.pressed.connect(
		_on_card_delete_confirmed
	)
	$DiscardCardChangesOverlay/Panel/Margin/Content/Buttons/KeepEditingButton.pressed.connect(
		_on_discard_card_changes_canceled
	)
	$DiscardCardChangesOverlay/Panel/Margin/Content/Buttons/DiscardChangesButton.pressed.connect(
		_on_discard_card_changes_confirmed
	)
	$Margin/Page/StudyFlow/Header/BackToReadyButton.pressed.connect(_return_to_study_ready)
	edit_study_card_button.pressed.connect(_on_edit_study_card_pressed)
	study_gesture_surface.swiped.connect(_on_study_swiped)
	study_gesture_surface.tapped.connect(_on_card_tapped)
	again_button.pressed.connect(_on_again_requested)
	good_button.pressed.connect(_on_good_requested)
	restart_button.pressed.connect(_on_restart_pressed)
	_setup_study_ready_options()
	_setup_card_editor_status_options()

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
	_ready_deck_file = ""
	_ready_cards.clear()
	_ready_deck_hash = 0
	_active_card_indices.clear()
	_editing_deck_file = ""
	_editing_cards.clear()
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false
	_menu_deck_file = ""
	deck_context_menu.hide()
	rename_deck_overlay.hide()
	delete_confirmation_overlay.hide()
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	library_status_label.visible = false
	library_container.visible = true
	study_ready_view.visible = false
	card_list_view.visible = false
	card_editor_view.visible = false
	study_flow.visible = false
	study_container.visible = false
	done_container.visible = false
	_refresh_deck_list()


func show_study_ready(deck_file: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_status("덱 파일을 읽지 못했습니다.")
		return false

	var deck_text := DeckStorage.read_deck(deck_file)
	var error_message := deck_content_error(deck_text)
	if not error_message.is_empty():
		_show_library_status(error_message)
		return false

	_ready_deck_file = deck_file
	_ready_cards = DeckParser.parse(deck_text)
	_ready_deck_hash = deck_text.hash()
	_menu_deck_file = ""
	deck_context_menu.hide()
	library_container.visible = false
	card_list_view.visible = false
	card_editor_view.visible = false
	study_flow.visible = false
	study_ready_view.visible = true
	ready_status_label.hide()
	_update_study_ready_summary()
	_update_continue_action()
	_show_ready_overview()
	return true


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
	_active_card_indices.clear()
	library_container.visible = false
	study_ready_view.visible = false
	card_list_view.visible = false
	card_editor_view.visible = false
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
	show_study_ready(deck_file)


func _setup_study_ready_options() -> void:
	study_scope_option.clear()
	study_scope_option.add_item("전체 카드", StudyScope.ALL)
	study_scope_option.add_item("미완료 카드", StudyScope.INCOMPLETE)
	study_scope_option.add_item("오답 카드", StudyScope.WRONG)
	study_order_option.clear()
	study_order_option.add_item("순서대로", DeckOrdering.StudyOrder.SEQUENTIAL)
	study_order_option.add_item("섞어서", DeckOrdering.StudyOrder.SHUFFLE)


func _setup_card_editor_status_options() -> void:
	card_status_option.clear()
	card_status_option.add_item("NEW", CardStatus.Value.NEW)
	card_status_option.add_item("LEARNING", CardStatus.Value.LEARNING)
	card_status_option.add_item("MASTERED", CardStatus.Value.MASTERED)


func _update_study_ready_summary() -> void:
	var progress := DeckStorage.load_progress(_ready_deck_file)
	var new_count := 0
	var learning_count := 0
	var mastered_count := 0
	for card in _ready_cards:
		match progress.get_status(card.question):
			CardStatus.Value.LEARNING:
				learning_count += 1
			CardStatus.Value.MASTERED:
				mastered_count += 1
			_:
				new_count += 1

	ready_deck_name_label.text = DeckNaming.display_name(_ready_deck_file)
	setup_deck_name_label.text = DeckNaming.display_name(_ready_deck_file)
	ready_total_count_label.text = str(_ready_cards.size())
	ready_new_count_label.text = str(new_count)
	ready_learning_count_label.text = str(learning_count)
	ready_mastered_count_label.text = str(mastered_count)
	mastery_progress.max_value = maxi(_ready_cards.size(), 1)
	mastery_progress.value = mastered_count


func _show_ready_overview() -> void:
	new_study_content.hide()
	ready_overview.show()
	ready_status_label.hide()


func _on_open_study_setup() -> void:
	var resume := DeckStorage.load_study_resume(_ready_deck_file)
	var replacing_resume := _is_valid_resume(resume)
	setup_description.text = (
		"진행 중 세션은 교체되며 카드별 진행 기록은 유지됩니다."
		if replacing_resume
		else "진행 기록은 유지하고 새로운 학습 세션을 시작합니다."
	)
	start_study_button.text = (
		"진행 중 세션 교체하고 시작"
		if replacing_resume
		else "새 학습 시작"
	)
	ready_status_label.hide()
	ready_overview.hide()
	new_study_content.show()


func _on_cancel_study_setup() -> void:
	_show_ready_overview()


func _on_manage_cards_pressed() -> void:
	_open_card_list(_ready_deck_file)


func _open_card_list(deck_file: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_status("편집할 덱 파일을 찾을 수 없습니다.")
		return false

	_editing_deck_file = deck_file
	_editing_cards = _copy_cards(DeckParser.parse(DeckStorage.read_deck(deck_file)))
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false
	card_list_deck_label.text = DeckNaming.display_name(deck_file)
	card_list_status_label.hide()
	var source := DeckStorage.read_deck(deck_file).replace("\r\n", "\n")
	if DeckWriter.to_markdown(_editing_cards) != source:
		_show_card_list_status(
			"카드를 저장하면 Markdown이 앱 표준 형식으로 정리됩니다."
		)
	_refresh_card_rows()
	library_container.hide()
	study_ready_view.hide()
	study_flow.hide()
	card_editor_view.hide()
	card_list_view.show()
	return true


static func _copy_cards(cards: Array[FlashCard]) -> Array[FlashCard]:
	var copies: Array[FlashCard] = []
	for card in cards:
		copies.append(FlashCard.new(card.question, card.answer))
	return copies


func _refresh_card_rows() -> void:
	for child in card_rows.get_children():
		child.free()
	for index in _editing_cards.size():
		var row := CARD_LIST_ROW_SCENE.instantiate() as CardListRow
		card_rows.add_child(row)
		row.setup(index, _editing_cards[index])
		row.selected.connect(_on_card_row_selected)


func _on_card_row_selected(index: int) -> void:
	if index < 0 or index >= _editing_cards.size():
		return
	_open_card_editor(index)


func _on_add_card_pressed() -> void:
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_open_card_editor(-1)


func _on_edit_study_card_pressed() -> void:
	if (
		_session == null
		or _session.is_finished()
		or not DeckStorage.deck_exists(_deck_file)
	):
		return

	var current_card := _session.current()
	var deck_cards := DeckParser.parse(DeckStorage.read_deck(_deck_file))
	var deck_index := _current_study_deck_index(deck_cards, current_card)
	if deck_index < 0:
		return

	study_gesture_surface.cancel_drag()
	_reset_study_input_lock()
	_save_active_study_resume()
	_editing_deck_file = _deck_file
	_editing_cards = _copy_cards(deck_cards)
	_card_editor_origin = CardEditorOrigin.STUDY
	_study_edit_source_index = _source_cards.find(current_card)
	_study_edit_return_show_answer = answer_scroll.visible
	study_flow.hide()
	card_list_view.hide()
	_open_card_editor(deck_index)


func _current_study_deck_index(
	deck_cards: Array[FlashCard],
	current_card: FlashCard
) -> int:
	if (
		not _active_card_indices.is_empty()
		and _session.position() < _active_card_indices.size()
	):
		var active_index := _active_card_indices[_session.position()]
		if active_index >= 0 and active_index < deck_cards.size():
			var indexed_card := deck_cards[active_index]
			if (
				indexed_card.question == current_card.question
				and indexed_card.answer == current_card.answer
			):
				return active_index

	var source_index := _source_cards.find(current_card)
	if (
		_active_card_indices.is_empty()
		and source_index >= 0
		and source_index < deck_cards.size()
	):
		var source_card := deck_cards[source_index]
		if (
			source_card.question == current_card.question
			and source_card.answer == current_card.answer
		):
			return source_index

	for index in deck_cards.size():
		var card := deck_cards[index]
		if (
			card.question == current_card.question
			and card.answer == current_card.answer
		):
			return index
	return -1


func _open_card_editor(index: int) -> void:
	_editing_card_index = index
	card_editor_error_label.hide()
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	var progress := DeckStorage.load_progress(_editing_deck_file)
	if index < 0:
		_editing_original_question = ""
		_editing_original_answer = ""
		_editing_original_wrong_count = 0
		_editing_original_status = CardStatus.Value.NEW
		card_editor_title.text = "카드 추가"
		delete_card_button.hide()
	else:
		var card := _editing_cards[index]
		_editing_original_question = card.question
		_editing_original_answer = card.answer
		_editing_original_wrong_count = progress.get_wrong_count(card.question)
		_editing_original_status = progress.get_status(card.question)
		card_editor_title.text = (
			"학습 중 카드 편집"
			if _card_editor_origin == CardEditorOrigin.STUDY
			else "카드 편집"
		)
		delete_card_button.visible = _card_editor_origin == CardEditorOrigin.CARD_LIST
	_editing_wrong_count = _editing_original_wrong_count
	_select_card_editor_status(_editing_original_status)
	_update_card_editor_learning_fields()
	card_question_input.text = _editing_original_question
	card_answer_input.text = _editing_original_answer
	card_list_view.hide()
	card_editor_view.show()
	card_question_input.call_deferred("grab_focus")


func _request_close_card_editor() -> void:
	if _card_editor_has_changes():
		discard_card_changes_overlay.show()
		return
	_close_card_editor_without_save()


func _card_editor_has_changes() -> bool:
	return (
		card_question_input.text != _editing_original_question
		or card_answer_input.text != _editing_original_answer
		or _editing_wrong_count != _editing_original_wrong_count
		or _card_editor_status() != _editing_original_status
	)


func _on_wrong_minus_pressed() -> void:
	_editing_wrong_count = maxi(_editing_wrong_count - 1, 0)
	_update_card_editor_learning_fields()


func _on_wrong_plus_pressed() -> void:
	_editing_wrong_count += 1
	_update_card_editor_learning_fields()


func _on_reset_card_progress_pressed() -> void:
	_editing_wrong_count = 0
	_select_card_editor_status(CardStatus.Value.NEW)
	_update_card_editor_learning_fields()


func _on_card_status_selected(_index: int) -> void:
	_update_card_editor_learning_fields()


func _select_card_editor_status(status: CardStatus.Value) -> void:
	var item_index := card_status_option.get_item_index(status)
	if item_index >= 0:
		card_status_option.select(item_index)


func _card_editor_status() -> CardStatus.Value:
	return card_status_option.get_selected_id()


func _update_card_editor_learning_fields() -> void:
	editor_wrong_count_label.text = str(_editing_wrong_count)
	editor_wrong_count_label.tooltip_text = "오답 %d회" % _editing_wrong_count
	wrong_minus_button.disabled = _editing_wrong_count == 0
	reset_card_progress_button.disabled = (
		_editing_wrong_count == 0
		and _card_editor_status() == CardStatus.Value.NEW
	)


func _on_discard_card_changes_canceled() -> void:
	discard_card_changes_overlay.hide()


func _on_discard_card_changes_confirmed() -> void:
	discard_card_changes_overlay.hide()
	_close_card_editor_without_save()


func _close_card_editor_without_save() -> void:
	var return_to_study := _card_editor_origin == CardEditorOrigin.STUDY
	var restore_answer := _study_edit_return_show_answer
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	card_editor_view.hide()
	if return_to_study:
		card_list_view.hide()
		study_flow.show()
		if _session != null and not _session.is_finished():
			_show_current()
			if restore_answer:
				_set_answer_visible(true)
	else:
		card_list_view.show()
	_editing_card_index = -1
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false


func _on_save_card_pressed() -> void:
	var question := card_question_input.text.strip_edges()
	var answer := card_answer_input.text.replace("\r\n", "\n").strip_edges()
	if question.is_empty():
		_show_card_editor_error(CARD_QUESTION_EMPTY_MESSAGE)
		return
	if answer_has_question_heading(answer):
		_show_card_editor_error(CARD_ANSWER_HEADING_MESSAGE)
		return

	var updated := _copy_cards(_editing_cards)
	if _editing_card_index < 0:
		updated.append(FlashCard.new(question, answer))
	else:
		updated[_editing_card_index] = FlashCard.new(question, answer)

	var updated_markdown := DeckWriter.to_markdown(updated)
	if not DeckStorage.write_deck(_editing_deck_file, updated_markdown):
		_show_card_editor_error(CARD_SAVE_FAILED_MESSAGE)
		return

	var progress := DeckStorage.load_progress(_editing_deck_file)
	if _editing_card_index >= 0 and _editing_original_question != question:
		var old_question_still_exists := false
		for index in updated.size():
			if index != _editing_card_index and (
				updated[index].question == _editing_original_question
			):
				old_question_still_exists = true
				break
		if not old_question_still_exists:
			progress.rename(_editing_original_question, question)
	progress.set_wrong_count(question, _editing_wrong_count)
	progress.set_status(question, _card_editor_status())
	var progress_saved := DeckStorage.save_progress(_editing_deck_file, progress)
	if _card_editor_origin == CardEditorOrigin.STUDY:
		var updated_card := updated[_editing_card_index]
		_progress = progress
		_session.replace_current(updated_card)
		if (
			_study_edit_source_index >= 0
			and _study_edit_source_index < _source_cards.size()
		):
			_source_cards[_study_edit_source_index] = updated_card
		_ready_deck_file = _editing_deck_file
		_ready_cards = _copy_cards(updated)
		_ready_deck_hash = updated_markdown.hash()
		_save_active_study_resume()
		_editing_cards = updated
		if not progress_saved:
			push_warning("Card progress save failed during study edit")
		_close_card_editor_without_save()
		return

	DeckStorage.delete_study_resume(_editing_deck_file)
	_editing_cards = updated
	_close_card_editor_without_save()
	_refresh_card_rows()
	_show_card_list_status(
		"카드 저장 완료"
		if progress_saved
		else "카드는 저장했지만 학습 기록을 저장하지 못했습니다."
	)


static func answer_has_question_heading(answer: String) -> bool:
	for line in answer.replace("\r\n", "\n").split("\n"):
		if line.begins_with("# "):
			return true
	return false


func _show_card_editor_error(message: String) -> void:
	card_editor_error_label.text = message
	card_editor_error_label.show()


func _on_delete_card_pressed() -> void:
	if _editing_card_index < 0 or _editing_card_index >= _editing_cards.size():
		return
	if _editing_cards.size() <= 1:
		_show_card_editor_error(LAST_CARD_DELETE_MESSAGE)
		return
	card_delete_confirmation_overlay.show()


func _on_card_delete_canceled() -> void:
	card_delete_confirmation_overlay.hide()


func _on_card_delete_confirmed() -> void:
	card_delete_confirmation_overlay.hide()
	if _editing_card_index < 0 or _editing_card_index >= _editing_cards.size():
		return

	var deleted_question := _editing_cards[_editing_card_index].question
	var updated := _copy_cards(_editing_cards)
	updated.remove_at(_editing_card_index)
	if not DeckStorage.write_deck(_editing_deck_file, DeckWriter.to_markdown(updated)):
		_show_card_editor_error(CARD_SAVE_FAILED_MESSAGE)
		return

	var progress := DeckStorage.load_progress(_editing_deck_file)
	var question_still_exists := false
	for card in updated:
		if card.question == deleted_question:
			question_still_exists = true
			break
	if not question_still_exists:
		progress.remove(deleted_question)
	var progress_saved := DeckStorage.save_progress(_editing_deck_file, progress)
	DeckStorage.delete_study_resume(_editing_deck_file)
	_editing_cards = updated
	_close_card_editor_without_save()
	_refresh_card_rows()
	_show_card_list_status(
		"카드 삭제 완료"
		if progress_saved
		else "카드는 삭제했지만 학습 기록을 저장하지 못했습니다."
	)


func _show_card_list_status(message: String) -> void:
	card_list_status_label.text = message
	card_list_status_label.show()


func _return_to_ready_from_card_list() -> void:
	var deck_file := _editing_deck_file
	show_study_ready(deck_file)


func _update_continue_action() -> void:
	var resume := DeckStorage.load_study_resume(_ready_deck_file)
	if not _is_valid_resume(resume):
		continue_study_button.hide()
		if resume != null:
			DeckStorage.delete_study_resume(_ready_deck_file)
		return

	continue_study_button.text = "이어서 학습 · %d장 남음" % resume.remaining_indices.size()
	continue_study_button.show()
	study_scope_option.select(resume.scope)
	study_order_option.select(resume.order)


func _is_valid_resume(resume: StudyResume) -> bool:
	if resume == null or resume.deck_hash != _ready_deck_hash:
		return false
	if resume.remaining_indices.is_empty():
		return false
	for index in resume.remaining_indices:
		if index < 0 or index >= _ready_cards.size():
			return false
	return true


static func filter_cards_for_scope(
	cards: Array[FlashCard],
	progress: Progress,
	scope: StudyScope
) -> Array[FlashCard]:
	var filtered: Array[FlashCard] = []
	for card in cards:
		if scope == StudyScope.INCOMPLETE and (
			progress.get_status(card.question) == CardStatus.Value.MASTERED
		):
			continue
		if scope == StudyScope.WRONG and progress.get_wrong_count(card.question) <= 0:
			continue
		filtered.append(card)
	return filtered


static func card_indices_for_scope(
	cards: Array[FlashCard],
	progress: Progress,
	scope: StudyScope
) -> Array[int]:
	var indices: Array[int] = []
	for index in cards.size():
		var card := cards[index]
		if scope == StudyScope.INCOMPLETE and (
			progress.get_status(card.question) == CardStatus.Value.MASTERED
		):
			continue
		if scope == StudyScope.WRONG and progress.get_wrong_count(card.question) <= 0:
			continue
		indices.append(index)
	return indices


func _on_start_study_pressed() -> void:
	if _ready_deck_file.is_empty() or not DeckStorage.deck_exists(_ready_deck_file):
		show_library()
		_show_library_status("덱 파일을 읽지 못했습니다.")
		return

	var scope: StudyScope = study_scope_option.get_selected_id()
	var selected_indices := card_indices_for_scope(
		_ready_cards,
		DeckStorage.load_progress(_ready_deck_file),
		scope
	)
	if selected_indices.is_empty():
		ready_status_label.text = (
			"오답 카드가 없습니다."
			if scope == StudyScope.WRONG
			else "학습할 미완료 카드가 없습니다."
		)
		ready_status_label.show()
		return

	ready_status_label.hide()
	var order: DeckOrdering.StudyOrder = study_order_option.get_selected_id()
	_begin_indexed_study(selected_indices, order, scope, true)


func _on_continue_study_pressed() -> void:
	var resume := DeckStorage.load_study_resume(_ready_deck_file)
	if not _is_valid_resume(resume):
		_update_continue_action()
		ready_status_label.text = "이어서 학습할 기록이 없습니다."
		ready_status_label.show()
		return

	var resume_scope: StudyScope = resume.scope
	_begin_indexed_study(
		resume.remaining_indices,
		resume.order,
		resume_scope,
		false
	)


func _begin_indexed_study(
	indices: Array[int],
	order: DeckOrdering.StudyOrder,
	scope: StudyScope,
	apply_order: bool
) -> void:
	_active_card_indices = indices.duplicate()
	if apply_order and order == DeckOrdering.StudyOrder.SHUFFLE:
		_active_card_indices.shuffle()

	var cards: Array[FlashCard] = []
	for index in _active_card_indices:
		cards.append(_ready_cards[index])

	_deck_file = _ready_deck_file
	_active_order = order
	_active_scope = scope
	_order = DeckOrdering.StudyOrder.SEQUENTIAL
	_progress = DeckStorage.load_progress(_deck_file)
	_source_cards = cards
	library_container.visible = false
	study_ready_view.visible = false
	study_flow.visible = true
	_restart_session()


func _save_active_study_resume() -> void:
	if _active_card_indices.is_empty() or _session == null or _deck_file.is_empty():
		return

	if _session.is_finished():
		DeckStorage.delete_study_resume(_deck_file)
		return

	var resume := StudyResume.new()
	resume.deck_hash = _ready_deck_hash
	resume.order = _active_order
	resume.scope = _active_scope
	for index in range(_session.position(), _active_card_indices.size()):
		resume.remaining_indices.append(_active_card_indices[index])
	DeckStorage.save_study_resume(_deck_file, resume)


func _return_to_study_ready() -> void:
	_save_active_study_resume()
	var deck_file := _deck_file
	if deck_file.is_empty():
		deck_file = _ready_deck_file
	show_study_ready(deck_file)


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
	if card_delete_confirmation_overlay.visible:
		_on_card_delete_canceled()
		return true

	if discard_card_changes_overlay.visible:
		_on_discard_card_changes_canceled()
		return true

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

	if card_editor_view.visible:
		_request_close_card_editor()
		return true

	if card_list_view.visible:
		_return_to_ready_from_card_list()
		return true

	if study_ready_view.visible:
		if new_study_content.visible:
			_on_cancel_study_setup()
			return true
		show_library()
		return true

	_return_to_study_ready()
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
	_reset_study_input_lock()
	_save_active_study_resume()
	_show_current()


func _show_current() -> void:
	if _session == null or _session.is_finished():
		if not _deck_file.is_empty():
			DeckStorage.delete_study_resume(_deck_file)
		_show_message("학습 완료!", true)
		return

	var card := _session.current()
	edit_study_card_button.visible = DeckStorage.deck_exists(_deck_file)
	study_container.visible = true
	done_container.visible = false
	card_status_label.text = card_status_text(_progress.get_status(card.question))
	var wrong_count := _progress.get_wrong_count(card.question)
	wrong_tally.set_count(wrong_count)
	question_label.text = card.question
	answer_label.text = card.answer
	question_scroll.scroll_vertical = 0
	answer_scroll.scroll_vertical = 0
	_set_answer_visible(false)
	study_gesture_surface.previous_enabled = _session.position() > 0
	remaining_label.text = "%d장 남음" % _session.remaining()
	study_progress_bar.max_value = maxi(_source_cards.size(), 1)
	study_progress_bar.value = _source_cards.size() - _session.remaining()


static func card_status_text(status: CardStatus.Value) -> String:
	match status:
		CardStatus.Value.LEARNING:
			return "LEARNING"
		CardStatus.Value.MASTERED:
			return "MASTERED"
		_:
			return "NEW"


func _show_message(message: String, can_restart: bool) -> void:
	edit_study_card_button.hide()
	study_container.visible = false
	done_container.visible = true
	done_label.text = message
	restart_button.visible = can_restart
	remaining_label.text = "0장 남음"
	study_progress_bar.max_value = maxi(_source_cards.size(), 1)
	study_progress_bar.value = _source_cards.size()


func _on_card_tapped() -> void:
	if _session == null or _session.is_finished():
		return

	var show_answer := not answer_scroll.visible
	study_gesture_surface.flip(_set_answer_visible.bind(show_answer))


func _set_answer_visible(visible: bool) -> void:
	answer_scroll.visible = visible
	card_properties.visible = visible
	if visible:
		question_scroll.custom_minimum_size.y = 150.0
		question_scroll.size_flags_vertical = Control.SIZE_FILL
		question_label.add_theme_color_override(
			"font_color",
			Color(0.56, 0.56, 0.56, 1)
		)
	else:
		question_scroll.custom_minimum_size.y = 0.0
		question_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		question_label.remove_theme_color_override("font_color")
	study_actions.show()


func _on_again_requested() -> void:
	study_gesture_surface.commit(StudyGestureSurface.AGAIN)


func _on_good_requested() -> void:
	study_gesture_surface.commit(StudyGestureSurface.GOOD)


func _on_again_pressed() -> void:
	if _session == null or _session.is_finished() or not _try_lock_study_input():
		return

	_progress.add_wrong(_session.current().question)
	_progress.set_status(_session.current().question, CardStatus.Value.LEARNING)
	DeckStorage.save_progress(_deck_file, _progress)
	_session.next()
	_save_active_study_resume()
	_show_current()


func _on_good_pressed() -> void:
	if _session == null or _session.is_finished() or not _try_lock_study_input():
		return

	_progress.set_status(_session.current().question, CardStatus.Value.MASTERED)
	DeckStorage.save_progress(_deck_file, _progress)
	_session.next()
	_save_active_study_resume()
	_show_current()


func _on_study_swiped(direction: int) -> void:
	if direction == StudyGestureSurface.AGAIN:
		_on_again_pressed()
	elif direction == StudyGestureSurface.GOOD:
		_on_good_pressed()
	elif direction == StudyGestureSurface.SKIP:
		_on_skip_requested()
	elif direction == StudyGestureSurface.PREVIOUS:
		_on_previous_requested()


func _on_skip_requested() -> void:
	if _session == null or _session.is_finished() or not _try_lock_study_input():
		return

	_session.next()
	_save_active_study_resume()
	_show_current()


func _on_previous_requested() -> void:
	if (
		_session == null
		or _session.is_finished()
		or _session.position() <= 0
		or not _try_lock_study_input()
	):
		return

	_session.previous()
	_save_active_study_resume()
	_show_current()


func _try_lock_study_input() -> bool:
	if _study_input_locked:
		return false

	_study_input_locked = true
	_study_input_lock_generation += 1
	again_button.disabled = true
	good_button.disabled = true
	study_gesture_surface.input_enabled = false
	var generation := _study_input_lock_generation
	get_tree().create_timer(STUDY_INPUT_LOCK_SECONDS).timeout.connect(
		_on_study_input_lock_timeout.bind(generation)
	)
	return true


func _on_study_input_lock_timeout(generation: int) -> void:
	if generation != _study_input_lock_generation:
		return
	_reset_study_input_lock()


func _reset_study_input_lock() -> void:
	_study_input_lock_generation += 1
	_study_input_locked = false
	again_button.disabled = false
	good_button.disabled = false
	study_gesture_surface.input_enabled = true


func _on_restart_pressed() -> void:
	if _deck_file.is_empty():
		return

	_progress = DeckStorage.load_progress(_deck_file)
	_restart_session()
