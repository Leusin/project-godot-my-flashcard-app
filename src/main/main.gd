class_name MainApp
extends Control

const StudyScope = StudyPlan.Scope

enum CardEditorOrigin {
	CARD_LIST,
	NEW_DECK,
	STUDY,
	CARD_DETAIL,
}

enum CardDetailOrigin {
	CARD_LIST,
	STUDY_RESULT,
}

enum CreateDeckMode {
	EMPTY,
	CLIPBOARD,
}

const BASE_PAGE_MARGIN := 32.0
const EMPTY_DECK_MESSAGE := DeckActionService.EMPTY_DECK_MESSAGE
const BROKEN_DECK_MESSAGE := DeckActionService.BROKEN_DECK_MESSAGE
const EXPORT_DECK_NOT_FOUND_MESSAGE := DeckActionService.EXPORT_DECK_NOT_FOUND_MESSAGE
const EXPORT_TARGET_OPEN_FAILED_MESSAGE := DeckActionService.EXPORT_TARGET_OPEN_FAILED_MESSAGE
const EXPORT_WRITE_FAILED_MESSAGE := DeckActionService.EXPORT_WRITE_FAILED_MESSAGE
const EXPORT_UNKNOWN_FAILED_MESSAGE := DeckActionService.EXPORT_UNKNOWN_FAILED_MESSAGE
const DELETE_DECK_NOT_FOUND_MESSAGE := DeckActionService.DELETE_DECK_NOT_FOUND_MESSAGE
const DELETE_DECK_FAILED_MESSAGE := DeckActionService.DELETE_DECK_FAILED_MESSAGE
# 이름 만들기와 이름 바꾸기는 같은 규칙을 쓴다.
const DECK_NAME_EMPTY_MESSAGE := DeckActionService.DECK_NAME_EMPTY_MESSAGE
const DECK_NAME_INVALID_MESSAGE := DeckActionService.DECK_NAME_INVALID_MESSAGE
const DECK_NAME_DUPLICATE_MESSAGE := DeckActionService.DECK_NAME_DUPLICATE_MESSAGE
const RENAME_DECK_NOT_FOUND_MESSAGE := DeckActionService.RENAME_DECK_NOT_FOUND_MESSAGE
const RENAME_FAILED_MESSAGE := DeckActionService.RENAME_FAILED_MESSAGE
const DUPLICATE_DECK_NOT_FOUND_MESSAGE := DeckActionService.DUPLICATE_DECK_NOT_FOUND_MESSAGE
const DUPLICATE_DECK_FAILED_MESSAGE := DeckActionService.DUPLICATE_DECK_FAILED_MESSAGE
const CREATE_DECK_SAVE_FAILED_MESSAGE := DeckActionService.CREATE_DECK_SAVE_FAILED_MESSAGE
const CLIPBOARD_EMPTY_MESSAGE := DeckActionService.CLIPBOARD_EMPTY_MESSAGE
const CLIPBOARD_BROKEN_MESSAGE := DeckActionService.CLIPBOARD_BROKEN_MESSAGE
const AI_PROMPT_TEMPLATE := """사진에 보이는 영어 단어를 아래 형식의 Markdown으로 만들어줘.
다른 설명 없이 코드 블록 하나로만 답해줘.

# apple
사과

# run
달리다"""
const AI_PROMPT_COPIED_MESSAGE := "AI 프롬프트를 복사했습니다. AI 앱에 단어장 사진과 함께 붙여넣으세요."
const CARD_QUESTION_EMPTY_MESSAGE := "질문을 입력하세요."
const CARD_ANSWER_HEADING_MESSAGE := "답의 줄 시작에는 '# '를 사용할 수 없습니다."
const CARD_SAVE_FAILED_MESSAGE := "카드를 저장하지 못했습니다. 저장 공간을 확인하세요."
const PRIVACY_POLICY_URL := "https://leusin.github.io/privacy/my-simple-flash-card/"
const STUDY_INPUT_LOCK_SECONDS := 0.22

@export var auto_start := true

@onready var page_margin: MarginContainer = $Margin
@onready var page_container: TabContainer = $Margin/Page
@onready var library_view: LibraryView = $Margin/Page/LibraryContainer
@onready var settings_view: SettingsView = $Margin/Page/SettingsView
@onready var add_deck_menu: AddDeckMenuView = $AddDeckMenu
@onready var library_context_menu: LibraryContextMenuView = $LibraryContextMenu
@onready var deck_context_menu: DeckContextMenuView = $DeckContextMenu
@onready var card_context_menu: CardContextMenuView = $CardContextMenu
@onready var rename_deck_overlay: ModalDialog = $RenameDeckOverlay
@onready var delete_confirmation_overlay: ModalDialog = $DeleteConfirmationOverlay
@onready var exit_confirmation_overlay: ModalDialog = $ExitConfirmationOverlay
@onready var restore_backup_confirmation_overlay: ModalDialog = $RestoreBackupConfirmationOverlay
@onready var create_deck_overlay: ModalDialog = $CreateDeckOverlay
@onready var study_ready_view: StudyReadyView = $Margin/Page/StudyReadyView
@onready var card_list_view: CardListView = $Margin/Page/CardListView
@onready var card_detail_view: CardDetailView = $Margin/Page/CardDetailView
@onready var card_editor_view: CardEditorView = $Margin/Page/CardEditorView
@onready var card_delete_confirmation_overlay: ModalDialog = $CardDeleteConfirmationOverlay
@onready var discard_card_changes_overlay: ModalDialog = $DiscardCardChangesOverlay
@onready var study_flow: StudyFlowView = $Margin/Page/StudyFlow
@onready var top_notification: TopNotification = $TopNotification

var _deck_file := ""
var _order := DeckOrdering.StudyOrder.SEQUENTIAL
var _session: StudySession
var _progress := Progress.new()
var _source_cards: Array[FlashCard] = []
var _session_cards: Array[FlashCard] = []
var _session_outcomes: Array[int] = []
var _pending_deck_action_file := ""
var _study_plan := StudyPlan.new()
var _card_workspace := CardWorkspace.new()
var _card_editor_origin: CardEditorOrigin = CardEditorOrigin.CARD_LIST
var _card_detail_origin: CardDetailOrigin = CardDetailOrigin.CARD_LIST
var _card_detail_index := -1
var _card_detail_result_index := -1
var _card_menu_from_study := false
var _card_menu_from_list := false
var _study_edit_source_index := -1
var _study_edit_return_show_answer := false
var _study_input_locked := false
var _study_input_lock_generation := 0
var _create_deck_mode := CreateDeckMode.EMPTY
var _pending_markdown := ""
var _pending_restore_path := ""


func _ready() -> void:
	get_tree().root.size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")
	_connect_library_signals()
	_configure_settings()
	_connect_deck_dialog_signals()
	_connect_card_management_signals()
	_connect_study_signals()
	_setup_study_ready_options()

	if auto_start:
		_show_startup_view()


func _connect_library_signals() -> void:
	library_view.deck_selected.connect(_on_deck_selected)
	library_view.deck_order_changed.connect(_on_deck_order_changed)
	library_view.import_file_selected.connect(import_deck_from_path)
	library_view.export_file_selected.connect(_on_export_file_selected)
	library_view.export_canceled.connect(_on_export_canceled)
	add_deck_menu.create_requested.connect(_on_create_new_deck_pressed)
	add_deck_menu.import_requested.connect(_on_import_from_add_menu_pressed)
	add_deck_menu.clipboard_requested.connect(_on_create_from_clipboard_pressed)
	library_view.add_pressed.connect(_on_library_add_pressed)
	library_view.settings_pressed.connect(_on_library_settings_pressed)
	library_context_menu.settings_requested.connect(_on_open_settings_pressed)
	deck_context_menu.rename_requested.connect(_on_rename_pressed)
	deck_context_menu.duplicate_requested.connect(_on_duplicate_pressed)
	deck_context_menu.export_requested.connect(_on_export_pressed)
	deck_context_menu.delete_requested.connect(_on_delete_pressed)


func _configure_settings() -> void:
	var settings := DeckStorage.load_settings()
	settings_view.configure(
		AI_PROMPT_TEMPLATE,
		settings.haptics_enabled,
		is_mobile()
	)
	study_flow.set_haptics_enabled(settings.haptics_enabled)
	settings_view.back_pressed.connect(show_library)
	settings_view.haptics_toggled.connect(_on_haptics_toggled)
	settings_view.privacy_policy_pressed.connect(_on_privacy_policy_pressed)
	settings_view.copy_ai_prompt_pressed.connect(_on_copy_ai_prompt_pressed)
	settings_view.backup_path_selected.connect(_on_backup_path_selected)
	settings_view.restore_path_selected.connect(_on_restore_path_selected)


func _connect_deck_dialog_signals() -> void:
	rename_deck_overlay.secondary_button.pressed.connect(_on_rename_canceled)
	rename_deck_overlay.primary_button.pressed.connect(_on_rename_confirmed)
	rename_deck_overlay.dialog_input.text_submitted.connect(_on_rename_submitted)
	create_deck_overlay.secondary_button.pressed.connect(_on_create_deck_canceled)
	create_deck_overlay.primary_button.pressed.connect(_on_create_deck_confirmed)
	create_deck_overlay.dialog_input.text_submitted.connect(_on_create_deck_submitted)
	delete_confirmation_overlay.secondary_button.pressed.connect(_on_delete_canceled)
	delete_confirmation_overlay.primary_button.pressed.connect(_on_delete_confirmed)
	exit_confirmation_overlay.secondary_button.pressed.connect(_on_exit_canceled)
	exit_confirmation_overlay.primary_button.pressed.connect(_on_exit_confirmed)
	restore_backup_confirmation_overlay.secondary_button.pressed.connect(
		_on_restore_backup_canceled
	)
	restore_backup_confirmation_overlay.primary_button.pressed.connect(
		_on_restore_backup_confirmed
	)


func _connect_card_management_signals() -> void:
	study_ready_view.back_pressed.connect(show_library)
	study_ready_view.menu_pressed.connect(_on_ready_deck_menu_pressed)
	study_ready_view.open_setup_pressed.connect(_on_open_study_setup)
	study_ready_view.continue_pressed.connect(_on_continue_study_pressed)
	study_ready_view.start_study_pressed.connect(_on_start_study_pressed)
	study_ready_view.cancel_setup_pressed.connect(_on_cancel_study_setup)
	study_ready_view.manage_cards_pressed.connect(_on_manage_cards_pressed)
	card_list_view.back_pressed.connect(_return_to_ready_from_card_list)
	card_list_view.add_card_pressed.connect(_on_add_card_pressed)
	card_list_view.card_selected.connect(_on_card_row_selected)
	card_list_view.card_menu_requested.connect(_on_card_row_menu_requested)
	card_list_view.card_move_requested.connect(_on_card_move_requested)
	card_context_menu.edit_requested.connect(_on_card_context_edit_pressed)
	card_context_menu.delete_requested.connect(_on_card_context_delete_pressed)
	card_detail_view.back_pressed.connect(_close_card_detail)
	card_detail_view.menu_requested.connect(_on_card_context_requested.bind(false))
	card_editor_view.cancel_requested.connect(_request_close_card_editor)
	card_editor_view.save_requested.connect(_on_save_card_pressed)
	card_delete_confirmation_overlay.secondary_button.pressed.connect(_on_card_delete_canceled)
	card_delete_confirmation_overlay.primary_button.pressed.connect(_on_card_delete_confirmed)
	discard_card_changes_overlay.secondary_button.pressed.connect(
		_on_discard_card_changes_canceled
	)
	discard_card_changes_overlay.primary_button.pressed.connect(
		_on_discard_card_changes_confirmed
	)


func _connect_study_signals() -> void:
	study_flow.back_pressed.connect(_return_to_study_ready)
	study_flow.action_committed.connect(_on_study_swiped)
	study_flow.result_card_selected.connect(_on_result_card_selected)
	study_flow.retry_requested.connect(_on_retry_again_pressed)
	study_flow.return_requested.connect(_return_to_study_ready)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return

	handle_back_request()


static func safe_insets_in_viewport(
	safe_area: Rect2i,
	window_size: Vector2i,
	viewport_size: Vector2
) -> Vector4:
	return SafeArea.insets_in_viewport(safe_area, window_size, viewport_size)


static func is_mobile() -> bool:
	return SafeArea.is_handheld()


func _apply_safe_area() -> void:
	var safe_insets := SafeArea.current_insets(get_viewport_rect().size)

	page_margin.offset_left = BASE_PAGE_MARGIN + safe_insets.x
	page_margin.offset_top = BASE_PAGE_MARGIN + safe_insets.y
	page_margin.offset_right = -(BASE_PAGE_MARGIN + safe_insets.z)
	page_margin.offset_bottom = -(BASE_PAGE_MARGIN + safe_insets.w)
	top_notification.set_safe_insets(safe_insets)

	for overlay in [
		create_deck_overlay,
		rename_deck_overlay,
		delete_confirmation_overlay,
		exit_confirmation_overlay,
		card_delete_confirmation_overlay,
		discard_card_changes_overlay,
		restore_backup_confirmation_overlay,
	]:
		(overlay as ModalDialog).set_bottom_inset(safe_insets.w)


func start_default_deck() -> void:
	_show_startup_view()


func _show_page(page: Control) -> void:
	var tab_index := page_container.get_tab_idx_from_control(page)
	if tab_index < 0:
		push_error("Page is not a child of the page container: %s" % page.name)
		return
	page_container.current_tab = tab_index


func _show_startup_view() -> void:
	DeckStorage.seed_sample_if_empty()
	var settings := DeckStorage.load_settings()
	var last_deck_file := settings.last_deck_file.strip_edges()
	if not last_deck_file.is_empty() and show_study_ready(last_deck_file):
		return

	if not last_deck_file.is_empty():
		settings.last_deck_file = ""
		_save_settings_or_warn(settings)
	show_library()


func _remember_last_study_deck(deck_file: String) -> void:
	if not DeckStorage.deck_exists(deck_file):
		return

	var settings := DeckStorage.load_settings()
	if settings.last_deck_file == deck_file:
		return

	settings.last_deck_file = deck_file
	_save_settings_or_warn(settings)


func _replace_last_study_deck(old_file: String, new_file: String) -> void:
	var settings := DeckStorage.load_settings()
	if settings.last_deck_file.to_lower() != old_file.to_lower():
		return

	settings.last_deck_file = new_file
	_save_settings_or_warn(settings)


func _save_settings_or_warn(settings: AppSettings) -> void:
	if not DeckStorage.save_settings(settings):
		push_warning("App settings save failed")


func _on_haptics_toggled(enabled: bool) -> void:
	study_flow.set_haptics_enabled(enabled)
	var settings := DeckStorage.load_settings()
	settings.haptics_enabled = enabled
	_save_settings_or_warn(settings)


func show_library() -> void:
	DeckStorage.seed_sample_if_empty()
	_session = null
	_source_cards.clear()
	_session_cards.clear()
	_session_outcomes.clear()
	_deck_file = ""
	_study_plan.clear()
	_card_workspace.clear()
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_card_detail_origin = CardDetailOrigin.CARD_LIST
	_card_detail_index = -1
	_card_detail_result_index = -1
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false
	_pending_deck_action_file = ""
	_reset_create_deck_state()
	add_deck_menu.dismiss()
	library_context_menu.dismiss()
	deck_context_menu.dismiss()
	card_context_menu.dismiss()
	create_deck_overlay.hide()
	rename_deck_overlay.hide()
	delete_confirmation_overlay.hide()
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	restore_backup_confirmation_overlay.hide()
	_pending_restore_path = ""
	_show_page(library_view)
	study_flow.reset_view()
	_refresh_deck_list()


func show_settings() -> void:
	show_library()
	_show_page(settings_view)
	settings_view.set_version(
		ProjectSettings.get_setting("application/config/version", "")
	)


func show_study_ready(deck_file: String) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_notice("덱 파일을 읽지 못했습니다.")
		return false

	var deck_text := DeckStorage.read_deck(deck_file)
	var error_message := deck_content_error(deck_text)
	if not error_message.is_empty():
		_show_library_notice(error_message)
		return false

	_study_plan.prepare(deck_file, DeckParser.parse(deck_text), deck_text.hash())
	_pending_deck_action_file = ""
	deck_context_menu.dismiss()
	card_context_menu.dismiss()
	_show_page(study_ready_view)
	_update_study_ready_summary()
	_update_continue_action()
	_show_ready_overview()
	return true


func start_deck(
	deck_file: String,
	order: DeckOrdering.StudyOrder = DeckOrdering.StudyOrder.SEQUENTIAL
) -> bool:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_notice("덱 파일을 읽지 못했습니다.")
		return false

	var deck_text := DeckStorage.read_deck(deck_file)
	var error_message := deck_content_error(deck_text)
	if not error_message.is_empty():
		_show_library_notice(error_message)
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
	_remember_last_study_deck(deck_file)
	_order = order
	_progress = DeckStorage.load_progress(deck_file)
	_source_cards = cards.duplicate()
	_study_plan.active_indices.clear()
	card_context_menu.dismiss()
	_show_page(study_flow)
	_restart_session()


func _refresh_deck_list() -> void:
	var settings := DeckStorage.load_settings()
	var ordered := DeckLibraryOrder.apply(
		settings.deck_order,
		DeckStorage.list_deck_files()
	)
	# 새로 생긴 덱이 앞에 놓인 결과를 그대로 굳혀 다음에도 같은 자리에 있게 한다.
	if ordered != settings.deck_order:
		settings.deck_order = ordered
		_save_settings_or_warn(settings)

	var decks: Array[DeckInfo] = []
	for deck_file in ordered:
		decks.append(DeckInfo.new(
			deck_file,
			DeckNaming.display_name(deck_file),
			DeckParser.parse(DeckStorage.read_deck(deck_file)).size()
		))
	library_view.render(decks)


func _on_deck_order_changed(order: Array[String]) -> void:
	var settings := DeckStorage.load_settings()
	if settings.deck_order == order:
		return
	settings.deck_order = order
	_save_settings_or_warn(settings)


func _on_deck_selected(deck_file: String) -> void:
	add_deck_menu.dismiss()
	deck_context_menu.dismiss()
	show_study_ready(deck_file)


func _setup_study_ready_options() -> void:
	study_ready_view.clear_options()
	study_ready_view.add_scope_option("전체 카드", StudyScope.ALL)
	study_ready_view.add_scope_option("미완료 카드", StudyScope.INCOMPLETE)
	study_ready_view.add_scope_option("오답 카드", StudyScope.WRONG)
	study_ready_view.add_order_option("순서대로", DeckOrdering.StudyOrder.SEQUENTIAL)
	study_ready_view.add_order_option("섞어서", DeckOrdering.StudyOrder.SHUFFLE)


func _update_study_ready_summary() -> void:
	var summary := _study_plan.summary(
		DeckStorage.load_progress(_study_plan.deck_file)
	)
	study_ready_view.render_summary(
		DeckNaming.display_name(_study_plan.deck_file),
		summary.total_count,
		summary.new_count,
		summary.learning_count,
		summary.mastered_count
	)


func _show_ready_overview() -> void:
	study_ready_view.show_overview()


func _on_open_study_setup() -> void:
	var resume := DeckStorage.load_study_resume(_study_plan.deck_file)
	var replacing_resume := _study_plan.is_valid_resume(resume)
	study_ready_view.show_setup(
		"진행 중 세션은 교체되며 카드별 진행 기록은 유지됩니다."
		if replacing_resume
		else "진행 기록은 유지하고 새로운 학습 세션을 시작합니다.",
		"진행 중 세션 교체하고 시작" if replacing_resume else "새 학습 시작"
	)


func _on_cancel_study_setup() -> void:
	_show_ready_overview()


func _on_manage_cards_pressed() -> void:
	_open_card_list(_study_plan.deck_file)


func _open_card_list(deck_file: String) -> bool:
	if not _card_workspace.open(deck_file):
		_show_library_notice("편집할 덱 파일을 찾을 수 없습니다.")
		return false

	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false
	_render_card_list()
	_show_page(card_list_view)
	return true

func _render_card_list() -> void:
	card_list_view.render(
		DeckNaming.display_name(_card_workspace.deck_file),
		_card_workspace.cards
	)


func _on_card_move_requested(index: int, target: int) -> void:
	match _card_workspace.move_card(index, target):
		CardWorkspace.MoveResult.SAVED:
			pass
		CardWorkspace.MoveResult.UNCHANGED:
			_render_card_list()
		CardWorkspace.MoveResult.SAVE_FAILED:
			_render_card_list()
			push_warning(
				"Card order save failed: %s" % _card_workspace.deck_file
			)


func _on_card_row_selected(index: int) -> void:
	if not _card_workspace.is_valid_index(index):
		return
	var card := _card_workspace.card_at(index)
	_show_card_detail(
		card,
		_card_workspace.load_progress(),
		index,
		CardDetailOrigin.CARD_LIST
	)


func _show_card_detail(
	card: FlashCard,
	progress: Progress,
	deck_index: int,
	origin: CardDetailOrigin,
	result_index: int = -1
) -> void:
	_card_detail_origin = origin
	_card_detail_index = deck_index
	_card_detail_result_index = result_index
	var menu_visible := (
		_card_workspace.is_valid_index(deck_index)
		and DeckStorage.deck_exists(_card_workspace.deck_file)
	)
	card_detail_view.present(
		DeckNaming.display_name(
			_card_workspace.deck_file
			if not _card_workspace.deck_file.is_empty()
			else _deck_file
		),
		card,
		progress.get_wrong_count(card.question),
		card_status_text(progress.get_status(card.question)),
		menu_visible,
		(
			"학습 결과로 돌아가기"
			if origin == CardDetailOrigin.STUDY_RESULT
			else "카드 목록으로 돌아가기"
		)
	)
	_show_page(card_detail_view)


func _on_edit_card_from_detail_pressed() -> void:
	if not _card_workspace.is_valid_index(_card_detail_index):
		return
	_card_editor_origin = CardEditorOrigin.CARD_DETAIL
	_open_card_editor(_card_detail_index)


func _on_card_row_menu_requested(index: int, anchor: Control) -> void:
	if not _card_workspace.is_valid_index(index):
		return
	_card_detail_index = index
	_on_card_context_requested(anchor, false, true)


func _on_card_context_requested(
	anchor: Control,
	from_study: bool,
	from_list: bool = false
) -> void:
	_card_menu_from_study = from_study
	_card_menu_from_list = from_list
	var card := _card_for_context_menu()
	if card == null:
		return
	var deck_file := _deck_file if from_study else _card_workspace.deck_file
	if not DeckStorage.deck_exists(deck_file):
		return
	# 학습 중에는 세션이 흔들리고, 마지막 한 장은 빈 덱이 되므로 삭제를 아예 내보이지 않는다.
	card_context_menu.open_for(
		anchor,
		not from_study and _card_workspace.cards.size() > 1
	)


func _card_for_context_menu() -> FlashCard:
	if _card_menu_from_study:
		if _session == null or _session.is_finished():
			return null
		return _session.current()
	if not _card_workspace.is_valid_index(_card_detail_index):
		return null
	return _card_workspace.card_at(_card_detail_index)


func _on_card_context_edit_pressed() -> void:
	if _card_menu_from_study:
		_on_edit_study_card_pressed()
	elif _card_menu_from_list:
		if not _card_workspace.is_valid_index(_card_detail_index):
			return
		_card_editor_origin = CardEditorOrigin.CARD_LIST
		_open_card_editor(_card_detail_index)
	else:
		_on_edit_card_from_detail_pressed()


func _on_card_context_delete_pressed() -> void:
	if _card_menu_from_study:
		return
	if not _card_workspace.is_valid_index(_card_detail_index):
		return
	if _card_workspace.cards.size() <= 1:
		return
	_card_workspace.select(_card_detail_index)
	_card_editor_origin = (
		CardEditorOrigin.CARD_LIST
		if _card_menu_from_list
		else CardEditorOrigin.CARD_DETAIL
	)
	card_delete_confirmation_overlay.show()


func _close_card_detail() -> void:
	card_context_menu.dismiss()
	if _card_detail_origin == CardDetailOrigin.STUDY_RESULT:
		_show_page(study_flow)
		_show_study_results()
	else:
		_show_page(card_list_view)
	_card_detail_index = -1
	_card_detail_result_index = -1


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

	study_flow.cancel_drag()
	_reset_study_input_lock()
	_save_active_study_resume()
	_card_workspace.load_snapshot(_deck_file, deck_cards)
	_card_editor_origin = CardEditorOrigin.STUDY
	_study_edit_source_index = _source_cards.find(current_card)
	_study_edit_return_show_answer = study_flow.is_answer_visible()
	_open_card_editor(deck_index)


func _current_study_deck_index(
	deck_cards: Array[FlashCard],
	current_card: FlashCard
) -> int:
	var active_index := _study_plan.active_index_at(_session.position())
	if active_index >= 0 and active_index < deck_cards.size():
		var indexed_card := deck_cards[active_index]
		if (
			indexed_card.question == current_card.question
			and indexed_card.answer == current_card.answer
		):
			return active_index

	var source_index := _source_cards.find(current_card)
	if (
		_study_plan.active_indices.is_empty()
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
	card_context_menu.dismiss()
	if not _card_workspace.select(index):
		return
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	var progress := _card_workspace.load_progress()
	var question := ""
	var answer := ""
	var wrong_count := 0
	var status: CardStatus.Value = CardStatus.Value.NEW
	var title := (
		"첫 카드 추가"
		if _card_editor_origin == CardEditorOrigin.NEW_DECK
		else "카드 추가"
	)
	if index >= 0:
		var card := _card_workspace.card_at(index)
		question = card.question
		answer = card.answer
		wrong_count = progress.get_wrong_count(card.question)
		status = progress.get_status(card.question)
		title = (
			"학습 중 카드 편집"
			if _card_editor_origin == CardEditorOrigin.STUDY
			else "카드 편집"
		)
	card_editor_view.begin_edit(title, question, answer, wrong_count, status)
	_show_page(card_editor_view)


func _request_close_card_editor() -> void:
	# 모바일 키보드가 하단 확인창의 버튼을 가리지 않게 먼저 입력을 끝낸다.
	_dismiss_virtual_keyboard()
	if card_editor_view.has_changes():
		discard_card_changes_overlay.show()
		return
	_close_card_editor_without_save()


func _on_discard_card_changes_canceled() -> void:
	discard_card_changes_overlay.hide()


func _on_discard_card_changes_confirmed() -> void:
	discard_card_changes_overlay.hide()
	_close_card_editor_without_save()


func _close_card_editor_without_save() -> void:
	_dismiss_virtual_keyboard()
	var return_to_study := _card_editor_origin == CardEditorOrigin.STUDY
	var return_to_library := _card_editor_origin == CardEditorOrigin.NEW_DECK
	var return_to_detail := _card_editor_origin == CardEditorOrigin.CARD_DETAIL
	var restore_answer := _study_edit_return_show_answer
	card_delete_confirmation_overlay.hide()
	discard_card_changes_overlay.hide()
	if return_to_study:
		_show_page(study_flow)
		if _session != null and not _session.is_finished():
			_show_current()
			if restore_answer:
				study_flow.set_answer_visible(true)
	elif return_to_library:
		show_library()
	elif return_to_detail:
		if _card_workspace.is_valid_index(_card_detail_index):
			var card := _card_workspace.card_at(_card_detail_index)
			var progress := _card_workspace.load_progress()
			card_detail_view.render_card(
				card,
				progress.get_wrong_count(card.question),
				card_status_text(progress.get_status(card.question))
			)
		_show_page(card_detail_view)
	else:
		_show_page(card_list_view)
	_card_workspace.select(-1)
	_card_editor_origin = CardEditorOrigin.CARD_LIST
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false


func _on_save_card_pressed() -> void:
	var creating_deck := _card_editor_origin == CardEditorOrigin.NEW_DECK
	var question := card_editor_view.question_text().strip_edges()
	var answer := card_editor_view.answer_text().replace("\r\n", "\n").strip_edges()
	if question.is_empty():
		_show_card_editor_error(CARD_QUESTION_EMPTY_MESSAGE)
		return
	if answer_has_question_heading(answer):
		_show_card_editor_error(CARD_ANSWER_HEADING_MESSAGE)
		return
	if creating_deck and DeckActionService.is_deck_file_taken(
		_card_workspace.deck_file
	):
		_show_card_editor_error(DECK_NAME_DUPLICATE_MESSAGE)
		return

	var save_result := _card_workspace.save_card(
		question,
		answer,
		card_editor_view.wrong_count(),
		card_editor_view.selected_status(),
		_card_editor_origin != CardEditorOrigin.STUDY
	)
	if not save_result.succeeded:
		_show_card_editor_error(CARD_SAVE_FAILED_MESSAGE)
		return

	var updated := _card_workspace.cards
	if _card_editor_origin == CardEditorOrigin.STUDY:
		var updated_card := save_result.card
		_progress = save_result.progress
		_session.replace_current(updated_card)
		if _session.position() < _session_cards.size():
			_session_cards[_session.position()] = updated_card
		if (
			_study_edit_source_index >= 0
			and _study_edit_source_index < _source_cards.size()
		):
			_source_cards[_study_edit_source_index] = updated_card
		_study_plan.replace_cards(
			_card_workspace.deck_file,
			updated,
			save_result.markdown.hash()
		)
		_save_active_study_resume()
		if not save_result.progress_saved:
			push_warning("Card progress save failed during study edit")
			_close_card_editor_without_save()
			return
	elif (
		_card_editor_origin == CardEditorOrigin.CARD_DETAIL
		and _card_detail_origin == CardDetailOrigin.STUDY_RESULT
		and _card_detail_result_index >= 0
		and _card_detail_result_index < _session_cards.size()
	):
		var updated_result_card := save_result.card
		_session_cards[_card_detail_result_index] = updated_result_card
		var active_index := _study_plan.active_index_at(_card_detail_result_index)
		if (
			active_index >= 0
			and active_index < _source_cards.size()
		):
			_source_cards[active_index] = updated_result_card
		_progress = save_result.progress
		_study_plan.replace_cards(
			_card_workspace.deck_file,
			updated,
			save_result.markdown.hash()
		)

	if creating_deck:
		_card_editor_origin = CardEditorOrigin.CARD_LIST
	_close_card_editor_without_save()
	_render_card_list()


static func answer_has_question_heading(answer: String) -> bool:
	for line in answer.replace("\r\n", "\n").split("\n"):
		if line.begins_with("# "):
			return true
	return false


# 카드 프레임은 2:3 비율로 고정이라 안에서 문구가 늘면 입력창이 눌린다.
func _show_card_editor_error(message: String) -> void:
	top_notification.show_message(message)


func _on_card_delete_canceled() -> void:
	card_delete_confirmation_overlay.hide()


func _on_card_delete_confirmed() -> void:
	card_delete_confirmation_overlay.hide()
	if not _card_workspace.is_valid_index(_card_workspace.editing_index):
		return
	var deleting_from_detail := _card_editor_origin == CardEditorOrigin.CARD_DETAIL
	var detail_origin := _card_detail_origin

	var delete_result := _card_workspace.delete_selected()
	if not delete_result.succeeded:
		if card_editor_view.visible:
			_show_card_editor_error(CARD_SAVE_FAILED_MESSAGE)
		else:
			_show_page(card_list_view)
			push_warning(
				"Card delete save failed: %s" % _card_workspace.deck_file
			)
		return

	if not delete_result.progress_saved:
		push_warning("Card progress save failed during delete")
	if deleting_from_detail:
		_card_editor_origin = CardEditorOrigin.CARD_LIST
		_card_detail_index = -1
		_card_detail_result_index = -1
		_render_card_list()
		if detail_origin == CardDetailOrigin.STUDY_RESULT:
			_show_page(study_flow)
			_show_study_results()
		else:
			_show_page(card_list_view)
		return
	_close_card_editor_without_save()
	_render_card_list()


func _return_to_ready_from_card_list() -> void:
	var deck_file := _card_workspace.deck_file
	show_study_ready(deck_file)


func _update_continue_action() -> void:
	var resume := DeckStorage.load_study_resume(_study_plan.deck_file)
	if not _study_plan.is_valid_resume(resume):
		study_ready_view.hide_continue_action()
		if resume != null:
			DeckStorage.delete_study_resume(_study_plan.deck_file)
		return

	study_ready_view.set_continue_action(
		"이어서 학습 (%d장 남음)" % resume.remaining_indices.size()
	)
	study_ready_view.select_scope(resume.scope)
	study_ready_view.select_order(resume.order)


func _on_start_study_pressed() -> void:
	if (
		_study_plan.deck_file.is_empty()
		or not DeckStorage.deck_exists(_study_plan.deck_file)
	):
		show_library()
		_show_library_notice("덱 파일을 읽지 못했습니다.")
		return

	var scope := study_ready_view.selected_scope()
	var selected_indices := _study_plan.indices_for_scope(
		DeckStorage.load_progress(_study_plan.deck_file),
		scope
	)
	if selected_indices.is_empty():
		_show_action_notice(
			"오답 카드가 없습니다."
			if scope == StudyScope.WRONG
			else "학습할 미완료 카드가 없습니다."
		)
		return

	var order := study_ready_view.selected_order() as DeckOrdering.StudyOrder
	_begin_indexed_study(selected_indices, order, scope, true)


func _on_continue_study_pressed() -> void:
	var resume := DeckStorage.load_study_resume(_study_plan.deck_file)
	if not _study_plan.is_valid_resume(resume):
		_update_continue_action()
		_show_action_notice("이어서 학습할 기록이 없습니다.")
		return

	_begin_indexed_study(
		resume.remaining_indices,
		resume.order,
		resume.scope,
		false
	)


func _begin_indexed_study(
	indices: Array[int],
	order: DeckOrdering.StudyOrder,
	scope: int,
	apply_order: bool
) -> void:
	var cards := _study_plan.begin(indices, order, scope, apply_order)
	if cards.is_empty():
		return

	_deck_file = _study_plan.deck_file
	_remember_last_study_deck(_deck_file)
	_order = DeckOrdering.StudyOrder.SEQUENTIAL
	_progress = DeckStorage.load_progress(_deck_file)
	_source_cards = cards
	_show_page(study_flow)
	_restart_session()


func _save_active_study_resume() -> void:
	if (
		_study_plan.active_indices.is_empty()
		or _session == null
		or _deck_file.is_empty()
	):
		return

	if _session.is_finished():
		DeckStorage.delete_study_resume(_deck_file)
		return

	var resume := _study_plan.make_resume(_session.position())
	if resume != null:
		DeckStorage.save_study_resume(_deck_file, resume)


func _return_to_study_ready() -> void:
	card_context_menu.dismiss()
	_save_active_study_resume()
	var deck_file := _deck_file
	if deck_file.is_empty():
		deck_file = _study_plan.deck_file
	show_study_ready(deck_file)


func _on_library_add_pressed(anchor: Control) -> void:
	_pending_deck_action_file = ""
	library_context_menu.dismiss()
	deck_context_menu.dismiss()
	add_deck_menu.open_at(anchor)


func _on_library_settings_pressed(anchor: Control) -> void:
	add_deck_menu.dismiss()
	deck_context_menu.dismiss()
	library_context_menu.open_at(anchor)


func _on_open_settings_pressed() -> void:
	show_settings()


func _on_ready_deck_menu_pressed(anchor: Control) -> void:
	if (
		_study_plan.deck_file.is_empty()
		or not DeckStorage.deck_exists(_study_plan.deck_file)
	):
		show_library()
		_show_library_notice("덱 파일을 읽지 못했습니다.")
		return
	_on_deck_menu_requested(_study_plan.deck_file, anchor)


func _on_deck_menu_requested(deck_file: String, anchor: Control) -> void:
	add_deck_menu.dismiss()
	deck_context_menu.open_for(deck_file, anchor)


func handle_back_request() -> bool:
	if restore_backup_confirmation_overlay.visible:
		_on_restore_backup_canceled()
		return true

	if card_delete_confirmation_overlay.visible:
		_on_card_delete_canceled()
		return true

	if discard_card_changes_overlay.visible:
		_on_discard_card_changes_canceled()
		return true

	if create_deck_overlay.visible:
		_on_create_deck_canceled()
		return true

	if rename_deck_overlay.visible:
		_on_rename_canceled()
		return true

	if delete_confirmation_overlay.visible:
		_on_delete_canceled()
		return true

	if add_deck_menu.visible:
		add_deck_menu.dismiss()
		return true

	if library_context_menu.visible:
		library_context_menu.dismiss()
		return true

	if card_context_menu.visible:
		card_context_menu.dismiss()
		return true

	if deck_context_menu.visible:
		deck_context_menu.dismiss()
		return true

	if exit_confirmation_overlay.visible:
		_on_exit_canceled()
		return true

	if settings_view.visible:
		show_library()
		return true

	if library_view.visible:
		exit_confirmation_overlay.show()
		return true

	if card_editor_view.visible:
		_request_close_card_editor()
		return true

	if card_detail_view.visible:
		_close_card_detail()
		return true

	if card_list_view.visible:
		_return_to_ready_from_card_list()
		return true

	if study_ready_view.visible:
		if study_ready_view.is_setup_visible():
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


func _on_privacy_policy_pressed() -> void:
	var open_error := OS.shell_open(PRIVACY_POLICY_URL)
	if open_error != OK:
		_show_settings_notice("개인정보처리방침 페이지를 열 수 없습니다.")


func _on_backup_path_selected(target_path: String) -> void:
	_dismiss_virtual_keyboard()
	# Native Android dialogs can return a Storage Access Framework path.
	# It is an opaque address, so changing it after selection can make it invalid.
	var result := AppBackup.create_backup(target_path)
	if result == AppBackup.Result.OK:
		_show_settings_notice("전체 백업을 저장했습니다.")
		return
	_show_settings_notice(AppBackup.result_message(result))


func _on_restore_path_selected(source_path: String) -> void:
	_dismiss_virtual_keyboard()
	_pending_restore_path = source_path
	restore_backup_confirmation_overlay.show()


func _on_restore_backup_canceled() -> void:
	restore_backup_confirmation_overlay.hide()
	_pending_restore_path = ""


func _on_restore_backup_confirmed() -> void:
	restore_backup_confirmation_overlay.hide()
	var source_path := _pending_restore_path
	_pending_restore_path = ""
	var result := AppBackup.restore_backup(source_path)
	if result != AppBackup.Result.OK:
		_show_settings_notice(AppBackup.result_message(result))
		return
	show_settings()
	_show_settings_notice("전체 복원을 완료했습니다.")


func _dismiss_virtual_keyboard() -> void:
	get_viewport().gui_release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()


func _on_create_new_deck_pressed() -> void:
	add_deck_menu.dismiss()
	_create_deck_mode = CreateDeckMode.EMPTY
	_pending_markdown = ""
	create_deck_overlay.title_label.text = "새 덱 만들기"
	create_deck_overlay.description_label.text = "이름을 정한 뒤 첫 카드를 작성합니다."
	create_deck_overlay.primary_button.text = "첫 카드 작성"
	create_deck_overlay.clear_input()
	create_deck_overlay.error_label.hide()
	create_deck_overlay.show()
	create_deck_overlay.dialog_input.call_deferred("grab_focus")


func _on_create_deck_canceled() -> void:
	create_deck_overlay.hide()
	create_deck_overlay.clear_input()
	create_deck_overlay.error_label.hide()
	_reset_create_deck_state()


func _on_create_deck_confirmed() -> void:
	if _create_deck_mode == CreateDeckMode.CLIPBOARD:
		create_deck_from_markdown(create_deck_overlay.dialog_input.text, _pending_markdown)
	else:
		_begin_new_deck(create_deck_overlay.dialog_input.text)


func _on_create_deck_submitted(_new_name: String) -> void:
	_on_create_deck_confirmed()


func _on_create_from_clipboard_pressed() -> void:
	begin_clipboard_deck_creation(DisplayServer.clipboard_get())


func _on_copy_ai_prompt_pressed() -> void:
	DisplayServer.clipboard_set(AI_PROMPT_TEMPLATE)
	_show_settings_notice(AI_PROMPT_COPIED_MESSAGE)


func begin_clipboard_deck_creation(markdown_text: String) -> bool:
	add_deck_menu.dismiss()
	var clipboard_error := clipboard_content_error(markdown_text)
	if not clipboard_error.is_empty():
		_show_library_notice(clipboard_error)
		return false

	_create_deck_mode = CreateDeckMode.CLIPBOARD
	_pending_markdown = markdown_text
	var card_count := DeckParser.parse(markdown_text).size()
	create_deck_overlay.title_label.text = "클립보드로 덱 만들기"
	create_deck_overlay.description_label.text = (
		"복사한 Markdown에서 %d장의 카드를 찾았습니다." % card_count
	)
	create_deck_overlay.primary_button.text = "덱 만들기"
	create_deck_overlay.clear_input()
	create_deck_overlay.error_label.hide()
	create_deck_overlay.show()
	create_deck_overlay.dialog_input.call_deferred("grab_focus")
	return true


func create_deck_from_markdown(display_name: String, markdown_text: String) -> bool:
	var result := DeckActionService.create_from_markdown(display_name, markdown_text)
	if not result.succeeded:
		_show_create_deck_error(result.message)
		return false

	create_deck_overlay.hide()
	_reset_create_deck_state()
	_open_card_list(result.deck_file)
	return true


func _begin_new_deck(display_name: String) -> bool:
	var deck_file := _new_deck_file(display_name)
	if deck_file.is_empty():
		return false

	create_deck_overlay.hide()
	_card_workspace.load_snapshot(deck_file, [])
	_card_editor_origin = CardEditorOrigin.NEW_DECK
	_study_edit_source_index = -1
	_study_edit_return_show_answer = false
	_open_card_editor(-1)
	return true


func _new_deck_file(display_name: String) -> String:
	var result := DeckActionService.validate_new_deck_file(display_name)
	if not result.succeeded:
		_show_create_deck_error(result.message)
		return ""
	return result.deck_file


func _reset_create_deck_state() -> void:
	_create_deck_mode = CreateDeckMode.EMPTY
	_pending_markdown = ""


func _show_create_deck_error(message: String) -> void:
	create_deck_overlay.error_label.text = message
	create_deck_overlay.error_label.show()


func _on_import_from_add_menu_pressed() -> void:
	_on_import_pressed()


func _on_import_pressed() -> void:
	add_deck_menu.dismiss()
	library_view.popup_import()


func _on_export_pressed(deck_file: String) -> void:
	if deck_file.is_empty():
		_show_library_notice(EXPORT_DECK_NOT_FOUND_MESSAGE)
		return

	_pending_deck_action_file = deck_file
	library_view.popup_export("%s%s" % [
		DeckNaming.display_name(deck_file),
		DeckNaming.EXTENSION,
	])


func _on_export_file_selected(target_path: String) -> void:
	export_deck_to_path(_pending_deck_action_file, target_path)
	_pending_deck_action_file = ""


func _on_export_canceled() -> void:
	_pending_deck_action_file = ""


func _on_duplicate_pressed(deck_file: String) -> void:
	duplicate_deck_from_library(deck_file)


func duplicate_deck_from_library(deck_file: String) -> bool:
	var result := DeckActionService.duplicate_deck(deck_file)
	if not result.succeeded:
		_show_library_notice(result.message)
		return false

	_refresh_deck_list()
	_show_action_notice(result.message)
	return true


func _on_rename_pressed(deck_file: String) -> void:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_notice(RENAME_DECK_NOT_FOUND_MESSAGE)
		return

	_pending_deck_action_file = deck_file
	rename_deck_overlay.set_input_text(
		DeckNaming.display_name(deck_file)
	)
	rename_deck_overlay.error_label.hide()
	rename_deck_overlay.show()
	rename_deck_overlay.dialog_input.call_deferred("grab_focus")
	rename_deck_overlay.dialog_input.call_deferred("select_all")


func _on_rename_canceled() -> void:
	rename_deck_overlay.hide()
	_pending_deck_action_file = ""


func _on_rename_confirmed() -> void:
	rename_deck_from_library(
		_pending_deck_action_file,
		rename_deck_overlay.dialog_input.text
	)


func _on_rename_submitted(_new_name: String) -> void:
	_on_rename_confirmed()


func rename_deck_from_library(deck_file: String, new_display_name: String) -> bool:
	var result := DeckActionService.rename(deck_file, new_display_name)
	if not result.succeeded:
		_show_rename_error(result.message)
		return false
	if not result.changed:
		rename_deck_overlay.hide()
		_pending_deck_action_file = ""
		_show_action_notice(result.message)
		return true

	_replace_last_study_deck(deck_file, result.deck_file)
	rename_deck_overlay.hide()
	_pending_deck_action_file = ""
	_refresh_deck_list()
	# 준비 화면에서는 제목이 새 이름으로 바뀌는 것 자체가 결과를 보여 준다.
	if study_ready_view.visible and _study_plan.deck_file == deck_file:
		show_study_ready(result.deck_file)
	else:
		_show_library_notice(result.message)
	return true


func _show_rename_error(message: String) -> void:
	rename_deck_overlay.error_label.text = message
	rename_deck_overlay.error_label.show()


func _on_delete_pressed(deck_file: String) -> void:
	if not DeckStorage.deck_exists(deck_file):
		_show_library_notice(DELETE_DECK_NOT_FOUND_MESSAGE)
		return

	_pending_deck_action_file = deck_file
	delete_confirmation_overlay.title_label.text = "'%s' 덱을 삭제할까요?" % DeckNaming.display_name(
		deck_file
	)
	delete_confirmation_overlay.show()


func _on_delete_canceled() -> void:
	delete_confirmation_overlay.hide()
	_pending_deck_action_file = ""


func _on_delete_confirmed() -> void:
	var deck_file := _pending_deck_action_file
	delete_confirmation_overlay.hide()
	_pending_deck_action_file = ""
	delete_deck_from_library(deck_file)


func delete_deck_from_library(deck_file: String) -> bool:
	var result := DeckActionService.delete(deck_file)
	if not result.succeeded:
		_show_library_notice(result.message)
		return false

	_replace_last_study_deck(deck_file, "")
	_refresh_deck_list()
	_show_library_notice(result.message)
	return true


func export_deck_to_path(deck_file: String, target_path: String) -> bool:
	var result := DeckActionService.export(deck_file, target_path)
	if result.succeeded:
		_show_action_notice(result.message)
		return true

	_show_library_notice(result.message)
	return false


static func ensure_markdown_extension(target_path: String) -> String:
	return DeckActionService.ensure_markdown_extension(target_path)


static func export_error_message(result: DeckStorage.ExportResult) -> String:
	return DeckActionService.export_error_message(result)


func import_deck_from_path(source_path: String) -> bool:
	var result := DeckActionService.import_from_path(source_path)
	if not result.succeeded:
		_show_library_notice(result.message)
		return false

	_refresh_deck_list()
	_show_library_notice(result.message)
	return true


static func deck_content_error(deck_text: String) -> String:
	return DeckActionService.deck_content_error(deck_text)


static func clipboard_content_error(markdown_text: String) -> String:
	return DeckActionService.clipboard_content_error(markdown_text)


# 예전 상태 문구처럼 덱 목록으로 돌아온 뒤 화면 위쪽에 잠깐 띄운다.
func _show_library_notice(message: String) -> void:
	if not library_view.visible:
		show_library()

	top_notification.show_message(message)


# 복제나 내보내기는 어느 화면에서 해도 결과가 화면에 드러나지 않는다.
# _show_library_notice()와 달리 화면을 옮기지 않고 그 자리에서 알린다.
func _show_action_notice(message: String) -> void:
	top_notification.show_message(message)


# 백업이나 복원 결과는 화면에 드러나지 않으므로 설정 화면으로 돌아가 알린다.
func _show_settings_notice(message: String) -> void:
	if not settings_view.visible:
		show_settings()

	top_notification.show_message(message)


func _restart_session() -> void:
	_session_cards = DeckOrdering.apply(_order, _source_cards)
	_session = StudySession.new(_session_cards)
	_session_outcomes.clear()
	_session_outcomes.resize(_session_cards.size())
	_session_outcomes.fill(StudyOutcome.Value.PENDING)
	study_flow.set_deck_name(DeckNaming.display_name(_deck_file))
	_reset_study_input_lock()
	_save_active_study_resume()
	_show_current()


func _show_current() -> void:
	if _session == null or _session.is_finished():
		if not _deck_file.is_empty():
			DeckStorage.delete_study_resume(_deck_file)
		_show_study_results()
		return

	var card := _session.current()
	study_flow.show_card(
		card,
		_progress.get_wrong_count(card.question),
		card_status_text(_progress.get_status(card.question)),
		_session.remaining(),
		_session.position() > 0
	)


static func card_status_text(status: CardStatus.Value) -> String:
	match status:
		CardStatus.Value.LEARNING:
			return "LEARNING"
		CardStatus.Value.MASTERED:
			return "MASTERED"
		_:
			return "NEW"


func _show_study_results() -> void:
	_reset_study_input_lock()
	card_context_menu.dismiss()
	study_flow.show_results(_session_cards, _session_outcomes)


func _on_result_card_selected(result_index: int) -> void:
	if result_index < 0 or result_index >= _session_cards.size():
		return

	var card := _session_cards[result_index]
	var deck_index := -1
	_card_workspace.clear()
	if DeckStorage.deck_exists(_deck_file):
		_card_workspace.open(_deck_file)
		var active_index := _study_plan.active_index_at(result_index)
		if (
			active_index >= 0
			and active_index < _card_workspace.cards.size()
		):
			deck_index = active_index
		else:
			for index in _card_workspace.cards.size():
				var deck_card := _card_workspace.cards[index]
				if (
					deck_card.question == card.question
					and deck_card.answer == card.answer
				):
					deck_index = index
					break

	_show_card_detail(
		card,
		_progress,
		deck_index,
		CardDetailOrigin.STUDY_RESULT,
		result_index
	)


func _on_again_pressed() -> void:
	if _session == null or _session.is_finished() or not _try_lock_study_input():
		return

	_record_current_outcome(StudyOutcome.Value.AGAIN)
	_progress.add_wrong(_session.current().question)
	_progress.set_status(_session.current().question, CardStatus.Value.LEARNING)
	DeckStorage.save_progress(_deck_file, _progress)
	_session.next()
	_save_active_study_resume()
	_show_current()


func _on_good_pressed() -> void:
	if _session == null or _session.is_finished() or not _try_lock_study_input():
		return

	_record_current_outcome(StudyOutcome.Value.GOOD)
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

	_record_current_outcome(StudyOutcome.Value.SKIP)
	_session.next()
	_save_active_study_resume()
	_show_current()


func _record_current_outcome(outcome: int) -> void:
	if _session == null:
		return

	var index := _session.position()
	if index >= 0 and index < _session_outcomes.size():
		_session_outcomes[index] = outcome


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
	study_flow.set_input_enabled(false)
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
	study_flow.set_input_enabled(true)


func _on_retry_again_pressed() -> void:
	if _deck_file.is_empty():
		return

	var retry_cards: Array[FlashCard] = []
	var retry_indices: Array[int] = []
	var can_reuse_deck_indices := _study_plan.can_map_active_cards(
		_session_cards.size()
	)
	for index in _session_outcomes.size():
		if _session_outcomes[index] != StudyOutcome.Value.AGAIN:
			continue
		retry_cards.append(_session_cards[index])
		if can_reuse_deck_indices:
			retry_indices.append(_study_plan.active_index_at(index))

	if retry_cards.is_empty():
		return

	if can_reuse_deck_indices:
		_begin_indexed_study(
			retry_indices,
			_study_plan.active_order,
			StudyScope.WRONG,
			false
		)
		return

	_start_cards(
		_deck_file,
		retry_cards,
		DeckOrdering.StudyOrder.SEQUENTIAL
	)
