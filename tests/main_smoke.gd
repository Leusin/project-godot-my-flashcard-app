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
const EXPORT_TARGET_WITHOUT_EXTENSION := "user://__gd_main_export"
const EXPORTED_PATH := "user://__gd_main_export.md"


func run_tests() -> void:
	_cleanup()
	DeckStorage.set_decks_dir(TEST_DECKS_DIR)
	DeckStorage.write_deck(TEST_DECK, TEST_TEXT)

	var safe_insets := MainApp.safe_insets_in_viewport(
		Rect2i(0, 94, 1080, 2402),
		Vector2i(1080, 2640),
		Vector2(720, 1760)
	)
	check(is_equal_approx(safe_insets.y, 62.666668), "MVP Safe Area: 노치 상단 여백 환산")
	check(is_equal_approx(safe_insets.w, 96.0), "MVP Safe Area: 하단 제스처 영역 환산")
	check(
		MainApp.safe_insets_in_viewport(Rect2i(), Vector2i.ZERO, Vector2.ZERO)
		== Vector4.ZERO,
		"MVP Safe Area: 창 크기가 없으면 추가 여백 없음"
	)

	var app := MAIN_SCENE.instantiate()
	app.auto_start = false
	add_child(app)
	app.show_library()

	check(_view(app, "LibraryContainer").visible, "MVP: 덱 목록 화면 표시")
	check(not _view(app, "StudyContainer").visible, "MVP: 덱 목록에서 학습 화면 숨김")
	var deck_buttons := _view(app, "DeckList").get_children()
	check(deck_buttons.size() == 2, "Main: 저장된 덱 뒤에 추가 타일 표시")
	check(
		_view(app, "DeckList").alignment == FlowContainer.ALIGNMENT_BEGIN,
		"Main: 덱 목록을 왼쪽부터 정렬"
	)
	check(
		_view(deck_buttons[-1], "AddDeckLabel").text == "덱 추가 / 가져오기",
		"Main Import: 덱 목록의 마지막에 추가·가져오기 표시"
	)
	check(
		_view(deck_buttons[0], "DeckNameLabel").text == "__gd_main",
		"Main: 카드 뭉치 타일에 덱 표시 이름 사용"
	)
	check(
		_view(deck_buttons[0], "DeckCountLabel").text == "2장",
		"Main: 카드 뭉치 타일에 카드 수 표시"
	)
	check(
		_view(deck_buttons[0], "BackCardFar") != null
		and _view(deck_buttons[0], "BackCardNear") != null,
		"Main: 덱 타일을 세 장의 카드 뭉치로 표시"
	)
	check(
		_view(deck_buttons[0], "DeckMenuButton").custom_minimum_size == Vector2(64, 64),
		"Main Export: 덱 관리 버튼을 모바일 크기로 표시"
	)
	check(
		_view(deck_buttons[0], "DeckMenuButton").get_theme_stylebox("normal")
		is StyleBoxEmpty
		and _view(deck_buttons[0], "DeckMenuButton").get_theme_stylebox("hover")
		is StyleBoxEmpty,
		"Main Deck Actions: ⋮ 버튼의 테두리와 hover 배경 제거"
	)
	_view(deck_buttons[0], "DeckMenuButton").pressed.emit()
	var deck_context_menu := _view(app, "DeckContextMenu") as Control
	check(deck_context_menu.visible, "Main Export: ⋮ 위치에 context list 표시")
	check(
		_view(app, "DeckContextMenuTitle") == null,
		"Main Deck Actions: 장식용 덱 제목 없이 context list만 표시"
	)
	check(
		_view(app, "ExportDialog").current_file == "__gd_main.md",
		"Main Export: 기본 파일명에 덱 이름 사용"
	)
	var deck_context_style := (
		_view(app, "DeckContextMenuPanel").get_theme_stylebox("panel") as StyleBoxFlat
	)
	check(
		deck_context_style != null
		and deck_context_style.bg_color == Color.WHITE
		and deck_context_style.border_width_left == 0
		and deck_context_style.shadow_size == 6
		and deck_context_style.corner_radius_top_left == 12,
		"Main Deck Actions: 테두리 없이 그림자만 있는 흰 context list 표시"
	)
	check(
		_view(app, "ExportDeckButton").get_theme_color("font_color") == Color.BLACK
		and _view(app, "DeleteDeckButton").get_theme_color("font_color") == Color.BLACK,
		"Main Deck Actions: context list 텍스트를 검게 표시"
	)
	check(
		_view(app, "DeckContextMenuPanel").position.y
		<= _view(deck_buttons[0], "DeckMenuButton").get_global_rect().end.y,
		"Main Deck Actions: context list 윗선을 ⋮ 버튼 위치에 배치"
	)
	check(
		_view(app, "DeckContextMenuPanel").position.x
		< _view(deck_buttons[0], "DeckMenuButton").get_global_rect().position.x,
		"Main Deck Actions: context list 오른쪽 끝을 ⋮ 버튼에 정렬"
	)
	check(
		_view(app, "DeckContextMenuPanel").size
		== _view(app, "DeckContextMenuPanel").get_combined_minimum_size(),
		"Main Deck Actions: context list 실제 layout 크기로 위치 계산"
	)
	check(
		_view(app, "DeckContextMenuPanel").custom_minimum_size == Vector2(200, 176)
		and _view(app, "ExportDeckButton").custom_minimum_size.y == 60.0
		and _view(app, "DeleteDeckButton").custom_minimum_size.y == 60.0,
		"Main Deck Actions: 이름표 없는 200px compact context list 표시"
	)
	_view(app, "DeleteDeckButton").pressed.emit()
	var delete_overlay := _view(app, "DeleteConfirmationOverlay") as Control
	check(
		not deck_context_menu.visible and delete_overlay.visible,
		"Main Delete: 삭제 선택 후 확인창으로 전환"
	)
	check(
		_view(app, "DeleteConfirmationTitle").text == "'__gd_main' 덱을 삭제할까요?",
		"Main Delete: 삭제할 덱 이름 표시"
	)
	check(
		_view(app, "DeleteWarningLabel").text.contains("학습 기록")
		and _view(app, "DeleteWarningLabel").text.contains("되돌릴 수 없습니다"),
		"Main Delete: 학습 기록 삭제와 복구 불가 안내"
	)
	check(app.handle_back_request(), "Main Delete: 확인창에서 뒤로가기 요청 소비")
	check(not delete_overlay.visible, "Main Delete: 확인창에서 뒤로가면 취소")
	check(DeckStorage.deck_exists(TEST_DECK), "Main Delete: 취소하면 덱 유지")
	_view(deck_buttons[0], "DeckButton").pressed.emit()
	check(not _view(app, "LibraryContainer").visible, "MVP: 덱 선택 후 목록 숨김")
	check(_view(app, "StudyContainer").visible, "MVP: 덱 선택 후 학습 화면 표시")
	check(app.handle_back_request(), "MVP Android Back: 학습 화면에서 요청 소비")
	check(_view(app, "LibraryContainer").visible, "MVP Android Back: 덱 목록으로 복귀")
	check(app.handle_back_request(), "MVP Android Back: 덱 목록에서 종료 요청 소비")
	var exit_overlay := _view(app, "ExitConfirmationOverlay") as Control
	check(exit_overlay.visible, "MVP Android Back: 덱 목록에서 종료 확인창 표시")
	check(
		_view(app, "ExitWarningLabel").text == "앱을 종료할까요?",
		"MVP Android Back: 종료 질문 표시"
	)
	check(_view(app, "ConfirmExitButton").text == "종료", "MVP Android Back: 종료 버튼 표시")
	check(_view(app, "CancelExitButton").text == "취소", "MVP Android Back: 취소 버튼 표시")
	var exit_panel_style := (
		_view(app, "ExitConfirmationPanel").get_theme_stylebox("panel") as StyleBoxFlat
	)
	check(
		exit_panel_style != null
		and exit_panel_style.bg_color == Color.WHITE
		and exit_panel_style.border_color == Color.BLACK,
		"MVP Android Back: 종료 확인창은 흰 배경과 검은 테두리"
	)
	check(
		_view(app, "ConfirmExitButton").custom_minimum_size.y == 96.0
		and _view(app, "CancelExitButton").custom_minimum_size.y == 96.0,
		"MVP Android Back: 종료 확인 버튼을 모바일 크기로 표시"
	)
	check(app.handle_back_request(), "MVP Android Back: 확인창에서 뒤로가기 요청 소비")
	check(not exit_overlay.visible, "MVP Android Back: 확인창에서 뒤로가면 취소")
	app.start_deck(TEST_DECK)
	_view(app, "BackToLibraryButton").pressed.emit()
	check(_view(app, "LibraryContainer").visible, "MVP: 덱 목록 버튼으로도 복귀")
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
		_view(app, "LibraryStatusLabel").text == "'__gd_main_export.md' 내보내기 완료",
		"Main Export: 완료 파일명을 목록 아래 표시"
	)
	check(
		not app.export_deck_to_path("__없는덱.md", EXPORTED_PATH),
		"Main Export: 사라진 원본 덱 실패"
	)
	check(
		_view(app, "LibraryStatusLabel").text == MainApp.EXPORT_DECK_NOT_FOUND_MESSAGE,
		"Main Export: 원본 덱 없음 오류 안내"
	)

	check(app.import_deck_from_path(IMPORT_SOURCE), "MVP Import: Markdown 덱 가져오기 성공")
	check(DeckStorage.deck_exists("cards_edge_cases.md"), "MVP Import: 실제 fixture를 앱 덱 폴더에 복사")
	check(_view(app, "DeckList").get_child_count() == 3, "MVP Import: 목록 즉시 갱신")
	check(
		_view(app, "LibraryStatusLabel").text == "'cards_edge_cases' 가져오기 완료",
		"MVP Import: 성공 메시지 표시"
	)
	check(
		not app.import_deck_from_path("user://__gd_main_missing.md"),
		"MVP Import: 없는 파일 가져오기 실패"
	)
	check(
		_view(app, "LibraryStatusLabel").text == "덱을 가져오지 못했습니다.",
		"MVP Import: 실패 메시지 표시"
	)

	check(not app.import_deck_from_path(EMPTY_IMPORT_SOURCE), "MVP Import: 빈 덱 거부")
	check(
		_view(app, "LibraryStatusLabel").text == MainApp.EMPTY_DECK_MESSAGE,
		"MVP Import: 빈 덱 수정 안내"
	)
	check(not DeckStorage.deck_exists("empty_deck.md"), "MVP Import: 빈 덱 미복사")

	var broken_import := FileAccess.open(BROKEN_IMPORT_SOURCE, FileAccess.WRITE)
	broken_import.store_string("질문 제목의 # 표시가 없습니다.\n")
	broken_import = null
	check(not app.import_deck_from_path(BROKEN_IMPORT_SOURCE), "MVP Import: 깨진 덱 거부")
	check(
		_view(app, "LibraryStatusLabel").text == MainApp.BROKEN_DECK_MESSAGE,
		"MVP Import: 깨진 덱 형식 안내"
	)
	check(not DeckStorage.deck_exists("__gd_main_broken.md"), "Main Import: 깨진 덱 미복사")

	DeckStorage.write_deck(EMPTY_DECK, "")
	check(not app.start_deck(EMPTY_DECK), "MVP: 저장된 빈 덱 학습 차단")
	check(
		_view(app, "LibraryStatusLabel").text == MainApp.EMPTY_DECK_MESSAGE,
		"MVP: 저장된 빈 덱 안내"
	)
	DeckStorage.write_deck(BROKEN_DECK, "일반 텍스트만 있는 덱")
	check(not app.start_deck(BROKEN_DECK), "MVP: 저장된 깨진 덱 학습 차단")
	check(
		_view(app, "LibraryStatusLabel").text == MainApp.BROKEN_DECK_MESSAGE,
		"MVP: 저장된 깨진 덱 안내"
	)

	app.start_deck(TEST_DECK)

	check(_view(app, "DeckLabel").text == "__gd_main", "Main: 덱 이름 표시")
	check(_view(app, "QuestionLabel").text == "A", "MVP: 첫 질문 표시")
	check(not _view(app, "AnswerLabel").visible, "MVP: 첫 화면에서 답 숨김")
	check(_view(app, "RemainingLabel").text == "2장 남음", "MVP: 남은 카드 수 표시")
	check(
		app.get_node("Margin/Page/Title").get_theme_color("font_color") == Color.BLACK,
		"MVP 스타일: 모든 Label 글자는 검은색"
	)
	var card_style := (
		app.get_node("Margin/Page/StudyFlow/StudyContainer/Card").get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	check(
		card_style != null
		and card_style.bg_color == Color.WHITE
		and card_style.border_color == Color.BLACK,
		"MVP 스타일: 카드는 흰 바탕과 검은 테두리"
	)
	var button_style := (
		_view(app, "RevealButton").get_theme_stylebox("normal") as StyleBoxFlat
	)
	check(
		button_style != null
		and button_style.bg_color == Color.WHITE
		and button_style.border_color == Color.BLACK,
		"MVP 스타일: 버튼은 흰 바탕과 검은 테두리"
	)

	_view(app, "RevealButton").pressed.emit()
	check(_view(app, "AnswerLabel").visible, "MVP: 답 보기 버튼으로 답 공개")
	check(_view(app, "AnswerLabel").text == "1", "MVP: 현재 카드의 답 표시")

	_view(app, "AgainButton").pressed.emit()
	check(_view(app, "QuestionLabel").text == "B", "MVP: Again 후 다음 질문")
	check(_view(app, "RemainingLabel").text == "1장 남음", "MVP: Again 후 남은 수 감소")
	check(
		DeckStorage.load_progress(TEST_DECK).get_wrong_count("A") == 1,
		"MVP: Again이 진행도를 저장"
	)

	_view(app, "GoodButton").pressed.emit()
	check(_view(app, "DoneContainer").visible, "MVP: 마지막 카드 후 완료 표시")
	check(not _view(app, "StudyContainer").visible, "MVP: 완료 시 학습 화면 숨김")

	_view(app, "RestartButton").pressed.emit()
	check(_view(app, "StudyContainer").visible, "MVP: 다시 시작으로 학습 화면 복귀")
	check(_view(app, "QuestionLabel").text == "A", "MVP: 다시 시작하면 첫 카드")

	app.start_sample_deck()
	check(_view(app, "StudyContainer").visible, "MVP: 샘플 덱으로 학습 시작")
	check(
		_view(app, "QuestionLabel").text == "MyFlashCard는 어떤 앱인가요?",
		"MVP: 앱 소개 샘플 덱의 첫 질문 표시"
	)

	DeckStorage.write_deck(DELETE_DECK, TEST_TEXT)
	var delete_progress := Progress.new()
	delete_progress.add_wrong("A")
	DeckStorage.save_progress(DELETE_DECK, delete_progress)
	app.show_library()
	var delete_tile: Node = null
	for tile in _view(app, "DeckList").get_children():
		var tile_name := _view(tile, "DeckNameLabel") as Label
		if tile_name != null and tile_name.text == "__gd_main_delete":
			delete_tile = tile
			break
	check(delete_tile != null, "Main Delete: 삭제할 덱 타일 표시")
	if delete_tile != null:
		_view(delete_tile, "DeckMenuButton").pressed.emit()
		_view(app, "DeleteDeckButton").pressed.emit()
		_view(app, "ConfirmDeleteButton").pressed.emit()
	check(not DeckStorage.deck_exists(DELETE_DECK), "Main Delete: 덱 파일 제거")
	check(
		not FileAccess.file_exists(DeckStorage.progress_path(DELETE_DECK)),
		"Main Delete: 덱 학습 기록도 제거"
	)
	check(
		_view(app, "LibraryStatusLabel").text == "'__gd_main_delete' 삭제 완료",
		"Main Delete: 목록 아래 완료 메시지 표시"
	)
	check(
		not app.delete_deck_from_library("__없는덱.md")
		and _view(app, "LibraryStatusLabel").text == MainApp.DELETE_DECK_NOT_FOUND_MESSAGE,
		"Main Delete: 사라진 덱 오류 안내"
	)

	app.queue_free()
	_cleanup()
	DeckStorage.set_decks_dir("")


func _view(app: Node, node_name: String) -> Node:
	return app.find_child(node_name, true, false)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_DECKS_DIR):
		for file_name in DirAccess.get_files_at(TEST_DECKS_DIR):
			DirAccess.remove_absolute("%s/%s" % [TEST_DECKS_DIR, file_name])
		DirAccess.remove_absolute(TEST_DECKS_DIR)

	var progress_path := DeckStorage.progress_path(TEST_DECK)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var delete_progress_path := DeckStorage.progress_path(DELETE_DECK)
	if FileAccess.file_exists(delete_progress_path):
		DirAccess.remove_absolute(delete_progress_path)

	if FileAccess.file_exists(BROKEN_IMPORT_SOURCE):
		DirAccess.remove_absolute(BROKEN_IMPORT_SOURCE)
	if FileAccess.file_exists(EXPORTED_PATH):
		DirAccess.remove_absolute(EXPORTED_PATH)
