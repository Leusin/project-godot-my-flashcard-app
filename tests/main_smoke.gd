extends TestCase

const MAIN_SCENE := preload("res://src/main/main.tscn")
const TEST_DECKS_DIR := "user://__gd_main_decks"
const TEST_DECK := "__gd_main.md"
const TEST_TEXT := "# A\n1\n# B\n2\n"
const IMPORT_SOURCE := "res://tests/fixtures/cards_edge_cases.md"
const EMPTY_IMPORT_SOURCE := "res://tests/fixtures/empty_deck.md"
const BROKEN_IMPORT_SOURCE := "user://__gd_main_broken.md"
const EMPTY_DECK := "__gd_main_empty_saved.md"
const BROKEN_DECK := "__gd_main_broken_saved.md"
const DELETE_DECK := "__gd_main_delete.md"
const RENAME_DECK := "__gd_main_rename.md"
const RENAMED_DECK := "__gd_main_renamed.md"
const DUPLICATED_DECK := "__gd_main (2).md"
const EDIT_DECK := "__gd_main_edit.md"
const EDIT_TEXT := "# Old\nAnswer\n# Keep\nStay\n"
const STUDY_EDIT_DECK := "__gd_main_study_edit.md"
const STUDY_EDIT_TEXT := "# Study old\nStudy answer\n# Study keep\nKeep answer\n"
const CREATED_DECK := "__gd_main_created.md"
const CLIPBOARD_DECK := "__gd_main_clipboard.md"
const CLIPBOARD_TEXT := "복사한 서문\r\n# Clip A\r\nOne\r\n# Clip B\r\nTwo\r\n"
const EXPORT_TARGET_WITHOUT_EXTENSION := "user://__gd_main_export"
const EXPORTED_PATH := "user://__gd_main_export.md"


func run_tests() -> void:
	_cleanup()
	DeckStorage.set_decks_dir(TEST_DECKS_DIR)
	DeckStorage.write_deck(TEST_DECK, TEST_TEXT)
	var startup_settings := AppSettings.new()
	startup_settings.last_deck_file = TEST_DECK
	check(DeckStorage.save_settings(startup_settings), "Main Startup: 마지막 학습 덱 저장")
	var startup_app := MAIN_SCENE.instantiate()
	add_child(startup_app)
	check(
		_view(startup_app, "StudyReadyView").visible
		and not _view(startup_app, "LibraryContainer").visible
		and _view(startup_app, "ReadyDeckNameLabel").text == "__gd_main",
		"Main Startup: 앱 재진입 시 마지막 학습 덱 준비 화면 표시"
	)
	startup_app.free()

	var stale_settings := AppSettings.new()
	stale_settings.last_deck_file = "__missing.md"
	DeckStorage.save_settings(stale_settings)
	var stale_startup_app := MAIN_SCENE.instantiate()
	add_child(stale_startup_app)
	check(
		_view(stale_startup_app, "LibraryContainer").visible
		and DeckStorage.load_settings().last_deck_file.is_empty(),
		"Main Startup: 마지막 덱이 사라졌으면 목록으로 복귀하고 기록 정리"
	)
	stale_startup_app.free()

	var app := MAIN_SCENE.instantiate()
	app.auto_start = false
	add_child(app)
	var top_notification := _view(app, "TopNotification") as TopNotification
	var dismiss_timer := _view(top_notification, "DismissTimer") as Timer
	(_view(app, "CardFrame") as StudyGestureSurface).animations_enabled = false
	_view(app, "CardDetailFrame").set("animations_enabled", false)
	app.show_library()

	check(_view(app, "LibraryContainer").visible, "MVP: 덱 목록 화면 표시")
	# 인스턴스한 공용 header 밑에 붙인 노드는 [editable path] 표시가 없으면
	# 실행 중에는 보이지만 export 변환에서 통째로 사라진다. 빈 화면으로 나가는 것을 막는다.
	var header_scenes := [
		"res://src/main/library_view.tscn",
		"res://src/main/study_ready_view.tscn",
		"res://src/main/card_list_view.tscn",
		"res://src/main/card_detail_view.tscn",
		"res://src/main/card_editor_view.tscn",
		"res://src/main/settings_view.tscn",
		"res://src/main/study_view.tscn",
	]
	var header_scenes_editable := true
	for scene_path in header_scenes:
		var scene_text := FileAccess.get_file_as_string(scene_path)
		if not scene_text.contains('parent="Header/'):
			continue
		header_scenes_editable = (
			header_scenes_editable
			and scene_text.contains('[editable path="Header"]')
		)
	check(
		header_scenes_editable,
		"Main Export: 공용 header에 붙인 노드를 editable로 표시해 export 누락 방지"
	)
	check(
		_view(app, "InteractionPanel").visible == MainApp.is_mobile()
		and _view(app, "InteractionTitle").visible == MainApp.is_mobile(),
		"Main Settings: 햅틱 설정은 진동이 있는 모바일에서만 표시"
	)
	check(
		_view(app, "LibraryHeading").text == "덱 목록",
		"Main Navigation: 시작 화면 이름을 덱 목록으로 통일"
	)
	check(not _view(app, "SettingsView").visible, "Main Settings: 덱 목록에서 설정 화면 숨김")
	check(not _view(app, "StudyReadyView").visible, "Main Ready: 덱 목록에서 준비 화면 숨김")
	check(
		not _view(app, "StudyContainer").visible,
		"MVP: 덱 목록에서 학습 화면 숨김"
	)
	_view(app, "LibrarySettingsButton").pressed.emit()
	check(
		_view(app, "LibraryContextMenu").visible
		and _view(app, "OpenSettingsButton").text == "설정",
		"Main Settings: 덱 목록 ⋮가 확장 가능한 context list 표시"
	)
	_view(app, "OpenSettingsButton").pressed.emit()
	var settings_view := _view(app, "SettingsView") as VBoxContainer
	var privacy_policy_link := _view(settings_view, "PrivacyPolicyLink") as LinkButton
	check(
		settings_view.visible
		and not _view(app, "LibraryContainer").visible
		and privacy_policy_link.text == "개인정보처리방침"
		and privacy_policy_link.pressed.is_connected(
			Callable(app, "_on_privacy_policy_pressed")
		)
		and MainApp.PRIVACY_POLICY_URL
		== "https://leusin.github.io/privacy/my-simple-flash-card/",
		"Main Settings: 별도 설정 화면에서 공개 개인정보처리방침 연결"
	)
	var create_backup_button := _view(settings_view, "CreateBackupButton") as Button
	var restore_backup_button := _view(settings_view, "RestoreBackupButton") as Button
	check(
		_view(settings_view, "AppVersionLabel").text == "버전 0.10.2"
		and create_backup_button.pressed.is_connected(
			Callable(app, "_on_create_backup_pressed")
		)
		and restore_backup_button.pressed.is_connected(
			Callable(app, "_on_restore_backup_pressed")
		),
		"Main Settings: 버전과 전체 백업·복원 작업 표시"
	)
	var haptics_toggle := _view(settings_view, "HapticsToggle") as CheckButton
	check(
		haptics_toggle.button_pressed
		and haptics_toggle.toggled.is_connected(
			Callable(app, "_on_haptics_toggled")
		),
		"Main Settings: 저장된 햅틱 설정과 toggle signal 연결"
	)
	haptics_toggle.button_pressed = false
	check(
		not (_view(app, "CardFrame") as StudyGestureSurface).haptics_enabled
		and not DeckStorage.load_settings().haptics_enabled,
		"Main Settings: 햅틱 끄기를 즉시 적용하고 저장"
	)
	haptics_toggle.button_pressed = true
	check(
		_view(settings_view, "BackupDialog").access == FileDialog.ACCESS_FILESYSTEM
		and _view(settings_view, "BackupDialog").file_mode == FileDialog.FILE_MODE_SAVE_FILE
		and _view(settings_view, "BackupDialog").use_native_dialog
		and _view(settings_view, "RestoreDialog").access == FileDialog.ACCESS_FILESYSTEM
		and _view(settings_view, "RestoreDialog").file_mode == FileDialog.FILE_MODE_OPEN_FILE
		and _view(settings_view, "RestoreDialog").use_native_dialog,
		"Main Backup: Android 네이티브 저장창으로 Drive 백업·복원 지원"
	)
	app.call("_on_restore_path_selected", "user://backup.zip")
	check(
		_view(app, "RestoreBackupConfirmationOverlay").visible,
		"Main Backup: 전체 복원 전에 교체 확인"
	)
	check(app.handle_back_request(), "Main Backup: 뒤로가기로 복원 확인 취소")
	check(
		not _view(app, "RestoreBackupConfirmationOverlay").visible
		and settings_view.visible,
		"Main Backup: 복원 취소 후 설정 화면 유지"
	)
	check(app.handle_back_request(), "Main Settings: 뒤로가기 요청 소비")
	check(
		_view(app, "LibraryContainer").visible and not settings_view.visible,
		"Main Settings: 뒤로가기로 덱 목록 복귀"
	)
	var deck_buttons := _view(app, "DeckList").get_children()
	check(deck_buttons.size() == 1, "Main: 덱 목록에는 저장된 덱만 표시")
	check(
		DeckStorage.load_settings().deck_order.has(TEST_DECK),
		"Main: 화면에 그린 덱 차례를 설정에 남긴다"
	)
	var library := _view(app, "LibraryContainer") as LibraryView
	check(
		library.current_order() == DeckStorage.load_settings().deck_order,
		"Main: 화면 차례와 저장된 차례가 같다"
	)
	check(
		_view(deck_buttons[0], "DeckNameLabel").text == "__gd_main",
		"Main: 카드 뭉치 타일에 덱 표시 이름 사용"
	)
	check(
		_view(deck_buttons[0], "DeckCountLabel").text == "2장",
		"Main: 카드 뭉치 타일에 카드 수 표시"
	)
	var insertion_decks: Array[DeckInfo] = [
		DeckInfo.new("a.md", "A", 1),
		DeckInfo.new("b.md", "B", 1),
		DeckInfo.new("c.md", "C", 1),
	]
	library.render(insertion_decks)
	var insertion_tiles := library.deck_list.get_children()
	var insertion_anchor := insertion_tiles[1] as DeckTileView
	var anchor_rect := insertion_anchor.get_global_rect()
	var insertion_pointer := Vector2(anchor_rect.end.x, anchor_rect.get_center().y)
	library.call("_on_tile_reorder_started", "a.md")
	library.call("_on_tile_reorder_ended", "a.md", insertion_pointer)
	check(
		library.current_order() == ["b.md", "a.md", "c.md"],
		"Main Deck List: 손을 뗀 타일 경계로 덱 순서를 이동"
	)
	app.show_library()
	deck_buttons = _view(app, "DeckList").get_children()
	var library_add_button := _view(app, "LibraryAddButton") as Button
	library_add_button.pressed.emit()
	var add_deck_menu := _view(app, "AddDeckMenu") as Control
	check(
		add_deck_menu.visible
		and _view(app, "CreateNewDeckButton").text == "새 덱 만들기"
		and _view(app, "ImportMarkdownButton").text == "Markdown 가져오기"
		and _view(app, "CreateFromClipboardButton").text == "클립보드에서 만들기"
		and add_deck_menu.find_child("OpenSettingsButton", true, false) == null
		and add_deck_menu.find_child("CopyAiPromptButton", true, false) == null,
		"Main Create: + 메뉴에는 세 가지 덱 추가 작업만 표시"
	)
	check(
		(_view(app, "CreateFromClipboardButton") as Button).pressed.is_connected(
			Callable(app, "_on_create_from_clipboard_pressed")
		),
		"Main Clipboard: 클립보드 생성 버튼 signal 연결"
	)
	check(
		(_view(app, "CopyAiPromptButton") as Button).pressed.is_connected(
			Callable(app, "_on_copy_ai_prompt_pressed")
		)
		and _view(app, "AiPromptPreviewLabel").text == MainApp.AI_PROMPT_TEMPLATE
		and _view(app, "TipNextStep").text.contains("클립보드에서 만들기"),
		"Main Settings: AI 프롬프트 미리보기·복사 signal·다음 단계 안내"
	)
	check(app.handle_back_request(), "Main Create: 추가 선택창에서 뒤로가기 요청 소비")
	check(not add_deck_menu.visible, "Main Create: 뒤로가기로 추가 선택창 닫기")
	app.call("_on_copy_ai_prompt_pressed")
	check(
		_view(app, "SettingsView").visible
		and top_notification.visible
		and top_notification.message_label.text == MainApp.AI_PROMPT_COPIED_MESSAGE
		and DeckParser.parse(MainApp.AI_PROMPT_TEMPLATE).size() == 2,
		"Main Settings: AI 프롬프트 복사 후 다음 단계 안내"
	)
	app.show_library()
	deck_buttons = _view(app, "DeckList").get_children()
	_view(deck_buttons[0], "DeckButton").pressed.emit()
	_view(app, "ReadyDeckMenuButton").pressed.emit()
	var deck_context_menu := _view(app, "DeckContextMenu") as Control
	check(deck_context_menu.visible, "Main Export: ⋮ 위치에 context list 표시")
	check(
		_view(app, "ExportDialog").current_file.is_empty(),
		"Main Export: ⋮ 메뉴만 열 때 숨은 파일명 입력 field를 건드리지 않음"
	)
	_view(app, "ExportDeckButton").pressed.emit()
	check(
		_view(app, "ExportDialog").current_file == "__gd_main.md",
		"Main Export: 실제 내보내기 요청 때 기본 파일명 준비"
	)
	_view(app, "ExportDialog").hide()
	_view(app, "RenameDeckButton").pressed.emit()
	var rename_overlay := _view(app, "RenameDeckOverlay") as Control
	check(
		not deck_context_menu.visible and rename_overlay.visible,
		"Main Rename: context list에서 이름 변경창으로 전환"
	)
	var rename_input := _dialog(app, "RenameDeckOverlay", "DialogInput") as LineEdit
	var rename_counter := _dialog(app, "RenameDeckOverlay", "DialogCounter") as Label
	check(
		rename_input.max_length == DeckNaming.MAX_DISPLAY_NAME_LENGTH
		and rename_counter.visible
		and rename_counter.text == "%d/%d" % [
			rename_input.text.length(),
			DeckNaming.MAX_DISPLAY_NAME_LENGTH
		]
		and not (_dialog(app, "DeleteConfirmationOverlay", "DialogCounter") as Label).visible,
		"Main Rename: 이름 입력에 길이 제한과 현재/최대 글자수 표시"
	)
	check(
		_dialog(app, "RenameDeckOverlay", "DialogInput").text == "__gd_main",
		"Main Rename: 현재 덱 이름을 입력창에 표시"
	)
	_dialog(app, "RenameDeckOverlay", "DialogInput").text = ""
	_dialog(app, "RenameDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_dialog(app, "RenameDeckOverlay", "DialogError").visible
		and _dialog(app, "RenameDeckOverlay", "DialogError").text
		== MainApp.DECK_NAME_EMPTY_MESSAGE,
		"Main Rename: 빈 이름 오류를 입력창 안에 표시"
	)
	_dialog(app, "RenameDeckOverlay", "SecondaryButton").pressed.emit()
	check(not rename_overlay.visible, "Main Rename: 취소하면 이름 변경창 닫기")
	_view(app, "ReadyDeckMenuButton").pressed.emit()
	_view(app, "DeleteDeckButton").pressed.emit()
	var delete_overlay := _view(app, "DeleteConfirmationOverlay") as Control
	check(
		not deck_context_menu.visible and delete_overlay.visible,
		"Main Delete: 삭제 선택 후 확인창으로 전환"
	)
	check(
		_dialog(app, "DeleteConfirmationOverlay", "DialogTitle").text
		== "'__gd_main' 덱을 삭제할까요?",
		"Main Delete: 삭제할 덱 이름 표시"
	)
	check(
		_dialog(app, "DeleteConfirmationOverlay", "DialogDescription").text.contains(
			"학습 기록"
		)
		and _dialog(app, "DeleteConfirmationOverlay", "DialogDescription").text.contains(
			"되돌릴 수 없습니다"
		),
		"Main Delete: 학습 기록 삭제와 복구 불가 안내"
	)
	check(app.handle_back_request(), "Main Delete: 확인창에서 뒤로가기 요청 소비")
	check(not delete_overlay.visible, "Main Delete: 확인창에서 뒤로가면 취소")
	check(DeckStorage.deck_exists(TEST_DECK), "Main Delete: 취소하면 덱 유지")
	check(not _view(app, "LibraryContainer").visible, "MVP: 덱 선택 후 목록 숨김")
	check(_view(app, "StudyReadyView").visible, "Main Ready: 덱 선택 후 학습 준비 화면 표시")
	check(not _view(app, "StudyContainer").visible, "Main Ready: 덱 선택만으로 학습을 시작하지 않음")
	check(_view(app, "ReadyDeckNameLabel").text == "__gd_main", "Main Ready: 선택한 덱 이름 표시")
	check(
		_view(app, "ReadyTotalCountLabel").text == "2"
		and _view(app, "ReadyNewCountLabel").text == "2"
		and _view(app, "ReadyLearningCountLabel").text == "0"
		and _view(app, "ReadyMasteredCountLabel").text == "0",
		"Main Ready: 전체·새 카드·학습 중·완료 요약 표시"
	)
	check(
		_view(app, "StudyScopeOption").item_count == 3
		and _view(app, "StudyOrderOption").item_count == 2,
		"Main Ready: 학습 범위와 카드 순서 설정 표시"
	)
	check(
		_view(app, "OverviewContent").visible
		and not _view(app, "NewStudyContent").visible,
		"Main Ready: 준비 단계에서는 덱 요약과 필요한 진입 버튼만 표시"
	)
	_view(app, "OpenStudySetupButton").pressed.emit()
	check(
		not _view(app, "OverviewContent").visible
		and _view(app, "NewStudyContent").visible
		and _view(app, "StartStudyButton").visible
		and _view(app, "CancelStudySetupButton").visible,
		"Main Ready: 새 학습 설정 면에는 설정·시작·취소만 표시"
	)
	_view(app, "StudyScopeOption").select(MainApp.StudyScope.WRONG)
	_view(app, "StartStudyButton").pressed.emit()
	check(
		_view(app, "StudyReadyView").visible
		and top_notification.message_label.text == "오답 카드가 없습니다.",
		"Main Ready: 대상 카드가 없는 설정은 구체적으로 안내"
	)
	_view(app, "StudyScopeOption").select(MainApp.StudyScope.ALL)
	_view(app, "StartStudyButton").pressed.emit()
	check(_view(app, "StudyContainer").visible, "Main Ready: 학습 시작 버튼으로 학습 화면 표시")
	check(
		DeckStorage.load_study_resume(TEST_DECK).remaining_indices.size() == 2,
		"Main Ready: 학습 시작 시 남은 카드 세션 저장"
	)
	check(app.handle_back_request(), "MVP Android Back: 학습 화면에서 요청 소비")
	check(_view(app, "StudyReadyView").visible, "Main Ready: 학습 화면 뒤로가기는 준비 화면으로 복귀")
	check(
		_view(app, "ContinueStudyButton").visible
		and _view(app, "ContinueStudyButton").text == "이어서 학습 (2장 남음)",
		"Main Ready: 저장된 세션의 남은 카드 수 표시"
	)
	_view(app, "OpenStudySetupButton").pressed.emit()
	check(
		_view(app, "StartStudyButton").text == "진행 중 세션 교체하고 시작"
		and _view(app, "SetupDescription").text.contains("세션은 교체"),
		"Main Ready: 새 학습이 진행 중 세션을 교체한다고 명확히 안내"
	)
	_view(app, "CancelStudySetupButton").pressed.emit()
	_view(app, "ContinueStudyButton").pressed.emit()
	check(_view(app, "QuestionLabel").text == "A", "Main Ready: 저장된 첫 카드부터 이어서 학습")
	_view(app, "GoodButton").pressed.emit()
	check(app.handle_back_request(), "Main Ready: 한 카드 학습 후 뒤로가기 요청 소비")
	check(
		_view(app, "ContinueStudyButton").text == "이어서 학습 (1장 남음)",
		"Main Ready: 진행 후 줄어든 남은 카드 수 표시"
	)
	_view(app, "ContinueStudyButton").pressed.emit()
	check(_view(app, "QuestionLabel").text == "B", "Main Ready: 남은 카드부터 정확히 이어서 학습")
	check(app.handle_back_request(), "Main Ready: 이어서 학습 화면에서 뒤로가기 요청 소비")
	check(app.handle_back_request(), "Main Ready: 준비 화면에서 뒤로가기 요청 소비")
	check(_view(app, "LibraryContainer").visible, "Main Ready: 준비 화면에서 덱 목록으로 복귀")
	check(app.handle_back_request(), "MVP Android Back: 덱 목록에서 종료 요청 소비")
	var exit_overlay := _view(app, "ExitConfirmationOverlay") as Control
	check(exit_overlay.visible, "MVP Android Back: 덱 목록에서 종료 확인창 표시")
	check(
		_dialog(app, "ExitConfirmationOverlay", "DialogDescription").text
		== "앱을 종료할까요?",
		"MVP Android Back: 종료 질문 표시"
	)
	check(
		_dialog(app, "ExitConfirmationOverlay", "PrimaryButton").text == "종료",
		"MVP Android Back: 종료 버튼 표시"
	)
	check(
		_dialog(app, "ExitConfirmationOverlay", "SecondaryButton").text == "취소",
		"MVP Android Back: 취소 버튼 표시"
	)
	check(app.handle_back_request(), "MVP Android Back: 확인창에서 뒤로가기 요청 소비")
	check(not exit_overlay.visible, "MVP Android Back: 확인창에서 뒤로가면 취소")
	app.start_deck(TEST_DECK)
	check(
		DeckStorage.load_settings().last_deck_file == TEST_DECK,
		"Main Startup: 실제 학습을 시작한 덱을 마지막 덱으로 기억"
	)
	_view(app, "BackToReadyButton").pressed.emit()
	check(_view(app, "StudyReadyView").visible, "Main Ready: 학습 화면 버튼으로도 준비 화면 복귀")
	app.show_library()
	check(
		_view(app, "ImportDialog").access == FileDialog.ACCESS_FILESYSTEM,
		"MVP Import: 파일시스템 접근 다이얼로그"
	)
	check(_view(app, "ImportDialog").use_native_dialog, "MVP Import: 네이티브 다이얼로그")
	check(
		_view(app, "ExportDialog").access == FileDialog.ACCESS_FILESYSTEM
		and _view(app, "ExportDialog").file_mode == FileDialog.FILE_MODE_SAVE_FILE,
		"Main Export: 파일시스템 저장 다이얼로그"
	)
	check(_view(app, "ExportDialog").use_native_dialog, "Main Export: 네이티브 저장 다이얼로그")
	check(
		MainApp.ensure_markdown_extension(EXPORT_TARGET_WITHOUT_EXTENSION) == EXPORTED_PATH,
		"Main Export: 확장자가 없으면 .md 자동 추가"
	)
	check(
		app.export_deck_to_path(TEST_DECK, EXPORT_TARGET_WITHOUT_EXTENSION),
		"Main Export: Markdown 덱 내보내기 성공"
	)
	check(
		FileAccess.get_file_as_string(EXPORTED_PATH) == TEST_TEXT,
		"Main Export: 원본 Markdown 내용 보존"
	)
	check(
		not app.export_deck_to_path("__없는덱.md", EXPORTED_PATH),
		"Main Export: 사라진 원본 덱 실패"
	)

	check(app.import_deck_from_path(IMPORT_SOURCE), "MVP Import: Markdown 덱 가져오기 성공")
	check(DeckStorage.deck_exists("cards_edge_cases.md"), "MVP Import: 실제 fixture를 앱 덱 폴더에 복사")
	check(_view(app, "DeckList").get_child_count() == 2, "MVP Import: 목록 즉시 갱신")
	check(
		top_notification.visible
		and top_notification.message_label.text == "'cards_edge_cases' 가져오기 완료",
		"Main Notification: 성공 안내를 화면 위에 표시"
	)
	check(
		not app.import_deck_from_path("user://__gd_main_missing.md"),
		"MVP Import: 없는 파일 가져오기 실패"
	)
	check(
		top_notification.visible
		and top_notification.message_label.text == "덱을 가져오지 못했습니다.",
		"Main Notification: 실패 안내를 화면 위에 표시"
	)
	check(
		dismiss_timer.one_shot and dismiss_timer.wait_time == TopNotification.DEFAULT_DURATION,
		"Main Notification: 안내 타이머는 기본 시간짜리 one-shot"
	)
	dismiss_timer.timeout.emit()
	top_notification.show_message("다음 안내")
	check(
		top_notification.visible
		and top_notification.message_label.text == "다음 안내"
		and top_notification.modulate.a == 1.0
		and not dismiss_timer.is_stopped(),
		"Main Notification: 사라지는 중에도 새 안내가 페이드와 타이머를 되돌림"
	)
	top_notification.hide_message()

	check(not app.import_deck_from_path(EMPTY_IMPORT_SOURCE), "MVP Import: 빈 덱 거부")
	check(not DeckStorage.deck_exists("empty_deck.md"), "MVP Import: 빈 덱 미복사")

	var broken_import := FileAccess.open(BROKEN_IMPORT_SOURCE, FileAccess.WRITE)
	broken_import.store_string("질문 제목의 # 표시가 없습니다.\n")
	broken_import = null
	check(not app.import_deck_from_path(BROKEN_IMPORT_SOURCE), "MVP Import: 깨진 덱 거부")
	check(not DeckStorage.deck_exists("__gd_main_broken.md"), "Main Import: 깨진 덱 미복사")

	DeckStorage.write_deck(EMPTY_DECK, "")
	check(not app.start_deck(EMPTY_DECK), "MVP: 저장된 빈 덱 학습 차단")
	DeckStorage.write_deck(BROKEN_DECK, "일반 텍스트만 있는 덱")
	check(not app.start_deck(BROKEN_DECK), "MVP: 저장된 깨진 덱 학습 차단")

	app.start_deck(TEST_DECK)

	check(_view(app, "DeckLabel").text == "__gd_main", "Main: 덱 이름 표시")
	var study_card_content := _view(app, "QuestionLabel").get_parent()
	check(_view(app, "QuestionLabel").text == "A", "MVP: 첫 질문 표시")
	check(not _view(app, "AnswerScroll").visible, "Main Study: 첫 화면에서 답 영역 숨김")
	check(_view(app, "Actions").visible, "Main Study: 답 공개 전에도 자기평가 버튼 표시")
	check(_view(app, "RemainingLabel").text == "2장 남음", "MVP: 남은 카드 수 표시")
	check(
		StudyGestureSurface.drag_direction(Vector2(120, 10))
		== StudyGestureSurface.GOOD
		and StudyGestureSurface.drag_direction(Vector2(-120, 10))
		== StudyGestureSurface.AGAIN
		and StudyGestureSurface.drag_direction(Vector2(10, -130))
		== StudyGestureSurface.SKIP
		and StudyGestureSurface.drag_direction(Vector2(10, 130))
		== StudyGestureSurface.PREVIOUS
		and StudyGestureSurface.drag_direction(Vector2(40, 0)) == 0
		and StudyGestureSurface.drag_direction(Vector2(100, 100)) == 0,
		"Main Study: 좌우 판정과 위 skip·아래 previous drag 구분"
	)
	check(
		StudyGestureSurface.key_direction(KEY_LEFT) == StudyGestureSurface.AGAIN
		and StudyGestureSurface.key_direction(KEY_RIGHT) == StudyGestureSurface.GOOD
		and StudyGestureSurface.key_direction(KEY_UP) == StudyGestureSurface.SKIP
		and StudyGestureSurface.key_direction(KEY_DOWN) == StudyGestureSurface.PREVIOUS,
		"Main Study: 방향키를 swipe 방향과 같은 네 동작에 mapping"
	)
	var gesture_surface := _view(app, "CardFrame") as StudyGestureSurface
	var threshold_crossings: Array[int] = []
	gesture_surface.judgment_threshold_crossed.connect(
		func(direction: int) -> void: threshold_crossings.append(direction)
	)
	gesture_surface._show_horizontal_preview(StudyGestureSurface.DRAG_THRESHOLD - 1.0)
	gesture_surface._show_horizontal_preview(StudyGestureSurface.DRAG_THRESHOLD + 1.0)
	gesture_surface._show_horizontal_preview(StudyGestureSurface.DRAG_THRESHOLD + 20.0)
	gesture_surface._show_horizontal_preview(0.0)
	gesture_surface._show_horizontal_preview(-StudyGestureSurface.DRAG_THRESHOLD - 1.0)
	check(
		threshold_crossings == [StudyGestureSurface.GOOD, StudyGestureSurface.AGAIN]
		and gesture_surface.haptics_enabled,
		"Main Study: GOOD·AGAIN 판정선을 넘을 때만 햅틱 요청"
	)
	check(
		FileAccess.get_file_as_string("res://export_presets.cfg").contains(
			"permissions/vibrate=true"
		),
		"Main Android: 햅틱용 VIBRATE 권한 포함"
	)
	var export_presets_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(
		export_presets_text.count("screen/immersive_mode=false") == 2
		and export_presets_text.count("screen/edge_to_edge=false") == 2,
		"Main Android: debug와 release에서 시스템 상태·내비게이션 bar 유지"
	)
	check(
		ProjectSettings.get_setting("application/config/version") == "0.10.2"
		and export_presets_text.count("version/name=\"0.10.2\"") == 2
		and export_presets_text.count("version/code=6") == 2
		and export_presets_text.contains("my-simple-flash-card-0.10.2.aab"),
		"Main Release: 0.10.2 versionName과 versionCode 6 일치"
	)
	check(
		export_presets_text.count("export_filter=\"all_resources\"") == 2,
		"Main Android: preload 리소스 누락 방지를 위해 전체 리소스 export"
	)
	check(
		export_presets_text.count(
			"exclude_filter=\"store-listing/*,tests/*,tools/*\""
		) == 2,
		"Main Android: 배포와 무관한 스토어 자료·테스트·도구 제외"
	)
	check(
		export_presets_text.count("include_filter=\"sample_deck.md\"") == 2,
		"Main Android: 일반 파일인 Markdown 샘플 덱도 export에 포함"
	)
	gesture_surface._reset_visual()

	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(
		_view(app, "AnswerScroll").visible
		and _view(app, "CardProperties").visible
		and _view(app, "StatusBadge").text == "MASTERED",
		"Main Study: 카드 tap으로 답·tally·상태 딱지를 함께 공개"
	)
	var gesture_center := gesture_surface.get_global_rect().get_center()
	check(
		gesture_surface._can_start_drag(gesture_center),
		"Main Study: 카드 안에서 gesture 시작"
	)
	gesture_surface._begin_drag(gesture_center, 0)
	gesture_surface._update_drag(gesture_center + Vector2(100.0, 0.0))
	_view(app, "AgainButton").button_down.emit()
	check(
		not gesture_surface._dragging
		and not gesture_surface._can_start_drag(gesture_center),
		"Main Study: 판정 버튼을 누르면 진행 중인 카드 drag를 취소하고 소유권 고정"
	)
	var blocked_touch := InputEventScreenTouch.new()
	blocked_touch.index = 0
	blocked_touch.position = gesture_center
	blocked_touch.pressed = true
	gesture_surface._handle_touch(blocked_touch)
	check(
		not gesture_surface._dragging,
		"Main Study: 판정 버튼을 누른 손가락 이동 중 카드가 drag를 다시 시작하지 않음"
	)
	_view(app, "AgainButton").button_up.emit()
	check(
		gesture_surface._can_start_drag(gesture_center),
		"Main Study: 판정 버튼에서 손을 떼면 다음 카드 gesture 허용"
	)
	check(_view(app, "AnswerLabel").text == "1", "MVP: 현재 카드의 답 표시")
	check(
		_view(app, "Actions").visible
		and _view(app, "AgainButton").text == "AGAIN"
		and _view(app, "GoodButton").text == "GOOD",
		"Main Study: 답 공개 후 자기평가 버튼 유지"
	)
	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(
		not _view(app, "AnswerScroll").visible
		and not _view(app, "CardProperties").visible,
		"Main Study: 카드를 다시 tap하면 질문만 보는 앞면으로 복귀"
	)

	_view(app, "AgainButton").pressed.emit()
	check(_view(app, "QuestionLabel").text == "B", "MVP: Again 후 다음 질문")
	check(_view(app, "RemainingLabel").text == "1장 남음", "MVP: Again 후 남은 수 감소")
	check(
		DeckStorage.load_progress(TEST_DECK).get_wrong_count("A") == 1
		and DeckStorage.load_progress(TEST_DECK).get_status("A")
		== CardStatus.Value.LEARNING,
		"Main Ready: Again이 오답 횟수와 학습 중 상태를 저장"
	)
	check(
		_view(app, "AgainButton").disabled and _view(app, "GoodButton").disabled,
		"Main Study: 판정 직후 자기평가 입력 잠금"
	)

	_view(app, "GoodButton").pressed.emit()
	check(
		_view(app, "QuestionLabel").text == "B"
		and not _view(app, "StudyResultView").visible
		and DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.NEW,
		"Main Study: 빠른 연속 판정은 다음 카드에 적용하지 않음"
	)
	app._reset_study_input_lock()
	_view(app, "GoodButton").pressed.emit()
	check(
		_view(app, "StudyResultView").visible
		and not _view(app, "StudyContainer").visible,
		"Main Result: 마지막 카드 후 학습 화면 대신 결과 화면 표시"
	)
	check(
		DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.MASTERED,
		"Main Ready: Good이 완료 상태를 저장"
	)
	var first_result_rows := app.result_rows as VBoxContainer
	check(
		_view(app, "ResultGoodCountLabel").text == "1"
		and _view(app, "ResultAgainCountLabel").text == "1"
		and _view(app, "ResultSkipCountLabel").text == "0"
		and first_result_rows.get_child_count() == 2,
		"Main Result: GOOD·AGAIN·SKIP 수와 학습 카드 목록 표시"
	)
	check(
		_view(first_result_rows.get_child(0), "QuestionLabel").text == "A"
		and _view(first_result_rows.get_child(0), "OutcomeLabel").text == "AGAIN"
		and _view(first_result_rows.get_child(1), "QuestionLabel").text == "B"
		and _view(first_result_rows.get_child(1), "OutcomeLabel").text == "GOOD",
		"Main Result: 카드별 마지막 판정을 학습 순서대로 표시"
	)
	var first_result_row = first_result_rows.get_child(0)
	var result_selection_count := [0]
	first_result_row.selected.connect(
		func(_index: int) -> void: result_selection_count[0] += 1
	)
	var result_row_press := InputEventMouseButton.new()
	result_row_press.button_index = MOUSE_BUTTON_LEFT
	result_row_press.pressed = true
	first_result_row._gui_input(result_row_press)
	var result_row_drag := InputEventMouseMotion.new()
	result_row_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	result_row_drag.relative = Vector2(0, -24)
	first_result_row._gui_input(result_row_drag)
	var result_row_release := InputEventMouseButton.new()
	result_row_release.button_index = MOUSE_BUTTON_LEFT
	first_result_row._gui_input(result_row_release)
	check(
		result_selection_count[0] == 0
		and _view(app, "StudyResultView").visible
		and first_result_row.mouse_filter == Control.MOUSE_FILTER_PASS,
		"Main Result: 행 drag는 스크롤로 전달하고 카드를 열지 않음"
	)
	first_result_row._gui_input(result_row_press)
	first_result_row._gui_input(result_row_release)
	check(
		_view(app, "CardDetailView").visible
		and not _view(app, "StudyResultView").is_visible_in_tree()
		and _view(app, "BackFromCardDetailButton").tooltip_text
		== "학습 결과로 돌아가기"
		and _view(app, "DetailQuestionLabel").text == "A"
		and _view(app, "CardDetailMenuButton").visible,
		"Main Result: 결과 카드 상세 화면 열기"
	)
	_view(app, "CardTapButton").pressed.emit()
	check(
		_view(app, "DetailAnswerScroll").visible
		and _view(app, "DetailAnswerLabel").text == "1"
		and (_view(app, "DetailWrongTally") as WrongTallyView).wrong_count == 1,
		"Main Result: 실제 카드 tap 버튼으로 뒷면과 tally 확인"
	)
	_view(app, "BackFromCardDetailButton").pressed.emit()
	check(
		_view(app, "StudyResultView").visible,
		"Main Result: 카드 보기에서 학습 결과로 복귀"
	)
	_view(app, "RetryAgainButton").pressed.emit()
	check(
		_view(app, "StudyContainer").visible
		and not _view(app, "StudyResultView").visible
		and _view(app, "QuestionLabel").text == "A"
		and _view(app, "RemainingLabel").text == "1장 남음",
		"Main Result: AGAIN 카드만 모아 다시 학습"
	)
	check(
		_view(app, "WrongTally").wrong_count == 1
		and _view(app, "WrongTally").tooltip_text == "오답 1회",
		"Main Study: 다시 표시한 카드에 저장된 tally 반영"
	)
	_view(app, "BackToReadyButton").pressed.emit()
	check(
		_view(app, "ReadyNewCountLabel").text == "0"
		and _view(app, "ReadyLearningCountLabel").text == "1"
		and _view(app, "ReadyMasteredCountLabel").text == "1",
		"Main Ready: 학습 결과를 진행상황 요약에 반영"
	)

	var sample_cards := DeckParser.parse(
		FileAccess.get_file_as_string(DeckStorage.SAMPLE_DECK_PATH)
	)
	app.start_sample_deck()
	check(_view(app, "StudyContainer").visible, "MVP: 샘플 덱으로 학습 시작")
	check(
		not sample_cards.is_empty()
		and _view(app, "QuestionLabel").text == sample_cards[0].question
		and _view(app, "RemainingLabel").text == "%d장 남음" % sample_cards.size(),
		"MVP: 번들 샘플 덱 내용으로 학습 시작"
	)

	DeckStorage.write_deck(RENAME_DECK, TEST_TEXT)
	var rename_progress := Progress.new()
	rename_progress.add_wrong("A")
	DeckStorage.save_progress(RENAME_DECK, rename_progress)
	var rename_settings := DeckStorage.load_settings()
	rename_settings.last_deck_file = RENAME_DECK
	DeckStorage.save_settings(rename_settings)
	app.show_library()
	var rename_tile := _find_deck_tile(app, "__gd_main_rename")
	check(rename_tile != null, "Main Rename: 이름을 바꿀 덱 타일 표시")
	if rename_tile != null:
		_view(rename_tile, "DeckButton").pressed.emit()
		_view(app, "ReadyDeckMenuButton").pressed.emit()
		_view(app, "RenameDeckButton").pressed.emit()
		_dialog(app, "RenameDeckOverlay", "DialogInput").text = "__gd_main"
		_dialog(app, "RenameDeckOverlay", "PrimaryButton").pressed.emit()
		check(
			_dialog(app, "RenameDeckOverlay", "DialogError").text
			== MainApp.DECK_NAME_DUPLICATE_MESSAGE
			and DeckStorage.deck_exists(RENAME_DECK),
			"Main Rename: 중복 이름을 거부하고 원본 유지"
		)
		_dialog(app, "RenameDeckOverlay", "DialogInput").text = "__gd_main_renamed"
		_dialog(app, "RenameDeckOverlay", "PrimaryButton").pressed.emit()
	check(not DeckStorage.deck_exists(RENAME_DECK), "Main Rename: 이전 덱 파일 제거")
	check(DeckStorage.deck_exists(RENAMED_DECK), "Main Rename: 새 덱 파일 생성")
	check(
		DeckStorage.load_progress(RENAMED_DECK).get_wrong_count("A") == 1,
		"Main Rename: 학습 기록도 새 이름으로 이동"
	)
	check(
		DeckStorage.load_settings().last_deck_file == RENAMED_DECK,
		"Main Rename: 마지막 학습 덱 설정도 새 이름으로 이동"
	)
	check(
		_view(app, "ReadyDeckNameLabel").text == "__gd_main_renamed",
		"Main Rename: 학습 준비 화면에 새 이름 반영"
	)

	app.show_library()
	var duplicate_tile := _find_deck_tile(app, "__gd_main")
	check(duplicate_tile != null, "Main Duplicate: 복제할 덱 타일 표시")
	if duplicate_tile != null:
		_view(duplicate_tile, "DeckButton").pressed.emit()
		_view(app, "ReadyDeckMenuButton").pressed.emit()
		_view(app, "DuplicateDeckButton").pressed.emit()
	check(DeckStorage.deck_exists(DUPLICATED_DECK), "Main Duplicate: 새 덱 파일 생성")
	check(
		DeckStorage.read_deck(DUPLICATED_DECK) == TEST_TEXT,
		"Main Duplicate: Markdown 내용 복사"
	)
	check(
		DeckStorage.load_progress(DUPLICATED_DECK).get_wrong_count("A") == 1,
		"Main Duplicate: 학습 기록 복사"
	)
	check(
		DeckStorage.deck_exists(DUPLICATED_DECK),
		"Main Duplicate: 복제한 덱 파일 존재"
	)
	check(
		_view(app, "StudyReadyView").visible
		and top_notification.message_label.text == "'__gd_main (2)' 복제 완료",
		"Main Duplicate: 준비 화면에서 복제해도 화면 이동 없이 알림"
	)
	check(
		not app.duplicate_deck_from_library("__없는덱.md"),
		"Main Duplicate: 사라진 덱 복제 실패"
	)

	DeckStorage.write_deck(DELETE_DECK, TEST_TEXT)
	var delete_progress := Progress.new()
	delete_progress.add_wrong("A")
	DeckStorage.save_progress(DELETE_DECK, delete_progress)
	var delete_settings := DeckStorage.load_settings()
	delete_settings.last_deck_file = DELETE_DECK
	DeckStorage.save_settings(delete_settings)
	app.show_library()
	var delete_tile := _find_deck_tile(app, "__gd_main_delete")
	check(delete_tile != null, "Main Delete: 삭제할 덱 타일 표시")
	if delete_tile != null:
		_view(delete_tile, "DeckButton").pressed.emit()
		_view(app, "ReadyDeckMenuButton").pressed.emit()
		_view(app, "DeleteDeckButton").pressed.emit()
		_dialog(app, "DeleteConfirmationOverlay", "PrimaryButton").pressed.emit()
	check(not DeckStorage.deck_exists(DELETE_DECK), "Main Delete: 덱 파일 제거")
	check(
		DeckStorage.load_settings().last_deck_file.is_empty(),
		"Main Delete: 삭제한 덱의 마지막 학습 설정도 정리"
	)
	check(
		not FileAccess.file_exists(DeckStorage.progress_path(DELETE_DECK)),
		"Main Delete: 덱 학습 기록도 제거"
	)
	check(
		not app.delete_deck_from_library("__없는덱.md"),
		"Main Delete: 사라진 덱 삭제 실패"
	)

	DeckStorage.write_deck(EDIT_DECK, EDIT_TEXT)
	var edit_progress := Progress.new()
	edit_progress.set_wrong_count("Old", 3)
	edit_progress.set_status("Old", CardStatus.Value.LEARNING)
	DeckStorage.save_progress(EDIT_DECK, edit_progress)
	var edit_resume := StudyResume.new()
	edit_resume.deck_hash = EDIT_TEXT.hash()
	edit_resume.remaining_indices = [0]
	DeckStorage.save_study_resume(EDIT_DECK, edit_resume)
	app.show_library()
	var edit_tile := _find_deck_tile(app, "__gd_main_edit")
	check(edit_tile != null, "Main Card Edit: 편집할 덱 타일 표시")
	if edit_tile != null:
		_view(edit_tile, "DeckButton").pressed.emit()
	_view(app, "ManageCardsButton").pressed.emit()
	check(
		_view(app, "CardListView").visible
		and app.card_rows.get_child_count() == 2,
		"Main Card Edit: Study Ready에서 카드 목록 진입"
	)
	var first_card_row = app.card_rows.get_child(0)
	check(
		first_card_row.mouse_filter == Control.MOUSE_FILTER_PASS
		and (_view(app, "CardListScroll") as ScrollContainer).vertical_scroll_mode
		== ScrollContainer.SCROLL_MODE_AUTO,
		"Main Card List: 카드 행 drag를 scroll에 전달"
	)
	var row_menu_button := _view(first_card_row, "RowMenuButton") as Button
	var row_reorder_handle := _view(first_card_row, "RowReorderHandle") as Button
	check(
		row_menu_button != null
		and row_menu_button.visible
		and row_reorder_handle != null
		and row_reorder_handle.visible
		and not row_reorder_handle.disabled,
		"Main Card List: 카드 관리와 순서 변경 action 제공"
	)
	var reorder_deck_before := DeckParser.parse(DeckStorage.read_deck(EDIT_DECK))
	var second_card_row := app.card_rows.get_child(1) as CardCollectionRow
	var second_row_bottom := second_card_row.get_global_rect().end.y
	app.call("_on_card_row_reorder_started", 0)
	app.call("_on_card_row_reorder_ended", 0, second_row_bottom)
	var reorder_deck_after := DeckParser.parse(DeckStorage.read_deck(EDIT_DECK))
	check(
		reorder_deck_before.size() == reorder_deck_after.size()
		and reorder_deck_after[0].question == reorder_deck_before[1].question
		and reorder_deck_after[1].question == reorder_deck_before[0].question,
		"Main Card List: 손잡이로 옮긴 카드 순서를 Markdown에 저장"
	)
	check(
		app.card_rows.get_child(0).card_index == 0
		and app.card_rows.get_child(1).card_index == 1
		and (app.card_rows.get_child(0) as CardCollectionRow).question_label.text
		== reorder_deck_after[0].question
		and DeckStorage.load_study_resume(EDIT_DECK) == null,
		"Main Card List: 순서 변경 후 행 index와 이어하기 기록 정리"
	)
	var restore_anchor := app.card_rows.get_child(0) as CardCollectionRow
	var restore_top := restore_anchor.get_global_rect().position.y
	app.call("_on_card_row_reorder_started", first_card_row.card_index)
	app.call("_on_card_row_reorder_ended", first_card_row.card_index, restore_top)
	row_menu_button.pressed.emit()
	check(
		_view(app, "CardContextMenu").visible
		and _view(app, "CardListView").visible
		and not _view(app, "CardDetailView").visible,
		"Main Card List: 행 ⋮로 카드를 열지 않고 메뉴만 표시"
	)
	_view(app, "DeleteCardActionButton").pressed.emit()
	check(
		_view(app, "CardDeleteConfirmationOverlay").visible,
		"Main Card List: 행 ⋮에서 바로 삭제 확인"
	)
	_dialog(app, "CardDeleteConfirmationOverlay", "SecondaryButton").pressed.emit()
	row_menu_button.pressed.emit()
	_view(app, "EditCardActionButton").pressed.emit()
	check(
		_view(app, "CardEditorView").visible
		and _view(app, "CardQuestionInput").text == "Old",
		"Main Card List: 행 ⋮에서 바로 카드 편집 진입"
	)
	_view(app, "CancelCardEditButton").pressed.emit()
	check(
		_view(app, "CardListView").visible
		and not _view(app, "CardDetailView").visible,
		"Main Card List: 행 ⋮ 편집을 취소하면 카드 목록으로 복귀"
	)
	var row_selection_count := [0]
	first_card_row.selected.connect(
		func(_index: int) -> void: row_selection_count[0] += 1
	)
	var row_press := InputEventMouseButton.new()
	row_press.button_index = MOUSE_BUTTON_LEFT
	row_press.pressed = true
	first_card_row._gui_input(row_press)
	var row_drag := InputEventMouseMotion.new()
	row_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	row_drag.relative = Vector2(0, -24)
	first_card_row._gui_input(row_drag)
	var row_release := InputEventMouseButton.new()
	row_release.button_index = MOUSE_BUTTON_LEFT
	first_card_row._gui_input(row_release)
	check(
		row_selection_count[0] == 0 and _view(app, "CardListView").visible,
		"Main Card List: 행을 누른 채 drag하면 카드를 열지 않음"
	)
	first_card_row._gui_input(row_press)
	first_card_row._gui_input(row_release)
	check(row_selection_count[0] == 1, "Main Card List: 짧은 tap은 카드 열기로 유지")
	first_card_row._gui_input(row_press)
	first_card_row._gui_input(row_release)
	check(
		row_selection_count[0] == 2 and not first_card_row.get("_reordering"),
		"Main Card List: 행 본체는 눌러도 집히지 않고 카드를 연다"
	)
	var handle_pick_started := [0]
	first_card_row.reorder_started.connect(
		func(_index: int) -> void: handle_pick_started[0] += 1
	)
	var handle_press := InputEventMouseButton.new()
	handle_press.button_index = MOUSE_BUTTON_LEFT
	handle_press.pressed = true
	row_reorder_handle.gui_input.emit(handle_press)
	check(
		handle_pick_started[0] == 1
		and first_card_row.get("_reordering"),
		"Main Card List: 손잡이를 누르면 순서 변경 시작"
	)
	var handle_release := InputEventMouseButton.new()
	handle_release.button_index = MOUSE_BUTTON_LEFT
	row_reorder_handle.gui_input.emit(handle_release)
	check(
		not first_card_row.get("_reordering"),
		"Main Card List: 손잡이에서 손을 떼면 순서 변경 종료"
	)
	check(
		_view(app, "CardDetailView").visible
		and not _view(app, "CardEditorView").visible
		and _view(app, "DetailQuestionLabel").text == "Old"
		and not _view(app, "DetailAnswerScroll").visible
		and not _view(app, "DetailCardProperties").visible
		and _view(app, "CardDetailMenuButton").visible,
		"Main Card Detail: 선택한 카드 상세 화면 열기"
	)
	_view(app, "CardTapButton").pressed.emit()
	check(
		_view(app, "DetailAnswerScroll").visible
		and _view(app, "DetailAnswerLabel").text == "Answer"
		and _view(app, "DetailCardProperties").visible
		and (_view(app, "DetailWrongTally") as WrongTallyView).wrong_count == 3
		and _view(app, "DetailStatusBadge").text == "LEARNING",
		"Main Card Detail: tap으로 뒷면·tally·상태 딱지 확인"
	)
	check(
		(_view(app, "CardDetailMenuButton") as Button).action_mode
		== BaseButton.ACTION_MODE_BUTTON_RELEASE,
		"Main Card Detail: ⋮를 뗀 뒤 메뉴를 열어 같은 release로 닫히지 않음"
	)
	_view(app, "CardDetailMenuButton").pressed.emit()
	check(
		_view(app, "CardContextMenu").visible
		and _view(app, "EditCardActionButton").text == "수정하기"
		and _view(app, "DeleteCardActionButton").text == "카드 삭제"
		and _view(app, "DeleteCardActionButton").visible,
		"Main Card Detail: 수정과 삭제 action 제공"
	)
	var favorite_progress := DeckStorage.load_progress(EDIT_DECK)
	favorite_progress.set_favorite("Old", true)
	DeckStorage.save_progress(EDIT_DECK, favorite_progress)
	_view(app, "EditCardActionButton").pressed.emit()
	check(
		_view(app, "CardEditorView").visible
		and _view(app, "CardQuestionInput").text == "Old"
		and _view(app, "CardAnswerInput").text == "Answer"
		and _view(app, "EditorWrongCountLabel").text == "3"
		and _view(app, "CardStatusOption").get_selected_id()
		== CardStatus.Value.LEARNING,
		"Main Card Edit: 질문·답과 기존 학습 정보를 편집기에 표시"
	)
	var question_input := _view(app, "CardQuestionInput") as SingleLineTextEdit
	question_input.text = "Line one\nLine two"
	question_input.call("_strip_newlines")
	check(
		question_input.text == "Line one Line two",
		"Main Card Edit: 질문에 들어온 줄바꿈을 공백으로 정리"
	)
	question_input.text = "Old"
	check(
		question_input.submitted.is_connected(
			Callable(app, "_on_question_submitted")
		),
		"Main Card Edit: 질문 Enter 신호를 답 focus 이동에 연결"
	)
	app.call("_on_question_submitted")
	check(
		(_view(app, "CardAnswerInput") as TextEdit).has_focus(),
		"Main Card Edit: 질문 제출 시 답 입력으로 focus 이동"
	)
	_view(app, "WrongPlusButton").pressed.emit()
	_view(app, "CardStatusOption").select(
		_view(app, "CardStatusOption").get_item_index(CardStatus.Value.MASTERED)
	)
	_view(app, "CardStatusOption").item_selected.emit(
		_view(app, "CardStatusOption").selected
	)
	_view(app, "CardQuestionInput").text = "New"
	_view(app, "CardAnswerInput").text = "# 잘못된 답 제목"
	_view(app, "SaveCardButton").pressed.emit()
	check(
		top_notification.message_label.text == MainApp.CARD_ANSWER_HEADING_MESSAGE
		and DeckStorage.read_deck(EDIT_DECK) == EDIT_TEXT,
		"Main Card Edit: 카드를 분리시키는 답의 # 제목 저장 차단"
	)
	_view(app, "CardAnswerInput").text = "Updated"
	_view(app, "SaveCardButton").pressed.emit()
	var edited_cards := DeckParser.parse(DeckStorage.read_deck(EDIT_DECK))
	check(
		edited_cards.size() == 2
		and edited_cards[0].question == "New"
		and edited_cards[0].answer == "Updated",
		"Main Card Edit: 질문과 답을 Markdown 덱에 저장"
	)
	check(
		DeckStorage.load_progress(EDIT_DECK).get_wrong_count("New") == 4
		and DeckStorage.load_progress(EDIT_DECK).get_status("New")
		== CardStatus.Value.MASTERED
		and DeckStorage.load_progress(EDIT_DECK).is_favorite("New")
		and not DeckStorage.load_progress(EDIT_DECK).is_favorite("Old"),
		"Main Card Edit: 질문 변경과 함께 오답 횟수·상태·즐겨찾기 저장"
	)
	check(
		DeckStorage.load_study_resume(EDIT_DECK) == null,
		"Main Card Edit: 카드 변경 시 진행 중 세션 폐기"
	)
	check(
		_view(app, "CardDetailView").visible
		and _view(app, "DetailQuestionLabel").text == "New",
		"Main Card Detail: 편집 저장 후 갱신된 카드 보기로 복귀"
	)
	_view(app, "BackFromCardDetailButton").pressed.emit()
	_view(app, "AddCardButton").pressed.emit()
	check(
		_view(app, "EditorWrongCountLabel").text == "0"
		and _view(app, "CardStatusOption").get_selected_id()
		== CardStatus.Value.NEW
		and _view(app, "ResetCardProgressButton").disabled,
		"Main Card Edit: 새 카드는 NEW·오답 0회로 시작"
	)
	_view(app, "CardQuestionInput").text = "Added"
	_view(app, "CardAnswerInput").text = "Added answer"
	_view(app, "SaveCardButton").pressed.emit()
	check(
		DeckParser.parse(DeckStorage.read_deck(EDIT_DECK)).size() == 3,
		"Main Card Edit: 새 카드 추가"
	)
	app.card_rows.get_child(0).activate()
	_view(app, "CardDetailMenuButton").pressed.emit()
	_view(app, "EditCardActionButton").pressed.emit()
	_view(app, "WrongMinusButton").pressed.emit()
	_view(app, "CardAnswerInput").grab_focus()
	_view(app, "CancelCardEditButton").pressed.emit()
	check(
		_view(app, "DiscardCardChangesOverlay").visible
		and get_viewport().gui_get_focus_owner() == null
		and _view(app, "DiscardCardChangesOverlay").size == app.size,
		"Main Card Edit: 취소 시 지원하지 않는 키보드 API 없이 포커스를 놓고 변경사항 확인"
	)
	_dialog(app, "DiscardCardChangesOverlay", "SecondaryButton").pressed.emit()
	check(_view(app, "CardEditorView").visible, "Main Card Edit: 계속 편집 선택")
	_view(app, "CardAnswerInput").grab_focus()
	check(app.handle_back_request(), "Main Card Edit: 시스템 뒤로가기 요청 소비")
	check(
		_view(app, "DiscardCardChangesOverlay").visible
		and get_viewport().gui_get_focus_owner() == null
		and _view(app, "DiscardCardChangesOverlay").size == app.size,
		"Main Card Edit: 시스템 뒤로가기도 키보드를 닫고 변경사항 확인"
	)
	_dialog(app, "DiscardCardChangesOverlay", "PrimaryButton").pressed.emit()
	check(
		_view(app, "CardDetailView").visible
		and DeckStorage.load_progress(EDIT_DECK).get_wrong_count("New") == 4,
		"Main Card Edit: 학습 정보 변경사항 버리고 카드 보기 복귀"
	)
	_view(app, "BackFromCardDetailButton").pressed.emit()
	app.card_rows.get_child(2).activate()
	_view(app, "CardDetailMenuButton").pressed.emit()
	_view(app, "DeleteCardActionButton").pressed.emit()
	check(
		_view(app, "CardDeleteConfirmationOverlay").visible
		and not _view(app, "CardContextMenu").visible,
		"Main Card Detail: ⋮ 메뉴에서 바로 카드 삭제 확인"
	)
	_dialog(app, "CardDeleteConfirmationOverlay", "PrimaryButton").pressed.emit()
	check(
		DeckParser.parse(DeckStorage.read_deck(EDIT_DECK)).size() == 2
		and app.card_rows.get_child_count() == 2,
		"Main Card Edit: 카드 삭제 후 목록과 Markdown 갱신"
	)
	_view(app, "BackFromCardListButton").pressed.emit()
	check(
		_view(app, "StudyReadyView").visible
		and _view(app, "ReadyTotalCountLabel").text == "2",
		"Main Card Edit: 카드 관리에서 갱신된 Study Ready로 복귀"
	)

	DeckStorage.write_deck(STUDY_EDIT_DECK, STUDY_EDIT_TEXT)
	var study_edit_progress := Progress.new()
	study_edit_progress.set_wrong_count("Study old", 2)
	study_edit_progress.set_status("Study old", CardStatus.Value.LEARNING)
	DeckStorage.save_progress(STUDY_EDIT_DECK, study_edit_progress)
	app.show_study_ready(STUDY_EDIT_DECK)
	_view(app, "OpenStudySetupButton").pressed.emit()
	_view(app, "StudyScopeOption").select(
		_view(app, "StudyScopeOption").get_item_index(MainApp.StudyScope.ALL)
	)
	_view(app, "StudyOrderOption").select(
		_view(app, "StudyOrderOption").get_item_index(
			DeckOrdering.StudyOrder.SEQUENTIAL
		)
	)
	_view(app, "StartStudyButton").pressed.emit()
	check(
		_view(study_card_content, "QuestionLabel").text == "Study old",
		"Main Study: 설정한 첫 카드 학습"
	)
	_view(app, "GoodButton").pressed.emit()
	check(
		_view(study_card_content, "QuestionLabel").text == "Study keep"
		and _view(app, "RemainingLabel").text == "1장 남음",
		"Main Study: 설정 UI 없이 다음 카드 계속 학습"
	)
	app._reset_study_input_lock()
	_view(app, "AgainButton").pressed.emit()
	var indexed_result_rows := app.result_rows as VBoxContainer
	check(
		_view(app, "StudyResultView").visible
		and _view(app, "ResultGoodCountLabel").text == "1"
		and _view(app, "ResultAgainCountLabel").text == "1"
		and _view(indexed_result_rows.get_child(0), "QuestionLabel").text
		== "Study old"
		and _view(indexed_result_rows.get_child(0), "OutcomeLabel").text
		== "GOOD"
		and _view(indexed_result_rows.get_child(1), "OutcomeLabel").text
		== "AGAIN",
		"Main Result: 설정 버튼 제거 후에도 indexed 학습 결과 유지"
	)
	_view(app, "RetryAgainButton").pressed.emit()
	check(
		_view(study_card_content, "QuestionLabel").text == "Study keep"
		and _view(app, "RemainingLabel").text == "1장 남음",
		"Main Result: 설정 학습에서도 AGAIN 카드의 원본 index로 재시작"
	)
	(_view(app, "CardFrame") as StudyGestureSurface).swiped.emit(
		StudyGestureSurface.SKIP
	)
	check(
		_view(app, "StudyResultView").visible
		and _view(app, "ResultSkipCountLabel").text == "1"
		and _view(app, "ResultAgainCountLabel").text == "0"
		and _view(app, "RetryAgainButton").disabled
		and _view(app.result_rows.get_child(0), "OutcomeLabel").text
		== "SKIP",
		"Main Result: SKIP 판정 표시 및 AGAIN이 없으면 재학습 비활성화"
	)

	app.show_library()
	_view(app, "LibraryAddButton").pressed.emit()
	_view(app, "CreateNewDeckButton").pressed.emit()
	check(
		_view(app, "CreateDeckOverlay").visible
		and not _view(app, "AddDeckMenu").visible,
		"Main Create: 새 덱 이름 입력으로 전환"
	)
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_dialog(app, "CreateDeckOverlay", "DialogError").text
		== MainApp.DECK_NAME_EMPTY_MESSAGE,
		"Main Create: 빈 덱 이름 오류 안내"
	)
	_dialog(app, "CreateDeckOverlay", "DialogInput").text = "bad/name"
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_dialog(app, "CreateDeckOverlay", "DialogError").text
		== MainApp.DECK_NAME_INVALID_MESSAGE,
		"Main Create: 파일명에 쓸 수 없는 덱 이름 차단"
	)
	_dialog(app, "CreateDeckOverlay", "DialogInput").text = "__gd_main"
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_dialog(app, "CreateDeckOverlay", "DialogError").text
		== MainApp.DECK_NAME_DUPLICATE_MESSAGE,
		"Main Create: 기존 덱과 중복되는 이름 차단"
	)
	_dialog(app, "CreateDeckOverlay", "DialogInput").text = "  __gd_main_created  "
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_view(app, "CardEditorView").visible
		and _view(app, "CardEditorTitle").text == "첫 카드 추가"
		and not DeckStorage.deck_exists(CREATED_DECK),
		"Main Create: 파일을 만들기 전에 첫 카드 편집으로 진입"
	)
	_view(app, "CardQuestionInput").text = "Draft"
	_view(app, "CancelCardEditButton").pressed.emit()
	_dialog(app, "DiscardCardChangesOverlay", "PrimaryButton").pressed.emit()
	check(
		_view(app, "LibraryContainer").visible
		and not DeckStorage.deck_exists(CREATED_DECK),
		"Main Create: 첫 카드 작성을 취소하면 빈 덱을 남기지 않음"
	)
	_view(app, "LibraryAddButton").pressed.emit()
	_view(app, "CreateNewDeckButton").pressed.emit()
	_dialog(app, "CreateDeckOverlay", "DialogInput").text = "__gd_main_created"
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	_view(app, "CardQuestionInput").text = "Created question"
	_view(app, "CardAnswerInput").text = "Created answer"
	_view(app, "SaveCardButton").pressed.emit()
	var created_cards := DeckParser.parse(DeckStorage.read_deck(CREATED_DECK))
	check(
		_view(app, "CardListView").visible
		and DeckStorage.deck_exists(CREATED_DECK)
		and created_cards.size() == 1
		and created_cards[0].question == "Created question"
		and created_cards[0].answer == "Created answer"
		and app.card_rows.get_child_count() == 1,
		"Main Create: 첫 카드 저장 순간 유효한 Markdown 덱 생성"
	)
	check(
		_view(app, "CardListView").visible
		and _view(app, "CardListDeckLabel").text == "__gd_main_created",
		"Main Create: 생성 완료 후 카드 목록 표시"
	)
	_view(app, "BackFromCardListButton").pressed.emit()
	check(
		_view(app, "StudyReadyView").visible
		and _view(app, "ReadyTotalCountLabel").text == "1",
		"Main Create: 생성한 덱의 Study Ready로 복귀"
	)
	_view(app, "BackToLibraryButton").pressed.emit()
	var created_tile := _find_deck_tile(app, "__gd_main_created")
	check(
		created_tile != null
		and _view(created_tile, "DeckCountLabel").text == "1장",
		"Main Create: 덱 목록에 새 카드 뭉치 즉시 표시"
	)

	check(
		MainApp.clipboard_content_error("") == MainApp.CLIPBOARD_EMPTY_MESSAGE
		and MainApp.clipboard_content_error("질문 제목 없음")
		== MainApp.CLIPBOARD_BROKEN_MESSAGE,
		"Main Clipboard: 빈 텍스트와 잘못된 Markdown 안내"
	)
	check(
		app.begin_clipboard_deck_creation(CLIPBOARD_TEXT),
		"Main Clipboard: 복사한 Markdown에서 덱 생성 시작"
	)
	check(
		_view(app, "CreateDeckOverlay").visible
		and _dialog(app, "CreateDeckOverlay", "DialogTitle").text
		== "클립보드로 덱 만들기"
		and _dialog(app, "CreateDeckOverlay", "DialogDescription").text
		== "복사한 Markdown에서 2장의 카드를 찾았습니다."
		and _dialog(app, "CreateDeckOverlay", "PrimaryButton").text == "덱 만들기",
		"Main Clipboard: 카드 수를 확인하고 덱 이름 입력"
	)
	_dialog(app, "CreateDeckOverlay", "DialogInput").text = "__gd_main_clipboard"
	_dialog(app, "CreateDeckOverlay", "PrimaryButton").pressed.emit()
	check(
		_view(app, "CardListView").visible
		and DeckStorage.read_deck(CLIPBOARD_DECK) == CLIPBOARD_TEXT
		and app.card_rows.get_child_count() == 2,
		"Main Clipboard: 복사한 Markdown 원문 그대로 덱 저장"
	)
	check(
		_view(app, "CardListView").visible
		and _view(app, "CardListDeckLabel").text == "__gd_main_clipboard",
		"Main Clipboard: 생성 완료 후 카드 목록 진입"
	)
	_view(app, "BackFromCardListButton").pressed.emit()
	_view(app, "BackToLibraryButton").pressed.emit()
	var clipboard_tile := _find_deck_tile(app, "__gd_main_clipboard")
	check(
		clipboard_tile != null
		and _view(clipboard_tile, "DeckCountLabel").text == "2장",
		"Main Clipboard: 생성한 덱을 라이브러리에 즉시 표시"
	)

	app.queue_free()
	_cleanup()
	DeckStorage.set_decks_dir("")


func _view(app: Node, node_name: String) -> Node:
	return app.find_child(node_name, true, false)


func _dialog(app: Node, overlay_name: String, node_name: String) -> Node:
	return _view(app, overlay_name).find_child(node_name, true, false)


func _find_deck_tile(app: Node, display_name: String) -> Node:
	for tile in _view(app, "DeckList").get_children():
		var tile_name := _view(tile, "DeckNameLabel") as Label
		if tile_name != null and tile_name.text == display_name:
			return tile
	return null


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_DECKS_DIR):
		for file_name in DirAccess.get_files_at(TEST_DECKS_DIR):
			DirAccess.remove_absolute("%s/%s" % [TEST_DECKS_DIR, file_name])
		DirAccess.remove_absolute(TEST_DECKS_DIR)

	for deck_file in [
		TEST_DECK,
		DELETE_DECK,
		RENAME_DECK,
		RENAMED_DECK,
		DUPLICATED_DECK,
		EDIT_DECK,
		STUDY_EDIT_DECK,
		CREATED_DECK,
		CLIPBOARD_DECK,
	]:
		var progress_path := DeckStorage.progress_path(deck_file)
		if FileAccess.file_exists(progress_path):
			DirAccess.remove_absolute(progress_path)
		var resume_path := DeckStorage.study_resume_path(deck_file)
		if FileAccess.file_exists(resume_path):
			DirAccess.remove_absolute(resume_path)

	if FileAccess.file_exists(BROKEN_IMPORT_SOURCE):
		DirAccess.remove_absolute(BROKEN_IMPORT_SOURCE)
	if FileAccess.file_exists(EXPORTED_PATH):
		DirAccess.remove_absolute(EXPORTED_PATH)
	if FileAccess.file_exists(DeckStorage.SETTINGS_PATH):
		DirAccess.remove_absolute(DeckStorage.SETTINGS_PATH)
