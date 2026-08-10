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
	(_view(app, "CardFrame") as StudyGestureSurface).animations_enabled = false
	app.show_library()

	check(_view(app, "LibraryContainer").visible, "MVP: 덱 목록 화면 표시")
	check(not _view(app, "StudyReadyView").visible, "Main Ready: 덱 목록에서 준비 화면 숨김")
	check(not _view(app, "StudyContainer").visible, "MVP: 덱 목록에서 학습 화면 숨김")
	check(
		not app.has_node("Margin/Page/Title")
		and _view(app, "LibraryHint") == null
		and _view(app, "ReadyTitleLabel") == null
		and _view(app, "CoverCaption") == null
		and _view(app, "SetupCaption") == null
		and _view(app, "CardListTitle") == null,
		"Main UI: 기능 없는 장식 문구 제거"
	)
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
		_view(app, "DeckContextMenuPanel").custom_minimum_size == Vector2(200, 230)
		and _view(app, "RenameDeckButton").custom_minimum_size.y == 48.0
		and _view(app, "DuplicateDeckButton").custom_minimum_size.y == 48.0
		and _view(app, "ExportDeckButton").custom_minimum_size.y == 48.0
		and _view(app, "DeleteDeckButton").custom_minimum_size.y == 48.0,
		"Main Deck Actions: 네 가지 작업을 담은 200px context list 표시"
	)
	_view(app, "RenameDeckButton").pressed.emit()
	var rename_overlay := _view(app, "RenameDeckOverlay") as Control
	check(
		not deck_context_menu.visible and rename_overlay.visible,
		"Main Rename: context list에서 이름 변경창으로 전환"
	)
	check(
		_view(app, "RenameDeckInput").text == "__gd_main",
		"Main Rename: 현재 덱 이름을 입력창에 표시"
	)
	_view(app, "RenameDeckInput").text = ""
	_view(app, "ConfirmRenameButton").pressed.emit()
	check(
		_view(app, "RenameErrorLabel").visible
		and _view(app, "RenameErrorLabel").text == MainApp.RENAME_EMPTY_MESSAGE,
		"Main Rename: 빈 이름 오류를 입력창 안에 표시"
	)
	_view(app, "CancelRenameButton").pressed.emit()
	check(not rename_overlay.visible, "Main Rename: 취소하면 이름 변경창 닫기")
	_view(deck_buttons[0], "DeckMenuButton").pressed.emit()
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
	var scope_option := _view(app, "StudyScopeOption") as OptionButton
	var dropdown_style := scope_option.get_theme_stylebox("normal") as StyleBoxFlat
	var dropdown_popup := scope_option.get_popup()
	var popup_style := dropdown_popup.get_theme_stylebox("panel") as StyleBoxFlat
	check(
		dropdown_style != null
		and dropdown_style.bg_color == Color.WHITE
		and dropdown_style.border_color == Color.BLACK
		and scope_option.get_theme_color("font_color") == Color.BLACK,
		"Main Ready: 새 학습 dropdown을 흰 배경·검은 글씨·검은 테두리로 표시"
	)
	check(
		popup_style != null
		and popup_style.bg_color == Color.WHITE
		and popup_style.border_color == Color.BLACK
		and dropdown_popup.get_theme_color("font_color") == Color.BLACK
		and dropdown_popup.get_theme_font_size("font_size") == 20,
		"Main Ready: dropdown 목록도 밝은 고대비 메뉴로 표시"
	)
	check(
		_view(app, "DeckCover") != null
		and _view(app, "BackCardFar") != null
		and _view(app, "BackCardNear") != null,
		"Main Ready: 카드 뭉치 위에 덱 커버를 씌운 프레임 표시"
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
		and _view(app, "ReadyStatusLabel").text == "오답 카드가 없습니다.",
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
		and _view(app, "ContinueStudyButton").text == "이어서 학습 · 2장 남음",
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
		_view(app, "ContinueStudyButton").text == "이어서 학습 · 1장 남음",
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
	check(not _view(app, "AnswerScroll").visible, "Main Study: 첫 화면에서 답 영역 숨김")
	check(_view(app, "Actions").visible, "Main Study: 답 공개 전에도 자기평가 버튼 표시")
	check(_view(app, "RemainingLabel").text == "2장 남음", "MVP: 남은 카드 수 표시")
	check(
		_view(app, "CardStatusLabel").text == "NEW"
		and _view(app, "WrongTally").wrong_count == 0
		and _view(app, "WrongCountLabel") == null,
		"Main Study: 카드의 학습 상태와 오답 횟수 표시"
	)
	check(
		_view(app, "WrongTally").get_index() < _view(app, "Spacer").get_index()
		and _view(app, "StatusBadge").get_index() > _view(app, "Spacer").get_index(),
		"Main Study: 오답은 좌상단, 카드 속성은 우상단 배치"
	)
	check(
		_view(app, "WrongTally").get_parent() is HBoxContainer
		and _view(app, "WrongTally").get_child_count() == 0,
		"Main Study: 프레임과 문구 없이 직접 그리는 tally 사용"
	)
	check(_view(app, "QuestionCaption") == null, "Main Study: QUESTION 장식 문구 제거")
	check(
		_view(app, "StudyProgressBar").value == 0
		and _view(app, "StudyProgressBar").max_value == 2,
		"Main Study: 첫 카드에서 학습 진행 bar 표시"
	)
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
		StudyGestureSurface.PREVIEW_FOLLOW_RATIO > 0.5
		and StudyGestureSurface.TAP_MAX_DISTANCE > 0.0
		and StudyGestureSurface.EXIT_DURATION > 0.0
		and StudyGestureSurface.ENTER_DURATION > 0.0
		and StudyGestureSurface.FLIP_HALF_DURATION > 0.0,
		"Main Study: drag 퇴장·다음 카드 안착·앞뒤 flip 연출 제공"
	)
	check(
		_view(app, "AgainHint").text == "←  AGAIN"
		and _view(app, "GoodHint").text == "GOOD  →"
		and _view(app, "SkipHint").text == "↑  SKIP"
		and _view(app, "PreviousHint").text == "↓  PREV"
		and _view(app, "GestureHints").get_parent().name == "CardStage"
		and _view(app, "GestureHints").show_behind_parent
		and StudyGestureSurface.HINT_MIN_SCALE < 1.0
		and StudyGestureSurface.HINT_MIN_ALPHA < 1.0
		and StudyGestureSurface.HINT_PULL_PADDING > 0.0
		and StudyGestureSurface.HINT_DRAG_DISTANCE_MULTIPLIER == 3.6
		and StudyGestureSurface.HINT_COMPLETE_DURATION == 0.4
		and _view(app, "AgainHint").get_theme_font_size("font_size") == 28
		and not _view(app, "CardFrame").is_ancestor_of(_view(app, "GestureHints"))
		and not _view(app, "AgainHint").visible
		and not _view(app, "GoodHint").visible
		and not _view(app, "SkipHint").visible
		and not _view(app, "PreviousHint").visible,
		"Main Study: 카드 뒤 빈 공간에만 drag 방향 도움말 준비"
	)
	check(
		_view(app, "LibraryHeading").get_theme_color("font_color") == Color.BLACK,
		"MVP 스타일: 모든 Label 글자는 검은색"
	)
	var card_style := (
		app.get_node("Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame").get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	check(
		card_style != null
		and card_style.bg_color == Color.WHITE
		and card_style.border_color == Color.BLACK,
		"MVP 스타일: 카드는 흰 바탕과 검은 테두리"
	)
	check(
		_view(app, "CardStack") == null
		and _view(app, "RevealButton") == null
		and _view(app, "Actions").get_parent().name == "StudyContainer"
		and not _view(app, "CardFrame").is_ancestor_of(_view(app, "Actions")),
		"Main Study: 답 보기 버튼 없이 판정 버튼만 카드 밖에 고정 배치"
	)
	var button_style := (
		_view(app, "AgainButton").get_theme_stylebox("normal") as StyleBoxFlat
	)
	check(
		button_style != null
		and button_style.bg_color == Color.WHITE
		and button_style.border_color == Color.BLACK,
		"MVP 스타일: 버튼은 흰 바탕과 검은 테두리"
	)

	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(_view(app, "AnswerScroll").visible, "Main Study: 카드 tap으로 답 영역 공개")
	check(
		_view(app, "AnswerCaption") == null and _view(app, "Separator") == null,
		"Main Study: ANSWER 문구와 질문·답 구분선 제거"
	)
	check(_view(app, "AnswerLabel").text == "1", "MVP: 현재 카드의 답 표시")
	check(
		_view(app, "AnswerLabel").horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT
		and _view(app, "AnswerLabel").vertical_alignment == VERTICAL_ALIGNMENT_TOP,
		"Main Study: 답 내용은 좌측 상단 정렬"
	)
	check(
		_view(app, "QuestionLabel").get_theme_color("font_color")
		== Color(0.56, 0.56, 0.56, 1),
		"Main Study: 답과 함께 표시되는 질문은 옅은 색으로 전환"
	)
	check(
		_view(app, "QuestionScroll").custom_minimum_size.y == 150.0
		and _view(app, "QuestionScroll").size_flags_vertical == Control.SIZE_FILL,
		"Main Study: 답 공개 후 질문 영역을 compact header 높이로 축소"
	)
	check(
		_view(app, "Actions").visible
		and _view(app, "AgainButton").text == "다시 보기"
		and _view(app, "GoodButton").text == "알겠음",
		"Main Study: 답 공개 후 자기평가 버튼 유지"
	)
	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(
		not _view(app, "AnswerScroll").visible
		and _view(app, "QuestionScroll").size_flags_vertical
		== Control.SIZE_EXPAND_FILL
		and _view(app, "QuestionLabel").get_theme_color("font_color") == Color.BLACK,
		"Main Study: 카드를 다시 tap하면 질문만 보는 앞면으로 복귀"
	)

	_view(app, "AgainButton").pressed.emit()
	check(_view(app, "QuestionLabel").text == "B", "MVP: Again 후 다음 질문")
	check(
		_view(app, "QuestionLabel").get_theme_color("font_color") == Color.BLACK,
		"Main Study: 다음 카드 질문은 검은색으로 복구"
	)
	check(_view(app, "RemainingLabel").text == "1장 남음", "MVP: Again 후 남은 수 감소")
	check(_view(app, "StudyProgressBar").value == 1, "Main Study: 다음 카드에서 진행 bar 갱신")
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
		and not _view(app, "DoneContainer").visible
		and DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.NEW,
		"Main Study: 빠른 연속 판정은 다음 카드에 적용하지 않음"
	)
	app._reset_study_input_lock()
	_view(app, "GoodButton").pressed.emit()
	check(_view(app, "DoneContainer").visible, "MVP: 마지막 카드 후 완료 표시")
	check(not _view(app, "StudyContainer").visible, "MVP: 완료 시 학습 화면 숨김")
	check(
		DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.MASTERED,
		"Main Ready: Good이 완료 상태를 저장"
	)
	_view(app, "RestartButton").pressed.emit()
	check(_view(app, "StudyContainer").visible, "MVP: 다시 시작으로 학습 화면 복귀")
	check(_view(app, "QuestionLabel").text == "A", "MVP: 다시 시작하면 첫 카드")
	check(
		_view(app, "CardStatusLabel").text == "LEARNING"
		and _view(app, "WrongTally").wrong_count == 1
		and _view(app, "WrongTally").tooltip_text == "오답 1회",
		"Main Study: 다시 표시한 카드에 저장된 속성 반영"
	)
	_view(app, "BackToReadyButton").pressed.emit()
	check(
		_view(app, "ReadyNewCountLabel").text == "0"
		and _view(app, "ReadyLearningCountLabel").text == "1"
		and _view(app, "ReadyMasteredCountLabel").text == "1",
		"Main Ready: 학습 결과를 진행상황 요약에 반영"
	)

	app.start_sample_deck()
	check(_view(app, "StudyContainer").visible, "MVP: 샘플 덱으로 학습 시작")
	check(
		_view(app, "QuestionLabel").text == "MyFlashCard는 어떤 앱인가요?",
		"MVP: 앱 소개 샘플 덱의 첫 질문 표시"
	)

	DeckStorage.write_deck(RENAME_DECK, TEST_TEXT)
	var rename_progress := Progress.new()
	rename_progress.add_wrong("A")
	DeckStorage.save_progress(RENAME_DECK, rename_progress)
	app.show_library()
	var rename_tile := _find_deck_tile(app, "__gd_main_rename")
	check(rename_tile != null, "Main Rename: 이름을 바꿀 덱 타일 표시")
	if rename_tile != null:
		_view(rename_tile, "DeckMenuButton").pressed.emit()
		_view(app, "RenameDeckButton").pressed.emit()
		_view(app, "RenameDeckInput").text = "__gd_main"
		_view(app, "ConfirmRenameButton").pressed.emit()
		check(
			_view(app, "RenameErrorLabel").text == MainApp.RENAME_DUPLICATE_MESSAGE
			and DeckStorage.deck_exists(RENAME_DECK),
			"Main Rename: 중복 이름을 거부하고 원본 유지"
		)
		_view(app, "RenameDeckInput").text = "__gd_main_renamed"
		_view(app, "ConfirmRenameButton").pressed.emit()
	check(not DeckStorage.deck_exists(RENAME_DECK), "Main Rename: 이전 덱 파일 제거")
	check(DeckStorage.deck_exists(RENAMED_DECK), "Main Rename: 새 덱 파일 생성")
	check(
		DeckStorage.load_progress(RENAMED_DECK).get_wrong_count("A") == 1,
		"Main Rename: 학습 기록도 새 이름으로 이동"
	)
	check(
		_view(app, "LibraryStatusLabel").text
		== "'__gd_main_rename' → '__gd_main_renamed' 이름 변경 완료",
		"Main Rename: 목록 아래 완료 메시지 표시"
	)

	app.show_library()
	var duplicate_tile := _find_deck_tile(app, "__gd_main")
	check(duplicate_tile != null, "Main Duplicate: 복제할 덱 타일 표시")
	if duplicate_tile != null:
		_view(duplicate_tile, "DeckMenuButton").pressed.emit()
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
		_view(app, "LibraryStatusLabel").text == "'__gd_main' → '__gd_main (2)' 복제 완료",
		"Main Duplicate: 목록 아래 완료 메시지 표시"
	)
	check(
		not app.duplicate_deck_from_library("__없는덱.md")
		and _view(app, "LibraryStatusLabel").text
		== MainApp.DUPLICATE_DECK_NOT_FOUND_MESSAGE,
		"Main Duplicate: 사라진 덱 오류 안내"
	)

	DeckStorage.write_deck(DELETE_DECK, TEST_TEXT)
	var delete_progress := Progress.new()
	delete_progress.add_wrong("A")
	DeckStorage.save_progress(DELETE_DECK, delete_progress)
	app.show_library()
	var delete_tile := _find_deck_tile(app, "__gd_main_delete")
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
		and _view(app, "CardRows").get_child_count() == 2,
		"Main Card Edit: Study Ready에서 카드 목록 진입"
	)
	(_view(app, "CardRows").get_child(0) as Button).pressed.emit()
	check(
		_view(app, "CardEditorView").visible
		and _view(app, "CardQuestionInput").text == "Old"
		and _view(app, "CardAnswerInput").text == "Answer",
		"Main Card Edit: 선택한 질문과 답을 편집기에 표시"
	)
	_view(app, "CardQuestionInput").text = "New"
	_view(app, "CardAnswerInput").text = "# 잘못된 답 제목"
	_view(app, "SaveCardButton").pressed.emit()
	check(
		_view(app, "CardEditorErrorLabel").text
		== MainApp.CARD_ANSWER_HEADING_MESSAGE
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
		DeckStorage.load_progress(EDIT_DECK).get_wrong_count("New") == 3
		and DeckStorage.load_progress(EDIT_DECK).get_status("New")
		== CardStatus.Value.LEARNING,
		"Main Card Edit: 질문 변경 시 학습 기록 이전"
	)
	check(
		DeckStorage.load_study_resume(EDIT_DECK) == null,
		"Main Card Edit: 카드 변경 시 진행 중 세션 폐기"
	)
	_view(app, "AddCardButton").pressed.emit()
	_view(app, "CardQuestionInput").text = "Added"
	_view(app, "CardAnswerInput").text = "Added answer"
	_view(app, "SaveCardButton").pressed.emit()
	check(
		DeckParser.parse(DeckStorage.read_deck(EDIT_DECK)).size() == 3,
		"Main Card Edit: 새 카드 추가"
	)
	(_view(app, "CardRows").get_child(0) as Button).pressed.emit()
	_view(app, "CardQuestionInput").text = "Unsaved"
	_view(app, "CancelCardEditButton").pressed.emit()
	check(
		_view(app, "DiscardCardChangesOverlay").visible,
		"Main Card Edit: 저장하지 않은 변경사항 취소 확인"
	)
	_view(app, "KeepEditingButton").pressed.emit()
	check(_view(app, "CardEditorView").visible, "Main Card Edit: 계속 편집 선택")
	_view(app, "CancelCardEditButton").pressed.emit()
	_view(app, "DiscardChangesButton").pressed.emit()
	check(
		_view(app, "CardListView").visible
		and DeckParser.parse(DeckStorage.read_deck(EDIT_DECK))[0].question == "New",
		"Main Card Edit: 변경사항 버리고 카드 목록 복귀"
	)
	(_view(app, "CardRows").get_child(2) as Button).pressed.emit()
	_view(app, "DeleteCardButton").pressed.emit()
	check(_view(app, "CardDeleteConfirmationOverlay").visible, "Main Card Edit: 카드 삭제 확인")
	_view(app, "ConfirmCardDeleteButton").pressed.emit()
	check(
		DeckParser.parse(DeckStorage.read_deck(EDIT_DECK)).size() == 2
		and _view(app, "CardRows").get_child_count() == 2,
		"Main Card Edit: 카드 삭제 후 목록과 Markdown 갱신"
	)
	_view(app, "BackFromCardListButton").pressed.emit()
	check(
		_view(app, "StudyReadyView").visible
		and _view(app, "ReadyTotalCountLabel").text == "2",
		"Main Card Edit: 카드 관리에서 갱신된 Study Ready로 복귀"
	)

	app.queue_free()
	_cleanup()
	DeckStorage.set_decks_dir("")


func _view(app: Node, node_name: String) -> Node:
	return app.find_child(node_name, true, false)


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

	var progress_path := DeckStorage.progress_path(TEST_DECK)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var delete_progress_path := DeckStorage.progress_path(DELETE_DECK)
	if FileAccess.file_exists(delete_progress_path):
		DirAccess.remove_absolute(delete_progress_path)
	for rename_file in [RENAME_DECK, RENAMED_DECK]:
		var rename_progress_path := DeckStorage.progress_path(rename_file)
		if FileAccess.file_exists(rename_progress_path):
			DirAccess.remove_absolute(rename_progress_path)
	var duplicated_progress_path := DeckStorage.progress_path(DUPLICATED_DECK)
	if FileAccess.file_exists(duplicated_progress_path):
		DirAccess.remove_absolute(duplicated_progress_path)
	for deck_file in [
		TEST_DECK,
		DELETE_DECK,
		RENAME_DECK,
		RENAMED_DECK,
		DUPLICATED_DECK,
		EDIT_DECK,
	]:
		var resume_path := DeckStorage.study_resume_path(deck_file)
		if FileAccess.file_exists(resume_path):
			DirAccess.remove_absolute(resume_path)

	if FileAccess.file_exists(BROKEN_IMPORT_SOURCE):
		DirAccess.remove_absolute(BROKEN_IMPORT_SOURCE)
	if FileAccess.file_exists(EXPORTED_PATH):
		DirAccess.remove_absolute(EXPORTED_PATH)
