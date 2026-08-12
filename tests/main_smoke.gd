extends TestCase

const MAIN_SCENE := preload("res://src/main/main.tscn")
const CARD_DETAIL_SURFACE := preload("res://src/main/card_detail_surface.gd")
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
	var tall_card_rect := StudyGestureSurface.fitted_card_rect(Vector2(600, 1200))
	var wide_card_rect := StudyGestureSurface.fitted_card_rect(Vector2(900, 900))
	check(
		tall_card_rect == Rect2(0, 150, 600, 900)
		and wide_card_rect == Rect2(150, 0, 600, 900),
		"Main Study: 화면 비율과 무관하게 카드를 2:3으로 맞춰 중앙 배치"
	)

	var app := MAIN_SCENE.instantiate()
	app.auto_start = false
	add_child(app)
	(_view(app, "CardFrame") as StudyGestureSurface).animations_enabled = false
	_view(app, "CardDetailFrame").set("animations_enabled", false)
	app.show_library()

	check(_view(app, "LibraryContainer").visible, "MVP: 덱 목록 화면 표시")
	check(not _view(app, "StudyReadyView").visible, "Main Ready: 덱 목록에서 준비 화면 숨김")
	check(
		not _view(app, "StudyContainer").visible
		and not _view(app, "StudyProgressBar").visible,
		"MVP: 덱 목록에서 학습 화면과 XP bar 숨김"
	)
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
		_view(app, "LibraryContainer").get_theme_constant("separation") == 30
		and _view(app, "DeckList").get_theme_constant("h_separation") == 28
		and _view(app, "DeckList").get_theme_constant("v_separation") == 32,
		"Main: 덱 헤더와 카드 목록에 넉넉한 여백 표시"
	)
	check(
		_view(deck_buttons[-1], "AddDeckLabel").text == "덱 추가"
		and _view(deck_buttons[-1], "AddDeckHintLabel").text
		== "만들기 또는 가져오기",
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
		_view(deck_buttons[0], "ReorderHandle") != null
		and _view(deck_buttons[-1], "ReorderHandle") == null,
		"Main Deck Order: 실제 덱에만 전용 reorder handle 표시"
	)
	check(
		MainApp.ordered_deck_files(
			["A.md", "B.md", "C.md"],
			["b.MD", "missing.md", "A.md"]
		) == ["B.md", "A.md", "C.md"],
		"Main Deck Order: 저장 순서를 우선하고 새 덱은 뒤에 추가"
	)
	check(
		_view(deck_buttons[0], "BackCardFar") != null
		and _view(deck_buttons[0], "BackCardNear") != null,
		"Main: 덱 타일을 세 장의 카드 뭉치로 표시"
	)
	check(
		_view(deck_buttons[-1], "BackCardFar") == null
		and _view(deck_buttons[-1], "BackCardNear") == null
		and _view(deck_buttons[-1], "FrontCard") != null
		and _view(deck_buttons[-1], "AddDeckButton").text == "+"
		and _view(deck_buttons[-1], "AddDeckButton").custom_minimum_size
		== Vector2(64, 32),
		"Main Create: 추가 타일을 단일 카드와 우상단 + 버튼으로 표시"
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
	var add_deck_button := _view(deck_buttons[-1], "AddDeckButton") as Button
	add_deck_button.pressed.emit()
	var add_deck_menu := _view(app, "AddDeckMenu") as Control
	var add_deck_menu_panel := _view(app, "AddDeckMenuPanel") as PanelContainer
	check(
		add_deck_menu.visible
		and _view(app, "CreateNewDeckButton").text == "새 덱 만들기"
		and _view(app, "ImportMarkdownButton").text == "Markdown 가져오기",
		"Main Create: 추가 타일에서 새 덱과 Markdown 가져오기 선택"
	)
	check(
		add_deck_menu.scene_file_path.ends_with("add_deck_menu.tscn")
		and add_deck_menu_panel.custom_minimum_size == Vector2(320, 172)
		and _view(app, "CreateNewDeckButton").custom_minimum_size.y == 72.0
		and _view(app, "CreateNewDeckButton").get_theme_font_size("font_size") == 30,
		"Main Create: 추가 선택 context list를 큰 글자와 터치 크기로 표시"
	)
	var add_anchor_rect := MainApp._control_rect_in_overlay(
		add_deck_menu,
		add_deck_button
	)
	var add_menu_size := add_deck_menu_panel.get_combined_minimum_size()
	var expected_add_menu_x := clampf(
		add_anchor_rect.end.x - add_menu_size.x,
		12.0,
		add_deck_menu.size.x - add_menu_size.x - 12.0
	)
	check(
		is_equal_approx(add_deck_menu_panel.position.x, expected_add_menu_x)
		and is_equal_approx(
			add_deck_menu_panel.position.y,
			add_anchor_rect.end.y + 4.0
		)
		and not add_deck_menu_panel.get_rect().intersects(add_anchor_rect),
		"Main Create: 추가 선택 context list를 + 버튼 아래에 간격 두고 표시"
	)
	check(app.handle_back_request(), "Main Create: 추가 선택창에서 뒤로가기 요청 소비")
	check(not add_deck_menu.visible, "Main Create: 뒤로가기로 추가 선택창 닫기")
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
		"Main Deck Actions: 둥근 흰 바탕과 그림자 context list 표시"
	)
	check(
		_view(app, "ExportDeckButton").get_theme_color("font_color") == Color.BLACK
		and _view(app, "DeleteDeckButton").get_theme_color("font_color") == Color.BLACK
		and _view(app, "DeleteDeckButton").get_theme_color("font_hover_color")
		== Color.BLACK,
		"Main Deck Actions: context list hover에서도 검은 글자 유지"
	)
	var deck_menu_button := _view(deck_buttons[0], "DeckMenuButton") as Button
	var deck_menu_anchor_rect := MainApp._control_rect_in_overlay(
		deck_context_menu,
		deck_menu_button
	)
	check(
		is_equal_approx(
			_view(app, "DeckContextMenuPanel").position.y,
			deck_menu_anchor_rect.end.y + 4.0
		)
		and not _view(app, "DeckContextMenuPanel").get_rect().intersects(
			deck_menu_anchor_rect
		),
		"Main Deck Actions: context list를 ⋮ 버튼 아래에 간격 두고 배치"
	)
	var deck_menu_size := (
		_view(app, "DeckContextMenuPanel") as PanelContainer
	).get_combined_minimum_size()
	var expected_deck_menu_x := clampf(
		deck_menu_anchor_rect.end.x - deck_menu_size.x,
		12.0,
		deck_context_menu.size.x - deck_menu_size.x - 12.0
	)
	check(
		is_equal_approx(
			_view(app, "DeckContextMenuPanel").position.x,
			expected_deck_menu_x
		),
		"Main Deck Actions: context list 오른쪽 끝을 ⋮ 버튼에 정렬"
	)
	check(
		_view(app, "DeckContextMenuPanel").size
		== _view(app, "DeckContextMenuPanel").get_combined_minimum_size(),
		"Main Deck Actions: context list 실제 layout 크기로 위치 계산"
	)
	check(
		_view(app, "DeckContextMenuPanel").custom_minimum_size == Vector2(320, 324)
		and _view(app, "RenameDeckButton").custom_minimum_size.y == 72.0
		and _view(app, "DuplicateDeckButton").custom_minimum_size.y == 72.0
		and _view(app, "ExportDeckButton").custom_minimum_size.y == 72.0
		and _view(app, "DeleteDeckButton").custom_minimum_size.y == 72.0
		and _view(app, "DeleteDeckButton").get_theme_font_size("font_size") == 30,
		"Main Deck Actions: 네 가지 큰 작업을 담은 320px context list 표시"
	)
	var dialog_panels: Array[PanelContainer] = [
		_view(app, "CreateDeckPanel") as PanelContainer,
		_view(app, "RenameDeckPanel") as PanelContainer,
		_view(app, "DeleteConfirmationPanel") as PanelContainer,
		_view(app, "ExitConfirmationPanel") as PanelContainer,
		app.get_node("CardDeleteConfirmationOverlay/Panel") as PanelContainer,
		app.get_node("DiscardCardChangesOverlay/Panel") as PanelContainer,
	]
	var dialogs_unified := true
	for dialog_panel in dialog_panels:
		var dialog_style := dialog_panel.get_theme_stylebox("panel") as StyleBoxFlat
		dialogs_unified = (
			dialogs_unified
			and dialog_style != null
			and dialog_style.bg_color == Color.WHITE
			and dialog_style.border_width_left == 2
			and dialog_style.border_color == Color.BLACK
			and dialog_style.corner_radius_top_left == 18
			and dialog_style.shadow_size == 8
		)
	var modal_shades: Array[ColorRect] = [
		_view(app, "CreateDeckOverlay") as ColorRect,
		_view(app, "RenameDeckOverlay") as ColorRect,
		_view(app, "DeleteConfirmationOverlay") as ColorRect,
		_view(app, "ExitConfirmationOverlay") as ColorRect,
		app.get_node("CardDeleteConfirmationOverlay/Shade") as ColorRect,
		app.get_node("DiscardCardChangesOverlay/Shade") as ColorRect,
	]
	var shades_unified := true
	for modal_shade in modal_shades:
		shades_unified = shades_unified and modal_shade.color == Color(0, 0, 0, 0.18)
	check(
		dialogs_unified and shades_unified,
		"Main UI: 모든 다이얼로그의 표면과 배경 dim 규격 통일"
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
	var order_option := _view(app, "StudyOrderOption") as OptionButton
	var dropdown_style := scope_option.get_theme_stylebox("normal") as StyleBoxFlat
	var dropdown_hover_style := scope_option.get_theme_stylebox("hover") as StyleBoxFlat
	var order_dropdown_style := order_option.get_theme_stylebox("normal") as StyleBoxFlat
	var dropdown_popup := scope_option.get_popup()
	var popup_style := dropdown_popup.get_theme_stylebox("panel") as StyleBoxFlat
	check(
		dropdown_style != null
		and order_dropdown_style != null
		and dropdown_style.bg_color == Color.WHITE
		and dropdown_style.border_color == Color.BLACK
		and dropdown_style.border_width_left == 3
		and dropdown_style.corner_radius_top_left == 8
		and dropdown_style.get_content_margin(SIDE_LEFT) == 22.0
		and order_dropdown_style.get_content_margin(SIDE_LEFT) == 22.0
		and scope_option.get_theme_color("font_color") == Color.BLACK
		and dropdown_hover_style.bg_color == Color(0.94, 0.94, 0.94, 1)
		and scope_option.get_theme_color("font_hover_color") == Color.BLACK,
		"Main Ready: 새 학습 dropdown을 둥근 테두리와 옅은 hover로 표시"
	)
	check(
		popup_style != null
		and popup_style.bg_color == Color.WHITE
		and popup_style.border_color == Color.BLACK
		and dropdown_popup.get_theme_color("font_color") == Color.BLACK
		and dropdown_popup.get_theme_font_size("font_size") == 28,
		"Main Ready: dropdown 목록도 밝은 고대비 메뉴로 표시"
	)
	check(
		_view(app, "DeckCover") != null
		and _view(app, "BackCardFar") != null
		and _view(app, "BackCardNear") != null,
		"Main Ready: 카드 뭉치 위에 덱 커버를 씌운 프레임 표시"
	)
	var ready_deck_stage := _view(app, "DeckStage") as AspectRatioContainer
	var ready_deck_stack := _view(app, "DeckStack") as Control
	var ready_deck_cover_style := (
		(_view(app, "DeckCover") as PanelContainer).get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	check(
		is_equal_approx(ready_deck_stage.ratio, 2.0 / 3.0)
		and ready_deck_stage.stretch_mode == AspectRatioContainer.STRETCH_FIT
		and ready_deck_stack.get_parent() == ready_deck_stage,
		"Main Ready: 덱 상세와 학습 설정 프레임을 화면 안의 2:3 카드로 유지"
	)
	check(
		ready_deck_cover_style != null
		and ready_deck_cover_style.shadow_size == 0,
		"Main Ready: 덱 커버 프레임의 그림자 제거"
	)
	var ready_action_buttons: Array[Button] = [
		_view(app, "ContinueStudyButton") as Button,
		_view(app, "OpenStudySetupButton") as Button,
		_view(app, "ManageCardsButton") as Button,
		_view(app, "StartStudyButton") as Button,
		_view(app, "CancelStudySetupButton") as Button,
	]
	var ready_buttons_are_uniform := true
	for button in ready_action_buttons:
		if (
			button.get_theme_font_size("font_size") != 28
			or button.custom_minimum_size.y != 72.0
		):
			ready_buttons_are_uniform = false
			break
	check(
		ready_buttons_are_uniform,
		"Main Ready: 덱 상세와 학습 설정 버튼의 높이·font 크기 통일"
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
		_view(app, "ConfirmExitButton").custom_minimum_size.y == 88.0
		and _view(app, "CancelExitButton").custom_minimum_size.y == 88.0,
		"MVP Android Back: 종료 확인 버튼을 모바일 크기로 표시"
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
	var study_card_properties := _view(app, "CardProperties") as HBoxContainer
	var study_card_content := study_card_properties.get_parent()
	check(
		_view(app, "StudyCardMenuButton") == null
		and _view(app, "CardChrome") == null
		and _view(study_card_content, "MenuButtonSpacer") == null,
		"Main Study: 학습 흐름을 가리는 카드 설정 버튼과 여백 제거"
	)
	check(_view(app, "QuestionLabel").text == "A", "MVP: 첫 질문 표시")
	check(not _view(app, "AnswerScroll").visible, "Main Study: 첫 화면에서 답 영역 숨김")
	check(_view(app, "Actions").visible, "Main Study: 답 공개 전에도 자기평가 버튼 표시")
	check(_view(app, "RemainingLabel").text == "2장 남음", "MVP: 남은 카드 수 표시")
	check(
		_view(study_card_properties, "WrongCountLabel") == null
		and not study_card_properties.visible,
		"Main Study: 앞면에서는 오답 tally 숨김"
	)
	check(
		_view(study_card_properties, "WrongTally").get_index()
		< _view(study_card_properties, "Spacer").get_index()
		and _view(app, "CardStatusLabel") == null
		and _view(study_card_properties, "StatusBadge").get_index()
		> _view(study_card_properties, "Spacer").get_index()
		and _view(study_card_properties, "StatusBadge").text == "MASTERED",
		"Main Study: 뒷면용 오답 tally와 상태 딱지 배치"
	)
	check(
		_view(app, "WrongTally").get_parent() is HBoxContainer
		and _view(app, "WrongTally").get_child_count() == 0,
		"Main Study: 프레임과 문구 없이 직접 그리는 tally 사용"
	)
	check(
		_view(study_card_content, "QuestionCaption") == null,
		"Main Study: QUESTION 장식 문구 제거"
	)
	var xp_bar := _view(app, "StudyProgressBar") as ProgressBar
	check(
		xp_bar.visible
		and xp_bar.value == 0
		and xp_bar.max_value == 2
		and xp_bar.custom_minimum_size.y == 2.0
		and xp_bar.get_parent() == app
		and xp_bar.scene_file_path.ends_with("study_progress_bar.tscn")
		and is_equal_approx(xp_bar.get_global_rect().position.x, 0.0)
		and is_equal_approx(xp_bar.get_global_rect().end.x, app.get_global_rect().end.x)
		and is_equal_approx(xp_bar.get_global_rect().end.y, app.get_global_rect().end.y),
		"Main Study: 학습 진행 bar를 화면 좌우·아래 edge에 붙인 XP strip으로 표시"
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
		StudyGestureSurface.key_direction(KEY_LEFT) == StudyGestureSurface.AGAIN
		and StudyGestureSurface.key_direction(KEY_RIGHT) == StudyGestureSurface.GOOD
		and StudyGestureSurface.key_direction(KEY_UP) == StudyGestureSurface.SKIP
		and StudyGestureSurface.key_direction(KEY_DOWN) == StudyGestureSurface.PREVIOUS,
		"Main Study: 방향키를 swipe 방향과 같은 네 동작에 mapping"
	)
	check(
		StudyGestureSurface.PREVIEW_FOLLOW_RATIO > 0.5
		and StudyGestureSurface.TAP_MAX_DISTANCE > 0.0
		and StudyGestureSurface.EXIT_DURATION > 0.0
		and StudyGestureSurface.ENTER_DURATION > 0.0
		and StudyGestureSurface.FLIP_LIFT_DURATION
		+ StudyGestureSurface.FLIP_HALF_DURATION
		+ StudyGestureSurface.FLIP_OPEN_DURATION
		+ StudyGestureSurface.FLIP_SETTLE_DURATION < 0.5
		and CARD_DETAIL_SURFACE.FLIP_HALF_DURATION
		+ CARD_DETAIL_SURFACE.FLIP_OPEN_DURATION
		+ CARD_DETAIL_SURFACE.FLIP_SETTLE_DURATION < 0.4,
		"Main Study: drag 퇴장·다음 카드 안착·앞뒤 flip 연출 제공"
	)
	check(
		_view(app, "AgainHint") == null
		and _view(app, "GoodHint") == null
		and _view(app, "SkipHint").text == "↑  SKIP"
		and _view(app, "PreviousHint").text == "↓  PREV"
		and _view(app, "GestureHints").get_parent().name == "CardStage"
		and _view(app, "GestureHints").z_index < _view(app, "CardFrame").z_index
		and StudyGestureSurface.HINT_MIN_SCALE < 1.0
		and StudyGestureSurface.HINT_MIN_ALPHA < 1.0
		and StudyGestureSurface.HINT_PULL_PADDING > 0.0
		and StudyGestureSurface.HINT_DRAG_DISTANCE_MULTIPLIER == 3.6
		and StudyGestureSurface.HINT_COMPLETE_DURATION == 0.4
		and not _view(app, "CardFrame").is_ancestor_of(_view(app, "GestureHints"))
		and not _view(app, "SkipHint").visible
		and not _view(app, "PreviousHint").visible,
		"Main Study: 중복 AGAIN·GOOD 문구 없이 세로 drag 도움말만 준비"
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
		and gesture_surface.haptics_enabled
		and StudyGestureSurface.HAPTIC_DURATION_MS == 15
		and StudyGestureSurface.HAPTIC_AMPLITUDE == 0.25,
		"Main Study: GOOD·AGAIN 판정선을 넘을 때만 짧은 햅틱 요청"
	)
	check(
		FileAccess.get_file_as_string("res://export_presets.cfg").contains(
			"permissions/vibrate=true"
		),
		"Main Android: 햅틱용 VIBRATE 권한 포함"
	)
	gesture_surface._reset_visual()
	gesture_surface._show_horizontal_preview(-gesture_surface.size.x * 0.25)
	var again_partial_style := (
		_view(app, "AgainButton").get_theme_stylebox("normal") as StyleBoxFlat
	)
	var good_inactive_style := (
		_view(app, "GoodButton").get_theme_stylebox("normal") as StyleBoxFlat
	)
	check(
		_view(app, "SwipeFeedback") == null
		and again_partial_style != null
		and again_partial_style.bg_color.r > 0.0
		and again_partial_style.bg_color.r < 1.0
		and _view(app, "AgainButton").get_theme_color("font_color").r > 0.0
		and _view(app, "AgainButton").get_theme_color("font_color").r < 1.0
		and good_inactive_style != null
		and good_inactive_style.bg_color == Color.WHITE,
		"Main Study: swipe 기울기에 따라 AGAIN 버튼이 서서히 어두워짐"
	)
	gesture_surface._show_horizontal_preview(-gesture_surface.size.x)
	check(
		(_view(app, "AgainButton").get_theme_stylebox("normal") as StyleBoxFlat).bg_color
		== Color.BLACK
		and _view(app, "AgainButton").get_theme_color("font_color") == Color.WHITE,
		"Main Study: 왼쪽 최대 기울기에서 AGAIN 버튼 반전 완료"
	)
	gesture_surface._show_horizontal_preview(gesture_surface.size.x)
	check(
		(_view(app, "GoodButton").get_theme_stylebox("normal") as StyleBoxFlat).bg_color
		== Color.BLACK
		and _view(app, "GoodButton").get_theme_color("font_color") == Color.WHITE,
		"Main Study: 오른쪽 최대 기울기에서 GOOD 버튼 반전 완료"
	)
	gesture_surface._reset_visual()
	check(
		_view(app, "LibraryHeading").get_theme_color("font_color") == Color.BLACK
		and _view(app, "LibraryHeading").get_theme_font_size("font_size") == 36,
		"MVP 스타일: 제목을 큰 검은 글자로 표시"
	)
	var card_style := (
		app.get_node("Margin/Page/StudyFlow/StudyContainer/CardStage/CardFrame").get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	check(
		card_style != null
		and card_style.bg_color == Color.WHITE
		and card_style.border_color == Color.BLACK
		and card_style.shadow_size == 7,
		"MVP 스타일: Study 카드는 흰 바탕과 검은 테두리·가벼운 그림자"
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
	var button_hover_style := (
		_view(app, "AgainButton").get_theme_stylebox("hover") as StyleBoxFlat
	)
	check(
		button_style != null
		and button_style.bg_color == Color.WHITE
		and button_style.border_color == Color.BLACK
		and button_style.border_width_left == 3
		and button_style.corner_radius_top_left == 8
		and button_hover_style != null
		and button_hover_style.bg_color == Color(0.94, 0.94, 0.94, 1)
		and _view(app, "AgainButton").get_theme_color("font_hover_color")
		== Color.BLACK,
		"MVP 스타일: 버튼을 둥근 흰 바탕과 옅은 hover로 표시"
	)

	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(
		_view(app, "AnswerScroll").visible
		and _view(app, "CardProperties").visible
		and _view(app, "StatusBadge").text == "MASTERED",
		"Main Study: 카드 tap으로 답·tally·상태 딱지를 함께 공개"
	)
	check(
		gesture_surface._can_start_drag(
			gesture_surface.get_global_rect().get_center()
		),
		"Main Study: 설정 버튼 없이 카드 전체를 drag 영역으로 사용"
	)
	check(
		_view(study_card_content, "AnswerCaption") == null
		and _view(study_card_content, "Separator") == null,
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
		and _view(app, "QuestionScroll").size_flags_vertical == Control.SIZE_FILL
		and _view(app, "QuestionScroll").vertical_scroll_mode
		== ScrollContainer.SCROLL_MODE_DISABLED
		and _view(app, "QuestionLabel").max_lines_visible == 2
		and _view(app, "QuestionLabel").text_overrun_behavior
		== TextServer.OVERRUN_TRIM_ELLIPSIS,
		"Main Study: 뒷면 질문을 두 줄 말줄임표로 고정하고 scroll 제거"
	)
	check(
		_view(app, "Actions").visible
		and _view(app, "AgainButton").text == "AGAIN"
		and _view(app, "GoodButton").text == "GOOD",
		"Main Study: 답 공개 후 자기평가 버튼 유지"
	)
	(_view(app, "CardFrame") as StudyGestureSurface).tapped.emit()
	check(
		not _view(app, "AnswerScroll").visible
		and not _view(app, "CardProperties").visible
		and _view(app, "QuestionScroll").size_flags_vertical
		== Control.SIZE_EXPAND_FILL
		and _view(app, "QuestionScroll").vertical_scroll_mode
		== ScrollContainer.SCROLL_MODE_AUTO
		and _view(app, "QuestionLabel").max_lines_visible == -1
		and _view(app, "QuestionLabel").text_overrun_behavior
		== TextServer.OVERRUN_NO_TRIMMING
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
		and not _view(app, "StudyResultView").visible
		and DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.NEW,
		"Main Study: 빠른 연속 판정은 다음 카드에 적용하지 않음"
	)
	app._reset_study_input_lock()
	_view(app, "GoodButton").pressed.emit()
	check(
		_view(app, "StudyResultView").visible
		and not _view(app, "StudyContainer").visible
		and not _view(app, "StudyProgressBar").visible,
		"Main Result: 마지막 카드 후 학습 화면 대신 결과 화면 표시"
	)
	check(
		DeckStorage.load_progress(TEST_DECK).get_status("B")
		== CardStatus.Value.MASTERED,
		"Main Ready: Good이 완료 상태를 저장"
	)
	var first_result_rows := _view(app, "ResultRows") as VBoxContainer
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
	check(
		_view(app, "StudyResultView").scene_file_path.ends_with(
			"study_result_view.tscn"
		)
		and first_result_rows.get_child(0).scene_file_path.ends_with(
			"study_result_row.tscn"
		),
		"Main Result: 결과 화면과 행을 개별 편집 가능한 scene으로 분리"
	)
	check(
		_view(app, "StudyResultView").get_theme_constant("separation") == 26
		and first_result_rows.get_theme_constant("separation") == 18
		and first_result_rows.get_child(0).custom_minimum_size.y == 132.0
		and _view(first_result_rows.get_child(0), "Margin").get_theme_constant(
			"margin_top"
		) == 18,
		"Main Result: 결과 목록의 행간과 카드 안쪽 여백 확보"
	)
	_view(first_result_rows.get_child(0), "OpenResultCardButton").pressed.emit()
	check(
		_view(app, "CardDetailView").visible
		and not _view(app, "StudyResultView").is_visible_in_tree()
		and _view(app, "BackFromCardDetailButton").text == "← 학습 결과"
		and _view(app, "DetailQuestionLabel").text == "A"
		and _view(app, "CardDetailMenuButton").visible
		and _view(app, "CardDetailMenuButton").text == "⋮"
		and _view(app, "CardDetailMenuButton").get_parent().name == "Header",
		"Main Result: 결과 카드를 열고 설정 버튼은 Header 우상단에 표시"
	)
	_view(app, "CardTapButton").pressed.emit()
	check(
		_view(app, "DetailAnswerScroll").visible
		and _view(app, "DetailAnswerLabel").text == "1"
		and (_view(app, "DetailWrongTally") as WrongTallyView).wrong_count == 1
		and _view(app, "DetailStatusLabel") == null,
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
		_view(app, "CardStatusLabel") == null
		and _view(app, "WrongTally").wrong_count == 1
		and _view(app, "WrongTally").tooltip_text == "오답 1회",
		"Main Study: 다시 표시한 카드에는 저장된 tally만 반영"
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
		_view(app, "QuestionLabel").text == "MyFlashCard는 어떤 앱인가요?"
		and _view(app, "RemainingLabel").text == "15장 남음",
		"MVP: 최신 앱 사용법 15장으로 구성된 샘플 덱 시작"
	)
	check(
		_view(app, "StudyCardMenuButton") == null,
		"Main Study: 샘플 덱에서도 카드 설정 버튼 없음"
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
		DeckStorage.load_settings().last_deck_file == RENAMED_DECK,
		"Main Rename: 마지막 학습 덱 설정도 새 이름으로 이동"
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
	var delete_settings := DeckStorage.load_settings()
	delete_settings.last_deck_file = DELETE_DECK
	DeckStorage.save_settings(delete_settings)
	app.show_library()
	var delete_tile := _find_deck_tile(app, "__gd_main_delete")
	check(delete_tile != null, "Main Delete: 삭제할 덱 타일 표시")
	if delete_tile != null:
		_view(delete_tile, "DeckMenuButton").pressed.emit()
		_view(app, "DeleteDeckButton").pressed.emit()
		_view(app, "ConfirmDeleteButton").pressed.emit()
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
	var first_card_row := _view(app, "CardRows").get_child(0) as CardListRow
	check(
		_view(first_card_row, "ListWrongTally") == null
		and _view(first_card_row, "ListStatusLabel") == null
		and _view(first_card_row, "Metadata") == null
		and _view(first_card_row, "QuestionLabel") != null
		and _view(first_card_row, "AnswerLabel") != null
		and first_card_row.custom_minimum_size.y == 132.0,
		"Main Card List: 틸리·상태 딱지를 빼고 질문·답만 강조"
	)
	check(
		_view(app, "ListMargin").get_theme_constant("margin_left") == 16
		and _view(app, "ListMargin").get_theme_constant("margin_top") == 18
		and _view(app, "ListMargin").get_theme_constant("margin_right") == 16
		and _view(first_card_row, "ReorderHandle") != null,
		"Main Card List: 상단·좌우 여백과 독립 reorder handle 확보"
	)
	check(
		first_card_row.get_class() == "PanelContainer"
		and first_card_row.mouse_filter == Control.MOUSE_FILTER_PASS
		and (_view(app, "CardListScroll") as ScrollContainer).vertical_scroll_mode
		== ScrollContainer.SCROLL_MODE_AUTO
		and (_view(app, "CardListScroll") as ScrollContainer).scroll_deadzone == 12,
		"Main Card List: 버튼 대신 pass-through 카드 행과 touch drag deadzone 사용"
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
	check(
		_view(app, "CardDetailView").visible
		and not _view(app, "CardEditorView").visible
		and _view(app, "DetailQuestionLabel").text == "Old"
		and not _view(app, "DetailAnswerScroll").visible
		and not _view(app, "DetailCardProperties").visible
		and _view(app, "CardDetailMenuButton").visible
		and _view(app, "CardDetailMenuButton").text == "⋮"
		and _view(app, "CardDetailMenuButton").get_parent().name == "Header"
		and _view(app, "CardDetailMenuButton").get_index()
		== _view(app, "CardDetailMenuButton").get_parent().get_child_count() - 1
		and _view(app, "CardDetailChrome") == null
		and not _view(app, "CardDetailFrame").is_ancestor_of(
			_view(app, "CardDetailMenuButton")
		)
		and _view(app, "CardTapButton").get_parent() == _view(app, "CardDetailFrame")
		and (_view(app, "CardDetailFrame").get_theme_stylebox("panel") as StyleBoxFlat).shadow_size
		== 0,
		"Main Card Detail: 카드 전체 tap 영역과 Header 우상단 설정 버튼 분리"
	)
	_view(app, "CardTapButton").pressed.emit()
	check(
		_view(app, "DetailAnswerScroll").visible
		and _view(app, "DetailAnswerLabel").text == "Answer"
		and _view(app, "DetailCardProperties").visible
		and (_view(app, "DetailWrongTally") as WrongTallyView).wrong_count == 3
		and _view(app, "DetailStatusLabel") == null
		and _view(app, "DetailStatusBadge").text == "LEARNING"
		and _view(_view(app, "DetailCardProperties"), "MenuButtonSpacer") == null
		and _view(app, "DetailQuestionScroll").vertical_scroll_mode
		== ScrollContainer.SCROLL_MODE_DISABLED
		and _view(app, "DetailQuestionLabel").max_lines_visible == 2
		and _view(app, "DetailQuestionLabel").text_overrun_behavior
		== TextServer.OVERRUN_TRIM_ELLIPSIS,
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
		and _view(app, "FavoriteCardActionButton").text == "즐겨찾기"
		and _view(app, "CardContextMenuPanel").custom_minimum_size
		== Vector2(320, 172)
		and _view(app, "EditCardActionButton").custom_minimum_size.y == 72.0
		and _view(app, "EditCardActionButton").get_theme_font_size("font_size") == 30,
		"Main Card Detail: ⋮ context list를 큰 글자와 터치 크기로 표시"
	)
	_view(app, "FavoriteCardActionButton").pressed.emit()
	check(
		DeckStorage.load_progress(EDIT_DECK).is_favorite("Old"),
		"Main Card Detail: 카드 즐겨찾기 저장"
	)
	_view(app, "CardDetailMenuButton").pressed.emit()
	check(
		_view(app, "FavoriteCardActionButton").text == "즐겨찾기 해제",
		"Main Card Detail: 저장된 즐겨찾기 상태를 메뉴에 반영"
	)
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
	var card_editor_content := _view(app, "CardEditorProperties").get_parent()
	var card_editor_style := (
		_view(app, "CardEditorFrame").get_theme_stylebox("panel") as StyleBoxFlat
	)
	check(
		_view(app, "CardEditorProperties").get_index()
		< _view(app, "QuestionCaption").get_index()
		and card_editor_content == _view(app, "QuestionCaption").get_parent()
		and _view(app, "CardEditorFrame").is_ancestor_of(card_editor_content)
		and card_editor_style != null
		and card_editor_style.bg_color == Color.WHITE
		and card_editor_style.border_color == Color.BLACK,
		"Main Card Edit: 질문·답·학습 정보를 카드 프레임 안에 배치"
	)
	check(
		_view(app, "CardEditorProperties") is VBoxContainer
		and _view(app, "StatusRow") is HBoxContainer
		and _view(app, "ProgressRow") is HBoxContainer
		and _view(app, "CardQuestionInput") is TextEdit
		and _view(app, "CardQuestionInput").custom_minimum_size.y == 140.0
		and _view(app, "CardAnswerInput").custom_minimum_size.y == 260.0,
		"Main Card Edit: 상태·오답 행을 분리하고 질문도 여러 줄 편집"
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
	(_view(app, "CardRows").get_child(0) as CardListRow).activate()
	_view(app, "CardDetailMenuButton").pressed.emit()
	_view(app, "EditCardActionButton").pressed.emit()
	_view(app, "WrongMinusButton").pressed.emit()
	_view(app, "CancelCardEditButton").pressed.emit()
	check(
		_view(app, "DiscardCardChangesOverlay").visible,
		"Main Card Edit: 저장하지 않은 학습 정보 변경사항 취소 확인"
	)
	_view(app, "KeepEditingButton").pressed.emit()
	check(_view(app, "CardEditorView").visible, "Main Card Edit: 계속 편집 선택")
	_view(app, "CancelCardEditButton").pressed.emit()
	_view(app, "DiscardChangesButton").pressed.emit()
	check(
		_view(app, "CardDetailView").visible
		and DeckStorage.load_progress(EDIT_DECK).get_wrong_count("New") == 4,
		"Main Card Edit: 학습 정보 변경사항 버리고 카드 보기 복귀"
	)
	_view(app, "BackFromCardDetailButton").pressed.emit()
	(_view(app, "CardRows").get_child(2) as CardListRow).activate()
	_view(app, "CardDetailMenuButton").pressed.emit()
	_view(app, "EditCardActionButton").pressed.emit()
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
		_view(app, "StudyCardMenuButton") == null
		and _view(study_card_content, "QuestionLabel").text == "Study old",
		"Main Study: 설정 버튼 없이 첫 카드 학습"
	)
	_view(app, "GoodButton").pressed.emit()
	check(
		_view(study_card_content, "QuestionLabel").text == "Study keep"
		and _view(app, "RemainingLabel").text == "1장 남음",
		"Main Study: 설정 UI 없이 다음 카드 계속 학습"
	)
	app._reset_study_input_lock()
	_view(app, "AgainButton").pressed.emit()
	var indexed_result_rows := _view(app, "ResultRows") as VBoxContainer
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
		and _view(_view(app, "ResultRows").get_child(0), "OutcomeLabel").text
		== "SKIP",
		"Main Result: SKIP 판정 표시 및 AGAIN이 없으면 재학습 비활성화"
	)

	app.show_library()
	var create_add_tile := _view(app, "DeckList").get_children()[-1]
	_view(create_add_tile, "AddDeckButton").pressed.emit()
	_view(app, "CreateNewDeckButton").pressed.emit()
	check(
		_view(app, "CreateDeckOverlay").visible
		and not _view(app, "AddDeckMenu").visible
		and _view(app, "CreateDeckOverlay").scene_file_path.ends_with(
			"create_deck_dialog.tscn"
		)
		and _view(app, "ConfirmCreateDeckButton").custom_minimum_size.y == 88.0,
		"Main Create: 새 덱 이름 입력 scene으로 전환"
	)
	_view(app, "ConfirmCreateDeckButton").pressed.emit()
	check(
		_view(app, "CreateDeckErrorLabel").text
		== MainApp.CREATE_DECK_EMPTY_MESSAGE,
		"Main Create: 빈 덱 이름 오류 안내"
	)
	_view(app, "CreateDeckInput").text = "bad/name"
	_view(app, "ConfirmCreateDeckButton").pressed.emit()
	check(
		_view(app, "CreateDeckErrorLabel").text
		== MainApp.CREATE_DECK_INVALID_MESSAGE,
		"Main Create: 파일명에 쓸 수 없는 덱 이름 차단"
	)
	_view(app, "CreateDeckInput").text = "__gd_main"
	_view(app, "ConfirmCreateDeckButton").pressed.emit()
	check(
		_view(app, "CreateDeckErrorLabel").text
		== MainApp.CREATE_DECK_DUPLICATE_MESSAGE,
		"Main Create: 기존 덱과 중복되는 이름 차단"
	)
	_view(app, "CreateDeckInput").text = "  __gd_main_created  "
	_view(app, "ConfirmCreateDeckButton").pressed.emit()
	check(
		_view(app, "CardEditorView").visible
		and _view(app, "CardEditorTitle").text == "첫 카드 추가"
		and not _view(app, "DeleteCardButton").visible
		and not DeckStorage.deck_exists(CREATED_DECK),
		"Main Create: 파일을 만들기 전에 첫 카드 편집으로 진입"
	)
	_view(app, "CardQuestionInput").text = "Draft"
	_view(app, "CancelCardEditButton").pressed.emit()
	_view(app, "DiscardChangesButton").pressed.emit()
	check(
		_view(app, "LibraryContainer").visible
		and not DeckStorage.deck_exists(CREATED_DECK),
		"Main Create: 첫 카드 작성을 취소하면 빈 덱을 남기지 않음"
	)
	create_add_tile = _view(app, "DeckList").get_children()[-1]
	_view(create_add_tile, "AddDeckButton").pressed.emit()
	_view(app, "CreateNewDeckButton").pressed.emit()
	_view(app, "CreateDeckInput").text = "__gd_main_created"
	_view(app, "ConfirmCreateDeckButton").pressed.emit()
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
		and _view(app, "CardRows").get_child_count() == 1,
		"Main Create: 첫 카드 저장 순간 유효한 Markdown 덱 생성"
	)
	check(
		_view(app, "CardListStatusLabel").text
		== "'__gd_main_created' 덱 생성 완료",
		"Main Create: 생성 완료 후 카드 추가가 가능한 목록 표시"
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

	var reorder_test_tile := _find_deck_tile(app, "__gd_main")
	_view(reorder_test_tile, "DeckButton").pressed.emit()
	_view(app, "ManageCardsButton").pressed.emit()
	var reorder_first_row := _view(app, "CardRows").get_child(0) as CardListRow
	var reorder_second_row := _view(app, "CardRows").get_child(1) as CardListRow
	var reorder_resume := StudyResume.new()
	reorder_resume.deck_hash = DeckStorage.read_deck(TEST_DECK).hash()
	reorder_resume.remaining_indices = [0, 1]
	DeckStorage.save_study_resume(TEST_DECK, reorder_resume)
	_view(reorder_first_row, "ReorderHandle").emit_signal("drag_started")
	_view(reorder_first_row, "ReorderHandle").emit_signal(
		"drag_moved",
		reorder_second_row.get_global_rect().get_center()
	)
	_view(reorder_first_row, "ReorderHandle").emit_signal("drag_finished")
	var reordered_cards := DeckParser.parse(DeckStorage.read_deck(TEST_DECK))
	check(
		reordered_cards[0].question == "B"
		and reordered_cards[1].question == "A",
		"Main Card Order: handle drag 순서를 Markdown에 저장"
	)
	check(
		_view(app, "CardListStatusLabel").text == "카드 순서 저장 완료",
		"Main Card Order: 순서 저장 완료 안내"
	)
	check(
		DeckStorage.load_study_resume(TEST_DECK) == null,
		"Main Card Order: 순서가 바뀌면 진행 중 세션 폐기"
	)
	_view(app, "BackFromCardListButton").pressed.emit()
	_view(app, "BackToLibraryButton").pressed.emit()

	created_tile = _find_deck_tile(app, "__gd_main_created")
	reorder_test_tile = _find_deck_tile(app, "__gd_main")
	_view(created_tile, "ReorderHandle").emit_signal("drag_started")
	_view(created_tile, "ReorderHandle").emit_signal(
		"drag_moved",
		reorder_test_tile.get_global_rect().get_center()
	)
	_view(created_tile, "ReorderHandle").emit_signal("drag_finished")
	var saved_deck_order := DeckStorage.load_settings().deck_order
	check(
		saved_deck_order.find(CREATED_DECK) < saved_deck_order.find(TEST_DECK)
		and _view(app, "LibraryStatusLabel").text == "덱 순서 저장 완료",
		"Main Deck Order: handle drag 순서를 설정에 저장"
	)
	app.show_library()
	var visible_deck_order: Array[String] = []
	for child in _view(app, "DeckList").get_children():
		if child is DeckTileView:
			visible_deck_order.append((child as DeckTileView).deck_file())
	check(
		visible_deck_order == DeckStorage.load_settings().deck_order
		and _view(app, "DeckList").get_children()[-1] is AddDeckTileView,
		"Main Deck Order: 다시 열어도 저장 순서를 유지하고 추가 타일은 마지막"
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

	for deck_file in [
		TEST_DECK,
		DELETE_DECK,
		RENAME_DECK,
		RENAMED_DECK,
		DUPLICATED_DECK,
		EDIT_DECK,
		STUDY_EDIT_DECK,
		CREATED_DECK,
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
