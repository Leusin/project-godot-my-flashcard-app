extends TestCase

# Phase 3: 학습 세션 큐와 덱 순서 규칙(StudySession, DeckOrdering).


func run_tests() -> void:
	_test_queue_progression()
	_test_single_and_empty_decks()
	_test_replace_current()
	_test_input_array_is_copied()
	_test_sequential_ordering()
	_test_app_settings_round_trip()
	_test_app_settings_defaults()

func _test_queue_progression() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]
	var session := StudySession.new(cards)

	check(session.current().question == "A", "세션: 첫 카드는 입력 순서의 첫 카드")
	check(session.remaining() == 3, "세션: 시작 시 남은 카드 수")
	check(not session.is_finished(), "세션: 카드가 남아 있으면 진행 중")

	session.next()
	check(session.current().question == "B", "세션: next 후 다음 카드로 이동")
	check(session.remaining() == 2, "세션: next 후 남은 카드 수 감소")

	session.next()
	session.next()
	check(session.is_finished(), "세션: 모든 카드를 넘기면 종료")
	check(session.current() == null, "세션: 종료 후 현재 카드는 null")
	check(session.remaining() == 0, "세션: 종료 후 남은 카드 수는 0")

	session.next()
	check(session.remaining() == 0, "세션: 종료 후 next는 남은 수를 음수로 만들지 않음")


func _test_single_and_empty_decks() -> void:
	var single_cards: Array[FlashCard] = [FlashCard.new("하나", "1")]
	var single := StudySession.new(single_cards)
	single.next()
	check(single.is_finished(), "세션: 카드 한 장은 한 번 넘기면 종료")

	var empty_cards: Array[FlashCard] = []
	var empty := StudySession.new(empty_cards)
	check(empty.is_finished(), "세션: 빈 덱은 처음부터 종료")
	check(empty.current() == null, "세션: 빈 덱의 현재 카드는 null")
	check(empty.remaining() == 0, "세션: 빈 덱의 남은 카드 수는 0")
	empty.next()
	check(empty.is_finished(), "세션: 빈 덱에서 next는 아무 일도 하지 않음")


func _test_replace_current() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
	]
	var session := StudySession.new(cards)

	session.replace_current(FlashCard.new("A2", "1e"))
	check(session.current().question == "A2", "세션: 현재 카드 질문 교체")
	check(session.current().answer == "1e", "세션: 현재 카드 답 교체")
	check(session.remaining() == 2, "세션: 현재 카드 교체 후 남은 수 유지")
	check(cards[0].question == "A", "세션: 현재 카드 교체가 입력 배열을 변경하지 않음")

	session.next()
	check(session.current().question == "B", "세션: 교체 후에도 다음 카드는 유지")
	session.next()
	session.replace_current(FlashCard.new("X", "x"))
	check(session.is_finished(), "세션: 종료 후 카드 교체는 종료 상태를 유지")
	check(session.current() == null, "세션: 종료 후 카드 교체는 아무 일도 하지 않음")


func _test_input_array_is_copied() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
	]
	var session := StudySession.new(cards)

	cards.clear()
	check(session.remaining() == 2, "세션: 생성 후 입력 배열 변경의 영향을 받지 않음")
	check(session.current().question == "A", "세션: 복사한 입력 배열의 첫 카드를 유지")


func _test_sequential_ordering() -> void:
	var cards: Array[FlashCard] = [
		FlashCard.new("A", "1"),
		FlashCard.new("B", "2"),
		FlashCard.new("C", "3"),
	]
	var ordered := DeckOrdering.apply(DeckOrdering.StudyOrder.SEQUENTIAL, cards)

	check(
		ordered.size() == 3
		and ordered[0].question == "A"
		and ordered[1].question == "B"
		and ordered[2].question == "C",
		"순서: Sequential은 입력 순서를 유지"
	)

	ordered.clear()
	check(
		cards.size() == 3
		and cards[0].question == "A"
		and cards[1].question == "B"
		and cards[2].question == "C",
		"순서: Sequential 결과를 변경해도 원본 배열은 유지"
	)
	
func _test_app_settings_round_trip() -> void:
	var settings := AppSettings.new()
	settings.last_deck_file = "영어단어.md"
	settings.deck_dir = "user://test-decks"
	settings.shuffle_study = true

	var restored := AppSettings.from_json(settings.to_json())

	check(
		restored.last_deck_file == "영어단어.md",
		"설정: 마지막 덱 직렬화 왕복"
	)
	check(
		restored.deck_dir == "user://test-decks",
		"설정: 덱 폴더 직렬화 왕복"
	)
	check(
		restored.shuffle_study,
		"설정: 학습 순서 직렬화 왕복"
	)


func _test_app_settings_defaults() -> void:
	var empty := AppSettings.from_json("")

	check(
		empty.last_deck_file.is_empty(),
		"설정: 빈 JSON의 마지막 덱 기본값"
	)
	check(
		empty.deck_dir.is_empty(),
		"설정: 빈 JSON의 덱 폴더 기본값"
	)
	check(
		not empty.shuffle_study,
		"설정: 학습 순서 기본값은 Sequential"
	)

	var malformed := AppSettings.from_json("{깨진 json")
	check(
		malformed.last_deck_file.is_empty()
		and malformed.deck_dir.is_empty()
		and not malformed.shuffle_study,
		"설정: 깨진 JSON은 모든 값을 기본값으로 복구"
	)
