extends TestCase

const MVP_SCENE := preload("res://src/mvp/mvp.tscn")
const TEST_DECKS_DIR := "user://__gd_mvp_decks"
const TEST_DECK := "__gd_mvp.md"
const TEST_TEXT := "# A\n1\n# B\n2\n"


func run_tests() -> void:
	_cleanup()
	DeckStorage.set_decks_dir(TEST_DECKS_DIR)
	DeckStorage.write_deck(TEST_DECK, TEST_TEXT)

	var app := MVP_SCENE.instantiate()
	app.auto_start = false
	add_child(app)
	app.show_library()

	check(app.get_node("%LibraryContainer").visible, "MVP: 덱 목록 화면 표시")
	check(not app.get_node("%StudyContainer").visible, "MVP: 덱 목록에서 학습 화면 숨김")
	var deck_buttons := app.get_node("%DeckList").get_children()
	check(deck_buttons.size() == 1, "MVP: 저장된 덱 수만큼 목록 버튼 표시")
	check(deck_buttons[0].text == "__gd_mvp", "MVP: 목록에 덱 표시 이름 사용")
	deck_buttons[0].pressed.emit()
	check(not app.get_node("%LibraryContainer").visible, "MVP: 덱 선택 후 목록 숨김")
	check(app.get_node("%StudyContainer").visible, "MVP: 덱 선택 후 학습 화면 표시")
	app.get_node("%BackToLibraryButton").pressed.emit()
	check(app.get_node("%LibraryContainer").visible, "MVP: 덱 목록 버튼으로 복귀")

	app.start_deck(TEST_DECK)

	check(app.get_node("%DeckLabel").text == "__gd_mvp", "MVP: 덱 이름 표시")
	check(app.get_node("%QuestionLabel").text == "A", "MVP: 첫 질문 표시")
	check(not app.get_node("%AnswerLabel").visible, "MVP: 첫 화면에서 답 숨김")
	check(app.get_node("%RemainingLabel").text == "2장 남음", "MVP: 남은 카드 수 표시")
	check(
		app.get_node("Margin/Page/Title").get_theme_color("font_color") == Color.BLACK,
		"MVP 스타일: 모든 Label 글자는 검은색"
	)
	var card_style := (
		app.get_node("Margin/Page/StudyContainer/Card").get_theme_stylebox("panel")
		as StyleBoxFlat
	)
	check(
		card_style != null
		and card_style.bg_color == Color.WHITE
		and card_style.border_color == Color.BLACK,
		"MVP 스타일: 카드는 흰 바탕과 검은 테두리"
	)
	var button_style := (
		app.get_node("%RevealButton").get_theme_stylebox("normal") as StyleBoxFlat
	)
	check(
		button_style != null
		and button_style.bg_color == Color.WHITE
		and button_style.border_color == Color.BLACK,
		"MVP 스타일: 버튼은 흰 바탕과 검은 테두리"
	)

	app.get_node("%RevealButton").pressed.emit()
	check(app.get_node("%AnswerLabel").visible, "MVP: 답 보기 버튼으로 답 공개")
	check(app.get_node("%AnswerLabel").text == "1", "MVP: 현재 카드의 답 표시")

	app.get_node("%AgainButton").pressed.emit()
	check(app.get_node("%QuestionLabel").text == "B", "MVP: Again 후 다음 질문")
	check(app.get_node("%RemainingLabel").text == "1장 남음", "MVP: Again 후 남은 수 감소")
	check(
		DeckStorage.load_progress(TEST_DECK).get_wrong_count("A") == 1,
		"MVP: Again이 진행도를 저장"
	)

	app.get_node("%GoodButton").pressed.emit()
	check(app.get_node("%DoneContainer").visible, "MVP: 마지막 카드 후 완료 표시")
	check(not app.get_node("%StudyContainer").visible, "MVP: 완료 시 학습 화면 숨김")

	app.get_node("%RestartButton").pressed.emit()
	check(app.get_node("%StudyContainer").visible, "MVP: 다시 시작으로 학습 화면 복귀")
	check(app.get_node("%QuestionLabel").text == "A", "MVP: 다시 시작하면 첫 카드")

	app.start_sample_deck()
	check(app.get_node("%StudyContainer").visible, "MVP: 샘플 덱으로 학습 시작")
	check(
		app.get_node("%QuestionLabel").text == "MyFlashCard는 어떤 앱인가요?",
		"MVP: 앱 소개 샘플 덱의 첫 질문 표시"
	)

	app.queue_free()
	_cleanup()
	DeckStorage.set_decks_dir("")


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_DECKS_DIR):
		for file_name in DirAccess.get_files_at(TEST_DECKS_DIR):
			DirAccess.remove_absolute("%s/%s" % [TEST_DECKS_DIR, file_name])
		DirAccess.remove_absolute(TEST_DECKS_DIR)

	var progress_path := DeckStorage.progress_path(TEST_DECK)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
